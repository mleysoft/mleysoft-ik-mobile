import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

const _dailyTaskUniqueName = 'mleysoft.dailyHrCheck';
const _dailyTaskName = 'mleysoft_daily_hr_check';

@pragma('vm:entry-point')
void mleysoftBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _dailyTaskName && task != Workmanager.iOSBackgroundTask) return true;
    try {
      return await NotificationService.instance.runDailyBackgroundCheck();
    } catch (_) {
      return true;
    }
  });
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final ValueNotifier<String?> birthdayTapMessage = ValueNotifier<String?>(null);
  bool initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'mleysoft_hr',
      'MleySoft İK Bildirimleri',
      channelDescription: 'Puantaj, vardiya ve personel bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> initialize() async {
    if (initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    try {
      await plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (response) async {
          await _handlePayload(response.payload);
        },
      );

      try {
        final launch = await plugin.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp == true) {
          await _handlePayload(launch?.notificationResponse?.payload);
        }
      } catch (_) {}

      initialized = true;
    } catch (e, st) {
      debugPrint('Notification initialization error: $e\n$st');
      // Bildirim desteği açılamasa bile ana uygulama çalışmaya devam eder.
    }
  }

  Future<void> _handlePayload(String? payload) async {
    if (payload == null || !payload.startsWith('birthday|')) return;
    final message = payload.substring('birthday|'.length);
    if (message.isEmpty) return;
    await storage.write(key: 'pending_birthday_message', value: message);
    birthdayTapMessage.value = message;
  }

  Future<String?> consumeBirthdayMessage() async {
    final direct = birthdayTapMessage.value;
    birthdayTapMessage.value = null;
    final stored = await storage.read(key: 'pending_birthday_message');
    await storage.delete(key: 'pending_birthday_message');
    return (direct != null && direct.isNotEmpty) ? direct : stored;
  }

  Future<bool> hasShownPermissionIntro() async =>
      (await storage.read(key: 'notification_permission_intro')) == '1';

  Future<void> markPermissionIntroShown() async =>
      storage.write(key: 'notification_permission_intro', value: '1');

  Future<bool> requestPermission() async {
    await initialize();
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final androidOk = await android?.requestNotificationsPermission() ?? true;
    final iosOk = await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    await storage.write(key: 'notification_permission_granted', value: (androidOk && iosOk) ? '1' : '0');
    return androidOk && iosOk;
  }

  Future<void> configureDailyChecks({required bool employeeMode}) async {
    await initialize();

    final now = DateTime.now();
    final hour = employeeMode ? 8 : 14;
    var next = DateTime(now.year, now.month, now.day, hour);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    try {
      await Workmanager().registerPeriodicTask(
        _dailyTaskUniqueName,
        _dailyTaskName,
        frequency: const Duration(hours: 24),
        initialDelay: next.difference(now),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (_) {}
  }

  Future<void> cancelDailyChecks() async {
    try {
      await Workmanager().cancelByUniqueName(_dailyTaskUniqueName);
    } catch (_) {}
  }

  Future<bool> runDailyBackgroundCheck() async {
    await initialize();

    final mode = await storage.read(key: 'session_mode');
    final employeeMode = mode == 'employee';
    final now = DateTime.now();

    if (employeeMode && now.hour < 8) return true;
    if (!employeeMode && now.hour < 14) return true;

    final dayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastKey = employeeMode ? 'employee_daily_notification_day' : 'admin_daily_notification_day';
    if (await storage.read(key: lastKey) == dayKey) return true;

    final token = await storage.read(key: 'api_token');
    if (token == null || token.isEmpty) return true;

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://mleysoft.com/system/ik',
    );
    final root = _apiRoot(baseUrl);
    final route = employeeMode ? 'employee/notifications/daily' : 'notifications/daily';

    final response = await http.get(
      Uri.parse('$root/$route'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) return true;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['ok'] != true) return true;

    if (employeeMode) {
      if (decoded['is_birthday'] == true) {
        final title = '${decoded['title'] ?? 'Doğum Günün Kutlu Olsun 🎉'}';
        final body = '${decoded['body'] ?? ''}';
        final full = '${decoded['full_message'] ?? body}';
        await plugin.show(5866, title, body, _details, payload: 'birthday|$full');
      }
      await storage.write(key: lastKey, value: dayKey);
      return true;
    }

    final missing = int.tryParse('${decoded['missing_attendance'] ?? 0}') ?? 0;
    final birthdays = int.tryParse('${decoded['birthday_count'] ?? 0}') ?? 0;
    final birthdayNames = (decoded['birthday_names'] ?? []) as List;
    final shiftExpiring = int.tryParse('${decoded['shift_expiring_count'] ?? 0}') ?? 0;
    final shiftRows = (decoded['shift_expiring'] ?? []) as List;

    if (missing > 0) {
      await plugin.show(5801, 'Puantaj Hatırlatması', 'Bugün $missing personelin puantaj işlemi henüz yapılmadı.', _details);
    }
    if (birthdays > 0) {
      final names = birthdayNames.take(2).join(', ');
      final body = birthdays == 1
          ? 'Bugün $names için doğum günü.'
          : 'Bugün $birthdays personelin doğum günü${names.isEmpty ? '.' : ': $names${birthdays > 2 ? '…' : ''}'}';
      await plugin.show(5802, 'Doğum Günü', body, _details);
    }
    if (shiftExpiring > 0) {
      final first = shiftRows.isNotEmpty ? '${shiftRows.first['person_name']} · ${shiftRows.first['shift_name']}' : '';
      await plugin.show(
        5803,
        'Vardiya Süresi Yaklaşıyor',
        '$shiftExpiring personelin vardiya bitiş tarihi yaklaşıyor${first.isEmpty ? '.' : ': $first${shiftExpiring > 1 ? '…' : ''}'}',
        _details,
      );
    }

    await storage.write(key: lastKey, value: dayKey);
    return true;
  }

  Future<void> showTest() async {
    await initialize();
    await plugin.show(5800, 'MleySoft İK', 'Mobil bildirimler çalışıyor.', _details);
  }

  String _apiRoot(String value) {
    var root = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (root.endsWith('/api/v1')) return root;
    if (root.endsWith('/api')) return '$root/v1';
    return '$root/api/v1';
  }
}

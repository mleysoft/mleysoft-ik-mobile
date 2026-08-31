import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'app_badge_service.dart';
import 'native_notification_permission_service.dart';

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
  final ValueNotifier<int?> announcementTapId = ValueNotifier<int?>(null);
  // V211: Firma push bildirimi tıklamasını Shell'e taşır.
  final ValueNotifier<int?> companyNotificationTapId = ValueNotifier<int?>(null);
  final ValueNotifier<int> unreadAnnouncementCount = ValueNotifier<int>(0);
  // V185: Firma yöneticisi zil rozeti için ayrı okunmamış sayaç.
  final ValueNotifier<int> unreadCompanyNotificationCount = ValueNotifier<int>(0);
  bool initialized = false;
  bool workmanagerInitialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'mleysoft_hr',
      'MleySoft İK Bildirimleri',
      channelDescription: 'Puantaj, vardiya ve personel bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    ),
  );

  Future<void> initialize() async {
    if (initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

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
    if (payload == null || payload.isEmpty) return;
    if (payload.startsWith('birthday|')) {
      final message = payload.substring('birthday|'.length);
      if (message.isEmpty) return;
      await storage.write(key: 'pending_birthday_message', value: message);
      birthdayTapMessage.value = message;
      return;
    }
    if (payload.startsWith('notice|')) {
      final id = int.tryParse(payload.substring('notice|'.length));
      if (id == null || id <= 0) return;
      await storage.write(key: 'pending_announcement_id', value: '$id');
      announcementTapId.value = id;
    }
  }

  Future<void> handleRemoteNotificationTap(int id) async {
    if (id <= 0) return;
    await storage.write(key: 'pending_announcement_id', value: '$id');
    announcementTapId.value = id;
  }

  Future<void> handleCompanyNotificationTap(int id) async {
    if (id <= 0) return;
    await storage.write(key: 'pending_company_notification_id', value: '$id');
    companyNotificationTapId.value = id;
  }

  Future<int?> consumeCompanyNotificationTapId() async {
    final direct = companyNotificationTapId.value;
    companyNotificationTapId.value = null;
    final stored = int.tryParse(await storage.read(key: 'pending_company_notification_id') ?? '');
    await storage.delete(key: 'pending_company_notification_id');
    return direct ?? stored;
  }

  Future<int?> consumeAnnouncementTapId() async {
    final direct = announcementTapId.value;
    announcementTapId.value = null;
    final stored = int.tryParse(await storage.read(key: 'pending_announcement_id') ?? '');
    await storage.delete(key: 'pending_announcement_id');
    return direct ?? stored;
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

  Future<bool> isPermissionGranted() async {
    await initialize();
    if (Platform.isIOS) {
      final status = await NativeNotificationPermissionService.status();
      return status == NativeNotificationAuthorizationStatus.authorized ||
          status == NativeNotificationAuthorizationStatus.provisional ||
          status == NativeNotificationAuthorizationStatus.ephemeral;
    }
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      return await android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (Platform.isIOS) {
      // V118: iOS izni doğrudan UNUserNotificationCenter native bridge üzerinden istenir.
      // Böylece flutter_local_notifications başlatma sırası / scene lifecycle nedeniyle
      // sistem izin penceresinin atlanması engellenir.
      final ok = await NativeNotificationPermissionService.request();
      await storage.write(key: 'notification_permission_granted', value: ok ? '1' : '0');
      return ok;
    }
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidOk = await android?.requestNotificationsPermission() ?? true;
    await storage.write(key: 'notification_permission_granted', value: androidOk ? '1' : '0');
    return androidOk;
  }

  Future<void> initializeBackgroundScheduler() async {
    if (workmanagerInitialized) return;
    try {
      await Workmanager().initialize(mleysoftBackgroundDispatcher);
      workmanagerInitialized = true;
    } catch (e, st) {
      debugPrint('WorkManager initialize error: $e\n$st');
    }
  }

  Future<void> configureDailyChecks({required bool employeeMode}) async {
    await initialize();
    // V115: Giriş anında AppState, main() içindeki asenkron native başlangıçtan önce
    // buraya gelebiliyordu. Bu durumda registerPeriodicTask sessizce başarısız oluyor ve
    // uygulama kapalıyken duyuru kontrolü hiç kaydolmuyordu. WorkManager'ı burada da
    // güvenli biçimde initialize ederek kayıt yarışını ortadan kaldırıyoruz.
    await initializeBackgroundScheduler();

    final now = DateTime.now();
    final hour = employeeMode ? 8 : 14;
    var next = DateTime(now.year, now.month, now.day, hour);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    try {
      await Workmanager().registerPeriodicTask(
        _dailyTaskUniqueName,
        _dailyTaskName,
        frequency: employeeMode ? const Duration(minutes: 15) : const Duration(hours: 24),
        initialDelay: employeeMode ? Duration.zero : next.difference(now),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (_) {}
  }

  Future<void> cancelDailyChecks() async {
    try { await Workmanager().cancelByUniqueName(_dailyTaskUniqueName); } catch (_) {}
    unreadAnnouncementCount.value = 0;
    await AppBadgeService.setCount(0);
  }

  NotificationDetails _announcementDetails(int unread) => NotificationDetails(
    android: AndroidNotificationDetails(
      'mleysoft_announcements',
      'Personel Duyuruları',
      channelDescription: 'Firma yöneticisi tarafından gönderilen personel duyuruları',
      importance: Importance.high,
      priority: Priority.high,
      number: unread > 0 ? unread : null,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: unread,
      interruptionLevel: InterruptionLevel.active,
    ),
  );

  Future<int> pollEmployeeAnnouncements({bool showSystemNotifications = true}) async {
    await initialize();
    final mode = await storage.read(key: 'session_mode');
    if (mode != 'employee') return 0;
    final token = await storage.read(key: 'api_token');
    if (token == null || token.isEmpty) return 0;
    const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://mleysoft.com/system/ik');
    final root = _apiRoot(baseUrl);
    final lastId = int.tryParse(await storage.read(key: 'employee_notice_last_notified_id') ?? '0') ?? 0;
    try {
      final response = await http.get(Uri.parse('$root/employee/notifications/poll?after_id=$lastId'), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
      if (response.statusCode != 200) return unreadAnnouncementCount.value;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['ok'] != true) return unreadAnnouncementCount.value;
      final unread = int.tryParse('${decoded['unread_count'] ?? 0}') ?? 0;
      unreadAnnouncementCount.value = unread;
      await AppBadgeService.setCount(unread);
      final rows = (decoded['notifications'] ?? []) as List;
      var newest = lastId;
      if (showSystemNotifications) {
        for (final raw in rows) {
          if (raw is! Map) continue;
          final id = int.tryParse('${raw['id'] ?? 0}') ?? 0;
          if (id <= 0) continue;
          newest = id > newest ? id : newest;
          final title = '${raw['title'] ?? 'MleySoft İK'}';
          final detail = '${raw['detail'] ?? ''}'.trim();
          final body = detail.length > 180 ? '${detail.substring(0, 177)}...' : detail;
          await plugin.show(700000 + (id % 2000000000), title, body, _announcementDetails(unread), payload: 'notice|$id');
        }
      } else if (rows.isNotEmpty) {
        newest = int.tryParse('${rows.last['id'] ?? lastId}') ?? lastId;
      }
      if (newest > lastId) await storage.write(key: 'employee_notice_last_notified_id', value: '$newest');
      return unread;
    } catch (_) {
      return unreadAnnouncementCount.value;
    }
  }

  Future<void> markRemoteEmployeeNotificationDelivered(int id) async {
    if (id <= 0) return;
    final lastId = int.tryParse(await storage.read(key: 'employee_notice_last_notified_id') ?? '0') ?? 0;
    if (id > lastId) await storage.write(key: 'employee_notice_last_notified_id', value: '$id');
  }

  Future<void> notificationReadLocally(int id, int unread) async {
    unreadAnnouncementCount.value = unread;
    await AppBadgeService.setCount(unread);
    try { await plugin.cancel(700000 + (id % 2000000000)); } catch (_) {}
  }

  Future<bool> runDailyBackgroundCheck() async {
    await initialize();

    final mode = await storage.read(key: 'session_mode');
    final employeeMode = mode == 'employee';
    final now = DateTime.now();

    if (employeeMode) await pollEmployeeAnnouncements(showSystemNotifications: false);
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

    // V194: Otomatik/doğum günü/puantaj/vardiya bildirimleri artık cihazda
    // yerel olarak üretilmez. Görünür bildirimlerin tek kaynağı sunucu cronunun
    // FCM gönderimidir. Bu görev yalnız sessiz veri/sayaç senkronizasyonu yapar.
    await storage.write(key: lastKey, value: dayKey);
    return true;
  }

  Future<void> showRemote(String title, String body, {String? payload}) async {
    await initialize();
    await plugin.show(DateTime.now().millisecondsSinceEpoch.remainder(2000000000), title, body, _details, payload: payload);
  }

  Future<bool> showTest() async {
    await initialize();
    try {
      if (Platform.isIOS) {
        final ios = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
        if (granted != true) return false;
      }
      await plugin.show(5800, 'MleySoft İK', 'Test bildirimi başarıyla oluşturuldu.', _details);
      return true;
    } catch (e, st) {
      debugPrint('Test notification error: $e\n$st');
      return false;
    }
  }

  String _apiRoot(String value) {
    var root = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (root.endsWith('/api/v1')) return root;
    if (root.endsWith('/api')) return '$root/v1';
    return '$root/api/v1';
  }
}

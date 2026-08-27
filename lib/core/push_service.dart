import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api.dart';
import 'device_identity.dart';
import 'notification_service.dart';
import 'native_notification_permission_service.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> mleysoftFirebaseBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: MleyFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}
}

class PushService {
  PushService._();
  static final instance = PushService._();

  bool _firebaseBootstrapped = false;
  bool _ready = false;
  bool _listenersBound = false;
  StreamSubscription<String>? _tokenSubscription;
  Timer? _retryTimer;

  String? lastFcmToken;
  String? lastApnsToken;
  String? lastError;
  int? _activeEmployeeId;

  Future<void> bootstrapForBackground() async {
    if (_firebaseBootstrapped) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: MleyFirebaseOptions.currentPlatform,
        );
      }
      FirebaseMessaging.onBackgroundMessage(
        mleysoftFirebaseBackgroundHandler,
      );
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      _firebaseBootstrapped = true;
      lastError = null;
    } catch (e) {
      _firebaseBootstrapped = false;
      lastError = 'Firebase başlatılamadı: $e';
    }
  }

  Future<void> initialize() async {
    if (_ready) return;
    await bootstrapForBackground();
    if (!_firebaseBootstrapped) return;

    try {
      // V167: Uygulama servis başlangıcında sistem bildirim iznini burada
      // İSTEMEZ. İlk izin penceresini yalnız main.dart yönetir. Böylece native
      // izin onaylandıktan sonra ikinci MleySoft izin ekranının görünmesi engellenir.
      if (Platform.isIOS) {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          await NativeNotificationPermissionService.ensureRemoteRegistration();
        }
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      if (!_listenersBound) {
        FirebaseMessaging.onMessage.listen((m) {
          // Push bildirimi cihazın değil, oturum açmış personelin bildirimidir.
          final targetEmployee =
              int.tryParse('${m.data['employee_id'] ?? 0}') ?? 0;
          if (_activeEmployeeId == null ||
              targetEmployee <= 0 ||
              targetEmployee != _activeEmployeeId) {
            return;
          }
          final n = m.notification;
          if (n != null) {
            NotificationService.instance.showRemote(
              n.title ?? 'MleySoft İK',
              n.body ?? '',
              payload: m.data['notification_id'] == null
                  ? null
                  : 'notice|${m.data['notification_id']}',
            );
          }
        });
        _listenersBound = true;
      }

      _ready = true;
      lastError = null;
    } catch (e) {
      _ready = false;
      lastError = 'Bildirim servisi başlatılamadı: $e';
    }
  }

  Future<String?> _waitForApnsToken() async {
    if (!Platform.isIOS) return '';
    await NativeNotificationPermissionService.ensureRemoteRegistration();

    // V168: Tek bir push kayıt denemesi uygulamayı uzun süre tutmaz.
    // APNs henüz hazır değilse en fazla yaklaşık 3 saniye beklenir ve işlem
    // arka plandaki retry mekanizmasına bırakılır.
    for (var i = 0; i < 6; i++) {
      try {
        final token = await FirebaseMessaging.instance.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          lastApnsToken = token;
          return token;
        }
      } catch (e) {
        lastError = 'APNs token bekleniyor: $e';
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    lastApnsToken = null;
    lastError = 'APNs cihaz tokenı alınamadı.';
    return null;
  }

  Future<void> _registerToken(
    ApiClient api,
    String token,
    Map<String, dynamic> device,
  ) async {
    if (token.isEmpty || api.token == null) return;
    await api.request('employee/push-token', method: 'POST', data: {
      'fcm_token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'device_fingerprint': '${device['device_fingerprint'] ?? ''}',
      'apns_token_present':
          Platform.isIOS && (lastApnsToken?.isNotEmpty ?? false) ? 1 : 0,
    });
    lastFcmToken = token;
    lastError = null;
  }

  Future<bool> registerEmployee(ApiClient api, {int? employeeId}) async {
    if (!_ready) await initialize();
    if (!_ready || api.token == null) return false;
    if (employeeId != null && employeeId > 0) {
      _activeEmployeeId = employeeId;
    }

    try {
      if (Platform.isIOS) {
        final apns = await _waitForApnsToken();
        if (apns == null || apns.isEmpty) {
          _scheduleRetry(api);
          return false;
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        lastError = 'FCM cihaz tokenı alınamadı.';
        _scheduleRetry(api);
        return false;
      }

      final device = await DeviceIdentity.collect();
      await _registerToken(api, token, device);

      await _tokenSubscription?.cancel();
      _tokenSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await _registerToken(api, newToken, device);
        } catch (e) {
          lastError = 'FCM token yenilenemedi: $e';
        }
      });

      _retryTimer?.cancel();
      _retryTimer = null;
      return true;
    } catch (e) {
      lastError = 'Push cihaz kaydı tamamlanamadı: $e';
      _scheduleRetry(api);
      return false;
    }
  }

  void _scheduleRetry(ApiClient api) {
    if (_retryTimer?.isActive == true || api.token == null) return;
    _retryTimer = Timer(const Duration(seconds: 8), () async {
      _retryTimer = null;
      await registerEmployee(api, employeeId: _activeEmployeeId);
    });
  }

  Future<void> unregisterEmployee(ApiClient api) async {
    _retryTimer?.cancel();
    _retryTimer = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;

    // Sunucudaki personel-cihaz eşleşmesini oturum kapanmadan pasifleştir.
    if (api.token != null) {
      try {
        await api.request('employee/push-token/revoke', method: 'POST');
      } catch (_) {}
    }

    _activeEmployeeId = null;
    lastFcmToken = null;
    lastApnsToken = null;

    // FCM token cihazda kalırsa sunucu tarafında bir ağ hatası yaşanan logout'ta
    // eski kullanıcı bildirim almaya devam edebilir. Tokenı cihazda da sil.
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> diagnostics() async {
    String authorization = 'unknown';
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      authorization = settings.authorizationStatus.name;
    } catch (_) {}

    return {
      'firebase_ready': _firebaseBootstrapped,
      'push_ready': _ready,
      'authorization': authorization,
      'apns_token': lastApnsToken ?? '',
      'fcm_token': lastFcmToken ?? '',
      'last_error': lastError ?? '',
      'platform': Platform.isIOS ? 'ios' : 'android',
    };
  }
}

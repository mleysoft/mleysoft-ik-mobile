import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api.dart';
import 'device_identity.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> mleysoftFirebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushService {
  PushService._();
  static final instance = PushService._();

  bool _firebaseBootstrapped = false;
  bool _ready = false;
  StreamSubscription<String>? _tokenSubscription;

  Future<void> bootstrapForBackground() async {
    if (_firebaseBootstrapped) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(mleysoftFirebaseBackgroundHandler);
      _firebaseBootstrapped = true;
    } catch (e) {
      _firebaseBootstrapped = false;
    }
  }

  Future<void> initialize() async {
    if (_ready) return;
    await bootstrapForBackground();
    if (!_firebaseBootstrapped) return;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      FirebaseMessaging.onMessage.listen((m) {
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

      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<String?> _waitForApnsToken() async {
    if (!Platform.isIOS) return '';
    for (var i = 0; i < 24; i++) {
      try {
        final token = await FirebaseMessaging.instance.getAPNSToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  Future<void> _registerToken(ApiClient api, String token, Map<String, dynamic> device) async {
    if (token.isEmpty || api.token == null) return;
    await api.request('employee/push-token', method: 'POST', data: {
      'fcm_token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'device_fingerprint': '${device['device_fingerprint'] ?? ''}',
    });
  }

  Future<void> registerEmployee(ApiClient api) async {
    if (!_ready) await initialize();
    if (!_ready || api.token == null) return;

    try {
      if (Platform.isIOS) {
        final apns = await _waitForApnsToken();
        if (apns == null || apns.isEmpty) {
          // APNs kaydı henüz hazır değilse bir sonraki hydrate/login çağrısında tekrar denenir.
          return;
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final device = await DeviceIdentity.collect();
      await _registerToken(api, token, device);

      await _tokenSubscription?.cancel();
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await _registerToken(api, newToken, device);
        } catch (_) {}
      });
    } catch (_) {}
  }
}

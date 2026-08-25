import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api.dart';
import 'device_identity.dart';
import 'notification_service.dart';

class PushService {
  PushService._();
  static final instance = PushService._();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) NotificationService.instance.showRemote(n.title ?? 'MleySoft İK', n.body ?? '', payload: m.data['notification_id'] == null ? null : 'notice|${m.data['notification_id']}');
      });
      _ready = true;
    } catch (_) {
      // Firebase native config henüz sunucu/mağaza projesine eklenmemişse
      // uygulama açılışını engellemez. Production preflight bunu ayrıca raporlar.
      _ready = false;
    }
  }

  Future<void> registerEmployee(ApiClient api) async {
    if (!_ready || api.token == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final device = await DeviceIdentity.collect();
      await api.request('employee/push-token', method: 'POST', data: {
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'device_fingerprint': '${device['device_fingerprint'] ?? ''}',
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await api.request('employee/push-token', method: 'POST', data: {
            'fcm_token': newToken,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'device_fingerprint': '${device['device_fingerprint'] ?? ''}',
          });
        } catch (_) {}
      });
    } catch (_) {}
  }
}

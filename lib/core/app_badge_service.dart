import 'dart:io';
import 'package:flutter/services.dart';

class AppBadgeService {
  AppBadgeService._();
  static const MethodChannel _channel = MethodChannel('com.mleysoft.ik/badge');

  static Future<void> setCount(int count) async {
    try {
      if (Platform.isIOS) await _channel.invokeMethod('setBadge', {'count': count < 0 ? 0 : count});
      // Android rozetleri launcher'a göre aktif bildirim sayısı/notification number üzerinden yönetilir.
    } catch (_) {}
  }
}

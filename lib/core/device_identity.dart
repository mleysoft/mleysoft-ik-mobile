import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentity {
  static const _storage = FlutterSecureStorage();
  static const _androidId = AndroidId();

  static Future<Map<String, dynamic>> collect() async {
    final plugin = DeviceInfoPlugin();
    String stableId;
    String platform;
    String model = '';
    String os = '';
    Map<String, dynamic> details = {};

    if (Platform.isAndroid) {
      platform = 'Android';
      stableId = (await _androidId.getId()) ?? await _persistentFallback();
      final info = await plugin.androidInfo;
      model = '${info.manufacturer} ${info.model}'.trim();
      os = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
      details = {'brand': info.brand, 'device': info.device, 'product': info.product};
    } else if (Platform.isIOS) {
      platform = 'iOS';
      final info = await plugin.iosInfo;
      final keychainId = await _persistentFallback();
      stableId = '${info.identifierForVendor ?? ''}:$keychainId';
      model = info.utsname.machine;
      os = '${info.systemName} ${info.systemVersion}';
      details = {'name': info.name, 'model': info.model};
    } else {
      platform = Platform.operatingSystem;
      stableId = await _persistentFallback();
      os = Platform.operatingSystemVersion;
    }

    return {
      'device_fingerprint': stableId,
      'platform': platform,
      'device_model': model,
      'os_version': os,
      'device_details': details,
    };
  }

  static Future<String> _persistentFallback() async {
    var value = await _storage.read(key: 'mleysoft_employee_device_key');
    if (value != null && value.isNotEmpty) return value;
    final rnd = Random.secure();
    value = List.generate(32, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await _storage.write(key: 'mleysoft_employee_device_key', value: value);
    return value;
  }
}

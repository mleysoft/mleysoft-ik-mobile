import 'dart:io';
import 'package:flutter/services.dart';

enum NativeNotificationAuthorizationStatus {
  notDetermined,
  denied,
  authorized,
  provisional,
  ephemeral,
  unknown,
}

class NativeNotificationPermissionService {
  static const MethodChannel _channel = MethodChannel('com.mleysoft.ik/permissions');

  static Future<NativeNotificationAuthorizationStatus> status() async {
    if (!Platform.isIOS) return NativeNotificationAuthorizationStatus.unknown;
    try {
      final value = await _channel.invokeMethod<String>('getNotificationAuthorizationStatus');
      switch (value) {
        case 'notDetermined': return NativeNotificationAuthorizationStatus.notDetermined;
        case 'denied': return NativeNotificationAuthorizationStatus.denied;
        case 'authorized': return NativeNotificationAuthorizationStatus.authorized;
        case 'provisional': return NativeNotificationAuthorizationStatus.provisional;
        case 'ephemeral': return NativeNotificationAuthorizationStatus.ephemeral;
        default: return NativeNotificationAuthorizationStatus.unknown;
      }
    } catch (_) {
      return NativeNotificationAuthorizationStatus.unknown;
    }
  }

  static Future<bool> request() async {
    if (!Platform.isIOS) return true;
    try {
      return await _channel.invokeMethod<bool>('requestNotificationPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openSettings() async {
    if (!Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('openNotificationSettings') ?? false;
    } catch (_) {
      return false;
    }
  }
}

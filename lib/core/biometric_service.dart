import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService({LocalAuthentication? auth}) : auth = auth ?? LocalAuthentication();
  final LocalAuthentication auth;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  static const _enabledKey = 'biometric_enabled';

  Future<bool> isSupported() async {
    try {
      final supported = await auth.isDeviceSupported();
      if (!supported) return false;
      return (await auth.getAvailableBiometrics()).isNotEmpty;
    } catch (e, st) {
      debugPrint('Biometric support check failed: $e\n$st');
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      return (await storage.read(key: _enabledKey)) == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await storage.write(key: _enabledKey, value: '1');
    } else {
      await storage.delete(key: _enabledKey);
    }
  }

  Future<bool> authenticate({String reason = 'MleySoft İK hesabınıza giriş yapın'}) async {
    try {
      if (!await auth.isDeviceSupported()) return false;
      if ((await auth.getAvailableBiometrics()).isEmpty) return false;
      return await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
    } catch (e, st) {
      debugPrint('Biometric authentication failed: $e\n$st');
      return false;
    }
  }

  Future<void> stopAuthentication() async {
    try { await auth.stopAuthentication(); } catch (_) {}
  }
}

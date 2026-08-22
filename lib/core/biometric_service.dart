import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService({LocalAuthentication? auth}) : auth = auth ?? LocalAuthentication();
  final LocalAuthentication auth;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  static const _enabledKey = 'biometric_enabled';

  Future<bool> isSupported() async {
    try {
      return await auth.isDeviceSupported() && await auth.canCheckBiometrics;
    } catch (_) {
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
      return await auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

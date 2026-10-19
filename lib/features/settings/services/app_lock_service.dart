import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockSettings {
  const AppLockSettings({
    required this.passwordEnabled,
    required this.biometricsEnabled,
    required this.biometricsAvailable,
  });

  final bool passwordEnabled;
  final bool biometricsEnabled;
  final bool biometricsAvailable;
}

class AppLockService {
  AppLockService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuthentication,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _localAuthentication = localAuthentication ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuthentication;

  Future<AppLockSettings> loadSettings(String userId) async {
    final password = await _storage.read(key: _passwordKey(userId));
    final biometrics = await _storage.read(key: _biometricsKey(userId));
    final availableBiometrics = await _localAuthentication
        .getAvailableBiometrics();

    return AppLockSettings(
      passwordEnabled: password != null,
      biometricsEnabled: biometrics == 'true',
      biometricsAvailable: availableBiometrics.isNotEmpty,
    );
  }

  Future<void> setPassword(String userId, String password) =>
      _storage.write(key: _passwordKey(userId), value: password);

  Future<bool> verifyPassword(String userId, String password) async =>
      await _storage.read(key: _passwordKey(userId)) == password;

  Future<void> setBiometricsEnabled(String userId, bool enabled) async {
    if (enabled) {
      final settings = await loadSettings(userId);
      if (!settings.passwordEnabled || !settings.biometricsAvailable) {
        throw StateError('Biometric unlock is not available.');
      }
      await _storage.write(key: _biometricsKey(userId), value: 'true');
    } else {
      await _storage.delete(key: _biometricsKey(userId));
    }
  }

  Future<bool> authenticateWithBiometrics(String localizedReason) =>
      _localAuthentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
      );

  Future<void> clearForUser(String userId) async {
    await _storage.delete(key: _biometricsKey(userId));
    await _storage.delete(key: _passwordKey(userId));
  }

  String _passwordKey(String userId) => 'app_lock_password_$userId';
  String _biometricsKey(String userId) => 'app_lock_biometrics_$userId';
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/error/exceptions.dart';

abstract class AuthLocalDataSource {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract final class AuthKeys {
  static const pinHash = 'pin_hash';
  static const pinSalt = 'pin_salt';
  static const failedAttempts = 'failed_attempts';
  static const lockedUntil = 'locked_until';
  static const biometricsEnabled = 'biometrics_enabled';
}

@LazySingleton(as: AuthLocalDataSource)
class SecureAuthLocalDataSource implements AuthLocalDataSource {
  const SecureAuthLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _attempt(() => _storage.read(key: key));

  @override
  Future<void> write(String key, String value) =>
      _attempt(() => _storage.write(key: key, value: value));

  @override
  Future<void> delete(String key) => _attempt(() => _storage.delete(key: key));

  Future<T> _attempt<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Exception {
      throw const StorageException();
    }
  }
}

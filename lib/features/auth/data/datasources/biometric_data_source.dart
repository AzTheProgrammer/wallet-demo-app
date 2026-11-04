import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

abstract class BiometricDataSource {
  Future<bool> isAvailable();

  Future<bool> authenticate(String reason);
}

@LazySingleton(as: BiometricDataSource)
class LocalBiometricDataSource implements BiometricDataSource {
  const LocalBiometricDataSource(this._localAuth);

  final LocalAuthentication _localAuth;

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}

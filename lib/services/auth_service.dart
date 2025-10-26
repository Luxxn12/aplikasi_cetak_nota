import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages persisted authentication state and biometric access.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _loggedInKey = 'loggedIn';
  static const _biometricEnabledKey = 'biometricEnabled';

  final LocalAuthentication _localAuth = LocalAuthentication();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs != null) return _prefs!;
    await init();
    return _prefs!;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_loggedInKey, value);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_biometricEnabledKey, value);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _localAuth.canCheckBiometrics;
      return canCheck;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  Future<bool> authenticate({String reason = 'Konfirmasi identitas Anda'}) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}

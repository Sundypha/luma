import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PIN hashing, secure storage, biometric auth, and lock preference flags.
final class LockService {
  LockService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    SharedPreferences? prefs,
    DateTime Function()? clock,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _auth = localAuth ?? LocalAuthentication(),
        _prefs = prefs,
        _clock = clock ?? DateTime.now;

  static const _hashKey = 'lock_pin_hash';
  static const _saltKey = 'lock_pin_salt';
  static const _enabledKey = 'lock_enabled';
  static const _biometricsKey = 'lock_biometrics_enabled';
  static const _failedAttemptsKey = 'lock_failed_attempts';
  static const _lockoutUntilKey = 'lock_lockout_until';

  static final Argon2id _kdf = Argon2id(
    parallelism: 1,
    memory: 8192,
    iterations: 3,
    hashLength: 32,
  );

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;
  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  static const _lockoutThresholds = <int, int>{
    3: 30,
    5: 60,
    7: 300,
    10: 900,
  };

  bool get isEnabled => _prefs?.getBool(_enabledKey) ?? false;

  bool get isBiometricsEnabled => _prefs?.getBool(_biometricsKey) ?? false;

  Future<bool> canUseBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> createPin(String pin) async {
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final secretKey = await _kdf.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    final hashBytes = await secretKey.extractBytes();
    await _storage.write(key: _saltKey, value: base64Encode(salt));
    await _storage.write(key: _hashKey, value: base64Encode(hashBytes));
  }

  Future<bool> verifyPin(String pin) async {
    final saltB64 = await _storage.read(key: _saltKey);
    final hashB64 = await _storage.read(key: _hashKey);
    if (saltB64 == null || hashB64 == null) {
      return false;
    }
    final salt = base64Decode(saltB64);
    final storedHash = base64Decode(hashB64);
    final secretKey = await _kdf.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    final hashBytes = await secretKey.extractBytes();
    if (hashBytes.length != storedHash.length) {
      return false;
    }
    for (var i = 0; i < hashBytes.length; i++) {
      if (hashBytes[i] != storedHash[i]) {
        return false;
      }
    }
    await resetLockoutState();
    return true;
  }

  Future<void> recordFailedAttempt() async {
    final raw = await _storage.read(key: _failedAttemptsKey);
    final count = (raw != null ? int.tryParse(raw) : 0) ?? 0;
    final next = count + 1;
    await _storage.write(key: _failedAttemptsKey, value: next.toString());

    int? lockoutSeconds;
    for (final entry in _lockoutThresholds.entries) {
      if (next >= entry.key) lockoutSeconds = entry.value;
    }
    if (lockoutSeconds != null) {
      final until = _clock().add(Duration(seconds: lockoutSeconds));
      await _storage.write(
        key: _lockoutUntilKey,
        value: until.toUtc().toIso8601String(),
      );
    }
  }

  Future<bool> isLockedOut() async {
    final raw = await _storage.read(key: _lockoutUntilKey);
    if (raw == null) return false;
    final until = DateTime.tryParse(raw);
    if (until == null) return false;
    return _clock().isBefore(until);
  }

  Future<Duration> lockoutRemaining() async {
    final raw = await _storage.read(key: _lockoutUntilKey);
    if (raw == null) return Duration.zero;
    final until = DateTime.tryParse(raw);
    if (until == null) return Duration.zero;
    final diff = until.difference(_clock());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> resetLockoutState() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  Future<bool> authenticateWithBiometrics(String localizedReason) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
      );
    } on LocalAuthException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> enableLock() async {
    await _prefs?.setBool(_enabledKey, true);
  }

  Future<void> disableLock() async {
    await _prefs?.setBool(_enabledKey, false);
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _prefs?.setBool(_biometricsKey, enabled);
  }

  Future<void> deletePinData() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _hashKey);
    return hash != null;
  }
}

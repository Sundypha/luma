import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyStorageKey = 'ptrack_db_encryption_key';

/// Returns the hex-encoded 256-bit database encryption key.
/// Generates and stores a new key on first call.
Future<String> getOrCreateDbEncryptionKey({
  FlutterSecureStorage? storage,
}) async {
  final store = storage ?? const FlutterSecureStorage();
  final existing = await store.read(key: _keyStorageKey);
  if (existing != null && existing.length == 64) {
    return existing;
  }
  final bytes =
      List<int>.generate(32, (_) => Random.secure().nextInt(256));
  final hex =
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  await store.write(key: _keyStorageKey, value: hex);
  return hex;
}

/// Deletes the stored encryption key (for factory reset).
Future<void> deleteDbEncryptionKey({
  FlutterSecureStorage? storage,
}) async {
  final store = storage ?? const FlutterSecureStorage();
  await store.delete(key: _keyStorageKey);
}

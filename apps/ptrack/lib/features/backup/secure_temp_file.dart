import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Generates a cryptographically random hex string of [byteLength] bytes
/// (producing `byteLength * 2` hex characters).
String randomHex(int byteLength) {
  final rng = Random.secure();
  return List.generate(
    byteLength,
    (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// Best-effort zero-fill and delete of a temporary file.
/// A short delay gives the share sheet time to copy the file before removal.
Future<void> secureTempCleanup(File file) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  try {
    if (!file.existsSync()) return;
    final length = file.lengthSync();
    file.writeAsBytesSync(Uint8List(length));
    file.deleteSync();
  } catch (e) {
    debugPrint('Temp file cleanup failed: $e');
  }
}

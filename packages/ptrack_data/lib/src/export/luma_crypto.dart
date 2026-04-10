import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM file payload encryption with Argon2id password KDF.
final class LumaCrypto {
  LumaCrypto._();

  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _macLength = 16;

  static final Argon2id _kdf = Argon2id(
    parallelism: 2,
    memory: 19456,
    iterations: 2,
    hashLength: 32,
  );

  static final AesGcm _aes = AesGcm.with256bits(nonceLength: _nonceLength);

  /// Returns `salt(16) + nonce(12) + ciphertext + mac(16)`.
  static Future<Uint8List> encrypt(List<int> plaintext, String password) async {
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => Random.secure().nextInt(256)),
    );
    final secretKey = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final nonce = _aes.newNonce();
    final box = await _aes.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    final macBytes = box.mac.bytes;
    if (macBytes.length != _macLength) {
      throw StateError(
        'Unexpected AES-GCM MAC length ${macBytes.length} (expected $_macLength)',
      );
    }
    final out = Uint8List(
      _saltLength + _nonceLength + box.cipherText.length + _macLength,
    );
    var offset = 0;
    out.setRange(offset, offset + _saltLength, salt);
    offset += _saltLength;
    out.setRange(offset, offset + _nonceLength, box.nonce);
    offset += _nonceLength;
    out.setRange(offset, offset + box.cipherText.length, box.cipherText);
    offset += box.cipherText.length;
    out.setRange(offset, offset + _macLength, macBytes);
    return out;
  }

  /// Inverts [encrypt]; [SecretBoxAuthenticationError] indicates a bad password.
  static Future<Uint8List> decrypt(List<int> encrypted, String password) async {
    if (encrypted.length < _saltLength + _nonceLength + _macLength) {
      throw FormatException('Encrypted blob too short');
    }
    final salt = encrypted.sublist(0, _saltLength);
    final nonce = encrypted.sublist(_saltLength, _saltLength + _nonceLength);
    final tailStart = encrypted.length - _macLength;
    final cipherText = encrypted.sublist(_saltLength + _nonceLength, tailStart);
    final macBytes = encrypted.sublist(tailStart);
    final secretKey = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final box = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );
    final clear = await _aes.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(clear);
  }
}

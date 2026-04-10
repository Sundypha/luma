import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/src/export/luma_crypto.dart';

void main() {
  test('encrypt then decrypt round-trip returns original bytes', () async {
    final plain = utf8.encode('{"hello":"luma"}');
    final enc = await LumaCrypto.encrypt(plain, 'correct horse battery staple');
    final out = await LumaCrypto.decrypt(enc, 'correct horse battery staple');
    expect(out, plain);
  });

  test('decrypt with wrong password throws authentication error', () async {
    final plain = utf8.encode('secret payload');
    final enc = await LumaCrypto.encrypt(plain, 'password-a');
    expect(
      () => LumaCrypto.decrypt(enc, 'password-b'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('encrypt output is longer than plaintext (overhead)', () async {
    final plain = utf8.encode('x');
    final enc = await LumaCrypto.encrypt(plain, 'p');
    expect(enc.length, greaterThan(plain.length));
  });
}

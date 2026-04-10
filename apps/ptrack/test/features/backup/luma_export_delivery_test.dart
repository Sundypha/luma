import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/backup/secure_temp_file.dart';

void main() {
  group('randomHex', () {
    test('produces correct length for various byte sizes', () {
      expect(randomHex(1).length, 2);
      expect(randomHex(4).length, 8);
      expect(randomHex(8).length, 16);
      expect(randomHex(16).length, 32);
    });

    test('contains only valid lowercase hex characters', () {
      final hex = randomHex(32);
      expect(hex, matches(RegExp(r'^[0-9a-f]+$')));
    });

    test('produces different values on successive calls', () {
      final values = List.generate(10, (_) => randomHex(8));
      expect(values.toSet().length, greaterThan(1));
    });

    test('returns empty string for zero length', () {
      expect(randomHex(0), '');
    });
  });

  group('temp file naming', () {
    test('luma export filename contains random hex, not original filename', () {
      final hex = randomHex(8);
      final filename = 'luma-$hex.luma';
      expect(filename, isNot(contains('backup')));
      expect(filename, matches(RegExp(r'^luma-[0-9a-f]{16}\.luma$')));
    });
  });
}

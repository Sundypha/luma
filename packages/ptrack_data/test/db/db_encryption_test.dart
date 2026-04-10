import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack_data/ptrack_data.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('getOrCreateDbEncryptionKey', () {
    late _MockSecureStorage storage;

    setUp(() {
      storage = _MockSecureStorage();
    });

    test('generates a 64-char hex key on first call', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final key = await getOrCreateDbEncryptionKey(storage: storage);

      expect(key.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key), isTrue);
      verify(() => storage.write(key: any(named: 'key'), value: key)).called(1);
    });

    test('returns existing key when already stored', () async {
      const existingKey =
          'aabbccdd11223344aabbccdd11223344aabbccdd11223344aabbccdd11223344';
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => existingKey);

      final key = await getOrCreateDbEncryptionKey(storage: storage);

      expect(key, existingKey);
      verifyNever(
          () => storage.write(key: any(named: 'key'), value: any(named: 'value')));
    });

    test('generates new key when stored value has wrong length', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'tooshort');
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final key = await getOrCreateDbEncryptionKey(storage: storage);

      expect(key.length, 64);
      verify(() => storage.write(key: any(named: 'key'), value: key)).called(1);
    });

    test('subsequent calls return same key', () async {
      String? stored;
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => stored);
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((inv) async {
        stored = inv.namedArguments[#value] as String;
      });

      final first = await getOrCreateDbEncryptionKey(storage: storage);
      final second = await getOrCreateDbEncryptionKey(storage: storage);

      expect(first, second);
    });
  });

  group('deleteDbEncryptionKey', () {
    late _MockSecureStorage storage;

    setUp(() {
      storage = _MockSecureStorage();
    });

    test('deletes the stored key', () async {
      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await deleteDbEncryptionKey(storage: storage);

      verify(() => storage.delete(key: any(named: 'key'))).called(1);
    });

    test('new key differs after delete', () async {
      String? stored;
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => stored);
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((inv) async {
        stored = inv.namedArguments[#value] as String;
      });
      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {
        stored = null;
      });

      final first = await getOrCreateDbEncryptionKey(storage: storage);
      await deleteDbEncryptionKey(storage: storage);
      final second = await getOrCreateDbEncryptionKey(storage: storage);

      expect(first.length, 64);
      expect(second.length, 64);
      // Cryptographically random — statistically won't match.
      expect(first, isNot(second));
    });
  });
}

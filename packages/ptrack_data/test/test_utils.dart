import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack_data/ptrack_data.dart';

class _MockEncStorage extends Mock implements FlutterSecureStorage {}

/// In-memory secure storage for opening encrypted DBs in VM tests (no plugins).
FlutterSecureStorage createTestDbEncryptionStorage() {
  final store = <String, String>{};
  final m = _MockEncStorage();
  when(() => m.read(key: any(named: 'key'))).thenAnswer(
    (inv) async => store[inv.namedArguments[#key] as String],
  );
  when(
    () => m.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((inv) async {
    final key = inv.namedArguments[#key] as String;
    final value = inv.namedArguments[#value] as String?;
    if (value != null) {
      store[key] = value;
    }
  });
  when(() => m.delete(key: any(named: 'key'))).thenAnswer((inv) async {
    store.remove(inv.namedArguments[#key] as String);
  });
  return m;
}

/// Opens [PtrackDatabase] for VM tests.
///
/// Pass the same [encryptionKeyStorage] when reopening the same file path
/// (e.g. close then open again) so the SQLCipher key matches.
PtrackDatabase openTestPtrackDatabase({
  required String databasePath,
  FlutterSecureStorage? encryptionKeyStorage,
}) {
  return openPtrackDatabase(
    databasePath: databasePath,
    encryptionKeyStorage:
        encryptionKeyStorage ?? createTestDbEncryptionStorage(),
  );
}

/// Creates a temporary directory and registers recursive delete on tear down.
///
/// Returns `path/to/db.sqlite` inside that directory.
String createTempSqlitePath() {
  final dir = Directory.systemTemp.createTempSync('ptrack_data_');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return '${dir.path}/test.sqlite';
}

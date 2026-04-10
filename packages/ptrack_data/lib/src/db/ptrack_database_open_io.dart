import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'db_encryption_key.dart';
import 'ptrack_database.dart';

/// PRAGMAs for SQLCipher v4–compatible files via SQLite3MultipleCiphers
/// (package:sqlite3 with `source: sqlite3mc`). See sqlite3 UPGRADING_TO_V3.md.
void _applySqlcipherMcKey(sqlite.Database db, String hexKey) {
  db.execute("PRAGMA cipher = 'sqlcipher';");
  db.execute('PRAGMA legacy = 4;');
  db.execute("PRAGMA key = \"x'$hexKey'\";");
}

Future<void> _configureSqliteTempOnAndroid() async {
  if (!Platform.isAndroid) return;
  final cacheBase = (await getTemporaryDirectory()).path;
  sqlite.sqlite3.tempDirectory = cacheBase;
}

/// Opens a [QueryExecutor] for the ptrack SQLite database, encrypted with
/// SQLCipher-compatible settings (SQLite3MultipleCiphers). On first launch, a
/// 256-bit key is generated and persisted in platform secure storage. Existing
/// plaintext databases are migrated transparently (in-place [PRAGMA rekey]).
///
/// [encryptionKeyStorage] overrides where the DB key is read/written (e.g. VM
/// tests without platform channels). When null, the default
/// [FlutterSecureStorage] is used.
QueryExecutor openPtrackQueryExecutor({
  String? databasePath,
  FlutterSecureStorage? encryptionKeyStorage,
}) {
  return LazyDatabase(() async {
    await _configureSqliteTempOnAndroid();

    final String resolvedPath;
    if (databasePath != null) {
      resolvedPath = databasePath;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      resolvedPath = p.join(dir.path, 'ptrack.sqlite');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      resolvedPath = p.join(dir.path, 'ptrack.sqlite');
    }

    final file = File(resolvedPath);
    final hexKey = await getOrCreateDbEncryptionKey(
      storage: encryptionKeyStorage,
    );

    if (file.existsSync()) {
      await _migrateIfPlaintext(file, hexKey);
    }

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) => _applySqlcipherMcKey(rawDb, hexKey),
    );
  });
}

/// Opens a [PtrackDatabase] using [openPtrackQueryExecutor].
PtrackDatabase openPtrackDatabase({
  String? databasePath,
  FlutterSecureStorage? encryptionKeyStorage,
}) {
  return PtrackDatabase(
    openPtrackQueryExecutor(
      databasePath: databasePath,
      encryptionKeyStorage: encryptionKeyStorage,
    ),
  );
}

/// Checks whether [file] is an unencrypted SQLite database. If so, encrypts
/// it in place using SQLite3MultipleCiphers ([PRAGMA cipher], [PRAGMA legacy],
/// [PRAGMA rekey]) so it matches SQLCipher v4–style files used by the app.
Future<void> _migrateIfPlaintext(File file, String hexKey) async {
  try {
    if (!_isPlaintextSqlite(file)) return;

    final plainDb = sqlite.sqlite3.open(file.path);
    try {
      plainDb.execute("PRAGMA cipher = 'sqlcipher';");
      plainDb.execute('PRAGMA legacy = 4;');
      plainDb.execute("PRAGMA rekey = \"x'$hexKey'\";");
    } finally {
      plainDb.close();
    }

    debugPrint('ptrack: migrated plaintext database to SQLCipher (sqlite3mc).');
  } on Object catch (e) {
    debugPrint(
      'ptrack: plaintext→encrypted migration failed ($e). '
      'The existing file will be opened as-is; a new encrypted DB will '
      'be created if the key does not match.',
    );
  }
}

/// Returns `true` when the first 16 bytes of [file] start with the SQLite
/// header magic string ("SQLite format 3\0").  Encrypted files will have
/// random bytes instead.
bool _isPlaintextSqlite(File file) {
  try {
    final raf = file.openSync(mode: FileMode.read);
    try {
      final header = raf.readSync(16);
      if (header.length < 16) return false;
      const magic = [
        0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // SQLite f
        0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // ormat 3\0
      ];
      for (var i = 0; i < 16; i++) {
        if (header[i] != magic[i]) return false;
      }
      return true;
    } finally {
      raf.closeSync();
    }
  } on Object {
    return false;
  }
}

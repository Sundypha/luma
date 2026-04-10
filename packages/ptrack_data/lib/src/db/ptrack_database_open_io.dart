import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'db_encryption_key.dart';
import 'ptrack_database.dart';

/// Drift opens SQLite in a background isolate; [open.overrideFor] must run
/// there too before any database API. (Platform channel workaround runs only
/// on the main isolate — see [_prepareSqlcipherOnAndroidMainIsolate].)
void ptrackDriftAndroidSqlcipherIsolateSetup() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}

Future<void> _prepareSqlcipherOnAndroidMainIsolate() async {
  if (!Platform.isAndroid) return;
  // sqlcipher_flutter_libs ships `libsqlcipher.so`; package:sqlite3 defaults
  // to `libsqlite3.so` on Android.
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
}

/// Opens a [QueryExecutor] for the ptrack SQLite database, encrypted with
/// SQLCipher.  On first launch, a 256-bit key is generated and persisted in
/// platform secure storage.  Existing plaintext databases are migrated
/// transparently.
QueryExecutor openPtrackQueryExecutor({String? databasePath}) {
  return LazyDatabase(() async {
    await _prepareSqlcipherOnAndroidMainIsolate();
    if (Platform.isAndroid) {
      final cacheBase = (await getTemporaryDirectory()).path;
      sqlite.sqlite3.tempDirectory = cacheBase;
    }

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
    final hexKey = await getOrCreateDbEncryptionKey();

    if (file.existsSync()) {
      await _migrateIfPlaintext(file, hexKey);
    }

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = \"x'$hexKey'\";");
      },
      isolateSetup: Platform.isAndroid ? ptrackDriftAndroidSqlcipherIsolateSetup : null,
    );
  });
}

/// Opens a [PtrackDatabase] using [openPtrackQueryExecutor].
PtrackDatabase openPtrackDatabase({String? databasePath}) {
  return PtrackDatabase(openPtrackQueryExecutor(databasePath: databasePath));
}

/// Checks whether [file] is an unencrypted SQLite database. If so, migrates
/// it to an encrypted copy using the `sqlcipher_export` extension, then
/// replaces the original file.
Future<void> _migrateIfPlaintext(File file, String hexKey) async {
  try {
    if (!_isPlaintextSqlite(file)) return;

    final encryptedPath = '${file.path}.encrypted';
    final encryptedFile = File(encryptedPath);

    final plainDb = sqlite.sqlite3.open(file.path);
    try {
      plainDb.execute(
        "ATTACH DATABASE '${encryptedPath.replaceAll("'", "''")}' "
        "AS encrypted KEY \"x'$hexKey'\";",
      );
      plainDb.execute("SELECT sqlcipher_export('encrypted');");
      plainDb.execute('DETACH DATABASE encrypted;');
    } finally {
      plainDb.dispose();
    }

    await file.delete();
    await encryptedFile.rename(file.path);

    debugPrint('ptrack: migrated plaintext database to SQLCipher.');
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

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart';

part 'ptrack_database.g.dart';

/// Supported on-disk schema version (`PRAGMA user_version` after migrations).
const int ptrackSupportedSchemaVersion = 1;

/// Opens a [QueryExecutor] for the ptrack SQLite database.
///
/// When [databasePath] is null, uses a default file under the application
/// support directory (desktop) or documents directory pattern from Drift docs.
QueryExecutor openPtrackQueryExecutor({String? databasePath}) {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
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
    return NativeDatabase.createInBackground(file);
  });
}

/// Opens a [PtrackDatabase] using [openPtrackQueryExecutor].
PtrackDatabase openPtrackDatabase({String? databasePath}) {
  return PtrackDatabase(openPtrackQueryExecutor(databasePath: databasePath));
}

@DriftDatabase(tables: [Periods])
class PtrackDatabase extends _$PtrackDatabase {
  PtrackDatabase(super.e);

  @override
  int get schemaVersion => ptrackSupportedSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          await m.database.transaction(() async {
            if (from >= to) return;
            // Future schema bumps: perform steps here inside this transaction.
          });
        },
      );
}

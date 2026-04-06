import 'package:drift/drift.dart';

import 'migrations.dart';
import 'tables.dart';

part 'ptrack_database.g.dart';

/// Supported on-disk schema version (`PRAGMA user_version` after migrations).
const int ptrackSupportedSchemaVersion = 3;

@DriftDatabase(tables: [Periods, DayEntries])
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
          assertSupportedSchemaUpgrade(
            fromVersion: from,
            toVersion: to,
            supported: ptrackSupportedSchemaVersion,
          );
          await m.database.transaction(() async {
            if (from >= to) return;
            if (from < 2) {
              await m.createTable(dayEntries);
            }
            if (from < 3) {
              await customStatement('''
                UPDATE periods
                SET end_utc = COALESCE(
                  (SELECT MAX(date_utc) FROM day_entries WHERE period_id = periods.id),
                  start_utc
                )
                WHERE end_utc IS NULL
              ''');
            }
          });
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

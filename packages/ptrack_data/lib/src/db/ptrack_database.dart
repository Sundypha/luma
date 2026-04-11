import 'package:drift/drift.dart';

import 'migrations.dart';
import 'tables.dart';

part 'ptrack_database.g.dart';

/// Supported on-disk schema version (`PRAGMA user_version` after migrations).
const int ptrackSupportedSchemaVersion = 4;

@DriftDatabase(tables: [Periods, DayEntries])
class PtrackDatabase extends _$PtrackDatabase {
  PtrackDatabase(super.e);

  @override
  int get schemaVersion => ptrackSupportedSchemaVersion;

  /// Ensures [DayEntries.personalNotes] exists (schema v4). Uses raw SQL instead
  /// of [Migrator.addColumn] because SQLCipher / some SQLite builds have been
  /// flaky with generated ALTER from addColumn.
  Future<void> _ensurePersonalNotesColumn() async {
    final cols = await customSelect('PRAGMA table_info(day_entries);').get();
    final hasPersonal = cols.any(
      (row) => row.read<String>('name') == 'personal_notes',
    );
    if (!hasPersonal) {
      await customStatement(
        'ALTER TABLE day_entries ADD COLUMN personal_notes TEXT;',
      );
    }
  }

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
            if (from < 4) {
              await _ensurePersonalNotesColumn();
            }
          });
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Heal installs where user_version already matches v4 but ALTER never ran
          // (migration skipped, partial failure, or pre-fix builds). Without this
          // column, every day_entries write fails and symptom save is impossible.
          try {
            await _ensurePersonalNotesColumn();
          } on Object {
            // e.g. day_entries missing during exotic repair paths
          }
        },
      );
}

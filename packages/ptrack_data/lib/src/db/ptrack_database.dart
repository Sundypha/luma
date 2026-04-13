import 'package:drift/drift.dart';

import 'migrations.dart';
import 'tables.dart';

part 'ptrack_database.g.dart';

/// Supported on-disk schema version (`PRAGMA user_version` after migrations).
const int ptrackSupportedSchemaVersion = 5;

@DriftDatabase(tables: [Periods, DayEntries, DiaryEntries, DiaryTags, DiaryEntryTagJoin])
class PtrackDatabase extends _$PtrackDatabase {
  PtrackDatabase(super.e);

  @override
  int get schemaVersion => ptrackSupportedSchemaVersion;

  /// Ensures legacy `personal_notes` exists on [dayEntries] before v5 migration
  /// reads it. Uses raw SQL instead of [Migrator.addColumn] because SQLCipher /
  /// some SQLite builds have been flaky with generated ALTER from addColumn.
  Future<void> _addPersonalNotesColumnIfMissing() async {
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
            if (from < 5) {
              await _addPersonalNotesColumnIfMissing();
              await m.createTable(diaryEntries);
              await m.createTable(diaryTags);
              await m.createTable(diaryEntryTagJoin);
              await customStatement('''
                INSERT INTO diary_entries (date_utc, mood, notes)
                SELECT DISTINCT date_utc,
                  CASE WHEN personal_notes IS NOT NULL AND TRIM(personal_notes) != ''
                       THEN mood ELSE NULL END,
                  personal_notes
                FROM day_entries
                WHERE personal_notes IS NOT NULL AND TRIM(personal_notes) != ''
              ''');
              await m.alterTable(TableMigration(dayEntries));
            }
          });
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

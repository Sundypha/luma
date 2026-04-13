import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_data/src/db/ptrack_database.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('migrations and schema guard', () {
    test('fresh database creates current schema and rows persist', () async {
      final path = createTempSqlitePath();
      final enc = createTestDbEncryptionStorage();
      var db = openTestPtrackDatabase(
        databasePath: path,
        encryptionKeyStorage: enc,
      );
      final start = DateTime.utc(2024, 5, 1);
      final end = DateTime.utc(2024, 5, 4);
      await db.into(db.periods).insert(periodSpanToInsertCompanion(
        PeriodSpan(startUtc: start, endUtc: end),
      ));
      await db.close();

      db = openTestPtrackDatabase(
        databasePath: path,
        encryptionKeyStorage: enc,
      );
      final rows = await db.select(db.periods).get();
      expect(rows, hasLength(1));
      expect(periodRowToDomain(rows.single).startUtc, start);
      expect(periodRowToDomain(rows.single).endUtc, end);
      final uv = await _readUserVersion(db);
      expect(uv, ptrackSupportedSchemaVersion);
      await db.close();
    });

    test('committed v1 fixture survives open and maps rows', () async {
      final fixture = File('test/fixtures/ptrack_v1.sqlite');
      expect(fixture.existsSync(), isTrue, reason: 'run tool/create_v1_fixture.dart');

      final path = createTempSqlitePath();
      await fixture.copy(path);

      final db = openTestPtrackDatabase(databasePath: path);
      final rows = await db.select(db.periods).get();
      expect(rows, hasLength(2));

      final first = periodRowToDomain(rows[0]);
      expect(first.startUtc, DateTime.utc(2024, 2, 1));
      expect(first.endUtc, DateTime.utc(2024, 2, 5));

      final second = periodRowToDomain(rows[1]);
      expect(second.startUtc, DateTime.utc(2024, 3, 1));
      expect(second.endUtc, DateTime.utc(2024, 3, 1));

      final uv = await _readUserVersion(db);
      expect(uv, ptrackSupportedSchemaVersion);
      await db.close();
    });

    test('committed v2 fixture migrates to schema 3 and closes open period', () async {
      final fixture = File('test/fixtures/ptrack_v2.sqlite');
      expect(fixture.existsSync(), isTrue, reason: 'run tool/create_v2_fixture.dart');

      final path = createTempSqlitePath();
      await fixture.copy(path);

      final db = openTestPtrackDatabase(databasePath: path);
      try {
        expect(await _readUserVersion(db), ptrackSupportedSchemaVersion);
        final periods = await db.select(db.periods).get();
        expect(periods, hasLength(2));
        expect(periodRowToDomain(periods[0]).endUtc, DateTime.utc(2024, 2, 5));
        expect(periodRowToDomain(periods[1]).startUtc, DateTime.utc(2024, 3, 1));
        expect(
          periodRowToDomain(periods[1]).endUtc,
          DateTime.utc(2024, 3, 1),
          reason: 'open period without day entries closes to start_utc',
        );
        final days = await db.select(db.dayEntries).get();
        expect(days, hasLength(1));
        expect(
          dayEntryRowToDomain(days.single),
          DayEntryData(
            dateUtc: DateTime.utc(2024, 2, 2),
            flowIntensity: FlowIntensity.medium,
            painScore: PainScore.mild,
            mood: Mood.good,
            notes: 'fixture v2',
          ),
        );
        final colInfo =
            await db.customSelect('PRAGMA table_info(day_entries);').get();
        expect(
          colInfo.any((r) => r.read<String>('name') == 'personal_notes'),
          isTrue,
          reason: 'schema v4 adds personal_notes for diary field',
        );
      } finally {
        await db.close();
      }
    });

    test(
      'v2 database migrates to v3: closes open periods using day entry max or start',
      () async {
        int sec(DateTime d) => d.toUtc().millisecondsSinceEpoch ~/ 1000;

        final path = createTempSqlitePath();
        final raw = sqlite.sqlite3.open(path);
        try {
          raw.execute('''
CREATE TABLE periods (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  start_utc INTEGER NOT NULL,
  end_utc INTEGER
);
''');
          raw.execute('''
CREATE TABLE day_entries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  period_id INTEGER NOT NULL REFERENCES periods (id),
  date_utc INTEGER NOT NULL,
  flow_intensity INTEGER,
  pain_score INTEGER,
  mood INTEGER,
  notes TEXT,
  UNIQUE (period_id, date_utc)
);
''');

          final s1 = sec(DateTime.utc(2024, 6, 1));
          final s2 = sec(DateTime.utc(2024, 7, 1));
          final s3 = sec(DateTime.utc(2024, 8, 1));
          final e3 = sec(DateTime.utc(2024, 8, 10));
          raw.execute(
            'INSERT INTO periods (start_utc, end_utc) VALUES ($s1, NULL)',
          );
          raw.execute(
            'INSERT INTO periods (start_utc, end_utc) VALUES ($s2, NULL)',
          );
          raw.execute(
            'INSERT INTO periods (start_utc, end_utc) VALUES ($s3, $e3)',
          );
          final dLow = sec(DateTime.utc(2024, 7, 3));
          final dHigh = sec(DateTime.utc(2024, 7, 20));
          raw.execute('''
INSERT INTO day_entries (period_id, date_utc, flow_intensity)
VALUES (2, $dLow, 1), (2, $dHigh, 1);
''');
          raw.execute('PRAGMA user_version = 2');
        } finally {
          raw.close();
        }

        final db = openTestPtrackDatabase(databasePath: path);
        try {
          expect(await _readUserVersion(db), ptrackSupportedSchemaVersion);
          final periods = await db.select(db.periods).get()..sort((a, b) => a.id.compareTo(b.id));
          expect(periods, hasLength(3));

          expect(periodRowToDomain(periods[0]).endUtc, DateTime.utc(2024, 6, 1));

          expect(periodRowToDomain(periods[1]).endUtc, DateTime.utc(2024, 7, 20));

          expect(periodRowToDomain(periods[2]).endUtc, DateTime.utc(2024, 8, 10));
        } finally {
          await db.close();
        }
      },
    );

    test(
      'v1 fixture upgrades to v2 with DayEntries table and preserves periods',
      () async {
        final fixture = File('test/fixtures/ptrack_v1.sqlite');
        expect(fixture.existsSync(), isTrue, reason: 'run tool/create_v1_fixture.dart');

        final path = createTempSqlitePath();
        await fixture.copy(path);

        final db = openTestPtrackDatabase(databasePath: path);
        try {
          expect(await _readUserVersion(db), ptrackSupportedSchemaVersion);

          final periods = await db.select(db.periods).get();
          expect(periods, hasLength(2));
          expect(periodRowToDomain(periods[0]).startUtc, DateTime.utc(2024, 2, 1));
          expect(periodRowToDomain(periods[1]).startUtc, DateTime.utc(2024, 3, 1));

          final day = DayEntryData(
            dateUtc: DateTime.utc(2024, 2, 3),
            flowIntensity: FlowIntensity.light,
            painScore: PainScore.none,
            mood: Mood.good,
            notes: 'ok',
          );
          await db.into(db.dayEntries).insert(
                dayEntryDataToInsertCompanion(periods.first.id, day),
              );

          final days = await db.select(db.dayEntries).get();
          expect(days, hasLength(1));
          expect(dayEntryRowToDomain(days.single), day);

          await expectLater(
            db.into(db.dayEntries).insert(
                  DayEntriesCompanion.insert(
                    periodId: 99999,
                    dateUtc: DateTime.utc(2024, 1, 1),
                  ),
                ),
            throwsA(
              predicate<Object>(
                (e) =>
                    e.toString().contains('FOREIGN KEY') ||
                    e.toString().contains('foreign key'),
              ),
            ),
          );
        } finally {
          await db.close();
        }
      },
    );

    test(
      'v4 database with personal_notes migrates to v5: diary row, column dropped',
      () async {
        int sec(DateTime d) => d.toUtc().millisecondsSinceEpoch ~/ 1000;

        final path = createTempSqlitePath();
        final raw = sqlite.sqlite3.open(path);
        try {
          raw.execute('''
CREATE TABLE periods (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  start_utc INTEGER NOT NULL,
  end_utc INTEGER
);
''');
          raw.execute('''
CREATE TABLE day_entries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  period_id INTEGER NOT NULL REFERENCES periods (id),
  date_utc INTEGER NOT NULL,
  flow_intensity INTEGER,
  pain_score INTEGER,
  mood INTEGER,
  notes TEXT,
  personal_notes TEXT,
  UNIQUE (period_id, date_utc)
);
''');
          final p1 = sec(DateTime.utc(2024, 3, 1));
          final p1e = sec(DateTime.utc(2024, 3, 31));
          final p2 = sec(DateTime.utc(2024, 4, 1));
          final p2e = sec(DateTime.utc(2024, 4, 30));
          raw.execute(
            'INSERT INTO periods (start_utc, end_utc) VALUES ($p1, $p1e)',
          );
          raw.execute(
            'INSERT INTO periods (start_utc, end_utc) VALUES ($p2, $p2e)',
          );
          final d1 = sec(DateTime.utc(2024, 3, 10));
          final d2 = sec(DateTime.utc(2024, 3, 11));
          final d3 = sec(DateTime.utc(2024, 3, 12));
          raw.execute('''
INSERT INTO day_entries (period_id, date_utc, personal_notes, mood)
VALUES
  (1, $d1, 'My diary entry', ${Mood.good.dbValue}),
  (1, $d2, '', ${Mood.neutral.dbValue}),
  (1, $d3, NULL, ${Mood.bad.dbValue});
''');
          raw.execute('PRAGMA user_version = 4');
        } finally {
          raw.close();
        }

        final db = openTestPtrackDatabase(databasePath: path);
        try {
          expect(await _readUserVersion(db), ptrackSupportedSchemaVersion);

          final diaryRows =
              await db.customSelect('SELECT * FROM diary_entries').get();
          expect(diaryRows, hasLength(1));
          final dr = diaryRows.single;
          expect(dr.read<int>('mood'), Mood.good.dbValue);
          expect(dr.read<String?>('notes'), 'My diary entry');
          final dateRaw = dr.read<int>('date_utc');
          expect(
            DateTime.fromMillisecondsSinceEpoch(dateRaw * 1000, isUtc: true),
            DateTime.utc(2024, 3, 10),
          );

          final dayCols =
              await db.customSelect('PRAGMA table_info(day_entries);').get();
          expect(
            dayCols.any((r) => r.read<String>('name') == 'personal_notes'),
            isFalse,
          );

          final diaryCols =
              await db.customSelect('PRAGMA table_info(diary_entries);').get();
          final diaryNames = [for (final c in diaryCols) c.read<String>('name')];
          expect(diaryNames, containsAll(['id', 'date_utc', 'mood', 'notes']));

          final tagCols =
              await db.customSelect('PRAGMA table_info(diary_tags);').get();
          expect(
            [for (final c in tagCols) c.read<String>('name')],
            containsAll(['id', 'name']),
          );

          final joinCols = await db
              .customSelect('PRAGMA table_info(diary_entry_tag_join);')
              .get();
          expect(
            [for (final c in joinCols) c.read<String>('name')],
            containsAll(['diary_entry_id', 'tag_id']),
          );
        } finally {
          await db.close();
        }
      },
    );

    test('fresh database creates all five tables at v5 without personal_notes',
        () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      try {
        expect(await _readUserVersion(db), ptrackSupportedSchemaVersion);

        final tables = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' "
              "AND name NOT LIKE 'sqlite_%' ORDER BY name",
            )
            .get();
        final names = {for (final r in tables) r.read<String>('name')};
        expect(
          names,
          containsAll([
            'periods',
            'day_entries',
            'diary_entries',
            'diary_tags',
            'diary_entry_tag_join',
          ]),
        );

        final dayCols =
            await db.customSelect('PRAGMA table_info(day_entries);').get();
        expect(
          dayCols.any((r) => r.read<String>('name') == 'personal_notes'),
          isFalse,
        );
      } finally {
        await db.close();
      }
    });

    test('on-disk user_version newer than app fails closed', () async {
      final path = createTempSqlitePath();
      final raw = sqlite.sqlite3.open(path);
      try {
        raw.execute('''
CREATE TABLE periods (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  start_utc INTEGER NOT NULL,
  end_utc INTEGER
);
''');
        raw.execute('PRAGMA user_version = 99');
      } finally {
        raw.close();
      }

      final db = openTestPtrackDatabase(databasePath: path);
      try {
        await expectLater(
          db.customSelect('SELECT 1 AS c').getSingle(),
          throwsA(
            predicate<Object>(
              (e) =>
                  e is PtrackUnsupportedDatabaseSchemaException ||
                  e.toString().contains('database schema version 99'),
            ),
          ),
        );
      } finally {
        await db.close();
      }

      final raw2 = sqlite.sqlite3.open(path);
      try {
        final uv = raw2.select('PRAGMA user_version').first.columnAt(0) as int;
        expect(uv, 99);
      } finally {
        raw2.close();
      }
    });
  });
}

Future<int> _readUserVersion(PtrackDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}

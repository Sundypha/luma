import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('migrations and schema guard', () {
    test('fresh database creates v1 schema and rows persist', () async {
      final path = createTempSqlitePath();
      var db = openPtrackDatabase(databasePath: path);
      final start = DateTime.utc(2024, 5, 1);
      final end = DateTime.utc(2024, 5, 4);
      await db.into(db.periods).insert(periodSpanToInsertCompanion(
        PeriodSpan(startUtc: start, endUtc: end),
      ));
      await db.close();

      db = openPtrackDatabase(databasePath: path);
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

      final db = openPtrackDatabase(databasePath: path);
      final rows = await db.select(db.periods).get();
      expect(rows, hasLength(2));

      final first = periodRowToDomain(rows[0]);
      expect(first.startUtc, DateTime.utc(2024, 2, 1));
      expect(first.endUtc, DateTime.utc(2024, 2, 5));

      final second = periodRowToDomain(rows[1]);
      expect(second.startUtc, DateTime.utc(2024, 3, 1));
      expect(second.endUtc, isNull);

      final uv = await _readUserVersion(db);
      expect(uv, 1);
      await db.close();
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
        raw.dispose();
      }

      final db = openPtrackDatabase(databasePath: path);
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
        raw2.dispose();
      }
    });
  });
}

Future<int> _readUserVersion(PtrackDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}

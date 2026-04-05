import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  late PeriodCalendarContext utcCtx;

  setUp(() {
    utcCtx = PeriodCalendarContext.fromTimeZoneName('UTC');
  });

  group('PeriodRepository', () {
    test('successful insert and list round-trip', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final span = PeriodSpan(
        startUtc: DateTime.utc(2024, 5, 1),
        endUtc: DateTime.utc(2024, 5, 4),
      );
      final out = await repo.insertPeriod(span);
      expect(out, isA<PeriodWriteSuccess>());
      final id = (out as PeriodWriteSuccess).id;

      final listed = await repo.listOrderedByStartUtc();
      expect(listed, hasLength(1));
      expect(listed.single.id, id);
      expect(listed.single.span, span);
      await db.close();
    });

    test('rejected duplicate start calendar day does not persist', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);

      final first = await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 6, 1, 8),
          endUtc: DateTime.utc(2024, 6, 4),
        ),
      );
      expect(first, isA<PeriodWriteSuccess>());

      final second = await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 6, 1, 20),
          endUtc: DateTime.utc(2024, 6, 5),
        ),
      );
      expect(second, isA<PeriodWriteRejected>());
      final rej = second as PeriodWriteRejected;
      expect(rej.issues, contains(isA<DuplicateStartCalendarDay>()));

      final listed = await repo.listOrderedByStartUtc();
      expect(listed, hasLength(1));
      await db.close();
    });

    test('create, close, reopen preserves rows (migration path)', () async {
      final path = createTempSqlitePath();
      var db = openPtrackDatabase(databasePath: path);
      var repo = PeriodRepository(database: db, calendar: utcCtx);
      await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 1, 1),
          endUtc: DateTime.utc(2024, 1, 5),
        ),
      );
      await repo.insertPeriod(
        PeriodSpan(startUtc: DateTime.utc(2024, 2, 1), endUtc: null),
      );
      await db.close();

      db = openPtrackDatabase(databasePath: path);
      repo = PeriodRepository(database: db, calendar: utcCtx);
      final listed = await repo.listOrderedByStartUtc();
      expect(listed, hasLength(2));
      expect(listed.first.span.startUtc, DateTime.utc(2024, 1, 1));
      expect(listed.last.span.isOpen, isTrue);
      await db.close();
    });

    test('update succeeds when validation passes', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final inserted = await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 7, 1),
          endUtc: DateTime.utc(2024, 7, 4),
        ),
      );
      final id = (inserted as PeriodWriteSuccess).id;

      final out = await repo.updatePeriod(
        id,
        PeriodSpan(
          startUtc: DateTime.utc(2024, 7, 1),
          endUtc: DateTime.utc(2024, 7, 6),
        ),
      );
      expect(out, isA<PeriodWriteSuccess>());

      final listed = await repo.listOrderedByStartUtc();
      expect(listed.single.span.endUtc, DateTime.utc(2024, 7, 6));
      await db.close();
    });
  });

  group('day entry CRUD and watch', () {
    test('saveDayEntry creates entry linked to period', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 8, 1),
          endUtc: DateTime.utc(2024, 8, 5),
        ),
      ) as PeriodWriteSuccess)
          .id;

      final dayId = await repo.saveDayEntry(
        periodId,
        DayEntryData(
          dateUtc: DateTime.utc(2024, 8, 2),
          flowIntensity: FlowIntensity.medium,
        ),
      );
      expect(dayId, greaterThan(0));

      final rows = await db.select(db.dayEntries).get();
      expect(rows, hasLength(1));
      expect(rows.single.periodId, periodId);
      expect(rows.single.flowIntensity, FlowIntensity.medium.dbValue);
      await db.close();
    });

    test('saveDayEntry for non-existent period throws', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      await expectLater(
        repo.saveDayEntry(
          999,
          DayEntryData(dateUtc: DateTime.utc(2024, 9, 1)),
        ),
        throwsA(isA<StateError>()),
      );
      await db.close();
    });

    test('updateDayEntry modifies existing entry', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 10, 1),
          endUtc: DateTime.utc(2024, 10, 5),
        ),
      ) as PeriodWriteSuccess)
          .id;
      final dayId = await repo.saveDayEntry(
        periodId,
        DayEntryData(
          dateUtc: DateTime.utc(2024, 10, 2),
          flowIntensity: FlowIntensity.medium,
        ),
      );
      final ok = await repo.updateDayEntry(
        dayId,
        DayEntryData(
          dateUtc: DateTime.utc(2024, 10, 2),
          flowIntensity: FlowIntensity.heavy,
        ),
      );
      expect(ok, isTrue);
      final row = await (db.select(db.dayEntries)
            ..where((t) => t.id.equals(dayId)))
          .getSingle();
      expect(row.flowIntensity, FlowIntensity.heavy.dbValue);
      await db.close();
    });

    test('deleteDayEntry removes only the target entry', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 11, 1),
          endUtc: DateTime.utc(2024, 11, 5),
        ),
      ) as PeriodWriteSuccess)
          .id;
      final id1 = await repo.saveDayEntry(
        periodId,
        DayEntryData(dateUtc: DateTime.utc(2024, 11, 2)),
      );
      await repo.saveDayEntry(
        periodId,
        DayEntryData(dateUtc: DateTime.utc(2024, 11, 3)),
      );
      final removed = await repo.deleteDayEntry(id1);
      expect(removed, isTrue);
      final rows = await db.select(db.dayEntries).get();
      expect(rows, hasLength(1));
      final d = rows.single.dateUtc;
      expect(
        DateTime.utc(d.year, d.month, d.day),
        DateTime.utc(2024, 11, 3),
      );
      await db.close();
    });

    test('deletePeriod cascades to day entries', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 12, 1),
          endUtc: DateTime.utc(2024, 12, 5),
        ),
      ) as PeriodWriteSuccess)
          .id;
      await repo.saveDayEntry(
        periodId,
        DayEntryData(dateUtc: DateTime.utc(2024, 12, 2)),
      );
      await repo.saveDayEntry(
        periodId,
        DayEntryData(dateUtc: DateTime.utc(2024, 12, 3)),
      );
      final ok = await repo.deletePeriod(periodId);
      expect(ok, isTrue);
      expect(await db.select(db.dayEntries).get(), isEmpty);
      expect(await db.select(db.periods).get(), isEmpty);
      await db.close();
    });

    test('watchPeriodsWithDays emits updated list after insert', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 5, 1),
          endUtc: DateTime.utc(2024, 5, 4),
        ),
      ) as PeriodWriteSuccess)
          .id;

      final queue = StreamQueue(repo.watchPeriodsWithDays());
      try {
        final first = await queue.next;
        expect(first, hasLength(1));
        expect(first.single.period.id, periodId);
        expect(first.single.dayEntries, isEmpty);

        await repo.saveDayEntry(
          periodId,
          DayEntryData(
            dateUtc: DateTime.utc(2024, 5, 2),
            flowIntensity: FlowIntensity.medium,
          ),
        );

        final second = await queue.next;
        expect(second, hasLength(1));
        expect(second.single.dayEntries, hasLength(1));
        expect(
          second.single.dayEntries.single.data.flowIntensity,
          FlowIntensity.medium,
        );
      } finally {
        await queue.cancel();
        await db.close();
      }
    });
  });
}

import 'package:async/async.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'test_utils.dart';

/// Mirrors [PeriodRepository.watchPeriodsWithDays] load semantics for assertions.
Future<List<StoredPeriodWithDays>> _expectedWatchSnapshotFromDb(
  PtrackDatabase db,
) async {
  final periodRows = await (db.select(db.periods)
        ..orderBy([(t) => OrderingTerm.desc(t.startUtc)]))
      .get();
  final result = <StoredPeriodWithDays>[];
  for (final r in periodRows) {
    final dayRows = await (db.select(db.dayEntries)
          ..where((t) => t.periodId.equals(r.id))
          ..orderBy([(t) => OrderingTerm.asc(t.dateUtc)]))
        .get();
    final days = <StoredDayEntry>[];
    for (final d in dayRows) {
      days.add(
        StoredDayEntry(
          id: d.id,
          periodId: d.periodId,
          data: dayEntryRowToDomain(d),
        ),
      );
    }
    result.add(
      StoredPeriodWithDays(
        period: StoredPeriod(id: r.id, span: periodRowToDomain(r)),
        dayEntries: days,
      ),
    );
  }
  return result;
}

void _expectStoredPeriodListsEqual(
  List<StoredPeriodWithDays> actual,
  List<StoredPeriodWithDays> expected,
) {
  expect(actual, hasLength(expected.length));
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i].period.id, expected[i].period.id);
    expect(actual[i].period.span, expected[i].period.span);
    expect(actual[i].dayEntries, hasLength(expected[i].dayEntries.length));
    for (var j = 0; j < expected[i].dayEntries.length; j++) {
      expect(actual[i].dayEntries[j].id, expected[i].dayEntries[j].id);
      expect(actual[i].dayEntries[j].periodId, expected[i].dayEntries[j].periodId);
      expect(actual[i].dayEntries[j].data, expected[i].dayEntries[j].data);
    }
  }
}

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
      final db = openTestPtrackDatabase(databasePath: path);
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
      final db = openTestPtrackDatabase(databasePath: path);
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
      final enc = createTestDbEncryptionStorage();
      var db = openTestPtrackDatabase(
        databasePath: path,
        encryptionKeyStorage: enc,
      );
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

      db = openTestPtrackDatabase(
        databasePath: path,
        encryptionKeyStorage: enc,
      );
      repo = PeriodRepository(database: db, calendar: utcCtx);
      final listed = await repo.listOrderedByStartUtc();
      expect(listed, hasLength(2));
      expect(listed.first.span.startUtc, DateTime.utc(2024, 1, 1));
      expect(listed.last.span.isOpen, isTrue);
      await db.close();
    });

    test('update succeeds when validation passes', () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
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
      final db = openTestPtrackDatabase(databasePath: path);
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
      final db = openTestPtrackDatabase(databasePath: path);
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
      final db = openTestPtrackDatabase(databasePath: path);
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
      final db = openTestPtrackDatabase(databasePath: path);
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

    test('clearClinicalSymptoms deletes row when no personal notes', () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 11, 1),
          endUtc: DateTime.utc(2024, 11, 5),
        ),
      ) as PeriodWriteSuccess)
          .id;
      final id = await repo.saveDayEntry(
        periodId,
        DayEntryData(
          dateUtc: DateTime.utc(2024, 11, 2),
          flowIntensity: FlowIntensity.light,
          notes: 'clinical',
        ),
      );
      final ok = await repo.clearClinicalSymptoms(id);
      expect(ok, isTrue);
      expect(await db.select(db.dayEntries).get(), isEmpty);
      await db.close();
    });

    test('clearClinicalSymptoms keeps row when personal notes non-empty',
        () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 11, 1),
          endUtc: DateTime.utc(2024, 11, 5),
        ),
      ) as PeriodWriteSuccess)
          .id;
      final id = await repo.saveDayEntry(
        periodId,
        DayEntryData(
          dateUtc: DateTime.utc(2024, 11, 2),
          flowIntensity: FlowIntensity.light,
          notes: 'clinical',
        ),
      );
      await DiaryRepository(database: db).saveEntry(
        DiaryEntryData(
          dateUtc: DateTime.utc(2024, 11, 2),
          notes: 'keep me',
        ),
      );
      final ok = await repo.clearClinicalSymptoms(id);
      expect(ok, isTrue);
      final rows = await db.select(db.dayEntries).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, id);
      expect(row.flowIntensity, isNull);
      expect(row.notes, isNull);
      final diary = await db.select(db.diaryEntries).get();
      expect(diary, hasLength(1));
      expect(diary.single.notes, 'keep me');
      await db.close();
    });

    test('deletePeriod cascades to day entries', () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
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

    test('updatePeriod returns blocked when day entries fall outside new span',
        () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 8, 1),
          endUtc: DateTime.utc(2024, 8, 10),
        ),
      ) as PeriodWriteSuccess)
          .id;
      await repo.saveDayEntry(
        periodId,
        DayEntryData(dateUtc: DateTime.utc(2024, 8, 9)),
      );
      final out = await repo.updatePeriod(
        periodId,
        PeriodSpan(
          startUtc: DateTime.utc(2024, 8, 1),
          endUtc: DateTime.utc(2024, 8, 5),
        ),
      );
      expect(out, isA<PeriodWriteBlockedByOrphanDayEntries>());
      final blocked = out as PeriodWriteBlockedByOrphanDayEntries;
      expect(blocked.orphanEntryIds, hasLength(1));
      await db.close();
    });

    test('updatePeriodDeletingOrphanDayEntries applies shrink', () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 8, 1),
          endUtc: DateTime.utc(2024, 8, 10),
        ),
      ) as PeriodWriteSuccess)
          .id;
      await repo.saveDayEntry(
        periodId,
        DayEntryData(dateUtc: DateTime.utc(2024, 8, 9)),
      );
      final newSpan = PeriodSpan(
        startUtc: DateTime.utc(2024, 8, 1),
        endUtc: DateTime.utc(2024, 8, 5),
      );
      final blocked = await repo.updatePeriod(periodId, newSpan);
      expect(blocked, isA<PeriodWriteBlockedByOrphanDayEntries>());
      final ids = (blocked as PeriodWriteBlockedByOrphanDayEntries).orphanEntryIds;
      final done = await repo.updatePeriodDeletingOrphanDayEntries(
        periodId,
        newSpan,
        ids,
      );
      expect(done, isA<PeriodWriteSuccess>());
      expect(await db.select(db.dayEntries).get(), isEmpty);
      final p = await (db.select(db.periods)..where((t) => t.id.equals(periodId)))
          .getSingle();
      expect(periodRowToDomain(p).endUtc, DateTime.utc(2024, 8, 5));
      await db.close();
    });

    test('updatePeriodSplittingOrphansIntoNewPeriod moves rows', () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 9, 1),
          endUtc: DateTime.utc(2024, 9, 20),
        ),
      ) as PeriodWriteSuccess)
          .id;
      await repo.saveDayEntry(
        periodId,
        DayEntryData(dateUtc: DateTime.utc(2024, 9, 18)),
      );
      final newSpan = PeriodSpan(
        startUtc: DateTime.utc(2024, 9, 1),
        endUtc: DateTime.utc(2024, 9, 15),
      );
      final blocked = await repo.updatePeriod(periodId, newSpan);
      final ids = (blocked as PeriodWriteBlockedByOrphanDayEntries).orphanEntryIds;
      final done = await repo.updatePeriodSplittingOrphansIntoNewPeriod(
        periodId,
        newSpan,
        ids,
      );
      expect(done, isA<PeriodWriteSuccess>());
      final periods = await db.select(db.periods).get();
      expect(periods, hasLength(2));
      final days = await db.select(db.dayEntries).get();
      expect(days, hasLength(1));
      expect(days.single.periodId, isNot(periodId));
      await db.close();
    });

    test('upsertDayEntryForPeriod inserts then updates same calendar day',
        () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final periodId = (await repo.insertPeriod(
        PeriodSpan(
          startUtc: DateTime.utc(2024, 10, 1),
          endUtc: null,
        ),
      ) as PeriodWriteSuccess)
          .id;
      final id1 = await repo.upsertDayEntryForPeriod(
        periodId,
        DayEntryData(
          dateUtc: DateTime.utc(2024, 10, 2),
          flowIntensity: FlowIntensity.light,
        ),
      );
      final id2 = await repo.upsertDayEntryForPeriod(
        periodId,
        DayEntryData(
          dateUtc: DateTime.utc(2024, 10, 2),
          flowIntensity: FlowIntensity.heavy,
        ),
      );
      expect(id2, id1);
      final rows = await db.select(db.dayEntries).get();
      expect(rows, hasLength(1));
      expect(
        FlowIntensity.fromDbValue(rows.single.flowIntensity!),
        FlowIntensity.heavy,
      );
      await db.close();
    });

    test('watchPeriodsWithDays emits updated list after insert', () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
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

    test(
      'watchPeriodsWithDays matches direct-query snapshot for many periods',
      () async {
        final path = createTempSqlitePath();
        final db = openTestPtrackDatabase(databasePath: path);
        final repo = PeriodRepository(database: db, calendar: utcCtx);

        // Insert order != watch order; watch uses newest [startUtc] first.
        final spans = <PeriodSpan>[
          PeriodSpan(
            startUtc: DateTime.utc(2024, 1, 1),
            endUtc: DateTime.utc(2024, 1, 4),
          ),
          PeriodSpan(
            startUtc: DateTime.utc(2024, 3, 10),
            endUtc: DateTime.utc(2024, 3, 14),
          ),
          PeriodSpan(
            startUtc: DateTime.utc(2024, 2, 5),
            endUtc: DateTime.utc(2024, 2, 9),
          ),
          PeriodSpan(
            startUtc: DateTime.utc(2024, 5, 1),
            endUtc: DateTime.utc(2024, 5, 6),
          ),
          PeriodSpan(
            startUtc: DateTime.utc(2024, 4, 1),
            endUtc: DateTime.utc(2024, 4, 5),
          ),
        ];
        final periodIds = <int>[];
        for (final span in spans) {
          final id = (await repo.insertPeriod(span) as PeriodWriteSuccess).id;
          periodIds.add(id);
        }

        // Multiple days per period; save in reverse date order to assert sort.
        Future<void> saveDays(int periodIndex, List<DateTime> datesUtc) async {
          final pid = periodIds[periodIndex];
          for (final d in datesUtc.reversed) {
            await repo.saveDayEntry(
              pid,
              DayEntryData(
                dateUtc: d,
                flowIntensity: FlowIntensity.light,
              ),
            );
          }
        }

        await saveDays(0, [
          DateTime.utc(2024, 1, 1),
          DateTime.utc(2024, 1, 2),
          DateTime.utc(2024, 1, 3),
        ]);
        await saveDays(1, [
          DateTime.utc(2024, 3, 12),
          DateTime.utc(2024, 3, 10),
          DateTime.utc(2024, 3, 11),
        ]);
        await saveDays(2, [
          DateTime.utc(2024, 2, 6),
          DateTime.utc(2024, 2, 5),
        ]);
        await saveDays(3, [
          DateTime.utc(2024, 5, 1),
          DateTime.utc(2024, 5, 3),
          DateTime.utc(2024, 5, 2),
          DateTime.utc(2024, 5, 4),
        ]);
        await saveDays(4, [
          DateTime.utc(2024, 4, 2),
          DateTime.utc(2024, 4, 4),
          DateTime.utc(2024, 4, 3),
        ]);

        final expected = await _expectedWatchSnapshotFromDb(db);
        expect(expected, hasLength(5));

        // Newest period first (May → Apr → Mar → Feb → Jan).
        expect(
          expected.map((e) => e.period.span.startUtc),
          orderedEquals([
            DateTime.utc(2024, 5, 1),
            DateTime.utc(2024, 4, 1),
            DateTime.utc(2024, 3, 10),
            DateTime.utc(2024, 2, 5),
            DateTime.utc(2024, 1, 1),
          ]),
        );
        for (final block in expected) {
          final dates = block.dayEntries
              .map((e) => DateTime.utc(
                    e.data.dateUtc.year,
                    e.data.dateUtc.month,
                    e.data.dateUtc.day,
                  ))
              .toList();
          expect(dates, orderedEquals([...dates]..sort()));
        }

        final queue = StreamQueue(repo.watchPeriodsWithDays());
        try {
          final first = await queue.next;
          _expectStoredPeriodListsEqual(first, expected);
        } finally {
          await queue.cancel();
          await db.close();
        }
      },
    );
  });

  group('markDay/unmarkDay', () {
    test('markDay on empty DB creates single-day period', () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final out = await repo.markDay(DateTime.utc(2025, 1, 15));
      expect(out, isA<DayMarkSuccess>());
      final id = (out as DayMarkSuccess).periodId;
      expect(id, isNotNull);
      final listed = await repo.listOrderedByStartUtc();
      expect(listed.single.span.startUtc, DateTime.utc(2025, 1, 15));
      expect(listed.single.span.endUtc, DateTime.utc(2025, 1, 15));
      await db.close();
    });

    test('markDay adjacent to existing period extends', () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      await repo.markDay(DateTime.utc(2025, 2, 1));
      await repo.markDay(DateTime.utc(2025, 2, 2));
      final listed = await repo.listOrderedByStartUtc();
      expect(listed, hasLength(1));
      expect(listed.single.span.startUtc, DateTime.utc(2025, 2, 1));
      expect(listed.single.span.endUtc, DateTime.utc(2025, 2, 2));
      await db.close();
    });

    test('markDay bridging two periods merges and reassigns day entries',
        () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      await repo.markDay(DateTime.utc(2025, 3, 1));
      await repo.markDay(DateTime.utc(2025, 3, 2));
      final id2 =
          (await repo.markDay(DateTime.utc(2025, 3, 4)) as DayMarkSuccess)
              .periodId!;
      await repo.markDay(DateTime.utc(2025, 3, 5));
      await repo.saveDayEntry(
        id2,
        DayEntryData(dateUtc: DateTime.utc(2025, 3, 5)),
      );
      final listedBefore = await repo.listOrderedByStartUtc();
      expect(listedBefore, hasLength(2));
      final pidLeft = listedBefore[0].id;
      final pidRight = listedBefore[1].id;
      final out = await repo.markDay(DateTime.utc(2025, 3, 3));
      expect(out, isA<DayMarkSuccess>());
      final periods = await db.select(db.periods).get();
      expect(periods, hasLength(1));
      final keepId = periods.single.id;
      expect(keepId, pidLeft < pidRight ? pidLeft : pidRight);
      final days = await db.select(db.dayEntries).get();
      expect(days, hasLength(1));
      expect(days.single.periodId, keepId);
      expect(periodRowToDomain(periods.single).startUtc, DateTime.utc(2025, 3, 1));
      expect(periodRowToDomain(periods.single).endUtc, DateTime.utc(2025, 3, 5));
      await db.close();
    });

    test('unmarkDay on single-day period deletes period and its day entries',
        () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      final id =
          (await repo.markDay(DateTime.utc(2025, 4, 1)) as DayMarkSuccess)
              .periodId!;
      await repo.saveDayEntry(
        id,
        DayEntryData(dateUtc: DateTime.utc(2025, 4, 1)),
      );
      final out = await repo.unmarkDay(DateTime.utc(2025, 4, 1));
      expect(out, isA<DayMarkSuccess>());
      expect(await db.select(db.periods).get(), isEmpty);
      expect(await db.select(db.dayEntries).get(), isEmpty);
      await db.close();
    });

    test('unmarkDay on edge of multi-day period shrinks and removes day entry',
        () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      await repo.markDay(DateTime.utc(2025, 5, 1));
      await repo.markDay(DateTime.utc(2025, 5, 2));
      await repo.markDay(DateTime.utc(2025, 5, 3));
      final listed = await repo.listOrderedByStartUtc();
      final pid = listed.single.id;
      await repo.saveDayEntry(
        pid,
        DayEntryData(dateUtc: DateTime.utc(2025, 5, 3)),
      );
      await repo.unmarkDay(DateTime.utc(2025, 5, 3));
      final rows = await db.select(db.periods).get();
      expect(rows, hasLength(1));
      expect(periodRowToDomain(rows.single).endUtc, DateTime.utc(2025, 5, 2));
      expect(await db.select(db.dayEntries).get(), isEmpty);
      await db.close();
    });

    test('unmarkDay on middle of period splits and distributes day entries',
        () async {
      final path = createTempSqlitePath();
      final db = openTestPtrackDatabase(databasePath: path);
      final repo = PeriodRepository(database: db, calendar: utcCtx);
      for (var d = 1; d <= 7; d++) {
        await repo.markDay(DateTime.utc(2025, 6, d));
      }
      final listed = await repo.listOrderedByStartUtc();
      final pid = listed.single.id;
      await repo.saveDayEntry(
        pid,
        DayEntryData(
          dateUtc: DateTime.utc(2025, 6, 2),
          notes: 'left',
        ),
      );
      await repo.saveDayEntry(
        pid,
        DayEntryData(
          dateUtc: DateTime.utc(2025, 6, 6),
          notes: 'right',
        ),
      );
      await repo.unmarkDay(DateTime.utc(2025, 6, 4));
      final periods = await db.select(db.periods).get()
        ..sort((a, b) => a.startUtc.compareTo(b.startUtc));
      expect(periods, hasLength(2));
      expect(periodRowToDomain(periods[0]).startUtc, DateTime.utc(2025, 6, 1));
      expect(periodRowToDomain(periods[0]).endUtc, DateTime.utc(2025, 6, 3));
      expect(periodRowToDomain(periods[1]).startUtc, DateTime.utc(2025, 6, 5));
      expect(periodRowToDomain(periods[1]).endUtc, DateTime.utc(2025, 6, 7));
      final days = await db.select(db.dayEntries).get()
        ..sort((a, b) => a.dateUtc.compareTo(b.dateUtc));
      expect(days, hasLength(2));
      expect(days[0].periodId, periods[0].id);
      expect(days[1].periodId, periods[1].id);
      await db.close();
    });
  });
}

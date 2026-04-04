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
}

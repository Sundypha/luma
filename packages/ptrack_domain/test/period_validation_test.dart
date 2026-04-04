import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  late PeriodCalendarContext utcCtx;
  late PeriodCalendarContext nyCtx;

  setUp(() {
    utcCtx = PeriodCalendarContext(tz.UTC);
    nyCtx = PeriodCalendarContext.fromTimeZoneName('America/New_York');
  });

  group('validateForSave', () {
    test('allows first period closed', () {
      final candidate = PeriodSpan(
        startUtc: DateTime.utc(2026, 1, 1, 12),
        endUtc: DateTime.utc(2026, 1, 5, 12),
      );
      final r = PeriodValidation.validateForSave(
        candidate: candidate,
        existing: const [],
        calendar: utcCtx,
      );
      expect(r.isValid, isTrue);
    });

    test('rejects end strictly before start', () {
      final candidate = PeriodSpan(
        startUtc: DateTime.utc(2026, 1, 5),
        endUtc: DateTime.utc(2026, 1, 1),
      );
      final r = PeriodValidation.validateForSave(
        candidate: candidate,
        existing: const [],
        calendar: utcCtx,
      );
      expect(r.isValid, isFalse);
      expect(r.issues, contains(isA<EndBeforeStart>()));
    });

    test('allows single-day span (start and end same calendar day in context)', () {
      final candidate = PeriodSpan(
        startUtc: DateTime.utc(2026, 2, 10, 8),
        endUtc: DateTime.utc(2026, 2, 10, 20),
      );
      final r = PeriodValidation.validateForSave(
        candidate: candidate,
        existing: const [],
        calendar: utcCtx,
      );
      expect(r.isValid, isTrue);
    });

    test('rejects overlap with existing closed period', () {
      final existing = [
        PeriodSpan(
          startUtc: DateTime.utc(2026, 3, 1),
          endUtc: DateTime.utc(2026, 3, 7),
        ),
      ];
      final candidate = PeriodSpan(
        startUtc: DateTime.utc(2026, 3, 5),
        endUtc: DateTime.utc(2026, 3, 10),
      );
      final r = PeriodValidation.validateForSave(
        candidate: candidate,
        existing: existing,
        calendar: utcCtx,
      );
      expect(r.isValid, isFalse);
      expect(
        r.issues.whereType<OverlappingPeriod>().single.existingIndex,
        0,
      );
    });

    test('rejects overlap with open existing period', () {
      final existing = [
        PeriodSpan(startUtc: DateTime.utc(2026, 4, 1)),
      ];
      final candidate = PeriodSpan(
        startUtc: DateTime.utc(2026, 4, 10),
        endUtc: DateTime.utc(2026, 4, 12),
      );
      final r = PeriodValidation.validateForSave(
        candidate: candidate,
        existing: existing,
        calendar: utcCtx,
      );
      expect(r.isValid, isFalse);
      expect(r.issues.whereType<OverlappingPeriod>(), isNotEmpty);
    });

    test('rejects second start on same local calendar day (America/New_York)', () {
      // Two UTC instants on 2026-05-10 local (EDT): same calendar start day.
      final existingAdjusted = [
        PeriodSpan(
          startUtc: DateTime.utc(2026, 5, 10, 10),
          endUtc: DateTime.utc(2026, 5, 11),
        ),
      ];
      expect(
        nyCtx.localCalendarDateForUtc(existingAdjusted.single.startUtc),
        const CalendarDate(2026, 5, 10),
      );
      final candidate = PeriodSpan(
        startUtc: DateTime.utc(2026, 5, 10, 20),
        endUtc: DateTime.utc(2026, 5, 12),
      );
      expect(
        nyCtx.localCalendarDateForUtc(candidate.startUtc),
        const CalendarDate(2026, 5, 10),
      );
      final r = PeriodValidation.validateForSave(
        candidate: candidate,
        existing: existingAdjusted,
        calendar: nyCtx,
      );
      expect(r.isValid, isFalse);
      expect(r.issues.whereType<DuplicateStartCalendarDay>(), isNotEmpty);
    });
  });

  group('PeriodSpan.completedOnly', () {
    test('drops open periods', () {
      final all = [
        PeriodSpan(startUtc: DateTime.utc(2026, 1, 1), endUtc: DateTime.utc(2026, 1, 3)),
        PeriodSpan(startUtc: DateTime.utc(2026, 2, 1)),
        PeriodSpan(startUtc: DateTime.utc(2026, 3, 1), endUtc: DateTime.utc(2026, 3, 4)),
      ];
      final completed = PeriodSpan.completedOnly(all).toList();
      expect(completed, hasLength(2));
      expect(completed.every((p) => p.isCompleted), isTrue);
    });
  });
}

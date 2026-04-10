import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('completedCycleBetweenStarts', () {
    test('28-day example in UTC calendar context (Jan 1 → Jan 29 next start)', () {
      final cal = PeriodCalendarContext(tz.UTC);
      final c = completedCycleBetweenStarts(
        periodStartUtc: DateTime.utc(2026, 1, 1, 15),
        nextPeriodStartUtc: DateTime.utc(2026, 1, 29, 9),
        calendar: cal,
      );
      expect(c.lengthInDays, 28);
    });

    test('1-day cycle when next start is the following local day', () {
      final cal = PeriodCalendarContext(tz.UTC);
      final c = completedCycleBetweenStarts(
        periodStartUtc: DateTime.utc(2026, 6, 1),
        nextPeriodStartUtc: DateTime.utc(2026, 6, 2),
        calendar: cal,
      );
      expect(c.lengthInDays, 1);
    });

    test('throws when next start is not after current start (local days)', () {
      final cal = PeriodCalendarContext(tz.UTC);
      expect(
        () => completedCycleBetweenStarts(
          periodStartUtc: DateTime.utc(2026, 7, 10),
          nextPeriodStartUtc: DateTime.utc(2026, 7, 10),
          calendar: cal,
        ),
        throwsArgumentError,
      );
    });

    test('DST-adjacent local days use timezone calendar, not UTC subtraction', () {
      final cal = PeriodCalendarContext.fromTimeZoneName('America/New_York');
      // Span includes US spring forward 2024-03-10; length is by **local** calendar days.
      final c = completedCycleBetweenStarts(
        periodStartUtc: DateTime.utc(2024, 3, 8, 17),
        nextPeriodStartUtc: DateTime.utc(2024, 3, 10, 17),
        calendar: cal,
      );
      expect(cal.localCalendarDateForUtc(c.periodStartUtc), const CalendarDate(2024, 3, 8));
      expect(cal.localCalendarDateForUtc(c.nextPeriodStartUtc), const CalendarDate(2024, 3, 10));
      // Next start local Mar 10 → last cycle day Mar 9 → inclusive Mar 8–9 → 2 days.
      expect(c.lengthInDays, 2);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import 'package:ptrack/features/calendar/calendar_day_data.dart';

StoredPeriodWithDays _period({
  required int id,
  required DateTime startUtc,
  DateTime? endUtc,
  List<StoredDayEntry> dayEntries = const [],
}) {
  return StoredPeriodWithDays(
    period: StoredPeriod(
      id: id,
      span: PeriodSpan(startUtc: startUtc, endUtc: endUtc),
    ),
    dayEntries: dayEntries,
  );
}

void main() {
  group('buildCalendarDayDataMap', () {
    const predictionNone = PredictionInsufficientHistory(
      completedCyclesAvailable: 0,
      minCompletedCyclesNeeded: 2,
    );

    test('single-day period yields single', () {
      final day = DateTime.utc(2025, 1, 15, 12);
      final map = buildCalendarDayDataMap(
        periodsWithDays: [
          _period(
            id: 1,
            startUtc: day,
            endUtc: day,
          ),
        ],
        prediction: predictionNone,
        today: DateTime.utc(2025, 1, 20),
      );
      final key = DateTime.utc(2025, 1, 15);
      expect(map[key]?.loggedPeriodState, PeriodDayState.single);
    });

    test('multi-day period (3 days) yields start, middle, end', () {
      final map = buildCalendarDayDataMap(
        periodsWithDays: [
          _period(
            id: 1,
            startUtc: DateTime.utc(2025, 1, 10),
            endUtc: DateTime.utc(2025, 1, 12),
          ),
        ],
        prediction: predictionNone,
        today: DateTime.utc(2025, 1, 20),
        startingDayOfWeek: DateTime.monday,
      );
      expect(
        map[DateTime.utc(2025, 1, 10)]?.loggedPeriodState,
        PeriodDayState.start,
      );
      expect(
        map[DateTime.utc(2025, 1, 11)]?.loggedPeriodState,
        PeriodDayState.middle,
      );
      expect(
        map[DateTime.utc(2025, 1, 12)]?.loggedPeriodState,
        PeriodDayState.end,
      );
    });

    test('period spanning week boundary (Mon start week) row-aware states', () {
      // Fri 10 – Tue 14 Jan 2025; Mon-first week rows.
      final map = buildCalendarDayDataMap(
        periodsWithDays: [
          _period(
            id: 1,
            startUtc: DateTime.utc(2025, 1, 10),
            endUtc: DateTime.utc(2025, 1, 14),
          ),
        ],
        prediction: predictionNone,
        today: DateTime.utc(2025, 1, 20),
        startingDayOfWeek: DateTime.monday,
      );
      expect(
        map[DateTime.utc(2025, 1, 10)]?.loggedPeriodState,
        PeriodDayState.start,
      );
      expect(
        map[DateTime.utc(2025, 1, 11)]?.loggedPeriodState,
        PeriodDayState.middle,
      );
      expect(
        map[DateTime.utc(2025, 1, 12)]?.loggedPeriodState,
        PeriodDayState.middleRowEnd,
      );
      expect(
        map[DateTime.utc(2025, 1, 13)]?.loggedPeriodState,
        PeriodDayState.middleRowStart,
      );
      expect(
        map[DateTime.utc(2025, 1, 14)]?.loggedPeriodState,
        PeriodDayState.end,
      );
    });

    test('PredictionRangeOnly marks predicted days', () {
      final map = buildCalendarDayDataMap(
        periodsWithDays: [],
        prediction: PredictionRangeOnly(
          rangeStartUtc: DateTime.utc(2025, 2, 1),
          rangeEndUtc: DateTime.utc(2025, 2, 3),
        ),
        today: DateTime.utc(2025, 1, 1),
      );
      expect(map[DateTime.utc(2025, 2, 1)]?.isPredictedPeriod, isTrue);
      expect(map[DateTime.utc(2025, 2, 2)]?.isPredictedPeriod, isTrue);
      expect(map[DateTime.utc(2025, 2, 3)]?.isPredictedPeriod, isTrue);
    });

    test('logged period overrides prediction for same day', () {
      final map = buildCalendarDayDataMap(
        periodsWithDays: [
          _period(
            id: 1,
            startUtc: DateTime.utc(2025, 3, 5),
            endUtc: DateTime.utc(2025, 3, 5),
          ),
        ],
        prediction: PredictionRangeOnly(
          rangeStartUtc: DateTime.utc(2025, 3, 1),
          rangeEndUtc: DateTime.utc(2025, 3, 10),
        ),
        today: DateTime.utc(2025, 3, 15),
      );
      final key = DateTime.utc(2025, 3, 5);
      expect(map[key]?.loggedPeriodState, PeriodDayState.single);
      expect(map[key]?.isPredictedPeriod, isFalse);
    });

    test('day entries set hasLoggedData', () {
      final map = buildCalendarDayDataMap(
        periodsWithDays: [
          _period(
            id: 1,
            startUtc: DateTime.utc(2025, 4, 1),
            endUtc: DateTime.utc(2025, 4, 5),
            dayEntries: [
              StoredDayEntry(
                id: 1,
                periodId: 1,
                data: DayEntryData(
                  dateUtc: DateTime.utc(2025, 4, 3),
                  mood: Mood.good,
                ),
              ),
            ],
          ),
        ],
        prediction: predictionNone,
        today: DateTime.utc(2025, 4, 10),
      );
      expect(
        map[DateTime.utc(2025, 4, 3)]?.hasLoggedData,
        isTrue,
      );
    });

    test('today is flagged', () {
      final today = DateTime.utc(2025, 5, 7);
      final map = buildCalendarDayDataMap(
        periodsWithDays: [],
        prediction: predictionNone,
        today: today,
      );
      expect(map[DateTime.utc(2025, 5, 7)]?.isToday, isTrue);
    });

    test('PredictionInsufficientHistory adds no predicted days', () {
      final map = buildCalendarDayDataMap(
        periodsWithDays: [],
        prediction: predictionNone,
        today: DateTime.utc(2025, 6, 1),
      );
      expect(
        map.values.where((e) => e.isPredictedPeriod),
        isEmpty,
      );
    });

    test('empty periods yields map with at least today only', () {
      final today = DateTime.utc(2025, 7, 4);
      final map = buildCalendarDayDataMap(
        periodsWithDays: [],
        prediction: predictionNone,
        today: today,
      );
      expect(map.length, 1);
      expect(map.containsKey(DateTime.utc(2025, 7, 4)), isTrue);
    });

    test('open period walks through today', () {
      final map = buildCalendarDayDataMap(
        periodsWithDays: [
          _period(
            id: 1,
            startUtc: DateTime.utc(2025, 8, 10),
            endUtc: null,
          ),
        ],
        prediction: predictionNone,
        today: DateTime.utc(2025, 8, 12),
      );
      expect(map.containsKey(DateTime.utc(2025, 8, 10)), isTrue);
      expect(map.containsKey(DateTime.utc(2025, 8, 11)), isTrue);
      expect(map.containsKey(DateTime.utc(2025, 8, 12)), isTrue);
      expect(map.containsKey(DateTime.utc(2025, 8, 13)), isFalse);
    });

    test('PredictionPointWithRange uses range when present', () {
      final map = buildCalendarDayDataMap(
        periodsWithDays: [],
        prediction: PredictionPointWithRange(
          pointStartUtc: DateTime.utc(2025, 9, 10),
          rangeStartUtc: DateTime.utc(2025, 9, 9),
          rangeEndUtc: DateTime.utc(2025, 9, 11),
        ),
        today: DateTime.utc(2025, 8, 1),
      );
      expect(map[DateTime.utc(2025, 9, 9)]?.isPredictedPeriod, isTrue);
      expect(map[DateTime.utc(2025, 9, 10)]?.isPredictedPeriod, isTrue);
      expect(map[DateTime.utc(2025, 9, 11)]?.isPredictedPeriod, isTrue);
    });

    test('PredictionPointWithRange falls back to point when range null', () {
      final point = DateTime.utc(2025, 10, 1);
      final map = buildCalendarDayDataMap(
        periodsWithDays: [],
        prediction: PredictionPointWithRange(
          pointStartUtc: point,
        ),
        today: DateTime.utc(2025, 8, 1),
      );
      expect(map[DateTime.utc(2025, 10, 1)]?.isPredictedPeriod, isTrue);
    });
  });
}

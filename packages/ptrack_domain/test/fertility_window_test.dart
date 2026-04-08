import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  group('FertilityWindowCalculator.compute', () {
    test('28-day cycle, 14-day luteal: table row 2026-01-01', () {
      final w = FertilityWindowCalculator.compute(
        lastPeriodStartUtc: DateTime.utc(2026, 1, 1),
        cycleLengthDays: 28,
        lutealPhaseDays: 14,
      );
      expect(w, isNotNull);
      expect(w!.estimatedOvulationUtc, DateTime.utc(2026, 1, 14));
      expect(w.startUtc, DateTime.utc(2026, 1, 9));
      expect(w.endUtc, DateTime.utc(2026, 1, 15));
    });

    test('30-day cycle: table row 2026-03-01', () {
      final w = FertilityWindowCalculator.compute(
        lastPeriodStartUtc: DateTime.utc(2026, 3, 1),
        cycleLengthDays: 30,
        lutealPhaseDays: 14,
      );
      expect(w, isNotNull);
      expect(w!.estimatedOvulationUtc, DateTime.utc(2026, 3, 16));
      expect(w.startUtc, DateTime.utc(2026, 3, 11));
      expect(w.endUtc, DateTime.utc(2026, 3, 17));
    });

    test('26-day cycle, 12-day luteal: table row 2026-02-01', () {
      final w = FertilityWindowCalculator.compute(
        lastPeriodStartUtc: DateTime.utc(2026, 2, 1),
        cycleLengthDays: 26,
        lutealPhaseDays: 12,
      );
      expect(w, isNotNull);
      expect(w!.estimatedOvulationUtc, DateTime.utc(2026, 2, 14));
      expect(w.startUtc, DateTime.utc(2026, 2, 9));
      expect(w.endUtc, DateTime.utc(2026, 2, 15));
    });

    test('21-day cycle: table row 2026-04-01', () {
      final w = FertilityWindowCalculator.compute(
        lastPeriodStartUtc: DateTime.utc(2026, 4, 1),
        cycleLengthDays: 21,
        lutealPhaseDays: 14,
      );
      expect(w, isNotNull);
      expect(w!.estimatedOvulationUtc, DateTime.utc(2026, 4, 7));
      expect(w.startUtc, DateTime.utc(2026, 4, 2));
      expect(w.endUtc, DateTime.utc(2026, 4, 8));
    });

    test('35-day cycle: table row 2026-05-01', () {
      final w = FertilityWindowCalculator.compute(
        lastPeriodStartUtc: DateTime.utc(2026, 5, 1),
        cycleLengthDays: 35,
        lutealPhaseDays: 14,
      );
      expect(w, isNotNull);
      expect(w!.estimatedOvulationUtc, DateTime.utc(2026, 5, 21));
      expect(w.startUtc, DateTime.utc(2026, 5, 16));
      expect(w.endUtc, DateTime.utc(2026, 5, 22));
    });

    test('invalid cycle length returns null', () {
      expect(
        FertilityWindowCalculator.compute(
          lastPeriodStartUtc: DateTime.utc(2026, 1, 1),
          cycleLengthDays: 8,
          lutealPhaseDays: 14,
        ),
        isNull,
      );
    });

    test('invalid luteal phase returns null', () {
      expect(
        FertilityWindowCalculator.compute(
          lastPeriodStartUtc: DateTime.utc(2026, 1, 1),
          cycleLengthDays: 28,
          lutealPhaseDays: 3,
        ),
        isNull,
      );
    });

    test('normalizes lastPeriodStart to UTC midnight', () {
      final w = FertilityWindowCalculator.compute(
        lastPeriodStartUtc: DateTime.utc(2026, 1, 1, 15, 30),
        cycleLengthDays: 28,
        lutealPhaseDays: 14,
      );
      expect(w, isNotNull);
      expect(w!.estimatedOvulationUtc, DateTime.utc(2026, 1, 14));
    });

    test('clamps fertile start to period start when early ovulation', () {
      final w = FertilityWindowCalculator.compute(
        lastPeriodStartUtc: DateTime.utc(2026, 6, 1),
        cycleLengthDays: 10,
        lutealPhaseDays: 5,
      );
      expect(w, isNotNull);
      expect(w!.startUtc, DateTime.utc(2026, 6, 1));
      expect(w.estimatedOvulationUtc, DateTime.utc(2026, 6, 5));
    });
  });

  group('FertilityWindowCalculator.averageCycleLengthFromHistory', () {
    test('empty list returns null', () {
      expect(FertilityWindowCalculator.averageCycleLengthFromHistory([]), isNull);
    });

    test('single value', () {
      expect(
        FertilityWindowCalculator.averageCycleLengthFromHistory([28]),
        28,
      );
    });

    test('mean rounded to nearest int', () {
      expect(
        FertilityWindowCalculator.averageCycleLengthFromHistory([28, 30, 26]),
        28,
      );
      expect(
        FertilityWindowCalculator.averageCycleLengthFromHistory([29, 31]),
        30,
      );
    });
  });
}

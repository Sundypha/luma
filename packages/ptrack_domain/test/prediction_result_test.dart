import 'package:flutter_test/flutter_test.dart';

import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  group('PredictionResult equality', () {
    test('PredictionInsufficientHistory', () {
      const a = PredictionInsufficientHistory(
        completedCyclesAvailable: 1,
        minCompletedCyclesNeeded: 2,
      );
      const b = PredictionInsufficientHistory(
        completedCyclesAvailable: 1,
        minCompletedCyclesNeeded: 2,
      );
      const c = PredictionInsufficientHistory(
        completedCyclesAvailable: 2,
        minCompletedCyclesNeeded: 2,
      );
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });

    test('PredictionRangeOnly', () {
      final a = PredictionRangeOnly(
        rangeStartUtc: DateTime.utc(2026, 2, 1),
        rangeEndUtc: DateTime.utc(2026, 2, 10),
        reasonCode: 'high_variability',
      );
      final b = PredictionRangeOnly(
        rangeStartUtc: DateTime.utc(2026, 2, 1),
        rangeEndUtc: DateTime.utc(2026, 2, 10),
        reasonCode: 'high_variability',
      );
      final c = PredictionRangeOnly(
        rangeStartUtc: DateTime.utc(2026, 2, 1),
        rangeEndUtc: DateTime.utc(2026, 2, 11),
        reasonCode: 'high_variability',
      );
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });

    test('PredictionPointWithRange', () {
      final a = PredictionPointWithRange(
        pointStartUtc: DateTime.utc(2026, 3, 15),
        rangeStartUtc: DateTime.utc(2026, 3, 12),
        rangeEndUtc: DateTime.utc(2026, 3, 18),
      );
      final b = PredictionPointWithRange(
        pointStartUtc: DateTime.utc(2026, 3, 15),
        rangeStartUtc: DateTime.utc(2026, 3, 12),
        rangeEndUtc: DateTime.utc(2026, 3, 18),
      );
      expect(a, b);
      expect(
        a,
        isNot(
          PredictionPointWithRange(
            pointStartUtc: DateTime.utc(2026, 3, 16),
            rangeStartUtc: DateTime.utc(2026, 3, 12),
            rangeEndUtc: DateTime.utc(2026, 3, 18),
          ),
        ),
      );
    });
  });

  group('placeholderExplanationSteps', () {
    test('returns a step for insufficient history', () {
      const r = PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      );
      final steps = placeholderExplanationSteps(r);
      expect(steps, hasLength(1));
      expect(steps.single.kind, ExplanationFactKind.insufficientHistory);
      expect(steps.single.payload['completedCyclesAvailable'], 0);
    });

    test('returns a step for range-only', () {
      final r = PredictionRangeOnly(
        rangeStartUtc: DateTime.utc(2026, 1, 1),
        rangeEndUtc: DateTime.utc(2026, 1, 20),
        reasonCode: 'high_variability',
      );
      final steps = placeholderExplanationSteps(r);
      expect(steps.single.kind, ExplanationFactKind.highVariabilityRange);
      expect(steps.single.payload['reasonCode'], 'high_variability');
    });

    test('returns a step for point with range', () {
      final r = PredictionPointWithRange(
        pointStartUtc: DateTime.utc(2026, 5, 1),
      );
      final steps = placeholderExplanationSteps(r);
      expect(steps.single.kind, ExplanationFactKind.enginePending);
      expect(steps.single.payload['pointStartUtc'], isNotNull);
    });
  });
}

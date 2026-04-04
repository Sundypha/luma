import 'package:flutter_test/flutter_test.dart';

import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  final engine = PredictionEngine();

  group('PredictionEngine', () {
    test('insufficient history when fewer than two cycles after exclusions', () {
      final cycles = [
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 1),
          lengthInDays: 28,
        ),
      ];
      final out = engine.predict(cycles);
      expect(out.result, isA<PredictionInsufficientHistory>());
      final ins = out.result as PredictionInsufficientHistory;
      expect(ins.completedCyclesAvailable, 1);
      expect(ins.minCompletedCyclesNeeded, 2);
      expect(
        out.explanation.map((e) => e.kind),
        contains(ExplanationFactKind.insufficientHistory),
      );
    });

    test('plain median of three equal cycles yields point with range', () {
      final cycles = [
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 1),
          lengthInDays: 28,
        ),
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 29),
          lengthInDays: 28,
        ),
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 2, 26),
          lengthInDays: 28,
        ),
      ];
      final out = engine.predict(cycles);
      expect(out.result, isA<PredictionPointWithRange>());
      final p = out.result as PredictionPointWithRange;
      expect(p.pointStartUtc, DateTime.utc(2026, 3, 26));
      expect(p.rangeStartUtc, DateTime.utc(2026, 3, 26));
      expect(p.rangeEndUtc, DateTime.utc(2026, 3, 26));
      expect(
        out.explanation.map((e) => e.kind),
        containsAll([
          ExplanationFactKind.cyclesConsidered,
          ExplanationFactKind.medianCycleLength,
        ]),
      );
    });

    test('within-window outlier excluded then median recomputed', () {
      final cycles = [
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 1),
          lengthInDays: 28,
        ),
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 29),
          lengthInDays: 28,
        ),
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 2, 26),
          lengthInDays: 45,
        ),
      ];
      final out = engine.predict(cycles);
      expect(out.result, isA<PredictionPointWithRange>());
      final p = out.result as PredictionPointWithRange;
      // Median of 28,28 after dropping 45 as outlier (|45-28|>7); anchor Feb 26 + 28 = Mar 26
      expect(p.pointStartUtc, DateTime.utc(2026, 3, 26));
      final excluded = out.explanation
          .where((e) => e.payload['exclusionReason'] == 'statistical_outlier')
          .toList();
      expect(excluded, isNotEmpty);
    });

    test('long-gap cycle excluded by length threshold', () {
      final cycles = [
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 1),
          lengthInDays: 28,
        ),
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 29),
          lengthInDays: 50,
        ),
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 3, 20),
          lengthInDays: 28,
        ),
      ];
      final out = engine.predict(cycles);
      expect(out.result, isA<PredictionPointWithRange>());
      final p = out.result as PredictionPointWithRange;
      expect(p.pointStartUtc, DateTime.utc(2026, 4, 17));
      final longGap = out.explanation
          .where((e) => e.payload['exclusionReason'] == 'long_gap')
          .toList();
      expect(longGap, isNotEmpty);
    });

    test('high variability downgrades to range-only with widened interval', () {
      // Lengths 22 / 28 / 34: median 28, within-window deviations ≤7 so all stay;
      // spread 12 → high-variability tier (threshold inclusive).
      final cycles = [
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 1),
          lengthInDays: 22,
        ),
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 23),
          lengthInDays: 28,
        ),
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 2, 20),
          lengthInDays: 34,
        ),
      ];
      final out = engine.predict(cycles);
      expect(out.result, isA<PredictionRangeOnly>());
      final r = out.result as PredictionRangeOnly;
      expect(r.reasonCode, 'high_variability');
      expect(r.rangeStartUtc, DateTime.utc(2026, 3, 14));
      expect(r.rangeEndUtc, DateTime.utc(2026, 3, 26));
      expect(
        out.explanation.map((e) => e.kind),
        contains(ExplanationFactKind.highVariabilityRange),
      );
    });
  });
}

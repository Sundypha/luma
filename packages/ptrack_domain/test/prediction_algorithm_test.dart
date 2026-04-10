import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

/// Consecutive period starts from [lengths] (oldest first), anchored at UTC midnight.
List<PredictionCycleInput> cyclesFromLengths(
  List<int> lengths, [
  DateTime? firstStart,
]) {
  var start = firstStart ?? DateTime.utc(2026, 1, 1);
  final out = <PredictionCycleInput>[];
  for (final len in lengths) {
    out.add(PredictionCycleInput(periodStartUtc: start, lengthInDays: len));
    start = addUtcCalendarDays(start, len);
  }
  return out;
}

void expectUtcMidnight(DateTime d) {
  expect(d.isUtc, isTrue);
  expect(d.hour, 0);
  expect(d.minute, 0);
  expect(d.second, 0);
  expect(d.microsecond, 0);
}

void main() {
  group('MedianBaselineAlgorithm', () {
    const algo = MedianBaselineAlgorithm();

    test('returns null with 0 or 1 cycles', () {
      expect(algo.predict([]), isNull);
      expect(algo.predict(cyclesFromLengths([28])), isNull);
    });

    test('with 3 regular cycles (28, 29, 30) predicts median 29 days from last start', () {
      final cycles = cyclesFromLengths([28, 29, 30]);
      final lastStart = cycles.last.periodStartUtc;
      final out = algo.predict(cycles);
      expect(out, isNotNull);
      final p = out!;
      expect(p.algorithmId, AlgorithmId.median);
      expect(p.predictedDurationDays, 5);
      final expected = addUtcCalendarDays(lastStart, 29);
      expect(p.predictedStartUtc, expected);
      expectUtcMidnight(p.predictedStartUtc);
    });

    test('preserves PredictionEngine outlier exclusion behavior', () {
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
      final out = algo.predict(cycles);
      expect(out, isNotNull);
      expect(out!.predictedStartUtc, DateTime.utc(2026, 3, 26));
      expect(
        out.explanationSteps
            .where((e) => e.payload['exclusionReason'] == 'statistical_outlier'),
        isNotEmpty,
      );
    });
  });

  group('EwmaAlgorithm', () {
    const algo = EwmaAlgorithm();

    test('returns null with fewer than 2 cycles', () {
      expect(algo.predict([]), isNull);
      expect(algo.predict(cyclesFromLengths([28])), isNull);
    });

    test('with [28, 28, 28] predicts ~28', () {
      final cycles = cyclesFromLengths([28, 28, 28]);
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      expect(out.predictedStartUtc, addUtcCalendarDays(anchor, 28));
    });

    test('with [28, 28, 32] predicts between 28 and 32 (recency-weighted)', () {
      final cycles = cyclesFromLengths([28, 28, 32]);
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      final lenDays = out.predictedStartUtc.difference(anchor).inDays;
      expect(lenDays, greaterThan(28));
      expect(lenDays, lessThan(32));
    });

    test('with [28, 28, 28, 60] outlier does not dominate vs last value 60', () {
      final cycles = cyclesFromLengths([28, 28, 28, 60]);
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      final lenDays = out.predictedStartUtc.difference(anchor).inDays;
      expect(lenDays, lessThan(60));
      expect(lenDays, greaterThan(28));
    });

    test('alpha=0.3 weighting matches manual EWMA on [28, 28, 32]', () {
      const custom = EwmaAlgorithm(alpha: 0.3);
      final cycles = cyclesFromLengths([28, 28, 32]);
      var smoothed = 28.0;
      smoothed = 0.3 * 28 + 0.7 * smoothed;
      smoothed = 0.3 * 32 + 0.7 * smoothed;
      final manualRounded = smoothed.round();
      final out = custom.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      expect(
        out.predictedStartUtc,
        addUtcCalendarDays(anchor, manualRounded),
      );
      expect(manualRounded, 29);
    });
  });

  group('BayesianAlgorithm', () {
    const algo = BayesianAlgorithm();

    test('returns null with no cycles', () {
      expect(algo.predict([]), isNull);
    });

    test('single cycle blends data with prior (κ₀=1, μ₀=28)', () {
      final cycles = cyclesFromLengths([32]);
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      // μₙ = (κ₀ μ₀ + n x̄) / (κ₀ + n) = (28 + 32) / 2 = 30
      expect(out.predictedStartUtc, addUtcCalendarDays(anchor, 30));
      expectUtcMidnight(out.predictedStartUtc);
    });

    test('with [28, 28, 28] predicts ~28', () {
      final cycles = cyclesFromLengths([28, 28, 28]);
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      final len = out.predictedStartUtc.difference(anchor).inDays;
      expect(len, 28);
    });

    test('with 2 cycles [28, 30] mean 29; posterior mean between prior 28 and data', () {
      final cycles = cyclesFromLengths([28, 30]);
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      final len = out.predictedStartUtc.difference(anchor).inDays;
      expect(len, greaterThanOrEqualTo(28));
      expect(len, lessThanOrEqualTo(30));
    });

    test('with 10 identical cycles prior is washed out; prediction ≈ sample mean', () {
      final cycles = cyclesFromLengths(List<int>.filled(10, 27));
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      final len = out.predictedStartUtc.difference(anchor).inDays;
      expect(len, 27);
    });

    test('weak prior does not dominate sparse data (2 cycles far from prior mean)', () {
      const far = BayesianAlgorithm();
      final cycles = cyclesFromLengths([40, 42]);
      final out = far.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      final len = out.predictedStartUtc.difference(anchor).inDays;
      expect(len, greaterThan(35));
      expect(len, lessThan(45));
    });
  });

  group('LinearTrendAlgorithm', () {
    const algo = LinearTrendAlgorithm();

    test('returns null with fewer than 5 cycles', () {
      expect(algo.predict(cyclesFromLengths([26, 27, 28, 29])), isNull);
    });

    test('with [26, 27, 28, 29, 30] detects upward trend; projects ~31', () {
      final cycles = cyclesFromLengths([26, 27, 28, 29, 30]);
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      final len = out.predictedStartUtc.difference(anchor).inDays;
      expect(len, 31);
    });

    test('with [28, 30, 28, 30, 28] oscillating pattern returns null (low R²)', () {
      final cycles = cyclesFromLengths([28, 30, 28, 30, 28]);
      expect(algo.predict(cycles), isNull);
    });

    test('projected length clamped to upper bound 50', () {
      final cycles = cyclesFromLengths([30, 36, 42, 48, 54]);
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      final len = out.predictedStartUtc.difference(anchor).inDays;
      expect(len, 50);
    });

    test('strong downward trend projects shorter cycle (respects clamp 18)', () {
      final cycles = cyclesFromLengths([40, 37, 34, 31, 28]);
      final out = algo.predict(cycles)!;
      final anchor = cycles.last.periodStartUtc;
      final len = out.predictedStartUtc.difference(anchor).inDays;
      expect(len, lessThan(28));
      expect(len, greaterThanOrEqualTo(18));
    });
  });

  group('cross-algorithm consistency', () {
    test('all algorithms share PredictionCycleInput and valid outputs', () {
      final cycles = cyclesFromLengths([28, 28, 28, 28, 28]);
      final algorithms = <PredictionAlgorithm>[
        const MedianBaselineAlgorithm(),
        const EwmaAlgorithm(),
        const BayesianAlgorithm(),
        const LinearTrendAlgorithm(),
      ];
      for (final a in algorithms) {
        final p = a.predict(cycles);
        expect(p, isNotNull, reason: '${a.id}');
        expect(p!.explanationSteps, isNotEmpty);
        expectUtcMidnight(p.predictedStartUtc);
      }
    });
  });
}

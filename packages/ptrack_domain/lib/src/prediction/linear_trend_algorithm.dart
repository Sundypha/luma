import 'package:meta/meta.dart';

import 'explanation_step.dart';
import 'prediction_algorithm.dart';

/// Least-squares line through cycle index (0…n−1) vs length; gated by R².
@immutable
class LinearTrendAlgorithm implements PredictionAlgorithm {
  const LinearTrendAlgorithm({
    this.rSquaredThreshold = 0.5,
    this.defaultDuration = 5,
  });

  final double rSquaredThreshold;
  final int defaultDuration;

  @override
  AlgorithmId get id => AlgorithmId.linearTrend;

  @override
  String get displayName => 'Trend';

  @override
  int get minCycles => 5;

  @override
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles) {
    if (cycles.length < minCycles) return null;

    final n = cycles.length;
    final ys = cycles.map((c) => c.lengthInDays.toDouble()).toList();
    final xs = List<double>.generate(n, (i) => i.toDouble());

    final xMean = xs.reduce((a, b) => a + b) / n;
    final yMean = ys.reduce((a, b) => a + b) / n;

    var sxy = 0.0;
    var sxx = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - xMean;
      final dy = ys[i] - yMean;
      sxy += dx * dy;
      sxx += dx * dx;
    }

    if (sxx == 0) {
      return null;
    }

    final slope = sxy / sxx;
    final intercept = yMean - slope * xMean;

    var ssTot = 0.0;
    var ssRes = 0.0;
    for (var i = 0; i < n; i++) {
      final yHat = slope * xs[i] + intercept;
      final dy = ys[i] - yMean;
      ssTot += dy * dy;
      ssRes += (ys[i] - yHat) * (ys[i] - yHat);
    }

    final rSquared = ssTot <= 0 ? 1.0 : (1.0 - ssRes / ssTot).clamp(0.0, 1.0);

    if (rSquared < rSquaredThreshold) {
      return null;
    }

    final projectedLength =
        (slope * n + intercept).round().clamp(18, 50);

    final anchor = utcCalendarDateOnly(cycles.last.periodStartUtc);
    final predictedStart = addUtcCalendarDays(anchor, projectedLength);

    return AlgorithmPrediction(
      algorithmId: id,
      predictedStartUtc: predictedStart,
      predictedDurationDays: defaultDuration,
      explanationSteps: [
        ExplanationStep(
          kind: ExplanationFactKind.cyclesConsidered,
          payload: {
            'count': cycles.length,
            'lengthsInDays': ys.map((e) => e.round()).toList(),
            'periodStartsUtc':
                cycles.map((c) => c.periodStartUtc.toIso8601String()).toList(),
          },
        ),
        ExplanationStep(
          kind: ExplanationFactKind.linearTrendProjection,
          payload: {
            'slope': slope,
            'intercept': intercept,
            'rSquared': rSquared,
            'projectedDays': projectedLength,
            'cycleCount': n,
          },
        ),
      ],
    );
  }
}

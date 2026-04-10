import 'package:meta/meta.dart';

import 'explanation_step.dart';
import 'prediction_algorithm.dart';

/// Normal–Inverse-Gamma conjugate update for unknown Gaussian mean (weak prior).
///
/// Point estimate is the posterior mean [μₙ] (rounded to whole days).
@immutable
class BayesianAlgorithm implements PredictionAlgorithm {
  const BayesianAlgorithm({
    this.priorMu = 28.0,
    this.priorKappa = 1.0,
    this.priorAlpha = 2.0,
    this.priorBeta = 15.0,
    this.defaultDuration = 5,
  });

  final double priorMu;
  final double priorKappa;
  final double priorAlpha;
  final double priorBeta;
  final int defaultDuration;

  @override
  AlgorithmId get id => AlgorithmId.bayesian;

  @override
  String get displayName => 'Pattern-learning';

  /// One observed cycle is enough: the weak NIG prior (μ₀, κ₀, α₀, β₀) combines
  /// with the single length to form a proper posterior mean for the next cycle.
  @override
  int get minCycles => 1;

  @override
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles) {
    if (cycles.isEmpty) return null;

    final lengths = cycles.map((c) => c.lengthInDays.toDouble()).toList();
    final n = lengths.length;
    final sum = lengths.reduce((a, b) => a + b);
    final xBar = sum / n;

    final kappaN = priorKappa + n;
    final muN = (priorKappa * priorMu + n * xBar) / kappaN;
    final alphaN = priorAlpha + n / 2;

    var sumSqDev = 0.0;
    for (final x in lengths) {
      final d = x - xBar;
      sumSqDev += d * d;
    }
    final betaN = priorBeta +
        0.5 * sumSqDev +
        (priorKappa * n * (xBar - priorMu) * (xBar - priorMu)) /
            (2 * kappaN);

    final predictedLength = muN.round();

    final anchor = utcCalendarDateOnly(cycles.last.periodStartUtc);
    final predictedStart = addUtcCalendarDays(anchor, predictedLength);

    return AlgorithmPrediction(
      algorithmId: id,
      predictedStartUtc: predictedStart,
      predictedDurationDays: defaultDuration,
      explanationSteps: [
        ExplanationStep(
          kind: ExplanationFactKind.cyclesConsidered,
          payload: {
            'count': cycles.length,
            'lengthsInDays': cycles.map((c) => c.lengthInDays).toList(),
            'periodStartsUtc':
                cycles.map((c) => c.periodStartUtc.toIso8601String()).toList(),
          },
        ),
        ExplanationStep(
          kind: ExplanationFactKind.bayesianPosteriorMean,
          payload: {
            'posteriorMeanDays': muN,
            'posteriorKappa': kappaN,
            'posteriorAlpha': alphaN,
            'posteriorBeta': betaN,
            'observationCount': n,
            'priorMu': priorMu,
            'priorKappa': priorKappa,
            'priorAlpha': priorAlpha,
            'priorBeta': priorBeta,
            'sampleMeanDays': xBar,
          },
        ),
      ],
    );
  }
}

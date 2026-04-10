import 'package:meta/meta.dart';

import 'explanation_step.dart';
import 'prediction_algorithm.dart';

/// Exponentially weighted moving average over cycle lengths (oldest → newest).
///
/// Recency weight: x̃ₜ = α·xₜ + (1−α)·x̃ₜ₋₁, rounded to nearest whole day.
@immutable
class EwmaAlgorithm implements PredictionAlgorithm {
  const EwmaAlgorithm({
    this.alpha = 0.3,
    this.defaultDuration = 5,
  });

  final double alpha;

  /// Shared period duration until ensemble supplies a user-specific value.
  final int defaultDuration;

  @override
  AlgorithmId get id => AlgorithmId.ewma;

  @override
  String get displayName => 'Recent-weighted';

  @override
  int get minCycles => 2;

  @override
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles) {
    if (cycles.length < minCycles) return null;

    final lengths = cycles.map((c) => c.lengthInDays).toList();
    var smoothed = lengths.first.toDouble();
    for (var i = 1; i < lengths.length; i++) {
      smoothed = alpha * lengths[i] + (1 - alpha) * smoothed;
    }
    final predictedLength = smoothed.round();

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
            'lengthsInDays': lengths,
            'periodStartsUtc':
                cycles.map((c) => c.periodStartUtc.toIso8601String()).toList(),
          },
        ),
        ExplanationStep(
          kind: ExplanationFactKind.ewmaSmoothedLength,
          payload: {
            'smoothedDays': predictedLength,
            'alpha': alpha,
            'finalEwmaValue': smoothed,
          },
        ),
      ],
    );
  }
}

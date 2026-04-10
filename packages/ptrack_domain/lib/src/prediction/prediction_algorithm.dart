import 'package:meta/meta.dart';

import 'explanation_step.dart';
import 'prediction_engine.dart';
import 'prediction_result.dart';

export 'prediction_engine.dart'
    show
        PredictionCycleInput,
        PredictionEngine,
        addUtcCalendarDays,
        utcCalendarDateOnly;

/// Identifies a prediction strategy in the multi-algorithm ensemble (PRED-01).
enum AlgorithmId { median, ewma, bayesian, linearTrend }

/// One algorithm's point prediction and factual explanation steps.
@immutable
class AlgorithmPrediction {
  const AlgorithmPrediction({
    required this.algorithmId,
    required this.predictedStartUtc,
    required this.predictedDurationDays,
    required this.explanationSteps,
  });

  final AlgorithmId algorithmId;

  /// Next period start at UTC calendar midnight.
  final DateTime predictedStartUtc;

  final int predictedDurationDays;

  final List<ExplanationStep> explanationSteps;
}

/// Predicts the next cycle length / start from completed cycles (oldest first).
abstract class PredictionAlgorithm {
  AlgorithmId get id;

  /// User-facing label (plain language; UI may localize later).
  String get displayName;

  /// Minimum number of completed cycles before [predict] may return non-null.
  int get minCycles;

  /// Returns null when history does not meet [minCycles] or is otherwise insufficient.
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles);
}

/// Wraps [PredictionEngine] median / variability logic without changing it.
@immutable
class MedianBaselineAlgorithm implements PredictionAlgorithm {
  const MedianBaselineAlgorithm({
    PredictionEngine engine = const PredictionEngine(),
    this.defaultDuration = 5,
  }) : _engine = engine;

  final PredictionEngine _engine;

  /// Shared period duration until the ensemble injects a measured value (Plan 02).
  final int defaultDuration;

  @override
  AlgorithmId get id => AlgorithmId.median;

  @override
  String get displayName => 'Average spacing';

  @override
  int get minCycles => 2;

  @override
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles) {
    final out = _engine.predict(cycles);
    return switch (out.result) {
      PredictionInsufficientHistory() => null,
      PredictionPointWithRange(:final pointStartUtc) => AlgorithmPrediction(
          algorithmId: id,
          predictedStartUtc: utcCalendarDateOnly(pointStartUtc),
          predictedDurationDays: defaultDuration,
          explanationSteps: out.explanation,
        ),
      PredictionRangeOnly(
        :final rangeStartUtc,
        :final rangeEndUtc,
      ) =>
        AlgorithmPrediction(
          algorithmId: id,
          predictedStartUtc: _utcMidpointCalendarDay(
            rangeStartUtc,
            rangeEndUtc,
          ),
          predictedDurationDays: defaultDuration,
          explanationSteps: out.explanation,
        ),
    };
  }
}

DateTime _utcMidpointCalendarDay(DateTime a, DateTime b) {
  final midMs =
      (a.toUtc().millisecondsSinceEpoch + b.toUtc().millisecondsSinceEpoch) ~/
          2;
  final mid = DateTime.fromMillisecondsSinceEpoch(midMs, isUtc: true);
  return utcCalendarDateOnly(mid);
}

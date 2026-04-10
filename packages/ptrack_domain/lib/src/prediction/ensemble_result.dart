import 'package:meta/meta.dart';

import 'ensemble_milestone.dart';
import 'explanation_step.dart';
import 'prediction_algorithm.dart';
import 'prediction_result.dart';

/// Per-day prediction metadata: how many algorithms agree, and which projected
/// cycle this day belongs to (0 = next period, 1 = the one after, etc.).
typedef DayPredictionMeta = ({int agreement, int cycleIndex});

/// Aggregated multi-algorithm output for ensemble UI and backward-compatible
/// single-result consumers (Plan 02 constructs instances).
@immutable
class EnsemblePredictionResult {
  const EnsemblePredictionResult({
    required this.algorithmOutputs,
    required this.dayConfidenceMap,
    required this.activeAlgorithmCount,
    required this.totalAlgorithmCount,
    this.milestone,
    required this.consensusPrediction,
    required this.mergedExplanationSteps,
    required this.explanationText,
    this.cycleSpreadDays = 0,
  });

  /// Non-null outputs only; order matches registration order where applicable.
  final List<AlgorithmPrediction> algorithmOutputs;

  /// UTC calendar midnight → agreement count + cycle hop index.
  ///
  /// [DayPredictionMeta.cycleIndex] 0 = next period, 1 = the period after, etc.
  /// When two algorithms project overlapping ranges at different hops, the entry
  /// with the lowest [DayPredictionMeta.cycleIndex] wins.
  final Map<DateTime, DayPredictionMeta> dayConfidenceMap;

  final int activeAlgorithmCount;
  final int totalAlgorithmCount;

  /// Set when an algorithm crosses its activation threshold (e.g. first trend output).
  final EnsembleMilestone? milestone;

  /// Single [PredictionResult] for existing [CyclePosition] wiring.
  final PredictionResult consensusPrediction;

  final List<ExplanationStep> mergedExplanationSteps;

  /// Reserved; localized copy is built in the Flutter app from structured steps.
  final String explanationText;

  /// Max − min of the included historical cycle lengths in days.
  /// Higher = more irregular cycles = confidence degrades faster across hops.
  final int cycleSpreadDays;
}

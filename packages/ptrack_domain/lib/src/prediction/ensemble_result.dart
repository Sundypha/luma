import 'package:meta/meta.dart';

import 'explanation_step.dart';
import 'prediction_algorithm.dart';
import 'prediction_result.dart';

/// Aggregated multi-algorithm output for ensemble UI and backward-compatible
/// single-result consumers (Plan 02 constructs instances).
@immutable
class EnsemblePredictionResult {
  const EnsemblePredictionResult({
    required this.algorithmOutputs,
    required this.dayConfidenceMap,
    required this.activeAlgorithmCount,
    required this.totalAlgorithmCount,
    this.milestoneMessage,
    required this.consensusPrediction,
    required this.mergedExplanationSteps,
    required this.explanationText,
  });

  /// Non-null outputs only; order matches registration order where applicable.
  final List<AlgorithmPrediction> algorithmOutputs;

  /// UTC calendar midnight → count of algorithms whose predicted start is that day.
  final Map<DateTime, int> dayConfidenceMap;

  final int activeAlgorithmCount;
  final int totalAlgorithmCount;

  /// Set when an algorithm crosses its activation threshold (e.g. first trend output).
  final String? milestoneMessage;

  /// Single [PredictionResult] for existing [CyclePosition] wiring.
  final PredictionResult consensusPrediction;

  final List<ExplanationStep> mergedExplanationSteps;

  /// Pre-rendered multi-line explanation (e.g. from [formatPredictionExplanation]).
  final String explanationText;
}

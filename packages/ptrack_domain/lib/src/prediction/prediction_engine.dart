import 'package:meta/meta.dart';

import 'explanation_step.dart';
import 'prediction_result.dart';

/// Hard-coded defaults; see [prediction_rules.md].
@immutable
class PredictionThresholds {
  const PredictionThresholds({
    this.longGapDays = 45,
    this.longBleedDays = 10,
    this.outlierMaxDeviationFromMedianDays = 7,
    this.highVariabilityMinSpreadDays = 12,
    this.minCompletedCyclesForPoint = 2,
    this.maxCyclesInWindow = 6,
  });

  /// Cycles longer than this (days) are excluded as [PredictionExclusionReason.longGap].
  final int longGapDays;

  /// When [PredictionCycleInput.bleedingDays] is set and exceeds this, exclude as [longBleed].
  final int longBleedDays;

  /// Within-window outlier if \|length − median\| exceeds this (days).
  final int outlierMaxDeviationFromMedianDays;

  /// When max(include lengths) − min(include lengths) ≥ this → range-only tier.
  final int highVariabilityMinSpreadDays;

  final int minCompletedCyclesForPoint;
  final int maxCyclesInWindow;

  static const PredictionThresholds standard = PredictionThresholds();
}

/// Why a cycle was excluded from median / spread statistics.
enum PredictionExclusionReason {
  longGap,
  longBleed,
  statisticalOutlier,
}

/// One completed cycle available for prediction (oldest-first list in [PredictionEngine.predict]).
@immutable
class PredictionCycleInput {
  const PredictionCycleInput({
    required this.periodStartUtc,
    required this.lengthInDays,
    this.bleedingDays,
  });

  final DateTime periodStartUtc;
  final int lengthInDays;

  /// When set, compared to [PredictionThresholds.longBleedDays].
  final int? bleedingDays;
}

/// Engine output: sealed [PredictionResult] plus ordered explanation (PRED-03).
@immutable
class PredictionEngineResult {
  const PredictionEngineResult({
    required this.result,
    required this.explanation,
  });

  final PredictionResult result;
  final List<ExplanationStep> explanation;
}

/// Deterministic median-based next-start prediction (Phase 02-03).
class PredictionEngine {
  const PredictionEngine({this.thresholds = PredictionThresholds.standard});

  final PredictionThresholds thresholds;

  /// RED stub: wrong outcome so TDD tests assert failures until implemented.
  PredictionEngineResult predict(
    List<PredictionCycleInput> completedCyclesOldestFirst,
  ) {
    return PredictionEngineResult(
      result: PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: thresholds.minCompletedCyclesForPoint,
      ),
      explanation: const [],
    );
  }
}

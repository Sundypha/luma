import 'package:meta/meta.dart';

import 'prediction_result.dart';

/// Machine-readable kinds for factual explanation lines (UI renders later).
enum ExplanationFactKind {
  /// Which completed cycles were included in a statistic.
  cyclesConsidered,

  /// Central tendency (e.g. median) over included cycles.
  medianCycleLength,

  /// History shorter than minimum for a point prediction.
  insufficientHistory,

  /// High variability / range-only presentation (no point date).
  highVariabilityRange,

  /// Placeholder until the prediction engine (Plan 03) fills real steps.
  enginePending,
}

/// One ordered, factual explanation step independent of Flutter widgets.
@immutable
class ExplanationStep {
  const ExplanationStep({
    required this.kind,
    this.payload = const {},
  });

  final ExplanationFactKind kind;
  final Map<String, Object?> payload;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExplanationStep &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          _mapEquals(payload, other.payload);

  @override
  int get hashCode {
    var h = kind.hashCode;
    final keys = payload.keys.toList()..sort();
    for (final k in keys) {
      h = Object.hash(h, k, payload[k]);
    }
    return h;
  }

  @override
  String toString() => 'ExplanationStep($kind, $payload)';
}

bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

/// Stable placeholder steps until full explanation logic exists (Plan 03).
List<ExplanationStep> placeholderExplanationSteps(PredictionResult result) {
  return switch (result) {
    PredictionInsufficientHistory(
      :final completedCyclesAvailable,
      :final minCompletedCyclesNeeded,
    ) =>
      [
        ExplanationStep(
          kind: ExplanationFactKind.insufficientHistory,
          payload: {
            'completedCyclesAvailable': completedCyclesAvailable,
            'minCompletedCyclesNeeded': minCompletedCyclesNeeded,
          },
        ),
      ],
    PredictionRangeOnly(:final reasonCode) => [
        ExplanationStep(
          kind: ExplanationFactKind.highVariabilityRange,
          payload: {
            'reasonCode': ?reasonCode,
          },
        ),
      ],
    PredictionPointWithRange(:final pointStartUtc) => [
        ExplanationStep(
          kind: ExplanationFactKind.enginePending,
          payload: {
            'pointStartUtc': pointStartUtc.toIso8601String(),
          },
        ),
      ],
  };
}

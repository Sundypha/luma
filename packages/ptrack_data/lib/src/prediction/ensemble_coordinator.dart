import 'package:ptrack_domain/ptrack_domain.dart';

import '../repositories/period_repository.dart';
import 'prediction_coordinator.dart';

/// Runs all registered [PredictionAlgorithm]s, aggregates per-day agreement, and
/// exposes a backward-compatible [PredictionResult] from the median engine path.
class EnsembleCoordinator {
  EnsembleCoordinator({
    List<PredictionAlgorithm>? algorithms,
  }) : _algorithmsOverride = algorithms;

  final List<PredictionAlgorithm>? _algorithmsOverride;

  static List<PredictionAlgorithm> _defaultAlgorithmsForDuration(int durationDays) {
    return [
      MedianBaselineAlgorithm(defaultDuration: durationDays),
      EwmaAlgorithm(defaultDuration: durationDays),
      BayesianAlgorithm(defaultDuration: durationDays),
      LinearTrendAlgorithm(defaultDuration: durationDays),
    ];
  }

  /// Median inclusive bleeding-day count across completed periods; default 5.
  static int medianBleedingDurationDays(Iterable<StoredPeriod> stored) {
    final durations = <int>[];
    for (final s in stored) {
      final span = s.span;
      if (!span.isCompleted || span.endUtc == null) continue;
      final start = utcCalendarDateOnly(span.startUtc);
      final end = utcCalendarDateOnly(span.endUtc!);
      final days = end.difference(start).inDays + 1;
      if (days > 0) durations.add(days);
    }
    if (durations.isEmpty) return 5;
    durations.sort();
    final mid = durations.length ~/ 2;
    if (durations.length.isOdd) return durations[mid];
    return ((durations[mid - 1] + durations[mid]) / 2).round();
  }

  /// Synchronous ensemble from in-memory periods (tests / preloaded data).
  EnsemblePredictionResult predictNext({
    required List<StoredPeriod> storedPeriods,
    required PeriodCalendarContext calendar,
    int? previousActiveCount,
  }) {
    final cycles = predictionCycleInputsFromStored(
      stored: storedPeriods,
      calendar: calendar,
    );
    final durationDays = medianBleedingDurationDays(storedPeriods);
    final algos =
        _algorithmsOverride ?? _defaultAlgorithmsForDuration(durationDays);

    final outputs = <AlgorithmPrediction>[];
    final merged = <ExplanationStep>[];

    for (final algo in algos) {
      final o = algo.predict(cycles);
      if (o != null) {
        outputs.add(o);
        merged.add(
          ExplanationStep(
            kind: ExplanationFactKind.algorithmContribution,
            payload: {
              'algorithmId': o.algorithmId.name,
              'displayName': algo.displayName,
              'predictedStartUtc': o.predictedStartUtc.toIso8601String(),
              'predictedLengthDays': o.predictedDurationDays,
            },
          ),
        );
        merged.addAll(o.explanationSteps);
      }
    }

    final dayConfidenceMap = <DateTime, int>{};
    for (final o in outputs) {
      for (var i = 0; i < o.predictedDurationDays; i++) {
        final day = utcCalendarDateOnly(
          addUtcCalendarDays(o.predictedStartUtc, i),
        );
        dayConfidenceMap[day] = (dayConfidenceMap[day] ?? 0) + 1;
      }
    }

    final activeAlgorithmCount = outputs.length;
    final totalAlgorithmCount = algos.length;
    final cycleCount = cycles.length;

    final milestoneMessage = _milestoneMessage(
      previousActiveCount: previousActiveCount,
      activeAlgorithmCount: activeAlgorithmCount,
      cycleCount: cycleCount,
    );

    if (milestoneMessage != null) {
      merged.add(
        ExplanationStep(
          kind: ExplanationFactKind.milestoneReached,
          payload: {
            'activeCount': activeAlgorithmCount,
            'message': milestoneMessage,
          },
        ),
      );
    }

    final agreementSummary =
        'On days where multiple methods agree, the prediction is more consistent.';
    merged.add(
      ExplanationStep(
        kind: ExplanationFactKind.ensembleConsensus,
        payload: {
          'activeCount': activeAlgorithmCount,
          'totalCount': totalAlgorithmCount,
          'agreementSummary': agreementSummary,
        },
      ),
    );

    final coord = PredictionCoordinator();
    final coordResult = coord.predictNext(
      storedPeriods: storedPeriods,
      calendar: calendar,
    );

    final withoutText = EnsemblePredictionResult(
      algorithmOutputs: List<AlgorithmPrediction>.unmodifiable(outputs),
      dayConfidenceMap: Map<DateTime, int>.unmodifiable(dayConfidenceMap),
      activeAlgorithmCount: activeAlgorithmCount,
      totalAlgorithmCount: totalAlgorithmCount,
      milestoneMessage: milestoneMessage,
      consensusPrediction: coordResult.result,
      mergedExplanationSteps: List<ExplanationStep>.unmodifiable(merged),
      explanationText: '',
    );

    final text = formatEnsembleExplanation(ensemble: withoutText);
    return EnsemblePredictionResult(
      algorithmOutputs: withoutText.algorithmOutputs,
      dayConfidenceMap: withoutText.dayConfidenceMap,
      activeAlgorithmCount: withoutText.activeAlgorithmCount,
      totalAlgorithmCount: withoutText.totalAlgorithmCount,
      milestoneMessage: withoutText.milestoneMessage,
      consensusPrediction: withoutText.consensusPrediction,
      mergedExplanationSteps: withoutText.mergedExplanationSteps,
      explanationText: text,
    );
  }

  /// Loads stored periods then runs [predictNext].
  Future<EnsemblePredictionResult> predictNextFromRepository({
    required PeriodRepository repository,
    required PeriodCalendarContext calendar,
    int? previousActiveCount,
  }) async {
    final stored = await repository.listOrderedByStartUtc();
    return predictNext(
      storedPeriods: stored,
      calendar: calendar,
      previousActiveCount: previousActiveCount,
    );
  }
}

String? _milestoneMessage({
  required int? previousActiveCount,
  required int activeAlgorithmCount,
  required int cycleCount,
}) {
  if (previousActiveCount == null) return null;
  if (activeAlgorithmCount <= previousActiveCount) return null;

  if (activeAlgorithmCount >= 4 && previousActiveCount < 4) {
    return 'With 5 cycles, trend detection is now active.';
  }
  if (activeAlgorithmCount >= 3 && previousActiveCount < 3) {
    return '3 cycles logged — all core methods are now active.';
  }
  if (activeAlgorithmCount >= 2 && previousActiveCount < 2) {
    return 'With $cycleCount cycles logged, your prediction now uses '
        '$activeAlgorithmCount methods for better accuracy.';
  }
  return null;
}

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

  /// Median inclusive bleeding-day count across periods with both bounds; default 5.
  static int medianBleedingDurationDays(Iterable<StoredPeriod> stored) {
    final durations = <int>[];
    for (final s in stored) {
      final span = s.span;
      if (span.endUtc == null) continue;
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
  ///
  /// [enabledAlgorithmIds]: null → all default algorithms; empty set → none.
  /// [horizonCycles]: how many future cycles to project (1 = next only, 3 = default).
  ///   Each additional hop reuses the same per-algorithm predicted cycle length.
  EnsemblePredictionResult predictNext({
    required List<StoredPeriod> storedPeriods,
    required PeriodCalendarContext calendar,
    int? previousActiveCount,
    Set<AlgorithmId>? enabledAlgorithmIds,
    int horizonCycles = 3,
  }) {
    final cycles = predictionCycleInputsFromStored(
      stored: storedPeriods,
      calendar: calendar,
    );
    final durationDays = medianBleedingDurationDays(storedPeriods);
    var algos =
        _algorithmsOverride ?? _defaultAlgorithmsForDuration(durationDays);
    if (enabledAlgorithmIds != null) {
      algos = algos.where((a) => enabledAlgorithmIds.contains(a.id)).toList();
    }

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
              'predictedStartUtc': o.predictedStartUtc.toIso8601String(),
              'predictedLengthDays': o.predictedDurationDays,
            },
          ),
        );
        merged.addAll(o.explanationSteps);
      }
    }

    // Compute cycle spread for variability-aware confidence decay.
    final cycleSpreadDays = _cycleSpreadDays(cycles);

    // Compute the anchor (most recent period start) to derive per-algorithm
    // cycle lengths for multi-hop projection.
    final anchor = cycles.isNotEmpty
        ? utcCalendarDateOnly(cycles.last.periodStartUtc)
        : null;

    // Build dayConfidenceMap across all projected cycles.
    // For the same day, keep the entry with the lowest cycleIndex; add to
    // agreement count when the same cycle index appears from multiple algorithms.
    final dayConfidenceMap = <DateTime, DayPredictionMeta>{};

    final clampedHorizon = horizonCycles.clamp(1, 12);

    for (var hop = 0; hop < clampedHorizon; hop++) {
      for (final o in outputs) {
        // Cycle length = distance from anchor to this algorithm's prediction.
        // Falls back to a 28-day default if no anchor is available.
        final cycleLengthDays = anchor != null
            ? utcCalendarDateOnly(o.predictedStartUtc).difference(anchor).inDays
            : 28;
        final effectiveCycleLength = cycleLengthDays.clamp(14, 60);

        final hopStart = addUtcCalendarDays(
          o.predictedStartUtc,
          hop * effectiveCycleLength,
        );

        for (var i = 0; i < o.predictedDurationDays; i++) {
          final day = utcCalendarDateOnly(addUtcCalendarDays(hopStart, i));
          final current = dayConfidenceMap[day];
          if (current == null || hop < current.cycleIndex) {
            // First entry for this day, or this hop is closer → replace.
            dayConfidenceMap[day] = (agreement: 1, cycleIndex: hop);
          } else if (hop == current.cycleIndex) {
            // Same hop, additional algorithm agrees → increment agreement.
            dayConfidenceMap[day] =
                (agreement: current.agreement + 1, cycleIndex: hop);
          }
          // Higher hop index: ignore (lower-hop entry already recorded).
        }
      }
    }

    final activeAlgorithmCount = outputs.length;
    final totalAlgorithmCount = algos.length;
    final cycleCount = cycles.length;

    final milestone = _ensembleMilestone(
      previousActiveCount: previousActiveCount,
      activeAlgorithmCount: activeAlgorithmCount,
      cycleCount: cycleCount,
    );

    merged.add(
      ExplanationStep(
        kind: ExplanationFactKind.ensembleConsensus,
        payload: {
          'activeCount': activeAlgorithmCount,
          'totalCount': totalAlgorithmCount,
        },
      ),
    );

    final coord = PredictionCoordinator();
    final coordResult = coord.predictNext(
      storedPeriods: storedPeriods,
      calendar: calendar,
    );

    return EnsemblePredictionResult(
      algorithmOutputs: List<AlgorithmPrediction>.unmodifiable(outputs),
      dayConfidenceMap:
          Map<DateTime, DayPredictionMeta>.unmodifiable(dayConfidenceMap),
      activeAlgorithmCount: activeAlgorithmCount,
      totalAlgorithmCount: totalAlgorithmCount,
      milestone: milestone,
      consensusPrediction: coordResult.result,
      mergedExplanationSteps: List<ExplanationStep>.unmodifiable(merged),
      explanationText: '',
      cycleSpreadDays: cycleSpreadDays,
    );
  }

  /// Loads stored periods then runs [predictNext].
  Future<EnsemblePredictionResult> predictNextFromRepository({
    required PeriodRepository repository,
    required PeriodCalendarContext calendar,
    int? previousActiveCount,
    Set<AlgorithmId>? enabledAlgorithmIds,
    int horizonCycles = 3,
  }) async {
    final stored = await repository.listOrderedByStartUtc();
    return predictNext(
      storedPeriods: stored,
      calendar: calendar,
      previousActiveCount: previousActiveCount,
      enabledAlgorithmIds: enabledAlgorithmIds,
      horizonCycles: horizonCycles,
    );
  }
}

/// Max − min of included cycle lengths; 0 when fewer than 2 cycles.
int _cycleSpreadDays(List<PredictionCycleInput> cycles) {
  if (cycles.length < 2) return 0;
  final lengths = cycles.map((c) => c.lengthInDays).toList();
  return lengths.reduce((a, b) => a > b ? a : b) -
      lengths.reduce((a, b) => a < b ? a : b);
}

EnsembleMilestone? _ensembleMilestone({
  required int? previousActiveCount,
  required int activeAlgorithmCount,
  required int cycleCount,
}) {
  if (previousActiveCount == null) return null;
  if (activeAlgorithmCount <= previousActiveCount) return null;

  if (activeAlgorithmCount >= 4 && previousActiveCount < 4) {
    return const EnsembleMilestone(
      kind: EnsembleMilestoneKind.trendDetectionActive,
    );
  }
  if (activeAlgorithmCount >= 3 && previousActiveCount < 3) {
    return const EnsembleMilestone(
      kind: EnsembleMilestoneKind.allCoreMethodsActive,
    );
  }
  if (activeAlgorithmCount >= 2 && previousActiveCount < 2) {
    return EnsembleMilestone(
      kind: EnsembleMilestoneKind.expandedMethodCount,
      cycleCount: cycleCount,
      activeAlgorithmCount: activeAlgorithmCount,
    );
  }
  return null;
}

import 'package:ptrack_domain/ptrack_domain.dart';

import '../repositories/period_repository.dart';

/// Full prediction output: structured [PredictionResult], engine steps, and PRED-04 copy.
class PredictionCoordinatorResult {
  const PredictionCoordinatorResult({
    required this.result,
    required this.explanationSteps,
    required this.explanationText,
  });

  final PredictionResult result;
  final List<ExplanationStep> explanationSteps;
  final String explanationText;
}

/// Derives [PredictionCycleInput] rows from completed periods only (open spans skipped).
List<PredictionCycleInput> predictionCycleInputsFromStored({
  required List<StoredPeriod> stored,
  required PeriodCalendarContext calendar,
}) {
  final completed = <PeriodSpan>[
    for (final s in stored)
      if (s.span.isCompleted) s.span,
  ];
  if (completed.length < 2) {
    return const [];
  }
  final out = <PredictionCycleInput>[];
  for (var i = 0; i < completed.length - 1; i++) {
    final cycle = completedCycleBetweenStarts(
      periodStartUtc: completed[i].startUtc,
      nextPeriodStartUtc: completed[i + 1].startUtc,
      calendar: calendar,
    );
    out.add(
      PredictionCycleInput(
        periodStartUtc: cycle.periodStartUtc,
        lengthInDays: cycle.lengthInDays,
      ),
    );
  }
  return out;
}

/// Loads periods, builds completed-cycle inputs, runs [PredictionEngine], formats copy.
class PredictionCoordinator {
  PredictionCoordinator({
    PredictionEngine? engine,
  }) : engine = engine ?? const PredictionEngine();

  final PredictionEngine engine;

  /// Uses repository rows (closed + open) with [calendar] for local-day cycle math.
  Future<PredictionCoordinatorResult> predictNextFromRepository({
    required PeriodRepository repository,
    required PeriodCalendarContext calendar,
  }) async {
    final stored = await repository.listOrderedByStartUtc();
    return predictNext(storedPeriods: stored, calendar: calendar);
  }

  /// Synchronous prediction from already-loaded [storedPeriods] (tests / fixtures).
  PredictionCoordinatorResult predictNext({
    required List<StoredPeriod> storedPeriods,
    required PeriodCalendarContext calendar,
  }) {
    final inputs = predictionCycleInputsFromStored(
      stored: storedPeriods,
      calendar: calendar,
    );
    final engineResult = engine.predict(inputs);
    final text = formatPredictionExplanation(
      result: engineResult.result,
      steps: engineResult.explanation,
    );
    return PredictionCoordinatorResult(
      result: engineResult.result,
      explanationSteps: engineResult.explanation,
      explanationText: text,
    );
  }
}

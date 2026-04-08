/// Placeholder for TDD RED — replaced in feat commit.
class FertileWindow {
  const FertileWindow({
    required this.startUtc,
    required this.endUtc,
    required this.estimatedOvulationUtc,
  });

  final DateTime startUtc;
  final DateTime endUtc;
  final DateTime estimatedOvulationUtc;
}

/// Placeholder for TDD RED — returns null so tests fail until implemented.
class FertilityWindowCalculator {
  const FertilityWindowCalculator._();

  static FertileWindow? compute({
    required DateTime lastPeriodStartUtc,
    required int cycleLengthDays,
    int lutealPhaseDays = 14,
  }) =>
      null;

  static int? averageCycleLengthFromHistory(List<int> cycleLengths) => null;
}

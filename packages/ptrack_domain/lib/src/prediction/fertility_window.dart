import 'package:meta/meta.dart';

/// Estimated fertile window and ovulation timing using a standard calendar method.
///
/// This is an **educational estimate only**, not medical advice, contraception, or
/// a substitute for professional care.
@immutable
class FertileWindow {
  const FertileWindow({
    required this.startUtc,
    required this.endUtc,
    required this.estimatedOvulationUtc,
  });

  /// First day of the modeled fertile interval (UTC calendar midnight).
  final DateTime startUtc;

  /// Last day of the modeled fertile interval (UTC calendar midnight).
  final DateTime endUtc;

  /// Estimated ovulation day (UTC calendar midnight).
  final DateTime estimatedOvulationUtc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FertileWindow &&
          runtimeType == other.runtimeType &&
          startUtc == other.startUtc &&
          endUtc == other.endUtc &&
          estimatedOvulationUtc == other.estimatedOvulationUtc;

  @override
  int get hashCode => Object.hash(startUtc, endUtc, estimatedOvulationUtc);
}

/// Pure calendar-method helpers for on-device fertility window estimation.
///
/// **Formula (standard calendar method):**
/// - Cycle day 1 is [lastPeriodStartUtc] (first day of bleeding), normalized to UTC midnight.
/// - Estimated ovulation is placed on cycle day `(cycleLengthDays - lutealPhaseDays)`
///   (i.e. `(cycleLengthDays - lutealPhaseDays - 1)` calendar days after that start).
///   This matches the usual “ovulation ~14 days before the next period” idea when
///   `lutealPhaseDays` is 14.
/// - Fertile window start = ovulation day − 5 (sperm may survive up to ~5 days).
/// - Fertile window end = ovulation day + 1 (ovum viability often cited ~12–24 hours).
/// - Modeled window length is up to 7 calendar days; start may be clamped (see below).
///
/// **Defaults / assumptions:** [lutealPhaseDays] defaults to 14, a common textbook
/// assumption; actual luteal length varies.
///
/// **Clinical basis (high level):** sperm survival up to several days and short egg
/// viability motivate the −5 / +1 day spread around estimated ovulation.
///
/// **Constraints:** Returns null if `cycleLengthDays` is outside \[10, 60\] or
/// `lutealPhaseDays` outside \[5, 20\].
///
/// **Clamp:** If ovulation occurs on cycle day 5 or earlier, raw fertile start would fall
/// before cycle day 1; in that case [FertileWindow.startUtc] is clamped to the same
/// UTC midnight as the normalized period start.
class FertilityWindowCalculator {
  const FertilityWindowCalculator._();

  /// Normalizes [d] to UTC midnight of its calendar date in UTC.
  static DateTime _utcMidnight(DateTime d) {
    final u = d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  static FertileWindow? compute({
    required DateTime lastPeriodStartUtc,
    required int cycleLengthDays,
    int lutealPhaseDays = 14,
  }) {
    if (cycleLengthDays < 10 || cycleLengthDays > 60) return null;
    if (lutealPhaseDays < 5 || lutealPhaseDays > 20) return null;

    final periodStart = _utcMidnight(lastPeriodStartUtc);
    final daysAfterStartToOvulation = cycleLengthDays - lutealPhaseDays - 1;
    final ovulation = periodStart.add(Duration(days: daysAfterStartToOvulation));

    var fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));

    if (fertileStart.isBefore(periodStart)) {
      fertileStart = periodStart;
    }

    return FertileWindow(
      startUtc: _utcMidnight(fertileStart),
      endUtc: _utcMidnight(fertileEnd),
      estimatedOvulationUtc: _utcMidnight(ovulation),
    );
  }

  /// Arithmetic mean of [cycleLengths], rounded to the nearest integer; null if empty.
  static int? averageCycleLengthFromHistory(List<int> cycleLengths) {
    if (cycleLengths.isEmpty) return null;
    final sum = cycleLengths.fold<int>(0, (a, b) => a + b);
    return (sum / cycleLengths.length).round();
  }
}

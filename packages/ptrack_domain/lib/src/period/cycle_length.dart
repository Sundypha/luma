import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

import 'period_validation.dart';

/// Canonical **completed-cycle length** (Phase 2 CONTEXT): the number of local
/// calendar days from this period’s **start day** through the local calendar
/// **day before** the next period’s **start day**, inclusive, evaluated in
/// [calendar]’s timezone.
///
/// ## Examples (UTC calendar context)
///
/// 1. Period start **2026-01-01**, next start **2026-01-29** → last cycle day is
///    **2026-01-28** → **28** days (Jan 1 … Jan 28 inclusive).
/// 2. Period start **2026-06-01**, next start **2026-06-02** → last cycle day is
///    **2026-06-01** → **1** day.
///
/// ## DST-adjacent note
///
/// Instants are stored in UTC; local **calendar** days come from
/// [PeriodCalendarContext]. Around DST, two UTC instants can map to local dates
/// that differ from naive UTC date arithmetic—always use this helper rather
/// than subtracting UTC [DateTime] values.
@immutable
class CompletedCycle {
  const CompletedCycle({
    required this.periodStartUtc,
    required this.nextPeriodStartUtc,
    required this.lengthInDays,
  });

  final DateTime periodStartUtc;
  final DateTime nextPeriodStartUtc;

  /// Inclusive local-day count from start day through day before next start.
  final int lengthInDays;
}

/// Computes [CompletedCycle.lengthInDays] for adjacent completed periods.
///
/// Requires the next period’s start to be strictly after the current period’s
/// start in **local calendar** ordering (same rules as [calendar]).
CompletedCycle completedCycleBetweenStarts({
  required DateTime periodStartUtc,
  required DateTime nextPeriodStartUtc,
  required PeriodCalendarContext calendar,
}) {
  final loc = calendar.location;
  final startDay = calendar.localCalendarDateForUtc(periodStartUtc);
  final nextDay = calendar.localCalendarDateForUtc(nextPeriodStartUtc);

  final startMidnight =
      tz.TZDateTime(loc, startDay.year, startDay.month, startDay.day);
  final nextMidnight =
      tz.TZDateTime(loc, nextDay.year, nextDay.month, nextDay.day);

  if (!nextMidnight.isAfter(startMidnight)) {
    throw ArgumentError.value(
      nextPeriodStartUtc,
      'nextPeriodStartUtc',
      'Next period start must fall on a later local calendar day than periodStartUtc',
    );
  }

  final endMidnight = nextMidnight.subtract(const Duration(days: 1));
  final lengthInDays = endMidnight.difference(startMidnight).inDays + 1;

  return CompletedCycle(
    periodStartUtc: periodStartUtc.toUtc(),
    nextPeriodStartUtc: nextPeriodStartUtc.toUtc(),
    lengthInDays: lengthInDays,
  );
}

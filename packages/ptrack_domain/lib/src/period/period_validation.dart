import 'package:meta/meta.dart';
import 'package:timezone/timezone.dart' as tz;

import 'period_models.dart';

/// Maps common non-IANA labels to ids present in [tzdata](package:timezone).
///
/// The `timezone` package database uses `Etc/UTC`, not `UTC`. Device APIs and
/// Dart may still report `"UTC"`.
String canonicalTimeZoneIdForLookup(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return trimmed;
  // Case-insensitive: Android may report "utc".
  if (trimmed.toUpperCase() == 'UTC') return 'Etc/UTC';
  return trimmed;
}

/// Resolves **local calendar dates** (year/month/day) for UTC instants using a
/// fixed [tz.Location] (IANA zone id). This matches Phase 2 CONTEXT: instants
/// are stored in UTC; calendar-day rules use an explicit timezone for
/// deterministic validation and tests (the app may supply the device zone at
/// save time).
class PeriodCalendarContext {
  PeriodCalendarContext(this.location);

  final tz.Location location;

  /// Builds a context from an IANA timezone name (e.g. `America/New_York`).
  ///
  /// Accepts `UTC` as an alias for `Etc/UTC` (see [canonicalTimeZoneIdForLookup]).
  factory PeriodCalendarContext.fromTimeZoneName(String name) {
    final id = canonicalTimeZoneIdForLookup(name);
    return PeriodCalendarContext(tz.getLocation(id));
  }

  /// Local calendar components for [utc] in [location].
  CalendarDate localCalendarDateForUtc(DateTime utc) {
    final t = tz.TZDateTime.from(utc.toUtc(), location);
    return CalendarDate(t.year, t.month, t.day);
  }
}

/// A calendar date without a timezone; used for duplicate-start checks.
@immutable
class CalendarDate implements Comparable<CalendarDate> {
  const CalendarDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  @override
  int compareTo(CalendarDate other) {
    final c = year.compareTo(other.year);
    if (c != 0) return c;
    final m = month.compareTo(other.month);
    if (m != 0) return m;
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarDate &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-$month-$day';
}

sealed class PeriodValidationIssue {
  const PeriodValidationIssue();
}

/// Inclusive end is strictly before start (invalid for any period).
final class EndBeforeStart extends PeriodValidationIssue {
  const EndBeforeStart();
}

/// Candidate overlaps an existing period in UTC time (open-ended ranges extend
/// forward when [PeriodSpan.endUtc] is null).
final class OverlappingPeriod extends PeriodValidationIssue {
  const OverlappingPeriod(this.existingIndex);

  /// Index into the [existing] list passed to [PeriodValidation.validateForSave].
  final int existingIndex;
}

/// Another period (or the candidate vs existing) already starts on this local
/// calendar day in [calendar] context.
final class DuplicateStartCalendarDay extends PeriodValidationIssue {
  const DuplicateStartCalendarDay(this.calendarDate);

  final CalendarDate calendarDate;
}

@immutable
class PeriodValidationResult {
  const PeriodValidationResult(this.issues);

  final List<PeriodValidationIssue> issues;

  bool get isValid => issues.isEmpty;
}

/// Validation applied before persistence (save/edit).
abstract final class PeriodValidation {
  PeriodValidation._();

  /// Returns structured issues; empty list means the candidate may be saved.
  ///
  /// Rules (Phase 2 CONTEXT):
  /// - Reject [EndBeforeStart] when `endUtc != null` and `endUtc.isBefore(startUtc)`.
  /// - Reject overlaps with any period in [existing] (UTC range overlap; open
  ///   periods have no upper bound).
  /// - Reject [DuplicateStartCalendarDay] when the candidate's start falls on
  ///   the same local calendar day as any start in `existing + candidate` is
  ///   not needed—we only check against **existing** period starts (the new
  ///   period's day must not match another period's start day).
  static PeriodValidationResult validateForSave({
    required PeriodSpan candidate,
    required List<PeriodSpan> existing,
    required PeriodCalendarContext calendar,
  }) {
    final issues = <PeriodValidationIssue>[];

    final end = candidate.endUtc;
    if (end != null && end.isBefore(candidate.startUtc)) {
      issues.add(const EndBeforeStart());
    }

    for (var i = 0; i < existing.length; i++) {
      if (_utcRangesOverlap(
        candidate.startUtc,
        candidate.endUtc,
        existing[i].startUtc,
        existing[i].endUtc,
      )) {
        issues.add(OverlappingPeriod(i));
      }
    }

    final candidateStartDay =
        calendar.localCalendarDateForUtc(candidate.startUtc);
    for (final other in existing) {
      final otherStartDay =
          calendar.localCalendarDateForUtc(other.startUtc);
      if (candidateStartDay == otherStartDay) {
        issues.add(DuplicateStartCalendarDay(candidateStartDay));
        break;
      }
    }

    return PeriodValidationResult(List.unmodifiable(issues));
  }

  /// `true` if UTC ranges share at least one instant (open end = unbounded).
  static bool _utcRangesOverlap(
    DateTime aStart,
    DateTime? aEnd,
    DateTime bStart,
    DateTime? bEnd,
  ) {
    final as = aStart.toUtc();
    final bs = bStart.toUtc();
    final ae = aEnd?.toUtc();
    final be = bEnd?.toUtc();

    if (ae != null && ae.isBefore(bs)) return false;
    if (be != null && be.isBefore(as)) return false;
    return true;
  }
}

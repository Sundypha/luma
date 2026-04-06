import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

/// Visual segment shape for a logged period day within the calendar grid.
enum PeriodDayState {
  /// No logged period band for this day.
  none,

  /// First day of a multi-day period (left-rounded, right-flat).
  start,

  /// Interior day (full-width flat).
  middle,

  /// Last day of a multi-day period (left-flat, right-rounded).
  end,

  /// One-day period (fully rounded).
  single,

  /// First day of a week row that continues from a prior row (restarts the band).
  middleRowStart,

  /// Last day of a week row where the period continues into the next row (caps the row).
  middleRowEnd,
}

/// Per-day decoration inputs for calendar cell rendering.
@immutable
class CalendarDayData {
  const CalendarDayData({
    this.loggedPeriodState = PeriodDayState.none,
    this.isPredictedPeriod = false,
    this.hasLoggedData = false,
    this.isToday = false,
  });

  final PeriodDayState loggedPeriodState;
  final bool isPredictedPeriod;
  final bool hasLoggedData;
  final bool isToday;
}

DateTime _utcMidnight(DateTime d) {
  final x = d.isUtc ? d : d.toUtc();
  return DateTime.utc(x.year, x.month, x.day);
}

/// Index 0 = first column ([startingDayOfWeek]), 6 = last column of the row.
int _indexInWeek(DateTime dayUtcMidnight, int startingDayOfWeek) {
  final w = dayUtcMidnight.weekday;
  return (w - startingDayOfWeek + 7) % 7;
}

bool _isFirstDayOfRow(DateTime dayUtcMidnight, int startingDayOfWeek) =>
    _indexInWeek(dayUtcMidnight, startingDayOfWeek) == 0;

bool _isLastDayOfRow(DateTime dayUtcMidnight, int startingDayOfWeek) =>
    _indexInWeek(dayUtcMidnight, startingDayOfWeek) == 6;

/// Merges logged periods, predictions, day-entry markers, and today into a day map.
///
/// Period days are keyed by UTC calendar date (midnight). Overlapping periods: later
/// entries in [periodsWithDays] overwrite earlier ones for the same day.
Map<DateTime, CalendarDayData> buildCalendarDayDataMap({
  required List<StoredPeriodWithDays> periodsWithDays,
  required PredictionResult prediction,
  required DateTime today,
  int startingDayOfWeek = DateTime.monday,
}) {
  final todayNorm = _utcMidnight(today);
  final periodDayStates = <DateTime, PeriodDayState>{};

  for (final pwd in periodsWithDays) {
    final span = pwd.period.span;
    final startNorm = _utcMidnight(span.startUtc);
    final endNorm = span.endUtc != null
        ? _utcMidnight(span.endUtc!)
        : todayNorm;
    if (endNorm.isBefore(startNorm)) continue;

    var day = startNorm;
    while (!day.isAfter(endNorm)) {
      final PeriodDayState raw;
      if (day == startNorm && day == endNorm) {
        raw = PeriodDayState.single;
      } else if (day == startNorm) {
        raw = PeriodDayState.start;
      } else if (day == endNorm) {
        raw = PeriodDayState.end;
      } else {
        raw = PeriodDayState.middle;
      }

      var state = raw;
      if (raw == PeriodDayState.middle) {
        final isActualStart = day == startNorm;
        final isActualEnd = day == endNorm;
        final firstRow = _isFirstDayOfRow(day, startingDayOfWeek);
        final lastRow = _isLastDayOfRow(day, startingDayOfWeek);
        if (firstRow && !isActualStart) {
          state = PeriodDayState.middleRowStart;
        } else if (lastRow && !isActualEnd) {
          state = PeriodDayState.middleRowEnd;
        }
      }

      periodDayStates[day] = state;
      day = day.add(const Duration(days: 1));
    }
  }

  final loggedDataDays = <DateTime>{};
  for (final pwd in periodsWithDays) {
    for (final e in pwd.dayEntries) {
      loggedDataDays.add(_utcMidnight(e.data.dateUtc));
    }
  }

  bool hasLoggedPeriod(DateTime day) => periodDayStates.containsKey(day);

  final predictedDays = <DateTime>{};

  void addPredictedDay(DateTime d) {
    final k = _utcMidnight(d);
    if (!hasLoggedPeriod(k)) {
      predictedDays.add(k);
    }
  }

  switch (prediction) {
    case PredictionInsufficientHistory():
      break;
    case PredictionRangeOnly(:final rangeStartUtc, :final rangeEndUtc):
      var d = _utcMidnight(rangeStartUtc);
      final end = _utcMidnight(rangeEndUtc);
      while (!d.isAfter(end)) {
        addPredictedDay(d);
        d = d.add(const Duration(days: 1));
      }
    case PredictionPointWithRange(
        :final pointStartUtc,
        :final rangeStartUtc,
        :final rangeEndUtc,
      ):
      if (rangeStartUtc != null && rangeEndUtc != null) {
        var d = _utcMidnight(rangeStartUtc);
        final end = _utcMidnight(rangeEndUtc);
        while (!d.isAfter(end)) {
          addPredictedDay(d);
          d = d.add(const Duration(days: 1));
        }
      } else {
        addPredictedDay(pointStartUtc);
      }
  }

  final allDays = <DateTime>{
    ...periodDayStates.keys,
    ...predictedDays,
    ...loggedDataDays,
    todayNorm,
  };

  return {
    for (final day in allDays)
      day: CalendarDayData(
        loggedPeriodState: periodDayStates[day] ?? PeriodDayState.none,
        isPredictedPeriod: predictedDays.contains(day),
        hasLoggedData: loggedDataDays.contains(day),
        isToday: day == todayNorm,
      ),
  };
}

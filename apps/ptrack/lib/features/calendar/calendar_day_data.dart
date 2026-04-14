import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../settings/prediction_settings.dart';

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
    this.predictionConfidenceTier = 0,
    this.predictionAgreementCount = 0,
    this.predictionCycleIndex = 0,
    this.hasLoggedData = false,
    this.hasDiaryEntry = false,
    this.isToday = false,
    this.isFertileDay = false,
  });

  final PeriodDayState loggedPeriodState;

  /// 0 = none, 1 = one method, 2 = two agree, 3 = three or more agree.
  final int predictionConfidenceTier;

  /// Raw agreement count for detail copy ("X of N methods agree").
  final int predictionAgreementCount;

  /// Which projected cycle this day belongs to: 0 = next period,
  /// 1 = the period after that, etc. Only meaningful when [isPredictedPeriod].
  final int predictionCycleIndex;

  bool get isPredictedPeriod => predictionConfidenceTier > 0;

  final bool hasLoggedData;

  /// True when a standalone diary row exists for this UTC calendar day.
  final bool hasDiaryEntry;

  final bool isToday;

  /// Estimated fertile window day (opt-in); never true on logged bleeding days.
  final bool isFertileDay;
}

DateTime _utcMidnight(DateTime d) {
  final x = d.isUtc ? d : d.toUtc();
  return DateTime.utc(x.year, x.month, x.day);
}

/// True if [dayNorm] (UTC Y-M-D midnight, same as table_calendar cells) falls
/// within any stored period span.
bool loggedBleedingCoversCalendarDay(
  DateTime dayNorm,
  List<StoredPeriodWithDays> periodsWithDays,
  DateTime today,
) {
  final d = DateTime.utc(dayNorm.year, dayNorm.month, dayNorm.day);
  for (final pwd in periodsWithDays) {
    if (pwd.period.span.containsCalendarDayUtc(d, todayLocal: today)) {
      return true;
    }
  }
  return false;
}

/// Adapter: single [PredictionResult] → synthetic ensemble (one method, tier 1 days).
EnsemblePredictionResult legacyEnsembleFromPrediction(PredictionResult prediction) {
  final dayMap = <DateTime, DayPredictionMeta>{};

  void markRange(DateTime start, DateTime end) {
    var d = _utcMidnight(start);
    final e = _utcMidnight(end);
    while (!d.isAfter(e)) {
      dayMap[d] = (agreement: 1, cycleIndex: 0);
      d = d.add(const Duration(days: 1));
    }
  }

  switch (prediction) {
    case PredictionInsufficientHistory():
      break;
    case PredictionRangeOnly(:final rangeStartUtc, :final rangeEndUtc):
      markRange(rangeStartUtc, rangeEndUtc);
    case PredictionPointWithRange(
        :final pointStartUtc,
        :final rangeStartUtc,
        :final rangeEndUtc,
      ):
      if (rangeStartUtc != null && rangeEndUtc != null) {
        markRange(rangeStartUtc, rangeEndUtc);
      } else {
        dayMap[_utcMidnight(pointStartUtc)] = (agreement: 1, cycleIndex: 0);
      }
  }

  final active = dayMap.isEmpty ? 0 : 1;

  return EnsemblePredictionResult(
    algorithmOutputs: const [],
    dayConfidenceMap: dayMap,
    activeAlgorithmCount: active,
    totalAlgorithmCount: 1,
    milestone: null,
    consensusPrediction: prediction,
    mergedExplanationSteps: const [],
    explanationText: '',
  );
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
///
/// Provide either [ensemble] + [displayMode], or [prediction] for legacy median-only data.
Map<DateTime, CalendarDayData> buildCalendarDayDataMap({
  required List<StoredPeriodWithDays> periodsWithDays,
  required DateTime today,
  int startingDayOfWeek = DateTime.monday,
  EnsemblePredictionResult? ensemble,
  PredictionDisplayMode displayMode = PredictionDisplayMode.consensusOnly,
  PredictionResult? prediction,
  Set<DateTime>? fertileDays,
  Set<DateTime> diaryDates = const {},
}) {
  assert(
    (ensemble != null) ^ (prediction != null),
    'Provide exactly one of ensemble or prediction',
  );

  final eff = ensemble ?? legacyEnsembleFromPrediction(prediction!);
  final mode = ensemble != null ? displayMode : PredictionDisplayMode.consensusOnly;

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

  final predictionMeta =
      <DateTime, ({int tier, int agreementCount, int cycleIndex})>{};

  for (final entry in eff.dayConfidenceMap.entries) {
    final day = _utcMidnight(entry.key);
    if (loggedBleedingCoversCalendarDay(day, periodsWithDays, today)) {
      continue;
    }

    final agreementCount = entry.value.agreement;
    final cycleIndex = entry.value.cycleIndex;
    final tier = agreementCount.clamp(0, 3);
    if (mode == PredictionDisplayMode.consensusOnly) {
      if (tier < 2 && eff.activeAlgorithmCount > 1) {
        continue;
      }
    }

    predictionMeta[day] =
        (tier: tier, agreementCount: agreementCount, cycleIndex: cycleIndex);
  }

  final allDays = <DateTime>{
    ...periodDayStates.keys,
    ...predictionMeta.keys,
    ...loggedDataDays,
    todayNorm,
    if (fertileDays != null) ...fertileDays,
    ...diaryDates,
  };

  return {
    for (final day in allDays)
      day: CalendarDayData(
        loggedPeriodState: periodDayStates[day] ?? PeriodDayState.none,
        predictionConfidenceTier: predictionMeta[day]?.tier ?? 0,
        predictionAgreementCount: predictionMeta[day]?.agreementCount ?? 0,
        predictionCycleIndex: predictionMeta[day]?.cycleIndex ?? 0,
        hasLoggedData: loggedDataDays.contains(day),
        hasDiaryEntry: diaryDates.contains(day),
        isToday: day == todayNorm,
        isFertileDay: (fertileDays?.contains(day) ?? false) &&
            !loggedBleedingCoversCalendarDay(day, periodsWithDays, today),
      ),
  };
}

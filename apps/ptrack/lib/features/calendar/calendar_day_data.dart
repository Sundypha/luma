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
    this.hasLoggedData = false,
    this.isToday = false,
  });

  final PeriodDayState loggedPeriodState;

  /// 0 = none, 1 = one method, 2 = two agree, 3 = three or more agree.
  final int predictionConfidenceTier;

  /// Raw agreement count for detail copy ("X of N methods agree").
  final int predictionAgreementCount;

  bool get isPredictedPeriod => predictionConfidenceTier > 0;

  final bool hasLoggedData;
  final bool isToday;
}

DateTime _utcMidnight(DateTime d) {
  final x = d.isUtc ? d : d.toUtc();
  return DateTime.utc(x.year, x.month, x.day);
}

/// Adapter: single [PredictionResult] → synthetic ensemble (one method, tier 1 days).
EnsemblePredictionResult legacyEnsembleFromPrediction(PredictionResult prediction) {
  final dayMap = <DateTime, int>{};

  void markRange(DateTime start, DateTime end) {
    var d = _utcMidnight(start);
    final e = _utcMidnight(end);
    while (!d.isAfter(e)) {
      dayMap[d] = 1;
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
        dayMap[_utcMidnight(pointStartUtc)] = 1;
      }
  }

  final active = dayMap.isEmpty ? 0 : 1;

  return EnsemblePredictionResult(
    algorithmOutputs: const [],
    dayConfidenceMap: dayMap,
    activeAlgorithmCount: active,
    totalAlgorithmCount: 1,
    milestoneMessage: null,
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

  bool hasLoggedPeriod(DateTime day) => periodDayStates.containsKey(day);

  final predictionMeta = <DateTime, ({int tier, int agreementCount})>{};

  for (final entry in eff.dayConfidenceMap.entries) {
    final day = _utcMidnight(entry.key);
    if (hasLoggedPeriod(day)) continue;

    final agreementCount = entry.value;
    final tier = agreementCount.clamp(0, 3);
    if (mode == PredictionDisplayMode.consensusOnly) {
      if (tier < 2 && eff.activeAlgorithmCount > 1) {
        continue;
      }
    }

    predictionMeta[day] = (tier: tier, agreementCount: agreementCount);
  }

  final allDays = <DateTime>{
    ...periodDayStates.keys,
    ...predictionMeta.keys,
    ...loggedDataDays,
    todayNorm,
  };

  return {
    for (final day in allDays)
      day: CalendarDayData(
        loggedPeriodState: periodDayStates[day] ?? PeriodDayState.none,
        predictionConfidenceTier: predictionMeta[day]?.tier ?? 0,
        predictionAgreementCount: predictionMeta[day]?.agreementCount ?? 0,
        hasLoggedData: loggedDataDays.contains(day),
        isToday: day == todayNorm,
      ),
  };
}

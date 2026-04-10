import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

DateTime _utcDay(DateTime d) {
  final x = d.isUtc ? d : d.toUtc();
  return DateTime.utc(x.year, x.month, x.day);
}

/// Snapshot of where the user is in their cycle and the next predicted window.
@immutable
class CyclePosition {
  const CyclePosition({
    required this.dayInCycle,
    required this.isOnPeriod,
    this.periodDayNumber,
    this.nextPeriodRange,
    this.insufficientData = false,
  });

  final int dayInCycle;
  final bool isOnPeriod;
  final int? periodDayNumber;
  final (DateTime, DateTime)? nextPeriodRange;
  final bool insufficientData;
}

/// Pure cycle math + mapping from [PredictionResult] to UI fields.
CyclePosition computeCyclePosition({
  required List<StoredPeriodWithDays> periods,
  required PredictionResult prediction,
  required DateTime today,
}) {
  final todayNorm = _utcDay(today);
  final todayUtc = DateTime.utc(today.year, today.month, today.day);

  StoredPeriodWithDays? latest;
  for (final p in periods) {
    final s = _utcDay(p.period.span.startUtc);
    if (!s.isAfter(todayNorm)) {
      if (latest == null ||
          s.isAfter(_utcDay(latest.period.span.startUtc))) {
        latest = p;
      }
    }
  }

  if (latest == null) {
    return const CyclePosition(
      dayInCycle: 0,
      isOnPeriod: false,
      insufficientData: true,
    );
  }

  final lastPeriodStartNorm = _utcDay(latest.period.span.startUtc);
  final dayInCycle = todayNorm.difference(lastPeriodStartNorm).inDays + 1;
  final isOnPeriod = latest.period.span.containsCalendarDayUtc(
    todayUtc,
    todayLocal: today,
  );
  final periodDayNumber = isOnPeriod ? dayInCycle : null;

  var insufficientData = false;
  (DateTime, DateTime)? nextPeriodRange;

  switch (prediction) {
    case PredictionInsufficientHistory():
      insufficientData = true;
      nextPeriodRange = null;
    case PredictionRangeOnly(:final rangeStartUtc, :final rangeEndUtc):
      nextPeriodRange = (rangeStartUtc, rangeEndUtc);
    case PredictionPointWithRange(
        :final pointStartUtc,
        :final rangeStartUtc,
        :final rangeEndUtc,
      ):
      if (rangeStartUtc != null && rangeEndUtc != null) {
        nextPeriodRange = (rangeStartUtc, rangeEndUtc);
      } else {
        nextPeriodRange = (pointStartUtc, pointStartUtc);
      }
  }

  return CyclePosition(
    dayInCycle: dayInCycle,
    isOnPeriod: isOnPeriod,
    periodDayNumber: periodDayNumber,
    nextPeriodRange: nextPeriodRange,
    insufficientData: insufficientData,
  );
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import 'cycle_position.dart';

DateTime _utcCalendarDay(DateTime d) {
  final x = d.isUtc ? d : d.toUtc();
  return DateTime.utc(x.year, x.month, x.day);
}

DayEntryData? _findTodayEntry(
  List<StoredPeriodWithDays> periods,
  DateTime today,
) {
  final t = _utcCalendarDay(today);
  for (final p in periods) {
    for (final e in p.dayEntries) {
      final d = e.data.dateUtc;
      final dn = _utcCalendarDay(d);
      if (dn == t) {
        return e.data;
      }
    }
  }
  return null;
}

StoredDayEntry? _findTodayStoredEntry(
  List<StoredPeriodWithDays> periods,
  DateTime today,
) {
  final t = _utcCalendarDay(today);
  for (final p in periods) {
    for (final e in p.dayEntries) {
      if (_utcCalendarDay(e.data.dateUtc) == t) {
        return e;
      }
    }
  }
  return null;
}

bool _isTodayMarkedInPeriods(
  List<StoredPeriodWithDays> data,
  DateTime today,
) {
  final todayUtc = DateTime.utc(today.year, today.month, today.day);
  for (final p in data) {
    if (p.period.span.containsCalendarDayUtc(
          todayUtc,
          todayLocal: today,
        )) {
      return true;
    }
  }
  return false;
}

int? _todayPeriodId(
  List<StoredPeriodWithDays> data,
  DateTime today,
) {
  final todayUtc = DateTime.utc(today.year, today.month, today.day);
  for (final p in data) {
    if (p.period.span.containsCalendarDayUtc(
          todayUtc,
          todayLocal: today,
        )) {
      return p.period.id;
    }
  }
  return null;
}

/// Home tab state: cycle summary, today entry, prediction, mark-today command.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(
    this._repository,
    this._calendar, {
    List<StoredPeriodWithDays>? initialData,
  }) {
    if (initialData != null) {
      _applyData(initialData);
    }
    _subscription = _repository.watchPeriodsWithDays().listen(
      _onData,
      onError: _onStreamError,
    );
  }

  final PeriodRepository _repository;
  final PeriodCalendarContext _calendar;
  final EnsembleCoordinator _ensembleCoordinator = EnsembleCoordinator();

  PeriodRepository get repository => _repository;
  PeriodCalendarContext get calendar => _calendar;

  StreamSubscription<List<StoredPeriodWithDays>>? _subscription;

  List<StoredPeriodWithDays> _periodsWithDays = const [];
  CyclePosition? _cyclePosition;
  DayEntryData? _todayEntry;
  bool _isTodayMarked = false;
  EnsemblePredictionResult? _ensembleResult;
  int _previousActiveCount = 0;
  PredictionResult _prediction = const PredictionInsufficientHistory(
    completedCyclesAvailable: 0,
    minCompletedCyclesNeeded: 2,
  );

  bool _hasInitialEvent = false;
  Object? _loadError;

  bool get hasInitialEvent => _hasInitialEvent;
  Object? get loadError => _loadError;

  CyclePosition? get cyclePosition => _cyclePosition;
  DayEntryData? get todayEntry => _todayEntry;
  bool get isTodayMarked => _isTodayMarked;
  PredictionResult get prediction => _prediction;
  List<StoredPeriodWithDays> get periodsWithDays => _periodsWithDays;

  String? get milestoneMessage => _ensembleResult?.milestoneMessage;
  String get ensembleExplanationText =>
      _ensembleResult?.explanationText ?? '';
  int get activeAlgorithmCount => _ensembleResult?.activeAlgorithmCount ?? 0;

  /// Period row id covering today's calendar day, if any.
  int? get todayPeriodId => _todayPeriodId(_periodsWithDays, DateTime.now());

  /// Today's [StoredDayEntry] row for the symptom sheet, if any.
  StoredDayEntry? get todayStoredEntry =>
      _findTodayStoredEntry(_periodsWithDays, DateTime.now());

  void _applyData(List<StoredPeriodWithDays> data) {
    _loadError = null;
    _hasInitialEvent = true;
    _periodsWithDays = data;
    _recompute();
  }

  void _onData(List<StoredPeriodWithDays> data) {
    _applyData(data);
    notifyListeners();
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    _loadError = error;
    _hasInitialEvent = true;
    notifyListeners();
  }

  void _recompute() {
    final today = DateTime.now();
    final storedPeriods = _periodsWithDays.map((p) => p.period).toList();
    final ensemble = _ensembleCoordinator.predictNext(
      storedPeriods: storedPeriods,
      calendar: _calendar,
      previousActiveCount: _previousActiveCount,
    );
    _ensembleResult = ensemble;
    _previousActiveCount = ensemble.activeAlgorithmCount;
    _prediction = ensemble.consensusPrediction;
    _cyclePosition = computeCyclePosition(
      periods: _periodsWithDays,
      prediction: _prediction,
      today: today,
    );
    _todayEntry = _findTodayEntry(_periodsWithDays, today);
    _isTodayMarked = _isTodayMarkedInPeriods(_periodsWithDays, today);
  }

  Future<DayMarkOutcome> markToday() => _repository.markDay(DateTime.now());

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

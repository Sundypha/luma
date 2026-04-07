import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../settings/prediction_settings.dart';
import 'calendar_day_data.dart';

/// Reactive calendar state: period stream, prediction, day map, and selection.
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel(
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
    unawaited(
      PredictionSettings.load().then((mode) {
        if (_disposed) return;
        _displayMode = mode;
        _recompute();
        notifyListeners();
      }),
    );
  }

  bool _disposed = false;

  final PeriodRepository _repository;
  final PeriodCalendarContext _calendar;
  final EnsembleCoordinator _ensembleCoordinator = EnsembleCoordinator();

  PredictionDisplayMode _displayMode = PredictionDisplayMode.consensusOnly;
  EnsemblePredictionResult? _ensembleResult;
  int _previousActiveCount = 0;

  PeriodRepository get repository => _repository;
  PeriodCalendarContext get calendar => _calendar;

  StreamSubscription<List<StoredPeriodWithDays>>? _subscription;

  List<StoredPeriodWithDays> _periodsWithDays = const [];
  PredictionResult _prediction = const PredictionInsufficientHistory(
    completedCyclesAvailable: 0,
    minCompletedCyclesNeeded: 2,
  );
  Map<DateTime, CalendarDayData> _dayDataMap = const {};

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _hasInitialEvent = false;
  Object? _loadError;

  bool get hasInitialEvent => _hasInitialEvent;
  Object? get loadError => _loadError;

  Map<DateTime, CalendarDayData> get dayDataMap => _dayDataMap;
  PredictionResult get prediction => _prediction;
  EnsemblePredictionResult? get ensembleResult => _ensembleResult;
  List<StoredPeriodWithDays> get periodsWithDays => _periodsWithDays;

  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;

  set focusedDay(DateTime value) {
    if (_focusedDay == value) return;
    _focusedDay = value;
    notifyListeners();
  }

  set selectedDay(DateTime? value) {
    if (_selectedDay == value) return;
    _selectedDay = value;
    notifyListeners();
  }

  bool get showTodayButton {
    final now = DateTime.now();
    return _focusedDay.year != now.year || _focusedDay.month != now.month;
  }

  bool get showInsufficientFutureMessage {
    if (_prediction is! PredictionInsufficientHistory) return false;
    final now = DateTime.now();
    final focusedMonth = DateTime(_focusedDay.year, _focusedDay.month);
    final thisMonth = DateTime(now.year, now.month);
    return focusedMonth.isAfter(thisMonth);
  }

  void selectDay(DateTime selectedDay, [DateTime? focusedForCalendar]) {
    _selectedDay = selectedDay;
    _focusedDay = focusedForCalendar ?? selectedDay;
    notifyListeners();
  }

  void changeFocusedMonth(DateTime month) {
    _focusedDay = month;
    notifyListeners();
  }

  void goToToday() {
    _focusedDay = DateTime.now();
    _selectedDay = null;
    notifyListeners();
  }

  Future<void> markDay(DateTime day) => _repository.markDay(day);

  Future<void> unmarkDay(DateTime day) => _repository.unmarkDay(day);

  Future<void> updateDisplayMode(PredictionDisplayMode mode) async {
    if (_displayMode == mode) return;
    _displayMode = mode;
    await PredictionSettings.save(mode);
    _recompute();
    notifyListeners();
  }

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
    final storedPeriods = _periodsWithDays.map((p) => p.period).toList();
    final ensemble = _ensembleCoordinator.predictNext(
      storedPeriods: storedPeriods,
      calendar: _calendar,
      previousActiveCount: _previousActiveCount,
    );
    _ensembleResult = ensemble;
    _previousActiveCount = ensemble.activeAlgorithmCount;
    _prediction = ensemble.consensusPrediction;
    _dayDataMap = buildCalendarDayDataMap(
      periodsWithDays: _periodsWithDays,
      ensemble: ensemble,
      displayMode: _displayMode,
      today: DateTime.now(),
      startingDayOfWeek: DateTime.monday,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

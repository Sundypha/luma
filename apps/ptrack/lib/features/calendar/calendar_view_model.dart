import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import 'calendar_day_data.dart';

/// Reactive calendar state: period stream, prediction, day map, and selection.
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel(this._repository, this._calendar) {
    _subscription = _repository.watchPeriodsWithDays().listen(
      _onData,
      onError: _onStreamError,
    );
  }

  final PeriodRepository _repository;
  final PeriodCalendarContext _calendar;

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

  void _onData(List<StoredPeriodWithDays> data) {
    _loadError = null;
    _hasInitialEvent = true;
    _periodsWithDays = data;
    _recompute();
    notifyListeners();
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    _loadError = error;
    _hasInitialEvent = true;
    notifyListeners();
  }

  void _recompute() {
    final storedPeriods = _periodsWithDays.map((p) => p.period).toList();
    final predResult = PredictionCoordinator().predictNext(
      storedPeriods: storedPeriods,
      calendar: _calendar,
    );
    _prediction = predResult.result;
    _dayDataMap = buildCalendarDayDataMap(
      periodsWithDays: _periodsWithDays,
      prediction: _prediction,
      today: DateTime.now(),
      startingDayOfWeek: DateTime.monday,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

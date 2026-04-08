import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../settings/fertility_settings.dart';
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
      Future.wait([
        PredictionSettings.load(),
        PredictionSettings.loadEnabledAlgorithms(),
        PredictionSettings.loadHorizonCycles(),
        FertilitySettings.loadEnabled(),
        FertilitySettings.loadCycleLengthOverride(),
        FertilitySettings.loadLutealPhaseDays(),
      ]).then((results) {
        if (_disposed) return;
        _displayMode = results[0] as PredictionDisplayMode;
        _enabledAlgorithmIds = Set<AlgorithmId>.from(
          results[1] as Set<AlgorithmId>,
        );
        _horizonCycles = results[2] as int;
        _fertilityEnabled = results[3] as bool;
        _cycleLengthOverride = results[4] as int?;
        _lutealPhaseDays = results[5] as int;
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
  Set<AlgorithmId> _enabledAlgorithmIds =
      Set<AlgorithmId>.from(PredictionSettings.defaultEnabledAlgorithms);
  int _horizonCycles = PredictionSettings.defaultHorizonCycles;
  bool _fertilityEnabled = false;
  int? _cycleLengthOverride;
  int _lutealPhaseDays = FertilitySettings.defaultLutealPhaseDays;
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

  /// True when no ensemble method produced a forecast. The median consensus can
  /// still be [PredictionInsufficientHistory] while e.g. the Bayesian path alone
  /// marks days — then this is false.
  bool get showInsufficientPredictionHint =>
      (_ensembleResult?.activeAlgorithmCount ?? 0) == 0;

  bool get fertilityEnabled => _fertilityEnabled;

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

  Future<void> updateEnabledAlgorithms(Set<AlgorithmId> enabled) async {
    final next = Set<AlgorithmId>.from(enabled);
    if (setEquals(_enabledAlgorithmIds, next)) return;
    _enabledAlgorithmIds = next;
    await PredictionSettings.saveEnabledAlgorithms(next);
    _recompute();
    notifyListeners();
  }

  Future<void> updateHorizonCycles(int horizon) async {
    final clamped = horizon.clamp(1, 12);
    if (_horizonCycles == clamped) return;
    _horizonCycles = clamped;
    await PredictionSettings.saveHorizonCycles(clamped);
    _recompute();
    notifyListeners();
  }

  Future<void> updateFertilityEnabled(bool enabled) async {
    if (_fertilityEnabled == enabled) return;
    _fertilityEnabled = enabled;
    await FertilitySettings.saveEnabled(enabled);
    _recompute();
    notifyListeners();
  }

  int get cycleSpreadDays => _ensembleResult?.cycleSpreadDays ?? 0;

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

  Set<DateTime>? _fertileDaysForStored(List<StoredPeriod> storedPeriods) {
    if (!_fertilityEnabled || storedPeriods.isEmpty) return null;

    final inputs = predictionCycleInputsFromStored(
      stored: storedPeriods,
      calendar: _calendar,
    );
    final lengths = inputs.map((e) => e.lengthInDays).toList();
    final cycleLen = _cycleLengthOverride ??
        FertilityWindowCalculator.averageCycleLengthFromHistory(lengths);
    if (cycleLen == null) return null;

    final window = FertilityWindowCalculator.compute(
      lastPeriodStartUtc: storedPeriods.last.span.startUtc,
      cycleLengthDays: cycleLen,
      lutealPhaseDays: _lutealPhaseDays,
    );
    if (window == null) return null;

    final out = <DateTime>{};
    var d = window.startUtc;
    final end = window.endUtc;
    while (!d.isAfter(end)) {
      out.add(d);
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  void _recompute() {
    final storedPeriods = _periodsWithDays.map((p) => p.period).toList()
      ..sort((a, b) => a.span.startUtc.compareTo(b.span.startUtc));
    final ensemble = _ensembleCoordinator.predictNext(
      storedPeriods: storedPeriods,
      calendar: _calendar,
      previousActiveCount: _previousActiveCount,
      enabledAlgorithmIds: _enabledAlgorithmIds,
      horizonCycles: _horizonCycles,
    );
    _ensembleResult = ensemble;
    _previousActiveCount = ensemble.activeAlgorithmCount;
    _prediction = ensemble.consensusPrediction;
    final fertileDays = _fertileDaysForStored(storedPeriods);
    _dayDataMap = buildCalendarDayDataMap(
      periodsWithDays: _periodsWithDays,
      ensemble: ensemble,
      displayMode: _displayMode,
      today: DateTime.now(),
      startingDayOfWeek: DateTime.monday,
      fertileDays: fertileDays,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

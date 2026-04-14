import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../settings/fertility_settings.dart';
import '../settings/prediction_settings.dart';
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
    this._calendar,
    this._diaryRepository, {
    List<StoredPeriodWithDays>? initialData,
  }) {
    if (initialData != null) {
      _applyData(initialData);
    }
    _subscription = _repository.watchPeriodsWithDays().listen(
      _onData,
      onError: _onStreamError,
    );
    _diarySub = _diaryRepository.watchAllEntries().listen(_onDiaryEntries);
    unawaited(
      Future.wait([
        PredictionSettings.loadEnabledAlgorithms(),
        PredictionSettings.loadHorizonCycles(),
        FertilitySettings.loadEnabled(),
        FertilitySettings.loadCycleLengthOverride(),
        FertilitySettings.loadLutealPhaseDays(),
        FertilitySettings.loadSuggestionCardDismissed(),
      ]).then((results) {
        if (_disposed) return;
        _enabledAlgorithmIds =
            Set<AlgorithmId>.from(results[0] as Set<AlgorithmId>);
        _horizonCycles = results[1] as int;
        _fertilityEnabled = results[2] as bool;
        _cycleLengthOverride = results[3] as int?;
        _lutealPhaseDays = results[4] as int;
        _suggestionCardDismissed = results[5] as bool;
        _recompute();
        notifyListeners();
      }),
    );
  }

  bool _disposed = false;

  final PeriodRepository _repository;
  final PeriodCalendarContext _calendar;
  final DiaryRepository _diaryRepository;
  final EnsembleCoordinator _ensembleCoordinator = EnsembleCoordinator();
  Set<AlgorithmId> _enabledAlgorithmIds =
      Set<AlgorithmId>.from(PredictionSettings.defaultEnabledAlgorithms);
  int _horizonCycles = PredictionSettings.defaultHorizonCycles;
  bool _fertilityEnabled = false;
  int? _cycleLengthOverride;
  int _lutealPhaseDays = FertilitySettings.defaultLutealPhaseDays;
  bool _suggestionCardDismissed = false;
  FertileWindow? _fertileWindow;
  int? _computedAverageCycleLength;

  PeriodRepository get repository => _repository;
  PeriodCalendarContext get calendar => _calendar;
  DiaryRepository get diaryRepository => _diaryRepository;

  StreamSubscription<List<StoredPeriodWithDays>>? _subscription;
  StreamSubscription<List<StoredDiaryEntry>>? _diarySub;

  StoredDiaryEntry? _todayDiaryEntry;

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

  EnsemblePredictionResult? get ensembleResult => _ensembleResult;

  EnsembleMilestone? get ensembleMilestone => _ensembleResult?.milestone;
  int get activeAlgorithmCount => _ensembleResult?.activeAlgorithmCount ?? 0;

  bool get fertilityEnabled => _fertilityEnabled;

  FertileWindow? get fertileWindow => _fertileWindow;

  bool get showSuggestionCard =>
      !_fertilityEnabled && !_suggestionCardDismissed;

  bool get hasEnoughDataForFertility {
    final stored = _periodsWithDays.map((p) => p.period).toList()
      ..sort((a, b) => a.span.startUtc.compareTo(b.span.startUtc));
    final inputs = predictionCycleInputsFromStored(
      stored: stored,
      calendar: _calendar,
    );
    return inputs.length >= 2;
  }

  int? get computedAverageCycleLength => _computedAverageCycleLength;

  /// Period row id covering today's calendar day, if any.
  int? get todayPeriodId => _todayPeriodId(_periodsWithDays, DateTime.now());

  /// Today's [StoredDayEntry] row for the symptom sheet, if any.
  StoredDayEntry? get todayStoredEntry =>
      _findTodayStoredEntry(_periodsWithDays, DateTime.now());

  /// Today's standalone diary row, if any.
  StoredDiaryEntry? get todayDiaryEntry => _todayDiaryEntry;

  void _onDiaryEntries(List<StoredDiaryEntry> entries) {
    if (_disposed) return;
    final today = _utcCalendarDay(DateTime.now());
    StoredDiaryEntry? found;
    for (final e in entries) {
      if (_utcCalendarDay(e.data.dateUtc) == today) {
        found = e;
        break;
      }
    }
    _todayDiaryEntry = found;
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
    final today = DateTime.now();
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
    _cyclePosition = computeCyclePosition(
      periods: _periodsWithDays,
      prediction: _prediction,
      today: today,
    );
    _todayEntry = _findTodayEntry(_periodsWithDays, today);
    _isTodayMarked = _isTodayMarkedInPeriods(_periodsWithDays, today);

    final cycleInputs = predictionCycleInputsFromStored(
      stored: storedPeriods,
      calendar: _calendar,
    );
    final lengths = cycleInputs.map((e) => e.lengthInDays).toList();
    _computedAverageCycleLength =
        FertilityWindowCalculator.averageCycleLengthFromHistory(lengths);

    if (!_fertilityEnabled) {
      _fertileWindow = null;
    } else if (storedPeriods.isEmpty) {
      _fertileWindow = null;
    } else {
      final cycleLen = _cycleLengthOverride ?? _computedAverageCycleLength;
      _fertileWindow = cycleLen == null
          ? null
          : FertilityWindowCalculator.compute(
              lastPeriodStartUtc: storedPeriods.last.span.startUtc,
              cycleLengthDays: cycleLen,
              lutealPhaseDays: _lutealPhaseDays,
            );
    }
  }

  Future<DayMarkOutcome> markToday() => _repository.markDay(DateTime.now());

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

  Future<void> dismissSuggestionCard() async {
    if (_suggestionCardDismissed) return;
    _suggestionCardDismissed = true;
    await FertilitySettings.saveSuggestionCardDismissed(true);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _diarySub?.cancel();
    super.dispose();
  }
}

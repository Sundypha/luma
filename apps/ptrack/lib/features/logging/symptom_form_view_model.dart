import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

/// Form state for [SymptomFormSheet] (flow, pain, mood, notes only).
class SymptomFormViewModel extends ChangeNotifier {
  SymptomFormViewModel({
    required PeriodRepository repository,
    required DateTime day,
    required int periodId,
    StoredDayEntry? existing,
  })  : _repository = repository,
        _day = DateTime.utc(day.year, day.month, day.day),
        _periodId = periodId,
        _existing = existing {
    final e = existing;
    if (e != null) {
      final d = e.data;
      _flowIntensity = d.flowIntensity;
      _painScore = d.painScore;
      _mood = d.mood;
      _notes = d.notes ?? '';
      _personalNotes = d.personalNotes ?? '';
    }
  }

  final PeriodRepository _repository;
  final DateTime _day;
  final int _periodId;
  final StoredDayEntry? _existing;

  FlowIntensity? _flowIntensity;
  PainScore? _painScore;
  Mood? _mood;
  String _notes = '';
  String _personalNotes = '';
  bool _isSaving = false;
  String? _errorText;

  FlowIntensity? get flowIntensity => _flowIntensity;
  PainScore? get painScore => _painScore;
  Mood? get mood => _mood;
  String get notes => _notes;
  String get personalNotes => _personalNotes;
  bool get isSaving => _isSaving;
  String? get errorText => _errorText;
  bool get isEditing => _existing != null;

  void setFlow(FlowIntensity? v) {
    _flowIntensity = v;
    notifyListeners();
  }

  void setPain(PainScore? v) {
    _painScore = v;
    notifyListeners();
  }

  void setMood(Mood? v) {
    _mood = v;
    notifyListeners();
  }

  void setNotes(String v) {
    _notes = v;
    notifyListeners();
  }

  void setPersonalNotes(String v) {
    _personalNotes = v;
    notifyListeners();
  }

  Future<bool> save() async {
    _isSaving = true;
    _errorText = null;
    notifyListeners();
    try {
      final data = DayEntryData(
        dateUtc: _day,
        flowIntensity: _flowIntensity,
        painScore: _painScore,
        mood: _mood,
        notes: _notes.trim().isEmpty ? null : _notes.trim(),
        personalNotes:
            _personalNotes.trim().isEmpty ? null : _personalNotes.trim(),
      );
      final existing = _existing;
      if (existing != null) {
        final updated = await _repository.updateDayEntry(existing.id, data);
        if (!updated) {
          throw StateError('Day entry update affected 0 rows (id=${existing.id})');
        }
      } else {
        await _repository.upsertDayEntryForPeriod(_periodId, data);
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      assert(() {
        debugPrint('SymptomFormViewModel.save failed: $e');
        debugPrint('$st');
        return true;
      }());
      _isSaving = false;
      _errorText = kDebugMode
          ? 'Could not save: $e'
          : 'Could not save symptoms. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearSymptoms() async {
    final existing = _existing;
    if (existing == null) return false;
    try {
      return await _repository.clearClinicalSymptoms(existing.id);
    } catch (_) {
      _errorText = 'Could not clear symptoms. Please try again.';
      notifyListeners();
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import 'luma_export_delivery.dart';

enum ExportStep { selectContent, setPassword, exporting, done, error }

typedef ExportDataRun = Future<ExportResult> Function({
  required ExportOptions options,
  ProgressCallback? onProgress,
});

enum ExportPreset { everything, periodsOnly }

/// State for the export backup wizard.
final class ExportViewModel extends ChangeNotifier {
  ExportStep _step = ExportStep.selectContent;
  bool _includePeriods = true;
  bool _includeSymptoms = true;
  bool _includeNotes = true;
  String? _password;
  double _progress = 0;
  ExportResult? _result;

  ExportStep get step => _step;
  bool get includePeriods => _includePeriods;
  bool get includeSymptoms => _includeSymptoms;
  bool get includeNotes => _includeNotes;
  String? get password => _password;
  double get progress => _progress;
  ExportResult? get result => _result;

  bool get hasContentSelection =>
      _includePeriods || _includeSymptoms || _includeNotes;

  bool get periodsOnlySelected =>
      _includePeriods && !_includeSymptoms && !_includeNotes;

  bool get symptomsOnlySelected =>
      !_includePeriods && _includeSymptoms && !_includeNotes;

  bool get notesOnlySelected =>
      !_includePeriods && !_includeSymptoms && _includeNotes;

  void applyPreset(ExportPreset preset) {
    switch (preset) {
      case ExportPreset.everything:
        _includePeriods = true;
        _includeSymptoms = true;
        _includeNotes = true;
      case ExportPreset.periodsOnly:
        _includePeriods = true;
        _includeSymptoms = false;
        _includeNotes = false;
    }
    notifyListeners();
  }

  void togglePeriods() {
    _includePeriods = !_includePeriods;
    notifyListeners();
  }

  void toggleSymptoms() {
    _includeSymptoms = !_includeSymptoms;
    notifyListeners();
  }

  void toggleNotes() {
    _includeNotes = !_includeNotes;
    notifyListeners();
  }

  void setPassword(String? pw) {
    _password = (pw == null || pw.isEmpty) ? null : pw;
    notifyListeners();
  }

  void nextStep() {
    if (_step == ExportStep.selectContent) {
      if (!hasContentSelection) return;
      _step = ExportStep.setPassword;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_step == ExportStep.setPassword) {
      _step = ExportStep.selectContent;
      notifyListeners();
    }
  }

  Future<void> startExport(ExportService service) {
    return runExport(
      ({required options, onProgress}) =>
          service.exportData(options: options, onProgress: onProgress),
    );
  }

  Future<void> runExport(ExportDataRun exportData) async {
    _step = ExportStep.exporting;
    _progress = 0;
    _result = null;
    notifyListeners();
    try {
      final options = ExportOptions(
        includePeriods: _includePeriods,
        includeSymptoms: _includeSymptoms,
        includeNotes: _includeNotes,
        password: _password,
      );
      _result = await exportData(
        options: options,
        onProgress: (current, total) {
          _progress = total > 0 ? current / total : 0;
          notifyListeners();
        },
      );
      _step = ExportStep.done;
    } catch (_) {
      _step = ExportStep.error;
    }
    notifyListeners();
  }

  Future<void> deliverExport(BuildContext context) async {
    final r = _result;
    if (r == null) return;
    await deliverLumaExport(context, r);
  }

  void reset() {
    _step = ExportStep.selectContent;
    _includePeriods = true;
    _includeSymptoms = true;
    _includeNotes = true;
    _password = null;
    _progress = 0;
    _result = null;
    notifyListeners();
  }
}

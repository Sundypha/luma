import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import 'pdf_data_collector.dart';
import 'pdf_document_builder.dart';
import 'pdf_section_config.dart';

/// State for the PDF export flow: section config, generation, and preview bytes.
class PdfExportViewModel extends ChangeNotifier {
  PdfExportViewModel(this._repository, this._calendar) {
    unawaited(_loadInitial());
  }

  final PeriodRepository _repository;
  final PeriodCalendarContext _calendar;

  bool _disposed = false;
  PdfSectionConfig _config = PdfSectionConfig.fromPreset(PdfExportPreset.full);
  bool _generating = false;
  Uint8List? _pdfBytes;
  String? _error;

  PdfSectionConfig get config => _config;
  bool get isGenerating => _generating;
  Uint8List? get pdfBytes => _pdfBytes;
  String? get error => _error;
  bool get hasPreview => _pdfBytes != null;

  /// Preset whose section set matches [config], or null if custom.
  PdfExportPreset? get matchingPreset {
    for (final p in PdfExportPreset.values) {
      if (sectionsForPreset(p).length == _config.enabledSections.length &&
          sectionsForPreset(p).containsAll(_config.enabledSections)) {
        return p;
      }
    }
    return null;
  }

  Future<void> _loadInitial() async {
    final loaded = await PdfSectionConfig.loadSaved();
    if (_disposed) return;
    _config = loaded;
    notifyListeners();
  }

  void updatePreset(PdfExportPreset preset) {
    _config = _config.copyWith(enabledSections: sectionsForPreset(preset));
    notifyListeners();
    unawaited(PdfSectionConfig.save(_config));
  }

  void toggleSection(PdfSection section) {
    final next = Set<PdfSection>.from(_config.enabledSections);
    if (next.contains(section)) {
      next.remove(section);
    } else {
      next.add(section);
    }
    _config = _config.copyWith(enabledSections: next);
    notifyListeners();
    unawaited(PdfSectionConfig.save(_config));
  }

  void updateDateRange(DateTime start, DateTime end) {
    _config = _config.copyWith(rangeStart: start, rangeEnd: end);
    notifyListeners();
    unawaited(PdfSectionConfig.save(_config));
  }

  void clearPreview() {
    _pdfBytes = null;
    _error = null;
    notifyListeners();
  }

  String generateFilename() {
    final d = DateTime.now().toUtc();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return 'luma-report-$y-$m-$day.pdf';
  }

  /// [locale] is a BCP-47 language code (e.g. from [Localizations.localeOf]).
  Future<void> generate(String locale, PdfContentStrings contentStrings) async {
    _generating = true;
    _error = null;
    _pdfBytes = null;
    notifyListeners();
    try {
      final snapshot = await _repository.watchPeriodsWithDays().first;
      final data = PdfDataCollector().collect(
        periodsWithDays: snapshot,
        config: _config,
        calendar: _calendar,
        locale: locale,
      );
      final bytes = await PdfDocumentBuilder().build(
        data: data,
        config: _config,
        strings: contentStrings,
      );
      if (_disposed) return;
      _pdfBytes = bytes;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PdfExportViewModel.generate failed: $e\n$st');
      }
      if (!_disposed) {
        _error = 'generate_failed';
      }
    } finally {
      if (!_disposed) {
        _generating = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

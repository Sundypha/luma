import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Toggleable sections of the PDF export (data sections; metadata/disclaimer are separate).
enum PdfSection {
  overviewStats,
  cycleHistory,
  cycleChart,
  daySummaryTable,
  notesLog,
}

/// Quick presets mapping to enabled [PdfSection]s.
enum PdfExportPreset {
  summary,
  standard,
  full,
}

/// Which sections are on for a given preset.
Set<PdfSection> sectionsForPreset(PdfExportPreset preset) => switch (preset) {
      PdfExportPreset.summary => {PdfSection.overviewStats},
      PdfExportPreset.standard => {
          PdfSection.overviewStats,
          PdfSection.cycleHistory,
          PdfSection.daySummaryTable,
        },
      PdfExportPreset.full => PdfSection.values.toSet(),
    };

@immutable
class PdfSectionConfig {
  const PdfSectionConfig({
    required this.enabledSections,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final Set<PdfSection> enabledSections;

  /// Inclusive UTC calendar date (time-of-day ignored for range logic).
  final DateTime rangeStart;

  /// Inclusive UTC calendar date (time-of-day ignored for range logic).
  final DateTime rangeEnd;

  bool isEnabled(PdfSection s) => enabledSections.contains(s);

  bool get hasAnySections => enabledSections.isNotEmpty;

  /// [rangeEnd] defaults to today (UTC date); [rangeStart] to 12 months before that (UTC date).
  factory PdfSectionConfig.fromPreset(
    PdfExportPreset preset, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    final end = rangeEnd ?? _utcDateOnly(DateTime.now().toUtc());
    final start = rangeStart ?? _addMonthsUtc(end, -12);
    return PdfSectionConfig(
      enabledSections: sectionsForPreset(preset),
      rangeStart: start,
      rangeEnd: end,
    );
  }

  PdfSectionConfig copyWith({
    Set<PdfSection>? enabledSections,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    return PdfSectionConfig(
      enabledSections: enabledSections ?? this.enabledSections,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
    );
  }

  static const _keySections = 'pdf_export_sections';
  static const _keyRangeStartMs = 'pdf_export_range_start_ms';
  static const _keyRangeEndMs = 'pdf_export_range_end_ms';

  /// Loads persisted sections and range, or a **full** preset with default 12‑month window if unset.
  static Future<PdfSectionConfig> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySections);
    if (raw == null || raw.isEmpty) {
      return PdfSectionConfig.fromPreset(PdfExportPreset.full);
    }
    final sections = <PdfSection>{};
    for (final part in raw.split(',')) {
      final name = part.trim();
      if (name.isEmpty) continue;
      for (final e in PdfSection.values) {
        if (e.name == name) {
          sections.add(e);
          break;
        }
      }
    }
    if (sections.isEmpty) {
      return PdfSectionConfig.fromPreset(PdfExportPreset.full);
    }
    final startMs = prefs.getInt(_keyRangeStartMs);
    final endMs = prefs.getInt(_keyRangeEndMs);
    if (startMs == null || endMs == null) {
      return PdfSectionConfig.fromPreset(PdfExportPreset.full).copyWith(
        enabledSections: sections,
      );
    }
    return PdfSectionConfig(
      enabledSections: sections,
      rangeStart: DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true),
      rangeEnd: DateTime.fromMillisecondsSinceEpoch(endMs, isUtc: true),
    );
  }

  static Future<void> save(PdfSectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final names = config.enabledSections.map((s) => s.name).join(',');
    await prefs.setString(_keySections, names);
    await prefs.setInt(
      _keyRangeStartMs,
      config.rangeStart.toUtc().millisecondsSinceEpoch,
    );
    await prefs.setInt(
      _keyRangeEndMs,
      config.rangeEnd.toUtc().millisecondsSinceEpoch,
    );
  }

  static DateTime _utcDateOnly(DateTime d) {
    final u = d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  static DateTime _addMonthsUtc(DateTime utcDateOnly, int deltaMonths) {
    var y = utcDateOnly.year;
    var m = utcDateOnly.month + deltaMonths;
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    final lastDay = DateTime.utc(y, m + 1, 0).day;
    final day = utcDateOnly.day > lastDay ? lastDay : utcDateOnly.day;
    return DateTime.utc(y, m, day);
  }
}

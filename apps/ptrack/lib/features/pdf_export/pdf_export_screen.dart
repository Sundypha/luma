import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../../l10n/app_localizations.dart';
import 'pdf_document_builder.dart';
import 'pdf_export_view_model.dart';
import 'pdf_preview_screen.dart';
import 'pdf_section_config.dart';

/// Export settings: presets, section toggles, date range, and PDF generation.
class PdfExportScreen extends StatefulWidget {
  const PdfExportScreen({
    super.key,
    required this.repository,
    required this.calendar,
  });

  final PeriodRepository repository;
  final PeriodCalendarContext calendar;

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  late final PdfExportViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PdfExportViewModel(widget.repository, widget.calendar);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  static DateTime _utcDateOnlyFromPicker(DateTime picked) {
    return DateTime.utc(picked.year, picked.month, picked.day);
  }

  String _formatRangeDate(DateTime utcDate, String localeName) {
    final d = utcDate.toUtc();
    final fmt = DateFormat.yMMMd(localeName);
    return fmt.format(DateTime.utc(d.year, d.month, d.day));
  }

  IconData _iconForSection(PdfSection s) => switch (s) {
        PdfSection.overviewStats => Icons.assessment_outlined,
        PdfSection.cycleHistory => Icons.history,
        PdfSection.cycleChart => Icons.bar_chart_outlined,
        PdfSection.daySummaryTable => Icons.calendar_view_day_outlined,
        PdfSection.notesLog => Icons.notes_outlined,
      };

  String _sectionTitle(PdfSection s) => switch (s) {
        PdfSection.overviewStats => 'Overview statistics',
        PdfSection.cycleHistory => 'Cycle history',
        PdfSection.cycleChart => 'Cycle length chart',
        PdfSection.daySummaryTable => 'Daily log summary',
        PdfSection.notesLog => 'Notes',
      };

  Future<void> _pickDate({required bool isStart}) async {
    final vm = _viewModel;
    final initial = isStart ? vm.config.rangeStart : vm.config.rangeEnd;
    final first = DateTime(vm.config.rangeStart.year - 10);
    final last = DateTime(vm.config.rangeEnd.year + 1, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.utc(initial.year, initial.month, initial.day)
          .toLocal(),
      firstDate: first,
      lastDate: last,
    );
    if (picked == null || !mounted) return;
    final utcPicked = _utcDateOnlyFromPicker(picked);
    if (isStart) {
      final end = vm.config.rangeEnd;
      final nextStart = utcPicked.isAfter(end) ? end : utcPicked;
      vm.updateDateRange(nextStart, end);
    } else {
      final start = vm.config.rangeStart;
      final nextEnd = utcPicked.isBefore(start) ? start : utcPicked;
      vm.updateDateRange(start, nextEnd);
    }
  }

  Future<void> _onGenerate() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    await _viewModel.generate(locale.languageCode, l10n.toPdfContentStrings());
    if (!mounted) return;
    if (_viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate report. Please try again.'),
        ),
      );
      return;
    }
    final bytes = _viewModel.pdfBytes;
    if (bytes != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PdfPreviewScreen(
            pdfBytes: bytes,
            filename: _viewModel.generateFilename(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final vm = _viewModel;
        final selectedPreset = vm.matchingPreset;

        return Scaffold(
          appBar: AppBar(title: const Text('Export PDF Report')),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Summary'),
                    selected: selectedPreset == PdfExportPreset.summary,
                    onSelected: (_) => vm.updatePreset(PdfExportPreset.summary),
                  ),
                  ChoiceChip(
                    label: const Text('Standard'),
                    selected: selectedPreset == PdfExportPreset.standard,
                    onSelected: (_) => vm.updatePreset(PdfExportPreset.standard),
                  ),
                  ChoiceChip(
                    label: const Text('Full'),
                    selected: selectedPreset == PdfExportPreset.full,
                    onSelected: (_) => vm.updatePreset(PdfExportPreset.full),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Sections'),
                children: [
                  for (final section in PdfSection.values)
                    SwitchListTile(
                      secondary: Icon(_iconForSection(section)),
                      title: Text(_sectionTitle(section)),
                      value: vm.config.isEnabled(section),
                      onChanged: (_) => vm.toggleSection(section),
                    ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.date_range_outlined),
                title: const Text('From'),
                subtitle: Text(
                  _formatRangeDate(vm.config.rangeStart, localeName),
                ),
                onTap: () => unawaited(_pickDate(isStart: true)),
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('To'),
                subtitle: Text(
                  _formatRangeDate(vm.config.rangeEnd, localeName),
                ),
                onTap: () => unawaited(_pickDate(isStart: false)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: vm.isGenerating ? null : () => unawaited(_onGenerate()),
                icon: vm.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  vm.isGenerating ? 'Generating report…' : 'Generate Preview',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import 'symptom_form_view_model.dart';

/// Single-purpose bottom sheet: flow, pain, mood, notes (no date or period UI).
class SymptomFormSheet extends StatefulWidget {
  const SymptomFormSheet({
    super.key,
    required this.repository,
    required this.day,
    required this.periodId,
    this.existing,
  });

  final PeriodRepository repository;
  final DateTime day;
  final int periodId;
  final StoredDayEntry? existing;

  @override
  State<SymptomFormSheet> createState() => _SymptomFormSheetState();
}

class _SymptomFormSheetState extends State<SymptomFormSheet> {
  late final SymptomFormViewModel _vm;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _vm = SymptomFormViewModel(
      repository: widget.repository,
      day: widget.day,
      periodId: widget.periodId,
      existing: widget.existing,
    );
    _notesController = TextEditingController(text: _vm.notes)
      ..addListener(() => _vm.setNotes(_notesController.text));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _vm.isEditing ? 'Edit symptoms' : 'Add symptoms',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Flow',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<FlowIntensity?>(
                segments: [
                  ButtonSegment<FlowIntensity?>(
                    value: null,
                    label: Text(
                      '—',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  for (final f in FlowIntensity.values)
                    ButtonSegment<FlowIntensity?>(
                      value: f,
                      label: Text(f.label),
                    ),
                ],
                selected: {_vm.flowIntensity},
                onSelectionChanged: (s) => _vm.setFlow(s.first),
              ),
              const SizedBox(height: 16),
              Text(
                'Pain',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PainScore?>(
                segments: [
                  ButtonSegment<PainScore?>(
                    value: null,
                    label: Text(
                      '—',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  for (final p in PainScore.values)
                    ButtonSegment<PainScore?>(
                      value: p,
                      label: Text(p.compactLabel),
                    ),
                ],
                selected: {_vm.painScore},
                onSelectionChanged: (s) => _vm.setPain(s.first),
              ),
              const SizedBox(height: 16),
              Text(
                'Mood',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in Mood.values)
                    ChoiceChip(
                      label: Text('${m.emoji} ${m.label}'),
                      selected: _vm.mood == m,
                      onSelected: (_) => _vm.setMood(m),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              if (_vm.errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _vm.errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _vm.isSaving
                    ? null
                    : () async {
                        final ok = await _vm.save();
                        if (!context.mounted) return;
                        if (ok) Navigator.of(context).pop();
                      },
                child: const Text('Save'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  if (_vm.isEditing) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: _vm.isSaving
                          ? null
                          : () async {
                              final ok = await _vm.clearSymptoms();
                              if (!context.mounted) return;
                              if (ok) Navigator.of(context).pop();
                            },
                      child: const Text('Clear symptoms'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Opens [SymptomFormSheet] as a modal bottom sheet.
Future<void> showSymptomFormSheet(
  BuildContext context, {
  required PeriodRepository repository,
  required DateTime day,
  required int periodId,
  StoredDayEntry? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SymptomFormSheet(
          repository: repository,
          day: day,
          periodId: periodId,
          existing: existing,
        ),
      );
    },
  );
}

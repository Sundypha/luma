import 'package:flutter/material.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:luma/l10n/logging_localizations.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import 'symptom_form_view_model.dart';

/// Flow / pain: index `0` = not set; `1..values.length` maps to enum `.values[i - 1]`.
double _sliderIndexFromNullableEnum(int? enumIndex) {
  if (enumIndex == null) return 0;
  return (enumIndex + 1).toDouble();
}

/// Mood uses the same “less → more severe” left-to-right as pain/flow: good mood left, distressed right.
/// Stored enum / DB order is unchanged (`veryBad`..`veryGood`); only the slider direction is inverted.
double _moodSliderIndexFromMood(Mood? mood) {
  if (mood == null) return 0;
  return (Mood.values.length - mood.index).toDouble();
}

Mood? _moodFromSliderTick(int tick) {
  if (tick == 0) return null;
  return Mood.values[Mood.values.length - tick];
}

String _moodSliderLabel(AppLocalizations l10n, Mood? mood) {
  if (mood == null) return l10n.symptomNotSet;
  return '${mood.emoji} ${LoggingLocalizations.moodLabel(l10n, mood)}';
}

/// Single-purpose bottom sheet: flow, pain, mood, clinical notes, personal notes.
class SymptomFormSheet extends StatefulWidget {
  const SymptomFormSheet({
    super.key,
    required this.repository,
    required this.diaryRepository,
    required this.initialPersonalNotes,
    required this.day,
    required this.periodId,
    this.existing,
  });

  final PeriodRepository repository;
  final DiaryRepository diaryRepository;
  final String initialPersonalNotes;
  final DateTime day;
  final int periodId;
  final StoredDayEntry? existing;

  @override
  State<SymptomFormSheet> createState() => _SymptomFormSheetState();
}

/// Discrete [Slider]: one stop for “not set”, then one per enum value.
class _DiscreteSymptomSlider extends StatelessWidget {
  const _DiscreteSymptomSlider({
    required this.title,
    required this.value,
    required this.stepCount,
    required this.displayLabel,
    required this.onChanged,
  });

  final String title;
  final double value;
  /// Enum `.values.length` — slider is `0..stepCount` with `divisions: stepCount`.
  final int stepCount;
  final String displayLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = stepCount.toDouble();
    // Default M3 tick marks are tiny and low-contrast; discrete steps need visible divisors.
    // Active ticks sit on the primary-filled segment — use [onPrimary], not [primary].
    final tickInactive = scheme.outline;
    final tickActive = scheme.onPrimary;
    final sliderTheme = theme.sliderTheme.copyWith(
      trackHeight: 6,
      activeTickMarkColor: tickActive,
      inactiveTickMarkColor: tickInactive,
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 5),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayLabel,
          style: theme.textTheme.titleMedium,
        ),
        SliderTheme(
          data: sliderTheme,
          child: Slider(
            value: value.clamp(0, max),
            min: 0,
            max: max,
            divisions: stepCount,
            label: displayLabel,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SymptomFormSheetState extends State<SymptomFormSheet> {
  late final SymptomFormViewModel _vm;
  late final TextEditingController _notesController;
  late final TextEditingController _personalNotesController;

  @override
  void initState() {
    super.initState();
    _vm = SymptomFormViewModel(
      repository: widget.repository,
      diaryRepository: widget.diaryRepository,
      initialPersonalNotes: widget.initialPersonalNotes,
      day: widget.day,
      periodId: widget.periodId,
      existing: widget.existing,
    );
    _notesController = TextEditingController(text: _vm.notes)
      ..addListener(() => _vm.setNotes(_notesController.text));
    _personalNotesController = TextEditingController(text: _vm.personalNotes)
      ..addListener(
        () => _vm.setPersonalNotes(_personalNotesController.text),
      );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _personalNotesController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                _vm.isEditing
                    ? l10n.symptomFormTitleEdit
                    : l10n.symptomFormTitleAdd,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _DiscreteSymptomSlider(
                title: l10n.symptomSectionFlow,
                value: _sliderIndexFromNullableEnum(_vm.flowIntensity?.index),
                stepCount: FlowIntensity.values.length,
                displayLabel: _vm.flowIntensity != null
                    ? LoggingLocalizations.flowLabel(l10n, _vm.flowIntensity!)
                    : l10n.symptomNotSet,
                onChanged: (v) {
                  final i = v.round();
                  if (i == 0) {
                    _vm.setFlow(null);
                  } else {
                    _vm.setFlow(FlowIntensity.values[i - 1]);
                  }
                },
              ),
              const SizedBox(height: 16),
              _DiscreteSymptomSlider(
                title: l10n.symptomSectionPain,
                value: _sliderIndexFromNullableEnum(_vm.painScore?.index),
                stepCount: PainScore.values.length,
                displayLabel: _vm.painScore != null
                    ? LoggingLocalizations.painLabel(l10n, _vm.painScore!)
                    : l10n.symptomNotSet,
                onChanged: (v) {
                  final i = v.round();
                  if (i == 0) {
                    _vm.setPain(null);
                  } else {
                    _vm.setPain(PainScore.values[i - 1]);
                  }
                },
              ),
              const SizedBox(height: 16),
              _DiscreteSymptomSlider(
                title: l10n.symptomSectionMood,
                value: _moodSliderIndexFromMood(_vm.mood),
                stepCount: Mood.values.length,
                displayLabel: _moodSliderLabel(l10n, _vm.mood),
                onChanged: (v) {
                  _vm.setMood(_moodFromSliderTick(v.round()));
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.symptomNotesLabel,
                  helperText: l10n.symptomNotesHelper,
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _personalNotesController,
                decoration: InputDecoration(
                  labelText: l10n.symptomPersonalNotesLabel,
                  helperText: l10n.symptomPersonalNotesHelper,
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
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
                child: Text(l10n.commonSave),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
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
                      child: Text(l10n.symptomClearSymptoms),
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
}) async {
  final diaryRepository = DiaryRepository(database: repository.database);
  final dayUtc = DateTime.utc(day.year, day.month, day.day);
  final diaryRow = await diaryRepository.getEntryForDate(dayUtc);
  final initialPersonalNotes = diaryRow?.data.notes ?? '';
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
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
          diaryRepository: diaryRepository,
          initialPersonalNotes: initialPersonalNotes,
          day: day,
          periodId: periodId,
          existing: existing,
        ),
      );
    },
  );
}

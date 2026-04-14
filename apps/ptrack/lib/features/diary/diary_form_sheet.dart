import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import 'package:luma/l10n/app_localizations.dart';
import 'package:luma/l10n/logging_localizations.dart';

DateTime _localCalendarDate(DateTime utcMidnight) {
  return DateTime(utcMidnight.year, utcMidnight.month, utcMidnight.day);
}

/// Discrete [Slider]: one stop for "not set", then one per enum value.
class _DiscreteDiarySlider extends StatelessWidget {
  const _DiscreteDiarySlider({
    required this.title,
    required this.value,
    required this.stepCount,
    required this.displayLabel,
    required this.onChanged,
  });

  final String title;
  final double value;
  final int stepCount;
  final String displayLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = stepCount.toDouble();
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

double _sliderIndexFromNullableMood(Mood? mood) {
  if (mood == null) return 0;
  return (mood.index + 1).toDouble();
}

Mood? _moodFromSliderTick(int tick) {
  if (tick == 0) return null;
  return Mood.values[tick - 1];
}

String _moodSliderLabel(AppLocalizations l10n, Mood? mood) {
  if (mood == null) return l10n.symptomNotSet;
  return '${mood.emoji} ${LoggingLocalizations.moodLabel(l10n, mood)}';
}

/// Modal bottom sheet for creating or editing a diary entry (notes, mood, tags).
class DiaryFormSheet extends StatefulWidget {
  const DiaryFormSheet({
    super.key,
    required this.diaryRepository,
    required this.day,
    this.existing,
  });

  final DiaryRepository diaryRepository;
  final DateTime day;
  final StoredDiaryEntry? existing;

  @override
  State<DiaryFormSheet> createState() => _DiaryFormSheetState();
}

class _DiaryFormSheetState extends State<DiaryFormSheet> {
  late final TextEditingController _notesController;
  late final TextEditingController _addTagController;
  Mood? _mood;
  List<DiaryTag> _allTags = [];
  final Set<int> _selectedTagIds = {};
  StreamSubscription<List<DiaryTag>>? _tagsSub;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _notesController = TextEditingController(text: existing?.data.notes ?? '');
    _addTagController = TextEditingController();
    if (existing != null) {
      _mood = existing.data.mood;
      _selectedTagIds.addAll(existing.tags.map((t) => t.id));
    }
    _tagsSub = widget.diaryRepository.watchTags().listen((tags) {
      if (mounted) setState(() => _allTags = tags);
    });
  }

  @override
  void dispose() {
    _tagsSub?.cancel();
    _notesController.dispose();
    _addTagController.dispose();
    super.dispose();
  }

  Future<void> _submitNewTag(String raw) async {
    for (final part in raw.split(',')) {
      final value = part.trim();
      if (value.isEmpty) continue;
      try {
        final id = await widget.diaryRepository.createTag(value);
        if (!mounted) return;
        setState(() {
          _selectedTagIds.add(id);
          _addTagController.clear();
        });
      } on ArgumentError catch (_) {
        if (!mounted) return;
        final lower = value.toLowerCase();
        DiaryTag? match;
        for (final t in _allTags) {
          if (t.name.toLowerCase() == lower) {
            match = t;
            break;
          }
        }
        if (match != null) {
          setState(() {
            _selectedTagIds.add(match!.id);
            _addTagController.clear();
          });
        }
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = DiaryEntryData(
        dateUtc: widget.day,
        mood: _mood,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      await widget.diaryRepository.saveEntry(
        data,
        tagIds: _selectedTagIds.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final l10n = AppLocalizations.of(context);
    final loc = MaterialLocalizations.of(context);
    final dateLabel =
        loc.formatFullDate(_localCalendarDate(widget.day));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.diaryDeleteEntryTitle),
        content: Text(l10n.diaryDeleteEntryBody(dateLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.diaryRepository.deleteEntry(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loc = MaterialLocalizations.of(context);
    final dateTitle =
        loc.formatFullDate(_localCalendarDate(widget.day));
    final isEdit = widget.existing != null;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEdit ? l10n.diaryFormTitleEdit : l10n.diaryFormTitleNew,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            dateTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.diaryNotesLabel,
              border: const OutlineInputBorder(),
            ),
            maxLines: null,
            minLines: 3,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 16),
          _DiscreteDiarySlider(
            title: l10n.diaryMoodLabel,
            value: _sliderIndexFromNullableMood(_mood),
            stepCount: Mood.values.length,
            displayLabel: _moodSliderLabel(l10n, _mood),
            onChanged: (v) {
              setState(() => _mood = _moodFromSliderTick(v.round()));
            },
          ),
          const SizedBox(height: 16),
          Text(
            l10n.diaryTagsLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _allTags)
                FilterChip(
                  label: Text(tag.name),
                  selected: _selectedTagIds.contains(tag.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTagIds.add(tag.id);
                      } else {
                        _selectedTagIds.remove(tag.id);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addTagController,
            decoration: InputDecoration(
              labelText: l10n.diaryAddTagLabel,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _submitNewTag(_addTagController.text),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: _submitNewTag,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.commonSave),
          ),
          if (isEdit) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _saving ? null : _confirmDelete,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.commonDelete),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens [DiaryFormSheet] as a modal bottom sheet.
Future<void> showDiaryFormSheet(
  BuildContext context, {
  required DiaryRepository diaryRepository,
  required DateTime day,
  StoredDiaryEntry? existing,
}) {
  final dayUtc = DateTime.utc(day.year, day.month, day.day);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => DiaryFormSheet(
      diaryRepository: diaryRepository,
      day: dayUtc,
      existing: existing,
    ),
  );
}

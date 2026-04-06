import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

/// Summary of today's period day + symptoms, with one primary action.
class TodayCard extends StatelessWidget {
  const TodayCard({
    super.key,
    required this.isTodayMarked,
    required this.todayEntry,
    required this.onTodayAction,
  });

  final bool isTodayMarked;
  final DayEntryData? todayEntry;
  final VoidCallback onTodayAction;

  static String _notesPreview(String notes) {
    if (notes.length <= 50) return notes;
    return '${notes.substring(0, 50)}…';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entry = todayEntry;

    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: !isTodayMarked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have not marked today as a period day.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: onTodayAction,
                    child: const Text('I had my period today'),
                  ),
                ],
              )
            : entry == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Today',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: onTodayAction,
                        child: const Text('Add symptoms for today'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's log",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (entry.flowIntensity != null)
                        Text('Flow: ${entry.flowIntensity!.label}'),
                      if (entry.painScore != null)
                        Text('Pain: ${entry.painScore!.label}'),
                      if (entry.mood != null) Text('Mood: ${entry.mood!.emoji}'),
                      if (entry.notes != null && entry.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _notesPreview(entry.notes!),
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: onTodayAction,
                        child: const Text("Edit today's log"),
                      ),
                    ],
                  ),
      ),
    );
  }
}

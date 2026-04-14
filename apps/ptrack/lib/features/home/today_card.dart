import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/logging_localizations.dart';
import '../diary/diary_form_sheet.dart';

/// Summary of today's period day + symptoms, with one primary action.
class TodayCard extends StatelessWidget {
  const TodayCard({
    super.key,
    required this.isTodayMarked,
    required this.todayEntry,
    required this.onTodayAction,
    required this.diaryRepository,
    this.todayDiaryEntry,
  });

  final bool isTodayMarked;
  final DayEntryData? todayEntry;
  final VoidCallback onTodayAction;
  final DiaryRepository diaryRepository;
  final StoredDiaryEntry? todayDiaryEntry;

  static String _notesPreview(String notes) {
    if (notes.length <= 50) return notes;
    return '${notes.substring(0, 50)}…';
  }

  DateTime _utcCalendarDayNow() {
    final n = DateTime.now();
    final u = n.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final entry = todayEntry;

    final diaryNotes = todayDiaryEntry?.data.notes;
    final diaryShortcut = ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.book_outlined),
      title: Text(
        todayDiaryEntry != null
            ? l10n.homeDiaryEditEntry
            : l10n.homeDiaryNewEntry,
      ),
      subtitle: diaryNotes != null && diaryNotes.isNotEmpty
          ? Text(
              diaryNotes,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDiaryFormSheet(
        context,
        diaryRepository: diaryRepository,
        day: _utcCalendarDayNow(),
        existing: todayDiaryEntry,
      ),
    );

    final Widget periodSection;
    if (!isTodayMarked) {
      periodSection = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.todaySectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.todayUnmarkedBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onTodayAction,
            child: Text(l10n.todayMarkPeriodCta),
          ),
        ],
      );
    } else if (entry == null) {
      periodSection = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.todaySectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onTodayAction,
            child: Text(l10n.todayAddSymptomsCta),
          ),
        ],
      );
    } else {
      periodSection = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todayLogTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (entry.flowIntensity != null)
            Text(
              l10n.todayFlowLine(
                LoggingLocalizations.flowLabel(
                  l10n,
                  entry.flowIntensity!,
                ),
              ),
            ),
          if (entry.painScore != null)
            Text(
              l10n.todayPainLine(
                LoggingLocalizations.painLabel(
                  l10n,
                  entry.painScore!,
                ),
              ),
            ),
          if (entry.mood != null)
            Text(
              l10n.todayMoodLine(
                entry.mood!.emoji,
                LoggingLocalizations.moodLabel(l10n, entry.mood!),
              ),
            ),
          if (entry.notes != null && entry.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _notesPreview(entry.notes!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onTodayAction,
            child: Text(l10n.todayEditLogCta),
          ),
        ],
      );
    }

    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            periodSection,
            const Divider(height: 24),
            diaryShortcut,
          ],
        ),
      ),
    );
  }
}

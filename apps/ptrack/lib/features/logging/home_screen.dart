import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../settings/about_screen.dart';
import '../settings/mood_settings.dart';
import 'logging_bottom_sheet.dart';

/// Home logging surface: reverse-chronological periods with expandable day rows.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.database,
    required this.calendar,
  });

  final PeriodRepository repository;
  // Reserved for plan 03 bottom sheet / direct DB access; kept for wiring from main.
  // ignore: unused_field
  final PtrackDatabase database;
  final PeriodCalendarContext calendar;

  void _openSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settings'),
        content: const SingleChildScrollView(
          child: MoodSettingsTile(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ptrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _openSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<StoredPeriodWithDays>>(
        stream: repository.watchPeriodsWithDays(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load periods: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return const _EmptyPeriodsBody();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _PeriodExpansionTile(
                  item: item,
                  repository: repository,
                  calendar: calendar,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Log period',
        onPressed: () {
          showLoggingBottomSheet(
            context,
            repository: repository,
            calendar: calendar,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyPeriodsBody extends StatelessWidget {
  const _EmptyPeriodsBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No periods logged yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to log your first period',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _PeriodExpansionTile extends StatelessWidget {
  const _PeriodExpansionTile({
    required this.item,
    required this.repository,
    required this.calendar,
  });

  final StoredPeriodWithDays item;
  final PeriodRepository repository;
  final PeriodCalendarContext calendar;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final span = item.period.span;
    final title = _periodRangeTitle(loc, span);
    final subtitleText = span.isOpen
        ? 'ongoing'
        : '${_inclusiveUtcDaySpan(span)} days';

    return ExpansionTile(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(title)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit_period') {
                await showLoggingBottomSheet(
                  context,
                  repository: repository,
                  calendar: calendar,
                  existingPeriod: item.period,
                );
              } else if (value == 'log_day') {
                final s = item.period.span.startUtc;
                await showLoggingBottomSheet(
                  context,
                  repository: repository,
                  calendar: calendar,
                  existingPeriod: item.period,
                  addDayEntryForPeriod: true,
                  initialDate: DateTime(s.year, s.month, s.day),
                );
              } else if (value == 'delete_period') {
                await _confirmDeletePeriod(context, repository, item.period);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'log_day',
                child: Text('Log day in period'),
              ),
              PopupMenuItem(
                value: 'edit_period',
                child: Text('Edit period dates'),
              ),
              PopupMenuItem(
                value: 'delete_period',
                child: Text('Delete period'),
              ),
            ],
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitleText),
          if (span.isOpen)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Chip(
                label: const Text('ongoing'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      children: item.dayEntries.isEmpty
          ? [
              ListTile(
                title: const Text('No daily details logged'),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () {
                  final s = item.period.span.startUtc;
                  showLoggingBottomSheet(
                    context,
                    repository: repository,
                    calendar: calendar,
                    existingPeriod: item.period,
                    addDayEntryForPeriod: true,
                    initialDate: DateTime(s.year, s.month, s.day),
                  );
                },
              ),
            ]
          : [
              for (final day in item.dayEntries)
                ListTile(
                  key: ValueKey<int>(day.id),
                  title: Text(
                    loc.formatMediumDate(day.data.dateUtc.toLocal()),
                  ),
                  subtitle: Text(_dayEntrySummary(day.data)),
                  isThreeLine: true,
                  onTap: () {
                    showLoggingBottomSheet(
                      context,
                      repository: repository,
                      calendar: calendar,
                      existingPeriod: item.period,
                      existingDayEntry: day,
                    );
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete day entry',
                    onPressed: () => _confirmDeleteDayEntry(
                      context,
                      repository,
                      day,
                      loc,
                    ),
                  ),
                ),
            ],
    );
  }
}

Future<void> _confirmDeleteDayEntry(
  BuildContext context,
  PeriodRepository repository,
  StoredDayEntry dayEntry,
  MaterialLocalizations loc,
) async {
  final dateLabel = loc.formatMediumDate(dayEntry.data.dateUtc.toLocal());
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete day entry?'),
      content: Text('This will remove the logged details for $dateLabel.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await repository.deleteDayEntry(dayEntry.id);
  }
}

Future<void> _confirmDeletePeriod(
  BuildContext context,
  PeriodRepository repository,
  StoredPeriod period,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete period?'),
      content: const Text(
        'This will permanently delete this period and all its daily entries.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await repository.deletePeriod(period.id);
  }
}

String _periodRangeTitle(MaterialLocalizations loc, PeriodSpan span) {
  String fmt(DateTime utc) => loc.formatMediumDate(utc.toLocal());
  final start = span.startUtc;
  final end = span.endUtc;
  if (end == null) {
    return '${fmt(start)} – ongoing';
  }
  return '${fmt(start)} – ${fmt(end)}';
}

int _inclusiveUtcDaySpan(PeriodSpan span) {
  final end = span.endUtc!;
  final s = DateTime.utc(
    span.startUtc.year,
    span.startUtc.month,
    span.startUtc.day,
  );
  final e = DateTime.utc(end.year, end.month, end.day);
  return e.difference(s).inDays + 1;
}

String _dayEntrySummary(DayEntryData data) {
  final parts = <String>[];
  if (data.flowIntensity != null) {
    parts.add(data.flowIntensity!.label);
  }
  if (data.painScore != null) {
    parts.add(data.painScore!.label);
  }
  if (data.mood != null) {
    parts.add(data.mood!.emoji);
  }
  final notes = data.notes;
  if (notes != null && notes.isNotEmpty) {
    final preview =
        notes.length > 30 ? '${notes.substring(0, 30)}…' : notes;
    parts.add(preview);
  }
  return parts.isEmpty ? '—' : parts.join(' · ');
}

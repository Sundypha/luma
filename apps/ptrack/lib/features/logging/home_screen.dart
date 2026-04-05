import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../settings/about_screen.dart';

/// Home logging surface: reverse-chronological periods with expandable day rows.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.database,
  });

  final PeriodRepository repository;
  // Reserved for plan 03 bottom sheet / direct DB access; kept for wiring from main.
  // ignore: unused_field
  final PtrackDatabase database;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ptrack'),
        actions: [
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
                child: _PeriodExpansionTile(item: item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Log period',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming in next plan')),
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
  const _PeriodExpansionTile({required this.item});

  final StoredPeriodWithDays item;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final span = item.period.span;
    final title = _periodRangeTitle(loc, span);
    final subtitle = span.isOpen
        ? 'ongoing'
        : '${_inclusiveUtcDaySpan(span)} days';

    return ExpansionTile(
        title: Text(title),
        subtitle: Text(subtitle),
        children: item.dayEntries.isEmpty
            ? [
                const ListTile(
                  title: Text('No daily details logged'),
                ),
              ]
            : [
                for (final day in item.dayEntries)
                  ListTile(
                    title: Text(
                      loc.formatMediumDate(day.data.dateUtc.toLocal()),
                    ),
                    subtitle: Text(_dayEntrySummary(day.data)),
                    isThreeLine: true,
                  ),
              ],
    );
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

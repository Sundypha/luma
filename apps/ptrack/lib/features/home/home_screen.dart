import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../logging/logging_bottom_sheet.dart';
import 'cycle_position.dart';
import 'today_card.dart';

/// Home tab: cycle position, next-period window, and today's log at a glance.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.database,
    required this.calendar,
  });

  final PeriodRepository repository;
  // ignore: unused_field
  final PtrackDatabase database;
  final PeriodCalendarContext calendar;

  static String _formatNextPeriodRange(
    MaterialLocalizations loc,
    (DateTime, DateTime) range,
  ) {
    final (start, end) = range;
    final a = loc.formatMediumDate(start.toLocal());
    final b = loc.formatMediumDate(end.toLocal());
    return '$a – $b';
  }

  static DayEntryData? _todayEntry(
    List<StoredPeriodWithDays> periods,
    DateTime today,
  ) {
    final t = DateTime.utc(today.year, today.month, today.day);
    for (final p in periods) {
      for (final e in p.dayEntries) {
        final d = e.data.dateUtc;
        final dn = DateTime.utc(d.year, d.month, d.day);
        if (dn == t) {
          return e.data;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);

    return StreamBuilder<List<StoredPeriodWithDays>>(
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

        final data = snapshot.data ?? [];
        final storedPeriods = data.map((p) => p.period).toList();
        final coordinatorResult = PredictionCoordinator().predictNext(
          storedPeriods: storedPeriods,
          calendar: calendar,
        );
        final today = DateTime.now();
        final pos = computeCyclePosition(
          periods: data,
          prediction: coordinatorResult.result,
          today: today,
        );
        final todayEntry = _todayEntry(data, today);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pos.isOnPeriod && pos.periodDayNumber != null) ...[
                  Text(
                    'Period day ${pos.periodDayNumber}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                  ),
                  const SizedBox(height: 12),
                ] else if (pos.dayInCycle > 0) ...[
                  Text(
                    'Cycle day ${pos.dayInCycle}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (pos.nextPeriodRange != null) ...[
                  Text(
                    'Next period expected ${_formatNextPeriodRange(loc, pos.nextPeriodRange!)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                ] else if (pos.insufficientData)
                  Text(
                    'Log a few more periods to see cycle insights',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                const SizedBox(height: 16),
                TodayCard(
                  todayEntry: todayEntry,
                  onLogToday: () => showLoggingBottomSheet(
                    context,
                    repository: repository,
                    calendar: calendar,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

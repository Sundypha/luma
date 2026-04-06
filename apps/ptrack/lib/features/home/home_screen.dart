import 'package:flutter/material.dart';

import '../logging/logging_bottom_sheet.dart';
import 'home_view_model.dart';
import 'today_card.dart';

/// Home tab: cycle position, next-period window, and today's log at a glance.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  static String _formatNextPeriodRange(
    MaterialLocalizations loc,
    (DateTime, DateTime) range,
  ) {
    final (start, end) = range;
    final a = loc.formatMediumDate(start.toLocal());
    final b = loc.formatMediumDate(end.toLocal());
    return '$a – $b';
  }

  Widget _buildBody(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final pos = viewModel.cyclePosition!;

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
              todayEntry: viewModel.todayEntry,
              onLogToday: () => showLoggingBottomSheet(
                context,
                repository: viewModel.repository,
                calendar: viewModel.calendar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!viewModel.hasInitialEvent) {
          return const Center(child: CircularProgressIndicator());
        }
        if (viewModel.loadError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load periods: ${viewModel.loadError}'),
            ),
          );
        }
        return _buildBody(context);
      },
    );
  }
}

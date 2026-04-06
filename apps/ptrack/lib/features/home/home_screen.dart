import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import '../logging/symptom_form_sheet.dart';
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

  Future<void> _handleTodayQuickAction(BuildContext context) async {
    final vm = viewModel;
    final today = DateTime.now();
    final dayUtc = DateTime.utc(today.year, today.month, today.day);

    int? periodId;
    if (!vm.isTodayMarked) {
      final outcome = await vm.markToday();
      if (!context.mounted) return;
      if (outcome is DayMarkFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: ${outcome.reason}')),
        );
        return;
      }
      if (outcome is DayMarkSuccess) {
        periodId = outcome.periodId;
      }
    }
    periodId ??= vm.todayPeriodId;
    if (periodId == null) {
      await Future<void>.delayed(Duration.zero);
      periodId = vm.todayPeriodId;
    }
    if (!context.mounted) return;
    if (periodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open symptom form.')),
      );
      return;
    }
    await showSymptomFormSheet(
      context,
      repository: vm.repository,
      day: dayUtc,
      periodId: periodId,
      existing: vm.todayStoredEntry,
    );
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
              isTodayMarked: viewModel.isTodayMarked,
              todayEntry: viewModel.todayEntry,
              onTodayAction: () => unawaited(_handleTodayQuickAction(context)),
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

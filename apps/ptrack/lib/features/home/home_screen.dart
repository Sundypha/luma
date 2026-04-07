import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          const SnackBar(
            content: Text('Could not save today. Please try again.'),
          ),
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
            if (viewModel.ensembleExplanationText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showPredictionExplanation(context),
                  child: Text(
                    'How is this calculated?',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TodayCard(
              isTodayMarked: viewModel.isTodayMarked,
              todayEntry: viewModel.todayEntry,
              onTodayAction: () => unawaited(_handleTodayQuickAction(context)),
            ),
            if (viewModel.milestoneMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _MilestoneNotice(
                  message: viewModel.milestoneMessage!,
                  dismissKeyCount: viewModel.activeAlgorithmCount,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPredictionExplanation(BuildContext context) {
    final vm = viewModel;
    final n = vm.activeAlgorithmCount;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: 24 + MediaQuery.viewPaddingOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How your prediction works',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                if (n > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Currently using $n prediction methods.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  vm.ensembleExplanationText,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
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

class _MilestoneNotice extends StatefulWidget {
  const _MilestoneNotice({
    required this.message,
    required this.dismissKeyCount,
  });

  final String message;
  final int dismissKeyCount;

  @override
  State<_MilestoneNotice> createState() => _MilestoneNoticeState();
}

class _MilestoneNoticeState extends State<_MilestoneNotice> {
  static String _prefsKey(int n) => 'milestone_dismissed_$n';

  bool _loading = true;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _dismissed = p.getBool(_prefsKey(widget.dismissKeyCount)) ?? false;
        _loading = false;
      });
    });
  }

  Future<void> _onDismiss() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefsKey(widget.dismissKeyCount), true);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _dismissed) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, color: scheme.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: _onDismiss,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}

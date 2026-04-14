import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/prediction_localizations.dart';
import '../logging/symptom_form_sheet.dart';
import 'home_view_model.dart';
import 'today_card.dart';

/// Home tab: cycle position, next-period window, and today's log at a glance.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.viewModel,
    this.onOpenSettings,
  });

  final HomeViewModel viewModel;

  /// Opens app settings (e.g. from fertility suggestion card).
  final VoidCallback? onOpenSettings;

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
          SnackBar(
            content: Text(AppLocalizations.of(context).homeCouldNotSaveToday),
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
        SnackBar(
          content: Text(AppLocalizations.of(context).homeCouldNotOpenSymptomForm),
        ),
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
    final l10n = AppLocalizations.of(context);
    final pos = viewModel.cyclePosition!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pos.isOnPeriod && pos.periodDayNumber != null) ...[
              Text(
                l10n.homePeriodDay(pos.periodDayNumber!),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(height: 12),
            ] else if (pos.dayInCycle > 0) ...[
              Text(
                l10n.homeCycleDay(pos.dayInCycle),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            if (pos.nextPeriodRange != null) ...[
              Text(
                l10n.homeNextPeriodExpected(
                  _formatNextPeriodRange(loc, pos.nextPeriodRange!),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
            ] else if (pos.insufficientData)
              Text(
                l10n.homeLogMorePeriods,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            if (viewModel.ensembleResult != null) ...[
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
                    l10n.homeHowCalculatedLink,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (viewModel.showSuggestionCard)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _FertilitySuggestionCard(
                  hasEnoughData: viewModel.hasEnoughDataForFertility,
                  onOpenSettings: onOpenSettings,
                  onDismiss: () => unawaited(viewModel.dismissSuggestionCard()),
                ),
              ),
            TodayCard(
              isTodayMarked: viewModel.isTodayMarked,
              todayEntry: viewModel.todayEntry,
              onTodayAction: () => unawaited(_handleTodayQuickAction(context)),
              diaryRepository: viewModel.diaryRepository,
              todayDiaryEntry: viewModel.todayDiaryEntry,
            ),
            if (viewModel.ensembleMilestone != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _MilestoneNotice(
                  message: PredictionLocalizations.formatEnsembleMilestone(
                    l10n,
                    viewModel.ensembleMilestone!,
                  ),
                  dismissKeyCount: viewModel.activeAlgorithmCount,
                ),
              ),
            if (viewModel.fertilityEnabled && viewModel.fertileWindow != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _FertilityWindowHomeCard(
                  window: viewModel.fertileWindow!,
                  explanationDays: viewModel.computedAverageCycleLength,
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
    final ensemble = vm.ensembleResult;
    final l10nRoot = AppLocalizations.of(context);
    final body = ensemble != null
        ? PredictionLocalizations.formatEnsembleExplanation(l10nRoot, ensemble)
        : '';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
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
                  l10n.homePredictionSheetTitle,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                if (n > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.homePredictionMethodsLine(n),
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  body,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.homeDone),
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
          final l10n = AppLocalizations.of(context);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.homeCouldNotLoadPeriods('${viewModel.loadError}'),
              ),
            ),
          );
        }
        return _buildBody(context);
      },
    );
  }
}

const Color _kFertilityTeal = Color(0xFF26A69A);

class _FertilityWindowHomeCard extends StatelessWidget {
  const _FertilityWindowHomeCard({
    required this.window,
    this.explanationDays,
  });

  final FertileWindow window;
  final int? explanationDays;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context);
    final start = loc.formatMediumDate(window.startUtc.toLocal());
    final end = loc.formatMediumDate(window.endUtc.toLocal());

    return Card(
      margin: EdgeInsets.zero,
      color: _kFertilityTeal.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.spa, color: _kFertilityTeal, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.fertilityHomeCardTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.fertilityHomeCardRange(start, end),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (explanationDays != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.fertilityHomeCardExplanation(explanationDays!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.fertilityHomeCardFooter,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FertilitySuggestionCard extends StatelessWidget {
  const _FertilitySuggestionCard({
    required this.hasEnoughData,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final bool hasEnoughData;
  final VoidCallback? onOpenSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: hasEnoughData ? 1.0 : 0.6,
      child: Card(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.spa_outlined, color: scheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.fertilitySuggestionTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasEnoughData
                              ? l10n.fertilitySuggestionBody
                              : l10n.fertilitySuggestionNotEnoughData,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: onDismiss,
                    tooltip: l10n.tooltipDismiss,
                  ),
                ],
              ),
              if (hasEnoughData && onOpenSettings != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onOpenSettings,
                    child: Text(l10n.fertilitySuggestionEnable),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
              tooltip: AppLocalizations.of(context).tooltipDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

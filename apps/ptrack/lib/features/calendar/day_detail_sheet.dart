import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/logging_localizations.dart';
import '../../l10n/prediction_localizations.dart';
import '../logging/symptom_form_sheet.dart';
import 'calendar_day_data.dart';
import 'calendar_view_model.dart';

/// Opens the day-detail bottom sheet for any calendar day (live [viewModel] data).
Future<void> showDayDetailSheet(
  BuildContext context, {
  required DateTime selectedDay,
  required CalendarViewModel viewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) {
      return DayDetailSheet(
        selectedDay: selectedDay,
        viewModel: viewModel,
      );
    },
  );
}

DateTime _utcMidnight(DateTime d) {
  final x = d.isUtc ? d : d.toUtc();
  return DateTime.utc(x.year, x.month, x.day);
}

DateTime _localCalendarDate(DateTime utcMidnight) {
  return DateTime(utcMidnight.year, utcMidnight.month, utcMidnight.day);
}

/// Last match wins if overlaps — same as [buildCalendarDayDataMap].
StoredPeriodWithDays? _periodCoveringDay(
  DateTime dayNorm,
  List<StoredPeriodWithDays> allData,
) {
  final now = DateTime.now();
  StoredPeriodWithDays? match;
  for (final pwd in allData) {
    if (pwd.period.span.containsCalendarDayUtc(dayNorm, todayLocal: now)) {
      match = pwd;
    }
  }
  return match;
}

StoredDayEntry? _entryForDay(DateTime dayNorm, StoredPeriodWithDays pwd) {
  for (final e in pwd.dayEntries) {
    if (_utcMidnight(e.data.dateUtc) == dayNorm) {
      return e;
    }
  }
  return null;
}

bool _algorithmCoversUtcDay(AlgorithmPrediction o, DateTime dayNormUtc) {
  for (var i = 0; i < o.predictedDurationDays; i++) {
    final d = utcCalendarDateOnly(
      addUtcCalendarDays(o.predictedStartUtc, i),
    );
    if (d == dayNormUtc) return true;
  }
  return false;
}

int? _periodDayNumber(
  StoredPeriod period,
  DateTime dayNorm,
  DateTime todayNorm,
) {
  final span = period.span;
  final startNorm = _utcMidnight(span.startUtc);
  final endNorm = span.endUtc != null ? _utcMidnight(span.endUtc!) : todayNorm;
  if (dayNorm.isBefore(startNorm) || dayNorm.isAfter(endNorm)) return null;
  return dayNorm.difference(startNorm).inDays + 1;
}

Future<void> _openSymptomFormAfterPop({
  required BuildContext sheetContext,
  required CalendarViewModel viewModel,
  required DateTime dayNorm,
  required int periodId,
  StoredDayEntry? existing,
}) async {
  final nav = Navigator.of(sheetContext);
  final overlay = nav.overlay;
  nav.pop();
  if (overlay == null) return;
  final repo = viewModel.repository;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!overlay.context.mounted) return;
    showSymptomFormSheet(
      overlay.context,
      repository: repo,
      day: dayNorm,
      periodId: periodId,
      existing: existing,
    );
  });
}

/// One day at a time; actions depend on prediction, period band, symptoms, and future/past.
class DayDetailSheet extends StatelessWidget {
  const DayDetailSheet({
    super.key,
    required this.selectedDay,
    required this.viewModel,
  });

  final DateTime selectedDay;
  final CalendarViewModel viewModel;

  Widget _chipRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(value),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionCard(
    BuildContext context, {
    required CalendarDayData dayData,
    required EnsemblePredictionResult? ensemble,
    required DateTime dayNormUtc,
  }) {
    return _PredictedDayInfoCard(
      dayData: dayData,
      ensemble: ensemble,
      dayNormUtc: dayNormUtc,
      cycleSpreadDays: ensemble?.cycleSpreadDays ?? 0,
    );
  }

  Future<void> _markDayAndPop(
    BuildContext context,
    DateTime dayNorm,
    AppLocalizations l10n,
  ) async {
    final outcome = await viewModel.repository.markDay(dayNorm);
    if (!context.mounted) return;
    switch (outcome) {
      case DayMarkSuccess():
        Navigator.of(context).pop();
      case DayMarkFailure():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dayDetailMarkFailed)),
        );
    }
  }

  Future<void> _confirmDeleteEntirePeriod(
    BuildContext context,
    MaterialLocalizations loc,
    AppLocalizations l10n,
    StoredPeriod period,
  ) async {
    String localDay(DateTime utc) =>
        loc.formatMediumDate(DateTime(utc.year, utc.month, utc.day));
    final startLabel = localDay(period.span.startUtc);
    final endLabel = period.span.isOpen
        ? l10n.dayDetailPeriodOngoing
        : localDay(period.span.endUtc!);
    final body = period.span.isOpen
        ? l10n.dayDetailDeletePeriodOngoingBody(startLabel)
        : l10n.dayDetailDeletePeriodClosedBody(startLabel, endLabel);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dayDetailDeletePeriodTitle),
        content: Text(body),
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
    if (confirmed != true || !context.mounted) return;
    final ok = await viewModel.repository.deletePeriod(period.id);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dayDetailDeletePeriodFailed)),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _removeThisDay(
    BuildContext context,
    DateTime dayNorm,
    StoredDayEntry? entry,
    AppLocalizations l10n,
  ) async {
    if (entry != null) {
      final loc = MaterialLocalizations.of(context);
      final dateLabel =
          loc.formatMediumDate(_localCalendarDate(_utcMidnight(entry.data.dateUtc)));
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.dayDetailRemoveDayTitle),
          content: Text(l10n.dayDetailRemoveDayBody(dateLabel)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonRemove),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    final outcome = await viewModel.repository.unmarkDay(dayNorm);
    if (!context.mounted) return;
    switch (outcome) {
      case DayMarkSuccess():
        Navigator.of(context).pop();
      case DayMarkFailure():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dayDetailRemoveDayFailed)),
        );
    }
  }

  Future<void> _clearSymptoms(
    BuildContext context,
    int dayEntryId,
    AppLocalizations l10n,
  ) async {
    final ok = await viewModel.repository.deleteDayEntry(dayEntryId);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.dayDetailClearSymptomsFailed)),
      );
    }
  }

  Widget _buildPredictedFuture(
    BuildContext context,
    MaterialLocalizations loc,
    AppLocalizations l10n,
    DateTime dayNorm,
    CalendarDayData dayData,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.formatFullDate(_localCalendarDate(dayNorm)),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _predictionCard(
            context,
            dayData: dayData,
            ensemble: viewModel.ensembleResult,
            dayNormUtc: dayNorm,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.dayDetailLogWhenArrives,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictedPastOrToday(
    BuildContext context,
    MaterialLocalizations loc,
    AppLocalizations l10n,
    DateTime dayNorm,
    CalendarDayData dayData,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.formatFullDate(_localCalendarDate(dayNorm)),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _predictionCard(
            context,
            dayData: dayData,
            ensemble: viewModel.ensembleResult,
            dayNormUtc: dayNorm,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _markDayAndPop(context, dayNorm, l10n),
            child: Text(l10n.dayDetailHadPeriod),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFuture(
    BuildContext context,
    MaterialLocalizations loc,
    AppLocalizations l10n,
    DateTime dayNorm,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.formatFullDate(_localCalendarDate(dayNorm)),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.dayDetailFuturePlaceholder,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPastOrToday(
    BuildContext context,
    MaterialLocalizations loc,
    AppLocalizations l10n,
    DateTime dayNorm,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.formatFullDate(_localCalendarDate(dayNorm)),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _markDayAndPop(context, dayNorm, l10n),
            child: Text(l10n.dayDetailHadPeriod),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodNoSymptoms(
    BuildContext context,
    MaterialLocalizations loc,
    AppLocalizations l10n,
    DateTime dayNorm,
    StoredPeriodWithDays pwd,
    StoredDayEntry? entry,
  ) {
    final todayNorm = _utcMidnight(DateTime.now());
    final periodDay = _periodDayNumber(pwd.period, dayNorm, todayNorm);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.formatFullDate(_localCalendarDate(dayNorm)),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (periodDay != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.homePeriodDay(periodDay),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.dayDetailNoSymptoms,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _openSymptomFormAfterPop(
              sheetContext: context,
              viewModel: viewModel,
              dayNorm: dayNorm,
              periodId: pwd.period.id,
            ),
            child: Text(l10n.dayDetailAddSymptoms),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _removeThisDay(context, dayNorm, entry, l10n),
            child: Text(l10n.dayDetailRemoveThisDay),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () =>
                _confirmDeleteEntirePeriod(context, loc, l10n, pwd.period),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.dayDetailDeleteEntirePeriod),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodWithSymptoms(
    BuildContext context,
    MaterialLocalizations loc,
    AppLocalizations l10n,
    DateTime dayNorm,
    StoredPeriodWithDays pwd,
    StoredDayEntry entry,
  ) {
    final todayNorm = _utcMidnight(DateTime.now());
    final periodDay = _periodDayNumber(pwd.period, dayNorm, todayNorm);
    final data = entry.data;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.formatFullDate(_localCalendarDate(dayNorm)),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (periodDay != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.homePeriodDay(periodDay),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          _chipRow(
            context,
            l10n.symptomSectionFlow,
            data.flowIntensity != null
                ? LoggingLocalizations.flowLabel(l10n, data.flowIntensity!)
                : l10n.commonNotAvailable,
          ),
          _chipRow(
            context,
            l10n.symptomSectionPain,
            data.painScore != null
                ? LoggingLocalizations.painLabel(l10n, data.painScore!)
                : l10n.commonNotAvailable,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    l10n.symptomSectionMood,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    data.mood != null
                        ? '${data.mood!.emoji} ${LoggingLocalizations.moodLabel(l10n, data.mood!)}'
                        : l10n.commonNotAvailable,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          Text(
            l10n.symptomNotesLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            (data.notes != null && data.notes!.isNotEmpty)
                ? data.notes!
                : l10n.commonNotAvailable,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _openSymptomFormAfterPop(
              sheetContext: context,
              viewModel: viewModel,
              dayNorm: dayNorm,
              periodId: pwd.period.id,
              existing: entry,
            ),
            child: Text(l10n.dayDetailEdit),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _clearSymptoms(context, entry.id, l10n),
            child: Text(l10n.dayDetailClearSymptoms),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _removeThisDay(context, dayNorm, entry, l10n),
            child: Text(l10n.dayDetailRemoveThisDay),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () =>
                _confirmDeleteEntirePeriod(context, loc, l10n, pwd.period),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.dayDetailDeleteEntirePeriod),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context);
    final dayNorm = _utcMidnight(selectedDay);
    final todayNorm = _utcMidnight(DateTime.now());
    final isFuture = dayNorm.isAfter(todayNorm);
    final dayData = viewModel.dayDataMap[dayNorm] ?? const CalendarDayData();
    final isPredicted = dayData.isPredictedPeriod;
    final isOnPeriod = dayData.loggedPeriodState != PeriodDayState.none;
    final hasLoggedData = dayData.hasLoggedData;
    final pwd = _periodCoveringDay(dayNorm, viewModel.periodsWithDays);
    final entry = pwd != null ? _entryForDay(dayNorm, pwd) : null;

    if (isPredicted && isFuture) {
      return _buildPredictedFuture(context, loc, l10n, dayNorm, dayData);
    }
    if (isPredicted && !isFuture) {
      return _buildPredictedPastOrToday(context, loc, l10n, dayNorm, dayData);
    }
    if (isOnPeriod && hasLoggedData && entry != null && pwd != null) {
      return _buildPeriodWithSymptoms(context, loc, l10n, dayNorm, pwd, entry);
    }
    if (isOnPeriod && pwd != null) {
      return _buildPeriodNoSymptoms(context, loc, l10n, dayNorm, pwd, entry);
    }
    if (isFuture) {
      return _buildEmptyFuture(context, loc, l10n, dayNorm);
    }
    return _buildEmptyPastOrToday(context, loc, l10n, dayNorm);
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.88;
    return SizedBox(
      height: maxH,
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => _buildBody(context),
      ),
    );
  }
}

class _PredictedDayInfoCard extends StatefulWidget {
  const _PredictedDayInfoCard({
    required this.dayData,
    required this.ensemble,
    required this.dayNormUtc,
    this.cycleSpreadDays = 0,
  });

  final CalendarDayData dayData;
  final EnsemblePredictionResult? ensemble;
  final DateTime dayNormUtc;
  final int cycleSpreadDays;

  @override
  State<_PredictedDayInfoCard> createState() => _PredictedDayInfoCardState();
}

class _PredictedDayInfoCardState extends State<_PredictedDayInfoCard> {
  bool _expanded = false;

  String _titleText(AppLocalizations l10n) {
    final idx = widget.dayData.predictionCycleIndex;
    if (idx == 0) return l10n.dayDetailPeriodExpectedTitle;
    final months = idx + 1;
    return l10n.dayDetailForecastMonthsTitle(months);
  }

  String _cycleDisclaimerText(AppLocalizations l10n) {
    final idx = widget.dayData.predictionCycleIndex;
    final highSpread = widget.cycleSpreadDays >= 8;
    final medSpread = widget.cycleSpreadDays >= 4;

    if (idx == 0) return '';
    if (idx == 1) {
      if (highSpread) {
        return l10n.dayDetailDisclaimerHop1HighSpread;
      }
      return l10n.dayDetailDisclaimerHop1;
    }
    final months = idx + 1;
    if (highSpread || medSpread) {
      return l10n.dayDetailDisclaimerHopNSpread(months);
    }
    return l10n.dayDetailDisclaimerHopN(months);
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final active = widget.ensemble?.activeAlgorithmCount ?? 0;
    final cycleIdx = widget.dayData.predictionCycleIndex;

    // For cycle 0 show agreement; for projected hops show a generic line.
    final l10n = AppLocalizations.of(context);
    final agreementLine = cycleIdx == 0
        ? (active > 0
            ? PredictionLocalizations.formatDayAgreementSummary(
                l10n,
                agreementCount: widget.dayData.predictionAgreementCount,
                activeCount: active,
              )
            : l10n.dayDetailBasedOnRecentCycles)
        : l10n.dayDetailProjectedHop;

    // Only cycle 0 days have direct algorithm output coverage.
    final covering = (widget.ensemble == null || cycleIdx > 0)
        ? const <AlgorithmPrediction>[]
        : widget.ensemble!.algorithmOutputs
            .where((o) => _algorithmCoversUtcDay(o, widget.dayNormUtc))
            .toList();

    final disclaimer = _cycleDisclaimerText(l10n);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleText(l10n),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    agreementLine,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (disclaimer.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      disclaimer,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                          ),
                    ),
                  ],
                  if (covering.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _expanded
                            ? l10n.dayDetailHideDetails
                            : l10n.dayDetailSeeDetails,
                      ),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 8),
                      for (final o in covering)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            l10n.dayDetailAlgoExpectsAround(
                              PredictionLocalizations.algorithmName(
                                l10n,
                                o.algorithmId,
                              ),
                              loc.formatMediumDate(
                                DateTime(
                                  o.predictedStartUtc.year,
                                  o.predictedStartUtc.month,
                                  o.predictedStartUtc.day,
                                ),
                              ),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ],
                  const SizedBox(height: 8),
                  Text(
                    l10n.dayDetailEstimatesOnly,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

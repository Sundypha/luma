import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../l10n/app_localizations.dart';
import 'calendar_day_data.dart';
import 'calendar_painters.dart';
import 'calendar_view_model.dart';
import 'day_detail_sheet.dart';

StartingDayOfWeek _startingDayOfWeekFor(BuildContext context) {
  final materialDow = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  final dartWeekday = materialDow == 0 ? DateTime.sunday : materialDow;
  return StartingDayOfWeek.values[dartWeekday - 1];
}

void _openDayDetail(
  BuildContext context,
  CalendarViewModel viewModel,
  DateTime selectedDay,
) {
  showDayDetailSheet(
    context,
    selectedDay: selectedDay,
    viewModel: viewModel,
  );
}

/// Calendar tab: month grid with logged period bands and predicted hatch marks.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.viewModel,
  });

  final CalendarViewModel viewModel;

  bool get _hasMultiCyclePredictions =>
      viewModel.dayDataMap.values.any((d) => d.predictionCycleIndex > 0);

  Widget? _dayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    final key = DateTime.utc(day.year, day.month, day.day);
    final data = viewModel.dayDataMap[key] ?? const CalendarDayData();
    return buildCalendarDayCell(day, data);
  }

  Widget _buildCalendar(BuildContext context) {
    final theme = Theme.of(context);
    final onVariant = theme.colorScheme.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TableCalendar<void>(
            locale: Localizations.localeOf(context).toString(),
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: viewModel.focusedDay,
            selectedDayPredicate: (day) =>
                viewModel.selectedDay != null &&
                isSameDay(viewModel.selectedDay!, day),
            onDaySelected: (selectedDay, focusedDay) {
              viewModel.selectDay(selectedDay, focusedDay);
              _openDayDetail(context, viewModel, selectedDay);
            },
            onPageChanged: viewModel.changeFocusedMonth,
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              cellMargin: EdgeInsets.zero,
              cellPadding: EdgeInsets.zero,
              isTodayHighlighted: false,
            ),
            calendarBuilders: CalendarBuilders<void>(
              prioritizedBuilder: _dayBuilder,
            ),
            startingDayOfWeek: _startingDayOfWeekFor(context),
          ),
        ),
        if ((viewModel.ensembleResult?.activeAlgorithmCount ?? 0) > 0 ||
            viewModel.fertilityEnabled) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: buildConfidenceLegend(
              context,
              showFertilityLegend: viewModel.fertilityEnabled,
              showPredictionTierLegend:
                  (viewModel.ensembleResult?.activeAlgorithmCount ?? 0) > 0,
            ),
          ),
          if (_hasMultiCyclePredictions &&
              (viewModel.ensembleResult?.activeAlgorithmCount ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l10n.calendarLegendHatching,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
        if (viewModel.showTodayButton)
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.today),
              label: Text(l10n.calendarToday),
              onPressed: viewModel.goToToday,
            ),
          ),
        if (viewModel.showInsufficientPredictionHint)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              l10n.calendarInsufficientPredictionHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: onVariant),
            ),
          ),
      ],
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
              child: Text(
                AppLocalizations.of(context)
                    .homeCouldNotLoadPeriods(viewModel.loadError.toString()),
              ),
            ),
          );
        }
        return _buildCalendar(context);
      },
    );
  }
}

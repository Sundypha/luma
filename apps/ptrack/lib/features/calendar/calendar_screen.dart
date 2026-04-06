import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../logging/logging_bottom_sheet.dart';
import 'calendar_day_data.dart';
import 'calendar_painters.dart';
import 'calendar_view_model.dart';
import 'day_detail_sheet.dart';

void _openDayDetail(
  BuildContext context,
  CalendarViewModel viewModel,
  DateTime selectedDay,
) {
  final dayNorm = DateTime.utc(
    selectedDay.year,
    selectedDay.month,
    selectedDay.day,
  );
  final dayData = viewModel.dayDataMap[dayNorm] ?? const CalendarDayData();

  if (!dayData.hasLoggedData &&
      !dayData.isPredictedPeriod &&
      dayData.loggedPeriodState == PeriodDayState.none) {
    showLoggingBottomSheet(
      context,
      repository: viewModel.repository,
      calendar: viewModel.calendar,
      initialDate: selectedDay,
    );
    return;
  }

  showDayDetailSheet(
    context,
    selectedDay: selectedDay,
    allData: viewModel.periodsWithDays,
    prediction: viewModel.prediction,
    repository: viewModel.repository,
    calendar: viewModel.calendar,
  );
}

/// Calendar tab: month grid with logged period bands and predicted hatch marks.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.viewModel,
  });

  final CalendarViewModel viewModel;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TableCalendar<void>(
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
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
        ),
        if (viewModel.showTodayButton)
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.today),
              label: const Text('Today'),
              onPressed: viewModel.goToToday,
            ),
          ),
        if (viewModel.showInsufficientFutureMessage)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Predictions appear after more data',
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
              child: Text('Could not load periods: ${viewModel.loadError}'),
            ),
          );
        }
        return _buildCalendar(context);
      },
    );
  }
}

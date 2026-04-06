import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:table_calendar/table_calendar.dart';

import '../logging/logging_bottom_sheet.dart';
import 'calendar_day_data.dart';
import 'calendar_painters.dart';

/// Calendar tab: month grid with logged period bands and predicted hatch marks.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.repository,
    required this.database,
    required this.calendar,
  });

  final PeriodRepository repository;
  // ignore: unused_field
  final PtrackDatabase database;
  final PeriodCalendarContext calendar;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, CalendarDayData> _dayDataMap = const {};
  PredictionResult? _cachedPrediction;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  bool get _showTodayButton {
    final now = DateTime.now();
    return _focusedDay.year != now.year || _focusedDay.month != now.month;
  }

  bool get _showInsufficientFutureMessage {
    if (_cachedPrediction is! PredictionInsufficientHistory) return false;
    final now = DateTime.now();
    final focusedMonth = DateTime(_focusedDay.year, _focusedDay.month);
    final thisMonth = DateTime(now.year, now.month);
    return focusedMonth.isAfter(thisMonth);
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = null;
    });
  }

  void _openDayDetail(DateTime selectedDay, List<StoredPeriodWithDays> data) {
    showLoggingBottomSheet(
      context,
      repository: widget.repository,
      calendar: widget.calendar,
      initialDate: selectedDay,
    );
  }

  Widget? _dayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final key = DateTime.utc(day.year, day.month, day.day);
    final data = _dayDataMap[key] ?? const CalendarDayData();
    return buildCalendarDayCell(day, data);
  }

  Widget _buildCalendar(
    BuildContext context,
    List<StoredPeriodWithDays> data,
  ) {
    final theme = Theme.of(context);
    final onVariant = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TableCalendar<void>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(_selectedDay!, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _openDayDetail(selectedDay, data);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders<void>(
              prioritizedBuilder: _dayBuilder,
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
        ),
        if (_showTodayButton)
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.today),
              label: const Text('Today'),
              onPressed: _goToToday,
            ),
          ),
        if (_showInsufficientFutureMessage)
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
    return StreamBuilder<List<StoredPeriodWithDays>>(
      stream: widget.repository.watchPeriodsWithDays(),
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
        final predResult = PredictionCoordinator().predictNext(
          storedPeriods: storedPeriods,
          calendar: widget.calendar,
        );
        _cachedPrediction = predResult.result;
        _dayDataMap = buildCalendarDayDataMap(
          periodsWithDays: data,
          prediction: predResult.result,
          today: DateTime.now(),
          startingDayOfWeek: DateTime.monday,
        );

        return _buildCalendar(context, data);
      },
    );
  }
}

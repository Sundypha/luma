import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../logging/logging_bottom_sheet.dart';

/// Opens the day-detail bottom sheet (read-only, swipe, prediction, edit bridge).
///
/// Callers must route empty non-predicted days to [showLoggingBottomSheet] directly
/// to avoid a one-frame flash.
Future<void> showDayDetailSheet(
  BuildContext context, {
  required DateTime selectedDay,
  required List<StoredPeriodWithDays> allData,
  required PredictionResult prediction,
  required PeriodRepository repository,
  required PeriodCalendarContext calendar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) {
      return DayDetailSheet(
        anchorContext: context,
        selectedDay: selectedDay,
        allData: allData,
        prediction: prediction,
        repository: repository,
        calendar: calendar,
      );
    },
  );
}

DateTime _utcMidnight(DateTime d) {
  final x = d.isUtc ? d : d.toUtc();
  return DateTime.utc(x.year, x.month, x.day);
}

bool _loggedPeriodCoversDay(
  DateTime dayNorm,
  List<StoredPeriodWithDays> periodsWithDays,
  DateTime todayNorm,
) {
  for (final pwd in periodsWithDays) {
    final span = pwd.period.span;
    final startNorm = _utcMidnight(span.startUtc);
    final endNorm =
        span.endUtc != null ? _utcMidnight(span.endUtc!) : todayNorm;
    if (endNorm.isBefore(startNorm)) continue;
    if (!dayNorm.isBefore(startNorm) && !dayNorm.isAfter(endNorm)) {
      return true;
    }
  }
  return false;
}

bool _isPredictedCalendarDay(
  DateTime dayNorm,
  List<StoredPeriodWithDays> periodsWithDays,
  PredictionResult prediction,
  DateTime today,
) {
  final todayNorm = _utcMidnight(today);
  if (_loggedPeriodCoversDay(dayNorm, periodsWithDays, todayNorm)) {
    return false;
  }
  switch (prediction) {
    case PredictionInsufficientHistory():
      return false;
    case PredictionRangeOnly(:final rangeStartUtc, :final rangeEndUtc):
      var d = _utcMidnight(rangeStartUtc);
      final end = _utcMidnight(rangeEndUtc);
      while (!d.isAfter(end)) {
        if (d == dayNorm) return true;
        d = d.add(const Duration(days: 1));
      }
      return false;
    case PredictionPointWithRange(
        :final pointStartUtc,
        :final rangeStartUtc,
        :final rangeEndUtc,
      ):
      if (rangeStartUtc != null && rangeEndUtc != null) {
        var d = _utcMidnight(rangeStartUtc);
        final end = _utcMidnight(rangeEndUtc);
        while (!d.isAfter(end)) {
          if (d == dayNorm) return true;
          d = d.add(const Duration(days: 1));
        }
        return false;
      }
      return _utcMidnight(pointStartUtc) == dayNorm;
  }
}

({StoredPeriodWithDays? pwd, StoredDayEntry? entry}) _lookupDay(
  DateTime dayNorm,
  List<StoredPeriodWithDays> allData,
) {
  for (final pwd in allData) {
    for (final e in pwd.dayEntries) {
      if (_utcMidnight(e.data.dateUtc) == dayNorm) {
        return (pwd: pwd, entry: e);
      }
    }
  }
  return (pwd: null, entry: null);
}

int? _periodDayNumber(StoredPeriod period, DateTime dayNorm, DateTime todayNorm) {
  final span = period.span;
  final startNorm = _utcMidnight(span.startUtc);
  final endNorm = span.endUtc != null ? _utcMidnight(span.endUtc!) : todayNorm;
  if (dayNorm.isBefore(startNorm) || dayNorm.isAfter(endNorm)) return null;
  return dayNorm.difference(startNorm).inDays + 1;
}

DateTime _calendarDateForLogging(DateTime dayNorm) {
  return DateTime(dayNorm.year, dayNorm.month, dayNorm.day);
}

class DayDetailSheet extends StatefulWidget {
  const DayDetailSheet({
    super.key,
    required this.anchorContext,
    required this.selectedDay,
    required this.allData,
    required this.prediction,
    required this.repository,
    required this.calendar,
  });

  final BuildContext anchorContext;
  final DateTime selectedDay;
  final List<StoredPeriodWithDays> allData;
  final PredictionResult prediction;
  final PeriodRepository repository;
  final PeriodCalendarContext calendar;

  @override
  State<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<DayDetailSheet> {
  late PageController _pageController;
  late DateTime _currentDay;

  @override
  void initState() {
    super.initState();
    _currentDay = _utcMidnight(widget.selectedDay);
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index == 1) return;
    final delta = index == 0 ? -1 : 1;
    final newDay = _utcMidnight(
      _currentDay.add(Duration(days: delta)),
    );
    setState(() => _currentDay = newDay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pageController.jumpToPage(1);
      _routeEmptyNonPredictedDay(newDay);
    });
  }

  void _routeEmptyNonPredictedDay(DateTime dayNorm) {
    final lookup = _lookupDay(dayNorm, widget.allData);
    if (lookup.entry != null) return;
    if (_isPredictedCalendarDay(
      dayNorm,
      widget.allData,
      widget.prediction,
      DateTime.now(),
    )) {
      return;
    }
    Navigator.of(context).pop();
    showLoggingBottomSheet(
      widget.anchorContext,
      repository: widget.repository,
      calendar: widget.calendar,
      initialDate: _calendarDateForLogging(dayNorm),
    );
  }

  Future<void> _edit(
    StoredPeriod period,
    StoredDayEntry dayEntry,
  ) async {
    Navigator.of(context).pop();
    await showLoggingBottomSheet(
      widget.anchorContext,
      repository: widget.repository,
      calendar: widget.calendar,
      existingPeriod: period,
      existingDayEntry: dayEntry,
    );
  }

  void _logForDay(DateTime dayNorm) {
    Navigator.of(context).pop();
    showLoggingBottomSheet(
      widget.anchorContext,
      repository: widget.repository,
      calendar: widget.calendar,
      initialDate: _calendarDateForLogging(dayNorm),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext dialogContext,
    MaterialLocalizations loc,
    StoredDayEntry dayEntry,
  ) async {
    final dateLabel = loc.formatMediumDate(
      _calendarDateForLogging(_utcMidnight(dayEntry.data.dateUtc)),
    );
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete day entry?'),
        content: Text(
          'This will remove the logged details for $dateLabel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.repository.deleteDayEntry(dayEntry.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _chipRow(String label, String value) {
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

  Widget _buildLoggedPage(
    MaterialLocalizations loc,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.formatFullDate(_calendarDateForLogging(dayNorm)),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => _confirmAndDelete(context, loc, entry),
                child: const Text('Delete'),
              ),
            ],
          ),
          if (periodDay != null) ...[
            const SizedBox(height: 4),
            Text(
              'Period day $periodDay',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          _chipRow(
            'Flow',
            data.flowIntensity?.label ?? '—',
          ),
          _chipRow(
            'Pain',
            data.painScore?.label ?? '—',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    'Mood',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    data.mood != null
                        ? '${data.mood!.emoji} ${data.mood!.label}'
                        : '—',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Notes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            (data.notes != null && data.notes!.isNotEmpty)
                ? data.notes!
                : '—',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _edit(pwd.period, entry),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictedPage(MaterialLocalizations loc, DateTime dayNorm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.formatFullDate(_calendarDateForLogging(dayNorm)),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period expected around this day',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Based on your recent cycles. Estimates only — not medical advice.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: () => _logForDay(dayNorm),
            child: const Text('Log period start'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPage(DateTime day) {
    final dayNorm = _utcMidnight(day);
    final loc = MaterialLocalizations.of(context);
    final lookup = _lookupDay(dayNorm, widget.allData);

    if (lookup.entry != null && lookup.pwd != null) {
      return _buildLoggedPage(loc, dayNorm, lookup.pwd!, lookup.entry!);
    }

    if (_isPredictedCalendarDay(
      dayNorm,
      widget.allData,
      widget.prediction,
      DateTime.now(),
    )) {
      return _buildPredictedPage(loc, dayNorm);
    }

    // Empty non-predicted: parent swipe handler opens logging; show placeholder.
    return Center(
      child: Text(
        'Opening log…',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.88;
    final prev = _utcMidnight(_currentDay.subtract(const Duration(days: 1)));
    final curr = _utcMidnight(_currentDay);
    final next = _utcMidnight(_currentDay.add(const Duration(days: 1)));

    return SizedBox(
      height: maxH,
      child: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildDayPage(prev),
          _buildDayPage(curr),
          _buildDayPage(next),
        ],
      ),
    );
  }
}

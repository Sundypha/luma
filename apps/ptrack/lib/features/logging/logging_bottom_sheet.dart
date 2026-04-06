import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../settings/mood_settings.dart';

/// Create flow when an open period may exist: start another, log a day on the
/// open period, or set the open period's end date.
enum _SheetCreateIntent {
  startNewPeriod,
  logDayForOpenPeriod,
  endOpenPeriod,
}

bool _isLiveDateErrorText(String? e) =>
    e == 'End date cannot be before start date' ||
    e == 'This date is before the current period started.' ||
    e == 'This date is outside this period\'s range.';

/// Open span that still includes **today** (same calendar-day rule as the grid).
/// If the DB ever has several (invalid), keeps the one with the latest [startUtc].
StoredPeriod? _ongoingUnclosedAsOfToday(Iterable<StoredPeriod> periods) {
  final now = DateTime.now();
  final todayUtc = DateTime.utc(now.year, now.month, now.day);
  StoredPeriod? best;
  for (final p in periods) {
    if (!p.span.isOpen) continue;
    if (!p.span.containsCalendarDayUtc(todayUtc, todayLocal: now)) continue;
    if (best == null || p.span.startUtc.isAfter(best.span.startUtc)) {
      best = p;
    }
  }
  return best;
}

enum _OrphanResolution { dismissed, deleteOrphans, splitToNewPeriod }

Future<_OrphanResolution> _promptOrphanDayEntries(
  BuildContext context,
  MaterialLocalizations loc,
  List<DateTime> datesUtc,
) async {
  final label = datesUtc
      .map((d) => loc.formatMediumDate(d.toLocal()))
      .join(', ');
  final result = await showDialog<_OrphanResolution>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Day logs outside new dates'),
      content: Text(
        'Some day entries fall outside the period you entered: $label.\n\n'
        'Remove those day logs, or move them into a new period spanning '
        'their dates (may fail if that would overlap another period).',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _OrphanResolution.dismissed),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _OrphanResolution.deleteOrphans),
          child: const Text('Remove day logs'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(ctx, _OrphanResolution.splitToNewPeriod),
          child: const Text('New period'),
        ),
      ],
    ),
  );
  return result ?? _OrphanResolution.dismissed;
}

/// Opens the create / edit logging bottom sheet.
Future<void> showLoggingBottomSheet(
  BuildContext context, {
  required PeriodRepository repository,
  required PeriodCalendarContext calendar,
  StoredPeriod? existingPeriod,
  StoredDayEntry? existingDayEntry,
  DateTime? initialDate,
  bool addDayEntryForPeriod = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: LoggingBottomSheet(
          repository: repository,
          calendar: calendar,
          existingPeriod: existingPeriod,
          existingDayEntry: existingDayEntry,
          initialDate: initialDate,
          addDayEntryForPeriod: addDayEntryForPeriod,
        ),
      );
    },
  );
}

/// Modal content for logging periods and per-day details.
class LoggingBottomSheet extends StatefulWidget {
  const LoggingBottomSheet({
    super.key,
    required this.repository,
    required this.calendar,
    this.existingPeriod,
    this.existingDayEntry,
    this.initialDate,
    this.addDayEntryForPeriod = false,
  });

  final PeriodRepository repository;
  final PeriodCalendarContext calendar;
  final StoredPeriod? existingPeriod;
  final StoredDayEntry? existingDayEntry;
  final DateTime? initialDate;

  /// When true with [existingPeriod], add a day entry for that period instead
  /// of editing period dates.
  final bool addDayEntryForPeriod;

  @override
  State<LoggingBottomSheet> createState() => _LoggingBottomSheetState();
}

class _LoggingBottomSheetState extends State<LoggingBottomSheet> {
  late DateTime _selectedDate;
  _SheetCreateIntent _createIntent = _SheetCreateIntent.startNewPeriod;
  FlowIntensity? _flowIntensity;
  PainScore? _painScore;
  Mood? _mood;
  late final TextEditingController _notesController;
  bool _isSaving = false;
  String? _errorText;
  MoodDisplayMode _moodDisplayMode = MoodDisplayMode.emoji;

  late DateTime _periodEditStartLocal;
  DateTime? _periodEditEndLocal;
  bool _periodEditHasEnd = true;

  /// From [PeriodRepository.watchPeriodsWithDays] in create mode; null until first
  /// event or when no open span covers today.
  StoredPeriod? _ongoingPeriod;
  bool _periodsStreamReady = false;
  StreamSubscription<List<StoredPeriodWithDays>>? _periodsSub;
  bool _firstPeriodsSnapshot = true;
  int? _lastOngoingIdForIntent;

  bool get _isEditMode => widget.existingPeriod != null;

  bool get _isEditDayMode =>
      widget.existingPeriod != null && widget.existingDayEntry != null;

  bool get _isAddDayForPeriodMode =>
      widget.addDayEntryForPeriod && widget.existingPeriod != null;

  bool get _isEditPeriodOnlyMode =>
      widget.existingPeriod != null &&
      widget.existingDayEntry == null &&
      !_isAddDayForPeriodMode;

  @override
  void initState() {
    super.initState();
    MoodSettings.load().then((m) {
      if (mounted) setState(() => _moodDisplayMode = m);
    });

    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);

    if (_isEditDayMode) {
      final d = widget.existingDayEntry!.data.dateUtc;
      _selectedDate = DateTime(d.year, d.month, d.day);
      _flowIntensity = widget.existingDayEntry!.data.flowIntensity;
      _painScore = widget.existingDayEntry!.data.painScore;
      _mood = widget.existingDayEntry!.data.mood;
      _notesController = TextEditingController(
        text: widget.existingDayEntry!.data.notes ?? '',
      );
    } else if (_isEditPeriodOnlyMode) {
      final span = widget.existingPeriod!.span;
      final s = span.startUtc;
      _periodEditStartLocal = DateTime(s.year, s.month, s.day);
      _periodEditHasEnd = span.endUtc != null;
      if (span.endUtc != null) {
        final e = span.endUtc!;
        _periodEditEndLocal = DateTime(e.year, e.month, e.day);
      } else {
        _periodEditEndLocal = _periodEditStartLocal;
      }
      _selectedDate = todayLocal;
      _notesController = TextEditingController();
    } else if (_isAddDayForPeriodMode) {
      _selectedDate = widget.initialDate ?? todayLocal;
      _notesController = TextEditingController();
    } else {
      _selectedDate = widget.initialDate ?? todayLocal;
      _notesController = TextEditingController();
    }

    if (!_isEditMode) {
      _periodsSub = widget.repository.watchPeriodsWithDays().listen(
        _onPeriodsSnapshot,
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _periodsStreamReady = true;
            _ongoingPeriod = null;
          });
        },
      );
    } else {
      _periodsStreamReady = true;
    }
  }

  void _onPeriodsSnapshot(List<StoredPeriodWithDays> data) {
    if (!mounted) return;
    final ongoing = _ongoingUnclosedAsOfToday(data.map((e) => e.period));
    final id = ongoing?.id;
    setState(() {
      _ongoingPeriod = ongoing;
      _periodsStreamReady = true;
      if (_firstPeriodsSnapshot) {
        _firstPeriodsSnapshot = false;
        _lastOngoingIdForIntent = id;
        _createIntent = ongoing != null
            ? _SheetCreateIntent.logDayForOpenPeriod
            : _SheetCreateIntent.startNewPeriod;
      } else if (id != _lastOngoingIdForIntent) {
        _lastOngoingIdForIntent = id;
        _createIntent = ongoing != null
            ? _SheetCreateIntent.logDayForOpenPeriod
            : _SheetCreateIntent.startNewPeriod;
      }
    });
  }

  @override
  void dispose() {
    _periodsSub?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _utcMidnightFromLocalDate(DateTime localDate) {
    return DateTime.utc(localDate.year, localDate.month, localDate.day);
  }

  Future<void> _pickDate({
    required DateTime initial,
    required void Function(DateTime picked) onPicked,
    DateTime? firstDate,
  }) async {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month, now.day);
    final first = firstDate ?? DateTime.now().subtract(const Duration(days: 365 * 5));
    // Android may log AccessibilityBridge deprecation from Material
    // CalendarDatePicker (flutter/flutter#165510); fix is upstream in Flutter.
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last) ? last : initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null && mounted) {
      setState(() {
        onPicked(picked);
        _errorText = null;
      });
      _validateEndBeforeStartLive();
    }
  }

  void _validateEndBeforeStartLive() {
    if (!_isEditMode && !_periodsStreamReady) return;
    if (_isEditPeriodOnlyMode || _isEditDayMode) return;
    String? next;
    if (_isAddDayForPeriodMode) {
      final span = widget.existingPeriod!.span;
      final dayUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (!span.containsCalendarDayUtc(dayUtc)) {
        next = 'This date is outside this period\'s range.';
      }
    }
    final open = _ongoingPeriod;
    if (next == null &&
        open != null &&
        _createIntent == _SheetCreateIntent.endOpenPeriod) {
      final endUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (endUtc.isBefore(open.span.startUtc)) {
        next = 'End date cannot be before start date';
      }
    }
    if (next == null &&
        open != null &&
        _createIntent == _SheetCreateIntent.logDayForOpenPeriod) {
      final dayUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (dayUtc.isBefore(open.span.startUtc)) {
        next = 'This date is before the current period started.';
      }
    }
    setState(() {
      if (next != null) {
        _errorText = next;
      } else if (_isLiveDateErrorText(_errorText)) {
        _errorText = null;
      }
    });
  }

  String _formatPeriodWriteIssues(
    List<PeriodValidationIssue> issues,
    MaterialLocalizations loc,
    List<StoredPeriod> orderedPeriods,
  ) {
    String fmt(DateTime utc) => loc.formatMediumDate(utc.toLocal());
    final parts = <String>[];
    for (final issue in issues) {
      switch (issue) {
        case EndBeforeStart():
          parts.add('End date cannot be before start date.');
        case DuplicateStartCalendarDay():
          parts.add('A period already starts on this date.');
        case OverlappingPeriod(:final existingIndex):
          if (existingIndex >= 0 && existingIndex < orderedPeriods.length) {
            final span = orderedPeriods[existingIndex].span;
            final startLabel = fmt(span.startUtc);
            final endLabel = span.isOpen
                ? 'ongoing'
                : fmt(span.endUtc!);
            parts.add(
              'This overlaps with your $startLabel–$endLabel period. Please adjust dates.',
            );
          } else {
            parts.add(
              'This overlaps with an existing period. Please adjust dates.',
            );
          }
      }
    }
    return parts.join(' ');
  }

  bool _hasDayDetails() {
    final notes = _notesController.text.trim();
    return _flowIntensity != null ||
        _painScore != null ||
        _mood != null ||
        notes.isNotEmpty;
  }

  DayEntryData _buildDayEntryData() {
    return DayEntryData(
      dateUtc: _utcMidnightFromLocalDate(_selectedDate),
      flowIntensity: _flowIntensity,
      painScore: _painScore,
      mood: _mood,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  Future<void> _save() async {
    if (_isSaving || (!_isEditMode && !_periodsStreamReady)) return;

    final loc = MaterialLocalizations.of(context);

    if (_isEditPeriodOnlyMode) {
      await _savePeriodEdit(loc);
      return;
    }

    if (_isEditDayMode) {
      await _saveDayEdit();
      return;
    }

    if (_isAddDayForPeriodMode) {
      final span = widget.existingPeriod!.span;
      final dayUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (!span.containsCalendarDayUtc(dayUtc)) {
        setState(() {
          _errorText = 'This date is outside this period\'s range.';
        });
        return;
      }
      setState(() {
        _isSaving = true;
        _errorText = null;
      });
      try {
        await widget.repository.upsertDayEntryForPeriod(
          widget.existingPeriod!.id,
          _buildDayEntryData(),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
      } on Object catch (_) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _errorText = 'Could not save. Please try again.';
        });
      }
      return;
    }

    if (_createIntent == _SheetCreateIntent.logDayForOpenPeriod) {
      final open = _ongoingPeriod;
      if (open == null) {
        setState(() {
          _errorText =
              'No open period through today. Close and reopen this sheet after '
              'the calendar updates.';
        });
        return;
      }
      final dayUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (dayUtc.isBefore(open.span.startUtc)) {
        setState(() {
          _errorText = 'This date is before the current period started.';
        });
        return;
      }
      setState(() {
        _isSaving = true;
        _errorText = null;
      });
      try {
        await widget.repository.upsertDayEntryForPeriod(
          open.id,
          _buildDayEntryData(),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
      } on Object catch (_) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _errorText = 'Could not save. Please try again.';
        });
      }
      return;
    }

    if (_createIntent == _SheetCreateIntent.endOpenPeriod) {
      final open = _ongoingPeriod;
      if (open == null) {
        setState(() {
          _errorText =
              'No open period through today. Pull the calendar back if needed, '
              'or close and reopen this sheet.';
        });
        return;
      }
      final endUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (endUtc.isBefore(open.span.startUtc)) {
        setState(() {
          _errorText = 'End date cannot be before start date';
        });
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final ordered = await widget.repository.listOrderedByStartUtc();
      late final int periodId;

      final PeriodWriteOutcome periodOutcome;
      if (_createIntent == _SheetCreateIntent.startNewPeriod) {
        final span = PeriodSpan(
          startUtc: _utcMidnightFromLocalDate(_selectedDate),
          endUtc: null,
        );
        periodOutcome = await widget.repository.insertPeriod(span);
      } else {
        final open = _ongoingPeriod;
        if (open == null) {
          if (mounted) {
            setState(() {
              _isSaving = false;
              _errorText =
                  'No ongoing period to end. Close and reopen this sheet.';
            });
          }
          return;
        }
        final newSpan = PeriodSpan(
          startUtc: open.span.startUtc,
          endUtc: _utcMidnightFromLocalDate(_selectedDate),
        );
        var o = await widget.repository.updatePeriod(open.id, newSpan);
        if (!mounted) return;
        o = await _resolveOrphanDayBlocking(
          periodId: open.id,
          span: newSpan,
          outcome: o,
          loc: loc,
        );
        if (!mounted) return;
        if (o is PeriodWriteBlockedByOrphanDayEntries) {
          setState(() {
            _isSaving = false;
          });
          return;
        }
        periodOutcome = o;
      }

      switch (periodOutcome) {
        case PeriodWriteSuccess(:final id):
          periodId = id;
        case PeriodWriteRejected(:final issues):
          if (!mounted) return;
          setState(() {
            _isSaving = false;
            _errorText = _formatPeriodWriteIssues(issues, loc, ordered);
          });
          return;
        case PeriodWriteNotFound():
          if (!mounted) return;
          setState(() {
            _isSaving = false;
            _errorText = 'Could not update period. Try again.';
          });
          return;
        case PeriodWriteBlockedByOrphanDayEntries():
          if (!mounted) return;
          setState(() {
            _isSaving = false;
            _errorText = 'Could not resolve day logs outside the new dates.';
          });
          return;
      }

      if (_hasDayDetails()) {
        if (_createIntent == _SheetCreateIntent.endOpenPeriod) {
          await widget.repository.upsertDayEntryForPeriod(
            periodId,
            _buildDayEntryData(),
          );
        } else {
          await widget.repository.saveDayEntry(periodId, _buildDayEntryData());
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Could not save. Please try again.';
      });
    }
  }

  Future<void> _saveDayEdit() async {
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final data = _buildDayEntryData();
      final ok = await widget.repository.updateDayEntry(
        widget.existingDayEntry!.id,
        data,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _isSaving = false;
          _errorText = 'Could not update day entry.';
        });
        return;
      }
      Navigator.of(context).pop();
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Could not save. Please try again.';
      });
    }
  }

  Future<PeriodWriteOutcome> _resolveOrphanDayBlocking({
    required int periodId,
    required PeriodSpan span,
    required PeriodWriteOutcome outcome,
    required MaterialLocalizations loc,
  }) async {
    var o = outcome;
    while (o is PeriodWriteBlockedByOrphanDayEntries) {
      final blocked = o;
      setState(() => _isSaving = false);
      final choice = await _promptOrphanDayEntries(
        context,
        loc,
        blocked.orphanDatesUtc,
      );
      if (!mounted) return blocked;
      if (choice == _OrphanResolution.dismissed) {
        return blocked;
      }
      setState(() {
        _isSaving = true;
        _errorText = null;
      });
      o = switch (choice) {
        _OrphanResolution.deleteOrphans =>
          await widget.repository.updatePeriodDeletingOrphanDayEntries(
            periodId,
            span,
            blocked.orphanEntryIds,
          ),
        _OrphanResolution.splitToNewPeriod =>
          await widget.repository.updatePeriodSplittingOrphansIntoNewPeriod(
            periodId,
            span,
            blocked.orphanEntryIds,
          ),
        _OrphanResolution.dismissed => blocked,
      };
      if (!mounted) return o;
    }
    return o;
  }

  Future<void> _deleteOngoingPeriodFromFab() async {
    final list = await widget.repository.listOrderedByStartUtc();
    if (!mounted) return;
    final ongoing = _ongoingUnclosedAsOfToday(list);
    if (ongoing == null) {
      setState(() {
        _errorText = 'There is no ongoing period to delete.';
      });
      return;
    }
    await _confirmDeletePeriod(ongoing);
  }

  void _navigateToPeriodOnlyEdit(StoredPeriod period) {
    final navigator = Navigator.of(context);
    final overlay = navigator.overlay;
    navigator.pop();
    if (overlay == null) return;
    final overlayCtx = overlay.context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!overlayCtx.mounted) return;
      showLoggingBottomSheet(
        overlayCtx,
        repository: widget.repository,
        calendar: widget.calendar,
        existingPeriod: period,
      );
    });
  }

  Future<void> _confirmDeletePeriod(StoredPeriod period) async {
    final list = await widget.repository.listOrderedByStartUtc();
    if (!mounted) return;
    StoredPeriod? fresh;
    for (final p in list) {
      if (p.id == period.id) {
        fresh = p;
        break;
      }
    }
    if (fresh == null) {
      if (mounted) {
        setState(() {
          _errorText =
              'That period no longer exists. Close this sheet and try again.';
        });
      }
      return;
    }

    final target = fresh;
    final loc = MaterialLocalizations.of(context);
    String localDay(DateTime utc) =>
        loc.formatMediumDate(DateTime(utc.year, utc.month, utc.day));
    final startLabel = localDay(target.span.startUtc);
    final endLabel = target.span.isOpen
        ? null
        : localDay(target.span.endUtc!);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          target.span.isOpen
              ? 'Delete ongoing period?'
              : 'Delete this period?',
        ),
        content: Text(
          target.span.isOpen
              ? 'Remove only the ongoing period that starts $startLabel '
                  '(still open). Older, finished periods are not affected.\n\n'
                  'To remove a past period instead, open a day inside that '
                  'period on the calendar and use Delete entire period there.'
              : 'Remove the period $startLabel–$endLabel and all day logs '
                  'saved under it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final ok = await widget.repository.deletePeriod(target.id);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _isSaving = false;
          _errorText = 'Could not delete period.';
        });
        return;
      }
      Navigator.of(context).pop();
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Could not delete period. Try again.';
      });
    }
  }

  Future<void> _savePeriodEdit(MaterialLocalizations loc) async {
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final ordered = await widget.repository.listOrderedByStartUtc();
      final startUtc = _utcMidnightFromLocalDate(_periodEditStartLocal);
      final endUtc = _periodEditHasEnd && _periodEditEndLocal != null
          ? _utcMidnightFromLocalDate(_periodEditEndLocal!)
          : null;
      final span = PeriodSpan(startUtc: startUtc, endUtc: endUtc);
      var outcome = await widget.repository.updatePeriod(
        widget.existingPeriod!.id,
        span,
      );
      if (!mounted) return;
      outcome = await _resolveOrphanDayBlocking(
        periodId: widget.existingPeriod!.id,
        span: span,
        outcome: outcome,
        loc: loc,
      );
      if (!mounted) return;
      if (outcome is PeriodWriteBlockedByOrphanDayEntries) {
        setState(() => _isSaving = false);
        return;
      }

      switch (outcome) {
        case PeriodWriteSuccess():
          Navigator.of(context).pop();
        case PeriodWriteRejected(:final issues):
          setState(() {
            _isSaving = false;
            _errorText = _formatPeriodWriteIssues(issues, loc, ordered);
          });
        case PeriodWriteNotFound():
          setState(() {
            _isSaving = false;
            _errorText = 'Period not found.';
          });
        case PeriodWriteBlockedByOrphanDayEntries():
          setState(() {
            _isSaving = false;
            _errorText = 'Could not resolve day logs outside the new dates.';
          });
      }
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Could not save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.calendar.location.name.isNotEmpty,
      'calendar must use a valid IANA location',
    );
    final loc = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (!_isEditMode && !_periodsStreamReady) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEditPeriodOnlyMode) ...[
              Text(
                'Edit period dates',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Period start'),
                subtitle: Text(loc.formatMediumDate(_periodEditStartLocal)),
                trailing: TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => _pickDate(
                            initial: _periodEditStartLocal,
                            onPicked: (d) => setState(() {
                              _periodEditStartLocal = d;
                              if (_periodEditEndLocal != null &&
                                  _periodEditEndLocal!.isBefore(d)) {
                                _periodEditEndLocal = d;
                              }
                            }),
                          ),
                  child: const Text('Change'),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Period end'),
                subtitle: Text(
                  _periodEditHasEnd && _periodEditEndLocal != null
                      ? loc.formatMediumDate(_periodEditEndLocal!)
                      : 'Ongoing (no end date)',
                ),
                trailing: _periodEditHasEnd && _periodEditEndLocal != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => setState(() {
                                      _periodEditHasEnd = false;
                                      _periodEditEndLocal = null;
                                    }),
                            child: const Text('Ongoing'),
                          ),
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => _pickDate(
                                      initial: _periodEditEndLocal ??
                                          _periodEditStartLocal,
                                      firstDate: _periodEditStartLocal,
                                      onPicked: (d) => setState(() {
                                        _periodEditHasEnd = true;
                                        _periodEditEndLocal = d;
                                      }),
                                    ),
                            child: const Text('Change'),
                          ),
                        ],
                      )
                    : TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => _pickDate(
                                  initial: _periodEditEndLocal ??
                                      _periodEditStartLocal,
                                  firstDate: _periodEditStartLocal,
                                  onPicked: (d) => setState(() {
                                    _periodEditHasEnd = true;
                                    _periodEditEndLocal = d;
                                  }),
                                ),
                        child: const Text('Change'),
                      ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => _confirmDeletePeriod(widget.existingPeriod!),
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  child: const Text('Delete period'),
                ),
              ),
            ] else ...[
              Text(
                _isEditDayMode
                    ? 'Edit day'
                    : _isAddDayForPeriodMode
                        ? 'Log day in period'
                        : 'Log period',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(loc.formatMediumDate(_selectedDate)),
                trailing: TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => _pickDate(
                            initial: _selectedDate,
                            onPicked: (d) => setState(() => _selectedDate = d),
                          ),
                  child: const Text('Change date'),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorText!,
                  style: TextStyle(color: scheme.error),
                ),
              ],
              if (!_isEditMode) ...[
                const SizedBox(height: 8),
                const Text('Period'),
                if (_ongoingPeriod != null) ...[
                  SegmentedButton<_SheetCreateIntent>(
                    segments: [
                      const ButtonSegment<_SheetCreateIntent>(
                        value: _SheetCreateIntent.startNewPeriod,
                        label: Text('Start new'),
                      ),
                      const ButtonSegment<_SheetCreateIntent>(
                        value: _SheetCreateIntent.logDayForOpenPeriod,
                        label: Text('Log day'),
                      ),
                      ButtonSegment<_SheetCreateIntent>(
                        value: _SheetCreateIntent.endOpenPeriod,
                        label: Text(
                          'End ${loc.formatMediumDate(DateTime(_ongoingPeriod!.span.startUtc.year, _ongoingPeriod!.span.startUtc.month, _ongoingPeriod!.span.startUtc.day))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    selected: {_createIntent},
                    onSelectionChanged: _isSaving
                        ? null
                        : (selected) {
                            if (selected.isEmpty) return;
                            setState(() {
                              _createIntent = selected.first;
                              if (_isLiveDateErrorText(_errorText)) {
                                _errorText = null;
                              }
                            });
                            _validateEndBeforeStartLive();
                          },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => _navigateToPeriodOnlyEdit(_ongoingPeriod!),
                        child: const Text('Adjust period dates'),
                      ),
                      TextButton(
                        onPressed: _isSaving ? null : _deleteOngoingPeriodFromFab,
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.error,
                        ),
                        child: const Text('Delete ongoing period'),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Past (ended) periods are not removed here. Open a day '
                      'in that older span on the calendar → Delete entire period.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Start new period on this date',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
              ],
            ],
            if (_errorText != null && _isEditPeriodOnlyMode) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: TextStyle(color: scheme.error),
              ),
            ],
            if (!_isEditPeriodOnlyMode) ...[
              const SizedBox(height: 16),
              const Text('Flow'),
              const SizedBox(height: 8),
              SegmentedButton<FlowIntensity>(
                key: const Key('flow_intensity_segments'),
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: [
                  for (final f in FlowIntensity.values)
                    ButtonSegment<FlowIntensity>(
                      value: f,
                      label: Text(f.label),
                    ),
                ],
                selected: _flowIntensity == null ? {} : {_flowIntensity!},
                onSelectionChanged: _isSaving
                    ? null
                    : (s) => setState(() {
                          _flowIntensity = s.isEmpty ? null : s.first;
                        }),
              ),
              const SizedBox(height: 16),
              const Text('Pain'),
              const SizedBox(height: 8),
              SegmentedButton<PainScore>(
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: [
                  for (final p in PainScore.values)
                    ButtonSegment<PainScore>(
                      value: p,
                      label: Text(p.compactLabel, maxLines: 1),
                    ),
                ],
                selected: _painScore == null ? {} : {_painScore!},
                onSelectionChanged: _isSaving
                    ? null
                    : (s) => setState(() {
                          _painScore = s.isEmpty ? null : s.first;
                        }),
              ),
              const SizedBox(height: 16),
              const Text('Mood'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in Mood.values)
                    ChoiceChip(
                      label: Text(
                        _moodDisplayMode == MoodDisplayMode.emoji
                            ? m.emoji
                            : m.label,
                      ),
                      selected: _mood == m,
                      onSelected: _isSaving
                          ? null
                          : (sel) => setState(() {
                                _mood = sel ? m : null;
                              }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Notes'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                readOnly: _isSaving,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(
                _isEditPeriodOnlyMode
                    ? 'Save dates'
                    : _isEditDayMode
                        ? 'Update'
                        : 'Save',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

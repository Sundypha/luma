import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../settings/mood_settings.dart';

/// Create flow when an open period may exist: start another, log a day on the
/// open period, or set the open period's end date.
///
/// When there is **no** open period but the selected date lies inside a
/// **completed** period, [logDayForPeriod] attaches the entry to that period
/// instead of inserting a new one.
enum _SheetCreateIntent {
  startNewPeriod,
  logDayForPeriod,
  endOpenPeriod,
}

bool _isLiveDateErrorText(String? e) =>
    e == 'End date cannot be before start date' ||
    e == 'This date is before the current period started.' ||
    e == 'This date is outside this period\'s range.';

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

  StoredPeriod? _openPeriod;

  /// Periods from the last [listOrderedByStartUtc] load (for containing-date lookup).
  List<StoredPeriod> _orderedPeriods = const [];

  /// When there is no [open] period, the completed (or any) period that
  /// contains [_selectedDate], if any.
  StoredPeriod? _containingPeriodForSelection;

  bool _loadingContext = true;

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
      widget.repository.listOrderedByStartUtc().then((list) {
        if (!mounted) return;
        StoredPeriod? open;
        for (final p in list) {
          if (p.span.isOpen) {
            open = p;
            break;
          }
        }
        final containing = _findContainingPeriod(list, _selectedDate);
        setState(() {
          _orderedPeriods = list;
          _openPeriod = open;
          _containingPeriodForSelection = containing;
          if (open != null) {
            _createIntent = _SheetCreateIntent.logDayForPeriod;
          } else if (containing != null) {
            _createIntent = _SheetCreateIntent.logDayForPeriod;
          } else {
            _createIntent = _SheetCreateIntent.startNewPeriod;
          }
          _loadingContext = false;
        });
      });
    } else {
      _loadingContext = false;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime _utcMidnightFromLocalDate(DateTime localDate) {
    return DateTime.utc(localDate.year, localDate.month, localDate.day);
  }

  StoredPeriod? _findContainingPeriod(
    List<StoredPeriod> list,
    DateTime localDate,
  ) {
    final dayUtc = _utcMidnightFromLocalDate(localDate);
    for (final p in list) {
      if (p.span.containsCalendarDayUtc(dayUtc)) return p;
    }
    return null;
  }

  /// Period that receives a day log when [_createIntent] is [logDayForPeriod].
  StoredPeriod? _periodTargetForDayLog() {
    if (_createIntent != _SheetCreateIntent.logDayForPeriod) return null;
    if (_openPeriod != null) return _openPeriod;
    return _containingPeriodForSelection;
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
        if (!_isEditMode) {
          _containingPeriodForSelection =
              _findContainingPeriod(_orderedPeriods, _selectedDate);
          if (_openPeriod == null) {
            if (_createIntent == _SheetCreateIntent.logDayForPeriod &&
                _containingPeriodForSelection == null) {
              _createIntent = _SheetCreateIntent.startNewPeriod;
            } else if (_createIntent == _SheetCreateIntent.startNewPeriod &&
                _containingPeriodForSelection != null) {
              _createIntent = _SheetCreateIntent.logDayForPeriod;
            }
          }
        }
      });
      _validateEndBeforeStartLive();
    }
  }

  void _validateEndBeforeStartLive() {
    if (_loadingContext) return;
    if (_isEditPeriodOnlyMode || _isEditDayMode) return;
    String? next;
    if (_isAddDayForPeriodMode) {
      final span = widget.existingPeriod!.span;
      final dayUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (!span.containsCalendarDayUtc(dayUtc)) {
        next = 'This date is outside this period\'s range.';
      }
    }
    final open = _openPeriod;
    if (next == null &&
        open != null &&
        _createIntent == _SheetCreateIntent.endOpenPeriod) {
      final endUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (endUtc.isBefore(open.span.startUtc)) {
        next = 'End date cannot be before start date';
      }
    }
    if (next == null &&
        _createIntent == _SheetCreateIntent.logDayForPeriod) {
      final target = _periodTargetForDayLog();
      if (target != null) {
        final dayUtc = _utcMidnightFromLocalDate(_selectedDate);
        if (!target.span.containsCalendarDayUtc(dayUtc)) {
          next = 'This date is outside this period\'s range.';
        }
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

  String _formatPeriodRangeLine(
    MaterialLocalizations loc,
    StoredPeriod p,
  ) {
    final span = p.span;
    final startLabel = loc.formatMediumDate(span.startUtc.toLocal());
    if (span.isOpen) return '$startLabel–ongoing';
    final endLabel = loc.formatMediumDate(span.endUtc!.toLocal());
    return '$startLabel–$endLabel';
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
    if (_isSaving || _loadingContext) return;

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

    if (_createIntent == _SheetCreateIntent.logDayForPeriod) {
      final target = _periodTargetForDayLog();
      if (target == null) return;
      final dayUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (!target.span.containsCalendarDayUtc(dayUtc)) {
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
          target.id,
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
      final open = _openPeriod;
      if (open == null) return;
      final endUtc = _utcMidnightFromLocalDate(_selectedDate);
      if (endUtc.isBefore(open.span.startUtc)) {
        setState(() {
          _errorText = 'End date cannot be before start date';
        });
        return;
      }
    }

    if (_createIntent == _SheetCreateIntent.startNewPeriod &&
        _openPeriod == null) {
      final dayUtc = _utcMidnightFromLocalDate(_selectedDate);
      final c = _findContainingPeriod(_orderedPeriods, _selectedDate);
      if (c != null && c.span.containsCalendarDayUtc(dayUtc)) {
        setState(() {
          _errorText =
              'To start a new period, choose a date outside your existing '
              'periods, or switch to Log day to add details to this one.';
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
        final open = _openPeriod!;
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

    if (_loadingContext) {
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
                            onPicked: (d) {
                              _periodEditStartLocal = d;
                              if (_periodEditEndLocal != null &&
                                  _periodEditEndLocal!.isBefore(d)) {
                                _periodEditEndLocal = d;
                              }
                            },
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
                                      onPicked: (d) {
                                        _periodEditHasEnd = true;
                                        _periodEditEndLocal = d;
                                      },
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
                                  onPicked: (d) {
                                    _periodEditHasEnd = true;
                                    _periodEditEndLocal = d;
                                  },
                                ),
                        child: const Text('Change'),
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
                            // Assignment only; [_pickDate] wraps in setState and
                            // refreshes containing-period context.
                            onPicked: (d) => _selectedDate = d,
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
                if (_openPeriod != null) ...[
                  SegmentedButton<_SheetCreateIntent>(
                    segments: [
                      const ButtonSegment<_SheetCreateIntent>(
                        value: _SheetCreateIntent.startNewPeriod,
                        label: Text('Start new'),
                      ),
                      const ButtonSegment<_SheetCreateIntent>(
                        value: _SheetCreateIntent.logDayForPeriod,
                        label: Text('Log day'),
                      ),
                      ButtonSegment<_SheetCreateIntent>(
                        value: _SheetCreateIntent.endOpenPeriod,
                        label: Text(
                          'End ${loc.formatMediumDate(DateTime(_openPeriod!.span.startUtc.year, _openPeriod!.span.startUtc.month, _openPeriod!.span.startUtc.day))}',
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
                ] else if (_containingPeriodForSelection != null) ...[
                  SegmentedButton<_SheetCreateIntent>(
                    segments: const [
                      ButtonSegment<_SheetCreateIntent>(
                        value: _SheetCreateIntent.logDayForPeriod,
                        label: Text('Log day'),
                      ),
                      ButtonSegment<_SheetCreateIntent>(
                        value: _SheetCreateIntent.startNewPeriod,
                        label: Text('Start new'),
                      ),
                    ],
                    selected: {_createIntent},
                    onSelectionChanged: _isSaving
                        ? null
                        : (selected) {
                            if (selected.isEmpty) return;
                            final intent = selected.first;
                            setState(() {
                              _createIntent = intent;
                              if (_isLiveDateErrorText(_errorText)) {
                                _errorText = null;
                              }
                              if (intent == _SheetCreateIntent.startNewPeriod) {
                                final dayUtc =
                                    _utcMidnightFromLocalDate(_selectedDate);
                                final c = _containingPeriodForSelection;
                                if (c != null &&
                                    c.span.containsCalendarDayUtc(dayUtc)) {
                                  _errorText =
                                      'To start a new period, choose a date '
                                      'outside your existing periods, or use '
                                      'Log day to add details to this one.';
                                }
                              }
                            });
                            _validateEndBeforeStartLive();
                          },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _createIntent == _SheetCreateIntent.logDayForPeriod
                          ? 'Adding details to your period '
                              '${_formatPeriodRangeLine(loc, _containingPeriodForSelection!)}.'
                          : 'New period will start on the date above.',
                      style: Theme.of(context).textTheme.bodySmall,
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
                _isEditDayMode || _isEditPeriodOnlyMode ? 'Update' : 'Save',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:ptrack_data/ptrack_data.dart';

/// First-run screen: mark period days via [PeriodRepository.markDay].
class FirstLogScreen extends StatefulWidget {
  const FirstLogScreen({
    super.key,
    required this.repository,
    required this.onComplete,
  });

  final PeriodRepository repository;
  final VoidCallback onComplete;

  @override
  State<FirstLogScreen> createState() => _FirstLogScreenState();
}

class _FirstLogScreenState extends State<FirstLogScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _periodHasEnded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _startDate = DateTime(n.year, n.month, n.day);
    _endDate = _startDate;
  }

  void _syncEndAfterStartChange() {
    if (_endDate.isBefore(_startDate)) {
      _endDate = _startDate;
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        _syncEndAfterStartChange();
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final startUtc = DateTime.utc(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );
    final endUtc = _periodHasEnded
        ? DateTime.utc(
            _endDate.year,
            _endDate.month,
            _endDate.day,
          )
        : startUtc;

    DayMarkOutcome? lastOutcome;
    for (var d = startUtc; !d.isAfter(endUtc); d = d.add(const Duration(days: 1))) {
      lastOutcome = await widget.repository.markDay(d);
      if (lastOutcome is DayMarkFailure) {
        break;
      }
    }

    if (!mounted) return;

    final failure = lastOutcome is DayMarkFailure ? lastOutcome : null;
    if (failure != null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.firstLogSaveFailed)),
      );
      setState(() => _isSaving = false);
      return;
    }

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.firstLogSuccessSnack)),
    );
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context);
    final startLabel = loc.formatFullDate(_startDate);
    final endLabel = loc.formatFullDate(_endDate);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.firstLogAppBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.firstLogStartQuestion,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(startLabel)),
                    TextButton(
                      onPressed: _isSaving ? null : _pickStartDate,
                      child: Text(l10n.firstLogChangeDate),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.firstLogPeriodEndedTitle),
              subtitle: Text(l10n.firstLogPeriodEndedSubtitle),
              value: _periodHasEnded,
              onChanged: _isSaving
                  ? null
                  : (v) {
                      setState(() {
                        _periodHasEnded = v;
                        if (v && _endDate.isBefore(_startDate)) {
                          _endDate = _startDate;
                        }
                      });
                    },
            ),
            if (_periodHasEnded) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(endLabel)),
                      TextButton(
                        onPressed: _isSaving ? null : _pickEndDate,
                        child: Text(l10n.firstLogChangeEndDate),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(l10n.firstLogSaveContinue),
            ),
          ],
        ),
      ),
    );
  }
}

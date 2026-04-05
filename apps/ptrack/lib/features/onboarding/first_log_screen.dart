import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

/// First-run screen to log one period start into [PeriodRepository].
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
        : null;

    final span = PeriodSpan(startUtc: startUtc, endUtc: endUtc);

    final outcome = await widget.repository.insertPeriod(span);

    if (!mounted) return;

    switch (outcome) {
      case PeriodWriteSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Period logged — you\'re all set!')),
        );
        widget.onComplete();
      case PeriodWriteRejected():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save — please try a different date.'),
          ),
        );
        setState(() => _isSaving = false);
      case PeriodWriteNotFound():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save — please try again.'),
          ),
        );
        setState(() => _isSaving = false);
      case PeriodWriteBlockedByOrphanDayEntries():
        // insertPeriod does not return this outcome.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save — please try again.'),
          ),
        );
        setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);
    final startLabel = loc.formatFullDate(_startDate);
    final endLabel = loc.formatFullDate(_endDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Log your first period')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'When did your current or most recent period start?',
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
                      child: const Text('Change date'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('This period has already ended'),
              subtitle: const Text(
                'Optional — add a last bleeding day if it is not ongoing.',
              ),
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
                        child: const Text('Change end date'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

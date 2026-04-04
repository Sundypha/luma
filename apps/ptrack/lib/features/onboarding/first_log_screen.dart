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
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _selectedDate = DateTime(n.year, n.month, n.day);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final span = PeriodSpan(
      startUtc: DateTime.utc(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
    );

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);
    final dateLabel = loc.formatFullDate(_selectedDate);

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(dateLabel)),
                    TextButton(
                      onPressed: _isSaving ? null : _pickDate,
                      child: const Text('Change date'),
                    ),
                  ],
                ),
              ),
            ),
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

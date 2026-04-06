import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import 'export_view_model.dart';

/// Multi-step flow: content → optional password → progress → share.
class ExportWizardScreen extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables — [ExportService] is not const.
  ExportWizardScreen({super.key, required this.service});

  final ExportService service;

  @override
  State<ExportWizardScreen> createState() => _ExportWizardScreenState();
}

class _ExportWizardScreenState extends State<ExportWizardScreen> {
  late final ExportViewModel _vm;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = ExportViewModel();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _confirmPopIfNeeded() async {
    if (_vm.step == ExportStep.exporting) return;
    if (_vm.step == ExportStep.selectContent) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave export?'),
        content: const Text('Your current progress in this wizard will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onPasswordNext() {
    final a = _passwordController.text;
    final b = _confirmPasswordController.text;
    if (a != b) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    _vm.setPassword(a.isEmpty ? null : a);
    _vm.startExport(widget.service);
  }

  void _onPasswordSkip() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    _vm.setPassword(null);
    _vm.startExport(widget.service);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return PopScope(
          canPop: _vm.step == ExportStep.selectContent ||
              _vm.step == ExportStep.done ||
              _vm.step == ExportStep.error,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _confirmPopIfNeeded();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Export Backup'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (_vm.step == ExportStep.exporting) return;
                  if (_vm.step == ExportStep.selectContent ||
                      _vm.step == ExportStep.done ||
                      _vm.step == ExportStep.error) {
                    if (mounted) Navigator.of(context).pop();
                    return;
                  }
                  await _confirmPopIfNeeded();
                },
              ),
            ),
            body: _buildBody(context),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_vm.step) {
      case ExportStep.selectContent:
        return _buildSelectContent(context);
      case ExportStep.setPassword:
        return _buildSetPassword(context);
      case ExportStep.exporting:
        return _buildExporting(context);
      case ExportStep.done:
        return _buildDone(context);
      case ExportStep.error:
        return _buildError(context);
    }
  }

  Widget _buildSelectContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('What to include', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Everything'),
              selected: _vm.includePeriods &&
                  _vm.includeSymptoms &&
                  _vm.includeNotes,
              onSelected: (_) => _vm.applyPreset(ExportPreset.everything),
            ),
            ChoiceChip(
              label: const Text('Periods only'),
              selected: _vm.periodsOnlySelected,
              onSelected: (_) => _vm.applyPreset(ExportPreset.periodsOnly),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: const Text('Periods'),
          value: _vm.includePeriods,
          onChanged: _vm.periodsOnlySelected
              ? null
              : (_) => _vm.togglePeriods(),
        ),
        SwitchListTile(
          title: const Text('Symptoms & flow'),
          subtitle: const Text('Flow, pain, mood'),
          value: _vm.includeSymptoms,
          onChanged: _vm.symptomsOnlySelected
              ? null
              : (_) => _vm.toggleSymptoms(),
        ),
        SwitchListTile(
          title: const Text('Notes'),
          value: _vm.includeNotes,
          onChanged:
              _vm.notesOnlySelected ? null : (_) => _vm.toggleNotes(),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _vm.hasContentSelection ? _vm.nextStep : null,
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildSetPassword(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Optionally protect this backup with a password.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _passwordController.clear(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirm password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(
              onPressed: _onPasswordSkip,
              child: const Text('Skip'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _onPasswordNext,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExporting(BuildContext context) {
    final pct = (_vm.progress * 100).round().clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LinearProgressIndicator(value: _vm.progress.clamp(0.0, 1.0)),
          const SizedBox(height: 16),
          Text('$pct%'),
          const SizedBox(height: 8),
          Text(
            'Creating backup…',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDone(BuildContext context) {
    final meta = _vm.result?.meta;
    final dateStr = meta != null ? meta.exportedAt.toLocal().toString() : '—';
    final types = meta?.contentTypes.join(', ') ?? '—';
    final enc = meta?.encrypted == true ? 'Yes' : 'No';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Export ready',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ListTile(
          title: const Text('Exported'),
          subtitle: Text(dateStr),
        ),
        ListTile(
          title: const Text('Content'),
          subtitle: Text(types),
        ),
        ListTile(
          title: const Text('Encrypted'),
          subtitle: Text(enc),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => _vm.deliverExport(context),
          child: const Text('Share'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Export failed',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _vm.errorMessage ?? 'Unknown error',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            _passwordController.clear();
            _confirmPasswordController.clear();
            _vm.reset();
          },
          child: const Text('Try Again'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

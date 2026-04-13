import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import '../../l10n/app_localizations.dart';
import 'backup_formatters.dart';
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
    final l10n = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportLeaveTitle),
        content: Text(l10n.exportLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.exportStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.exportLeave),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onPasswordNext() {
    final l10n = AppLocalizations.of(context);
    final a = _passwordController.text;
    final b = _confirmPasswordController.text;
    if (a != b) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportPasswordsMismatch)),
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
    final l10n = AppLocalizations.of(context);
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
              title: Text(l10n.exportAppBar),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.exportBackTooltip,
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
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.exportWhatToInclude,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.exportChipEverything),
              selected: _vm.includePeriods &&
                  _vm.includeSymptoms &&
                  _vm.includeNotes &&
                  _vm.includeDiary,
              onSelected: (_) => _vm.applyPreset(ExportPreset.everything),
            ),
            ChoiceChip(
              label: Text(l10n.exportChipPeriodsOnly),
              selected: _vm.periodsOnlySelected,
              onSelected: (_) => _vm.applyPreset(ExportPreset.periodsOnly),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: Text(l10n.exportTogglePeriods),
          value: _vm.includePeriods,
          onChanged: _vm.periodsOnlySelected
              ? null
              : (_) => _vm.togglePeriods(),
        ),
        SwitchListTile(
          title: Text(l10n.exportToggleSymptoms),
          subtitle: Text(l10n.exportToggleSymptomsSubtitle),
          value: _vm.includeSymptoms,
          onChanged: _vm.symptomsOnlySelected
              ? null
              : (_) => _vm.toggleSymptoms(),
        ),
        SwitchListTile(
          title: Text(l10n.exportToggleNotes),
          value: _vm.includeNotes,
          onChanged:
              _vm.notesOnlySelected ? null : (_) => _vm.toggleNotes(),
        ),
        SwitchListTile(
          title: Text(l10n.exportToggleDiary),
          value: _vm.includeDiary,
          onChanged:
              _vm.diaryOnlySelected ? null : (_) => _vm.toggleDiary(),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _vm.hasContentSelection ? _vm.nextStep : null,
          child: Text(l10n.exportNext),
        ),
      ],
    );
  }

  Widget _buildSetPassword(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.exportPasswordIntro,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.exportPasswordLabel,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              tooltip: l10n.exportClearPasswordTooltip,
              onPressed: () => _passwordController.clear(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.exportConfirmPasswordLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(
              onPressed: _onPasswordSkip,
              child: Text(l10n.exportSkip),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _onPasswordNext,
              child: Text(l10n.exportNext),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExporting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            l10n.exportCreating,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDone(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meta = _vm.result?.meta;
    final dateStr = meta != null
        ? formatBackupExportedAt(context, meta.exportedAt)
        : l10n.commonNotAvailable;
    final types =
        meta?.contentTypes.join(', ') ?? l10n.commonNotAvailable;
    final enc = meta?.encrypted == true ? l10n.commonYes : l10n.commonNo;

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
          l10n.exportReadyTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ListTile(
          title: Text(l10n.exportMetaExported),
          subtitle: Text(dateStr),
        ),
        ListTile(
          title: Text(l10n.exportMetaContent),
          subtitle: Text(types),
        ),
        ListTile(
          title: Text(l10n.exportMetaEncrypted),
          subtitle: Text(enc),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => _vm.deliverExport(context),
          child: Text(l10n.exportShare),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.exportDone),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          l10n.exportFailedTitle,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.exportFailedBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            _passwordController.clear();
            _confirmPasswordController.clear();
            _vm.reset();
          },
          child: Text(l10n.exportTryAgain),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.exportClose),
        ),
      ],
    );
  }
}

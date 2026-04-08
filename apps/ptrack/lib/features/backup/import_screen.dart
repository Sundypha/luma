import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import '../../l10n/app_localizations.dart';
import 'backup_formatters.dart';
import 'import_view_model.dart';

String _localizedImportError(AppLocalizations l10n, ImportViewModel vm) {
  final k = vm.importErrorKind;
  if (k == null) return l10n.importErrorGeneric;
  return switch (k) {
    ImportErrorKind.readSelectedFile => l10n.importErrorReadSelected,
    ImportErrorKind.wrongExtension => l10n.importErrorWrongExtension,
    ImportErrorKind.readBackup => l10n.importErrorReadBackup,
    ImportErrorKind.wrongPassword => l10n.importErrorWrongPassword,
    ImportErrorKind.decrypt => l10n.importErrorDecrypt,
    ImportErrorKind.applyFailed => l10n.importErrorApply,
    ImportErrorKind.parseFailed => l10n.importErrorParser(
        vm.importErrorDetail ?? l10n.importErrorGeneric,
      ),
  };
}

/// Multi-step flow: pick file → password if needed → preview → strategy → apply.
class ImportScreen extends StatefulWidget {
  const ImportScreen({
    super.key,
    required this.importService,
    required this.db,
  });

  final ImportService importService;
  final PtrackDatabase db;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late final ImportViewModel _vm;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = ImportViewModel(
      importService: widget.importService,
      db: widget.db,
      onPickerCancelled: () {
        if (mounted) Navigator.of(context).pop<void>();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.pickFile();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _vm.dispose();
    super.dispose();
  }

  bool get _canPop =>
      _vm.step != ImportStep.importing &&
      _vm.step != ImportStep.pickingFile;

  void _onPopBlocked() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.importInProgressSnack)),
    );
  }

  Future<void> _onPreviewContinue() async {
    final preview = _vm.preview;
    if (preview == null) return;
    if (preview.duplicateEntries == 0) {
      await _vm.applyImport();
    } else {
      _vm.proceedToImport();
    }
  }

  String _contentTypesLabel(AppLocalizations l10n, LumaExportMeta? meta) {
    if (meta == null || meta.contentTypes.isEmpty) {
      return l10n.dataContentTypesFallback;
    }
    return meta.contentTypes.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return PopScope(
          canPop: _canPop,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _onPopBlocked();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.importAppBar),
              leading: _vm.step == ImportStep.importing
                  ? const SizedBox.shrink()
                  : null,
            ),
            body: SafeArea(child: _buildBody(context, l10n)),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    switch (_vm.step) {
      case ImportStep.idle:
      case ImportStep.pickingFile:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.importSelectingFile),
            ],
          ),
        );
      case ImportStep.passwordPrompt:
        return _buildPasswordStep(context, l10n);
      case ImportStep.previewing:
        return _buildPreviewStep(context, l10n);
      case ImportStep.chooseStrategy:
        return _buildStrategyStep(context, l10n);
      case ImportStep.importing:
        return _buildImportingStep(context, l10n);
      case ImportStep.done:
        return _buildDoneStep(context, l10n);
      case ImportStep.error:
        return _buildErrorStep(context, l10n);
    }
  }

  Widget _buildPasswordStep(BuildContext context, AppLocalizations l10n) {
    final meta = _vm.meta;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.importPasswordProtectedTitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (meta != null) ...[
            Text(
              l10n.importExportedLine(
                formatBackupExportedAt(context, meta.exportedAt),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.importIncludesLine(_contentTypesLabel(l10n, meta)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
          ],
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.exportPasswordLabel,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submitPassword(),
          ),
          if (_vm.importErrorKind != null) ...[
            const SizedBox(height: 12),
            Text(
              _localizedImportError(l10n, _vm),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitPassword,
            child: Text(l10n.importDecrypt),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop<void>(),
            child: Text(l10n.importCancel),
          ),
        ],
      ),
    );
  }

  void _submitPassword() {
    FocusScope.of(context).unfocus();
    _vm.submitPassword(_passwordController.text);
  }

  Widget _buildPreviewStep(BuildContext context, AppLocalizations l10n) {
    final preview = _vm.preview;
    if (preview == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.importBackupSummary,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.importPreviewCounts(
                          preview.totalPeriods,
                          preview.totalEntries,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (preview.duplicateEntries > 0)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.importDupWarning(
                                  preview.duplicateEntries,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(l10n.importNoDupMessage),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _onPreviewContinue,
            child: Text(l10n.onbContinue),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyStep(BuildContext context, AppLocalizations l10n) {
    final preview = _vm.preview;
    final dup = preview?.duplicateEntries ?? 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.importStrategyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.importStrategyExplainer(dup),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<DuplicateStrategy>(
                    segments: [
                      ButtonSegment<DuplicateStrategy>(
                        value: DuplicateStrategy.skip,
                        label: Text(l10n.importSegmentKeep),
                        tooltip: l10n.importTooltipKeep,
                      ),
                      ButtonSegment<DuplicateStrategy>(
                        value: DuplicateStrategy.replace,
                        label: Text(l10n.importSegmentUseImported),
                        tooltip: l10n.importTooltipReplace,
                      ),
                    ],
                    selected: {_vm.strategy},
                    onSelectionChanged: (selection) {
                      if (selection.isNotEmpty) {
                        _vm.selectStrategy(selection.first);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _vm.strategy == DuplicateStrategy.skip
                        ? l10n.importStrategyHintKeep
                        : l10n.importStrategyHintReplace,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: () => _vm.applyImport(),
            child: Text(l10n.importImportCta),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop<void>(),
            child: Text(l10n.importCancel),
          ),
        ],
      ),
    );
  }

  Widget _buildImportingStep(BuildContext context, AppLocalizations l10n) {
    final showBackupPhase = !_vm.seenProgressDuringImport;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showBackupPhase)
            const LinearProgressIndicator()
          else
            LinearProgressIndicator(value: _vm.progress),
          const SizedBox(height: 24),
          Text(
            showBackupPhase
                ? l10n.importCreatingSafetyBackup
                : l10n.importImportingEntries,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep(BuildContext context, AppLocalizations l10n) {
    final r = _vm.result;
    if (r == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.importResultSummary(
              r.periodsCreated,
              r.entriesCreated,
              r.entriesSkipped,
              r.entriesReplaced,
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).pop<void>(),
            child: Text(l10n.exportDone),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStep(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            _localizedImportError(l10n, _vm),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () async {
              _vm.reset();
              await _vm.pickFile();
            },
            child: Text(l10n.importTryAgain),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop<void>(),
            child: Text(l10n.importClose),
          ),
        ],
      ),
    );
  }
}

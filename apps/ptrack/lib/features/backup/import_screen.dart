import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import 'import_view_model.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import in progress. Please wait.')),
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

  String _contentTypesLabel(LumaExportMeta? meta) {
    if (meta == null || meta.contentTypes.isEmpty) {
      return 'Periods and entries';
    }
    return meta.contentTypes.join(', ');
  }

  @override
  Widget build(BuildContext context) {
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
              title: const Text('Import Backup'),
              leading: _vm.step == ImportStep.importing
                  ? const SizedBox.shrink()
                  : null,
            ),
            body: SafeArea(child: _buildBody(context)),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_vm.step) {
      case ImportStep.idle:
      case ImportStep.pickingFile:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Selecting file…'),
            ],
          ),
        );
      case ImportStep.passwordPrompt:
        return _buildPasswordStep(context);
      case ImportStep.previewing:
        return _buildPreviewStep(context);
      case ImportStep.chooseStrategy:
        return _buildStrategyStep(context);
      case ImportStep.importing:
        return _buildImportingStep(context);
      case ImportStep.done:
        return _buildDoneStep(context);
      case ImportStep.error:
        return _buildErrorStep(context);
    }
  }

  Widget _buildPasswordStep(BuildContext context) {
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
            'This backup is password-protected',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (meta != null) ...[
            Text(
              'Exported: ${meta.exportedAt.toLocal().toString().split('.').first}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Includes: ${_contentTypesLabel(meta)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
          ],
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submitPassword(),
          ),
          if (_vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _vm.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitPassword,
            child: const Text('Decrypt'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop<void>(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _submitPassword() {
    FocusScope.of(context).unfocus();
    _vm.submitPassword(_passwordController.text);
  }

  Widget _buildPreviewStep(BuildContext context) {
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
                        'Backup summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Found ${preview.totalPeriods} period(s) and '
                        '${preview.totalEntries} day entries.',
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
                                '${preview.duplicateEntries} entries match dates '
                                'you already logged on this device.',
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
                            const Expanded(
                              child: Text(
                                'No duplicates found — all entries are new for '
                                'your existing dates.',
                              ),
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyStep(BuildContext context) {
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
                    'How should duplicates be handled?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duplicate means the same calendar day already has a log entry '
                    'on this device. $dup entries are affected.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<DuplicateStrategy>(
                    segments: const [
                      ButtonSegment<DuplicateStrategy>(
                        value: DuplicateStrategy.skip,
                        label: Text('Keep existing'),
                        tooltip:
                            'Entries already on your device stay unchanged. '
                            'Only new dates are imported.',
                      ),
                      ButtonSegment<DuplicateStrategy>(
                        value: DuplicateStrategy.replace,
                        label: Text('Use imported'),
                        tooltip:
                            'Entries from the backup replace your current data '
                            'for matching dates.',
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
                        ? 'Entries already on your device stay unchanged. Only '
                            'new dates are imported.'
                        : 'Entries from the backup replace your current data for '
                            'matching dates.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: () => _vm.applyImport(),
            child: const Text('Import'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop<void>(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildImportingStep(BuildContext context) {
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
                ? 'Creating safety backup…'
                : 'Importing entries…',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep(BuildContext context) {
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
            '${r.periodsCreated} period(s) imported, ${r.entriesCreated} new '
            'entries, ${r.entriesSkipped} skipped, ${r.entriesReplaced} replaced.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).pop<void>(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStep(BuildContext context) {
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
            _vm.errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () async {
              _vm.reset();
              await _vm.pickFile();
            },
            child: const Text('Try again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop<void>(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

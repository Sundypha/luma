import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import '../../l10n/app_localizations.dart';

/// Settings UI to list, create, rename, and delete diary tags.
class DiaryTagsSettingsScreen extends StatefulWidget {
  const DiaryTagsSettingsScreen({super.key, required this.diaryRepository});

  final DiaryRepository diaryRepository;

  @override
  State<DiaryTagsSettingsScreen> createState() =>
      _DiaryTagsSettingsScreenState();
}

class _DiaryTagsSettingsScreenState extends State<DiaryTagsSettingsScreen> {
  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocus = FocusNode();

  @override
  void dispose() {
    _addController.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  Future<void> _submitNewTag(BuildContext context, AppLocalizations l10n) async {
    final value = _addController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.diaryTagsErrorEmpty)),
      );
      return;
    }
    try {
      await widget.diaryRepository.createTag(value);
      if (!context.mounted) return;
      _addController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.diaryTagsAddedSnackbar)),
      );
    } on ArgumentError {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.diaryTagsErrorDuplicate)),
      );
    }
  }

  Future<void> _showRenameDialog(BuildContext context, DiaryTag tag) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: tag.name);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.diaryTagsRenameTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.diaryTagsAddLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty || name == tag.name) {
                  Navigator.of(dialogContext).pop();
                  return;
                }
                try {
                  await widget.diaryRepository.renameTag(tag.id, name);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                } on ArgumentError {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(l10n.diaryTagsErrorDuplicate)),
                  );
                }
              },
              child: Text(l10n.diaryTagsRenameConfirm),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  Future<void> _confirmDeleteTag(
    BuildContext context,
    AppLocalizations l10n,
    DiaryTag tag,
  ) async {
    final count = await widget.diaryRepository.entryCountForTag(tag.id);
    if (!context.mounted) return;
    final body = count > 0
        ? l10n.diaryTagsDeleteBodyWithCount(count)
        : l10n.diaryTagsDeleteBodyEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.diaryTagsDeleteTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await widget.diaryRepository.deleteTag(tag.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.diaryTagsDeletedSnackbar)),
    );
  }

  Widget _addTagBar(BuildContext context, AppLocalizations l10n) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _addController,
                focusNode: _addFocus,
                decoration: InputDecoration(
                  labelText: l10n.diaryTagsAddLabel,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitNewTag(context, l10n),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: () => _submitNewTag(context, l10n),
              child: Text(l10n.diaryTagsAddButton),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.diaryTagsSettingsTitle)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<DiaryTag>>(
              stream: widget.diaryRepository.watchTags(),
              builder: (context, snapshot) {
                final tags = snapshot.data ?? [];
                if (tags.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.diaryTagsEmptyState,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          IconButton.filledTonal(
                            onPressed: () => _addFocus.requestFocus(),
                            icon: const Icon(Icons.add),
                            tooltip: l10n.diaryTagsAddButton,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return ListTile(
                      title: Text(tag.name),
                      onLongPress: () => _showRenameDialog(context, tag),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: l10n.diaryTagsRenameTitle,
                            onPressed: () => _showRenameDialog(context, tag),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: l10n.commonDelete,
                            onPressed: () =>
                                _confirmDeleteTag(context, l10n, tag),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _addTagBar(context, l10n),
        ],
      ),
    );
  }
}

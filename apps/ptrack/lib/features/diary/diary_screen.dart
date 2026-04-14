import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import '../../l10n/app_localizations.dart';
import 'diary_form_sheet.dart';
import 'diary_view_model.dart';

/// App bar actions for the Diary tab (date-range filter).
List<Widget> diaryTabAppBarActions(BuildContext context, DiaryViewModel vm) {
  final l10n = AppLocalizations.of(context);
  return [
    IconButton(
      icon: Icon(
        Icons.filter_list,
        color: vm.dateFilter != null
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
      tooltip: l10n.diaryFilterIconTooltip,
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          initialDateRange: vm.dateFilter,
        );
        if (picked != null) vm.setDateFilter(picked);
      },
    ),
  ];
}

/// FAB for creating or editing today's diary entry from the shell.
Widget diaryTabFloatingActionButton(BuildContext context, DiaryViewModel vm) {
  final l10n = AppLocalizations.of(context);
  return FloatingActionButton(
    onPressed: () async {
      final now = DateTime.now();
      // Match [showDiaryFormSheet]'s calendar key: local Y-M-D as UTC midnight.
      final dayKey = DateTime.utc(now.year, now.month, now.day);
      final existing = await vm.diaryRepository.getEntryForDate(dayKey);
      if (!context.mounted) return;
      await showDiaryFormSheet(
        context,
        diaryRepository: vm.diaryRepository,
        day: now,
        existing: existing,
      );
    },
    tooltip: l10n.diaryFormTitleNew,
    child: const Icon(Icons.add),
  );
}

/// Paginated diary browser with search, tag chips, and optional date-range filter.
/// Used inside [TabShell]; app bar and FAB are provided by the shell.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key, required this.viewModel});

  final DiaryViewModel viewModel;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final ScrollController _scrollController = ScrollController();

  DiaryViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _vm.addListener(_onVmChanged);
  }

  void _onVmChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent - pos.pixels < 200) {
      unawaited(_vm.loadNextPage());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _vm.removeListener(_onVmChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.diaryListSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _vm.updateSearch,
          ),
        ),
        StreamBuilder<List<DiaryTag>>(
          stream: _vm.diaryRepository.watchTags(),
          builder: (context, snap) {
            final tags = snap.data;
            if (tags == null || tags.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final tag in tags)
                      FilterChip(
                        label: Text(tag.name),
                        selected: _vm.activeTagIds.contains(tag.id),
                        onSelected: (_) => _vm.toggleTag(tag.id),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_vm.dateFilter != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(
                  l10n.diaryDateFilterActive(
                    loc.formatMediumDate(_vm.dateFilter!.start),
                    loc.formatMediumDate(_vm.dateFilter!.end),
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _vm.setDateFilter(null),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        Expanded(
          child: ListenableBuilder(
            listenable: _vm,
            builder: (context, _) {
              if (_vm.filteredEntries.isEmpty &&
                  _vm.hasActiveFilters &&
                  !_vm.isLoadingMore) {
                return Center(
                  child: Text(
                    l10n.diaryListNoMatches,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (_vm.filteredEntries.isEmpty &&
                  !_vm.hasActiveFilters &&
                  !_vm.isLoadingMore &&
                  !_vm.hasMore) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 56,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.diaryListEmptyHint,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              if (_vm.filteredEntries.isEmpty &&
                  !_vm.hasActiveFilters &&
                  _vm.isLoadingMore) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                controller: _scrollController,
                itemCount: _vm.filteredEntries.length + (_vm.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _vm.filteredEntries.length) {
                    if (!_vm.hasMore) return const SizedBox.shrink();
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final entry = _vm.filteredEntries[index];
                  return _DiaryEntryCard(
                    entry: entry,
                    diaryRepository: _vm.diaryRepository,
                    onAfterEdit: () => _vm.reload(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  const _DiaryEntryCard({
    required this.entry,
    required this.diaryRepository,
    required this.onAfterEdit,
  });

  final StoredDiaryEntry entry;
  final DiaryRepository diaryRepository;
  final Future<void> Function() onAfterEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final formattedDate = loc.formatMediumDate(entry.data.dateUtc.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () async {
          await showDiaryFormSheet(
            context,
            diaryRepository: diaryRepository,
            day: entry.data.dateUtc,
            existing: entry,
          );
          await onAfterEdit();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    formattedDate,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (entry.data.mood != null) ...[
                    const Spacer(),
                    Text(
                      entry.data.mood!.emoji,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
              if (entry.data.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  entry.data.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final tag in entry.tags)
                      Chip(
                        label: Text(tag.name),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

const _kPageSize = 30;

class DiaryViewModel extends ChangeNotifier {
  DiaryViewModel(this.diaryRepository) {
    unawaited(loadNextPage());
  }

  final DiaryRepository diaryRepository;

  final List<StoredDiaryEntry> _loadedEntries = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int get _currentOffset => _loadedEntries.length;

  String _searchQuery = '';
  Set<int> _activeTagIds = {};
  DateTimeRange? _dateFilter;

  List<StoredDiaryEntry> _filteredEntries = [];

  List<StoredDiaryEntry> get filteredEntries => _filteredEntries;
  String get searchQuery => _searchQuery;
  Set<int> get activeTagIds => _activeTagIds;
  DateTimeRange? get dateFilter => _dateFilter;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    final page = await diaryRepository.getEntriesPage(
      offset: _currentOffset,
      limit: _kPageSize,
    );
    _loadedEntries.addAll(page);
    _hasMore = page.length == _kPageSize;
    _isLoadingMore = false;
    _rebuildFiltered();
  }

  Future<void> reload() async {
    _loadedEntries.clear();
    _hasMore = true;
    await loadNextPage();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _rebuildFiltered();
  }

  void toggleTag(int tagId) {
    if (_activeTagIds.contains(tagId)) {
      _activeTagIds = {..._activeTagIds}..remove(tagId);
    } else {
      _activeTagIds = {..._activeTagIds, tagId};
    }
    _rebuildFiltered();
  }

  void setDateFilter(DateTimeRange? range) {
    _dateFilter = range;
    _rebuildFiltered();
  }

  void clearFilters() {
    _searchQuery = '';
    _activeTagIds = {};
    _dateFilter = null;
    _rebuildFiltered();
  }

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _activeTagIds.isNotEmpty || _dateFilter != null;

  void _rebuildFiltered() {
    var result = List<StoredDiaryEntry>.from(_loadedEntries);
    if (_searchQuery.isNotEmpty) {
      final lower = _searchQuery.toLowerCase();
      result = result
          .where((e) => e.data.notes?.toLowerCase().contains(lower) == true)
          .toList();
    }
    if (_activeTagIds.isNotEmpty) {
      result = result
          .where((e) => e.tags.any((t) => _activeTagIds.contains(t.id)))
          .toList();
    }
    if (_dateFilter != null) {
      final start = DateUtils.dateOnly(_dateFilter!.start);
      final end = DateUtils.dateOnly(_dateFilter!.end);
      result = result.where((e) {
        final d = DateUtils.dateOnly(e.data.dateUtc.toLocal());
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
    }
    _filteredEntries = result;
    notifyListeners();
  }
}

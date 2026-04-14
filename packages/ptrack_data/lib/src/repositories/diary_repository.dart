import 'dart:async';

import 'package:drift/drift.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../db/ptrack_database.dart';

/// A persisted diary entry row with its tags.
class StoredDiaryEntry {
  const StoredDiaryEntry({
    required this.id,
    required this.data,
    required this.tags,
  });

  final int id;
  final DiaryEntryData data;
  final List<DiaryTag> tags;
}

/// CRUD and reactive streams for the standalone diary table.
class DiaryRepository {
  DiaryRepository({required PtrackDatabase database}) : _db = database;

  final PtrackDatabase _db;

  // ── Diary entries ─────────────────────────────────────────────────────────

  /// Stream of all diary entries (ordered by date desc) with their tags.
  Stream<List<StoredDiaryEntry>> watchAllEntries() {
    return _db.select(_db.diaryEntries).watch().asyncMap(_storedEntriesFromRows);
  }

  /// Loads every diary entry with tags, newest first.
  Future<List<StoredDiaryEntry>> getAllEntries() async {
    final rows = await (_db.select(_db.diaryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.dateUtc)]))
        .get();
    return _storedEntriesFromRows(rows);
  }

  Future<List<StoredDiaryEntry>> _storedEntriesFromRows(
    List<DiaryEntryRow> rows,
  ) async {
    final sorted = rows.toList()
      ..sort((a, b) => b.dateUtc.compareTo(a.dateUtc));
    final result = <StoredDiaryEntry>[];
    for (final row in sorted) {
      final tags = await _tagsForEntry(row.id);
      result.add(_rowToStored(row, tags));
    }
    return result;
  }

  /// Returns a page of diary entries for paginated display (ordered by date desc).
  /// [offset] is the number of entries to skip; [limit] is the page size.
  Future<List<StoredDiaryEntry>> getEntriesPage({
    required int offset,
    required int limit,
  }) async {
    final rows = await (_db.select(_db.diaryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.dateUtc)])
          ..limit(limit, offset: offset))
        .get();
    return _storedEntriesFromRows(rows);
  }

  /// Stream of diary entries matching [query] in notes text and/or [tagIds].
  /// Pass empty [tagIds] to skip tag filter; pass empty [query] to skip text filter.
  Stream<List<StoredDiaryEntry>> watchFilteredEntries({
    String query = '',
    List<int> tagIds = const [],
  }) {
    return watchAllEntries().map((entries) {
      var filtered = entries;
      if (query.isNotEmpty) {
        final lower = query.toLowerCase();
        filtered = filtered
            .where((e) => e.data.notes?.toLowerCase().contains(lower) == true)
            .toList();
      }
      if (tagIds.isNotEmpty) {
        filtered = filtered
            .where((e) => e.tags.any((t) => tagIds.contains(t.id)))
            .toList();
      }
      return filtered;
    });
  }

  /// Returns the diary entry for [dateUtc] (midnight UTC), or null if absent.
  Future<StoredDiaryEntry?> getEntryForDate(DateTime dateUtc) async {
    final norm = _midnight(dateUtc);
    final row = await (_db.select(_db.diaryEntries)
          ..where((t) => t.dateUtc.equals(norm)))
        .getSingleOrNull();
    if (row == null) return null;
    final tags = await _tagsForEntry(row.id);
    return _rowToStored(row, tags);
  }

  /// Upserts a diary entry for [data.dateUtc] with [tagIds].
  /// Returns the entry id.
  Future<int> saveEntry(DiaryEntryData data, {List<int> tagIds = const []}) async {
    final norm = _midnight(data.dateUtc);
    return _db.transaction(() async {
      final existing = await (_db.select(_db.diaryEntries)
            ..where((t) => t.dateUtc.equals(norm)))
          .getSingleOrNull();

      final int id;
      if (existing != null) {
        await (_db.update(_db.diaryEntries)
              ..where((t) => t.id.equals(existing.id)))
            .write(DiaryEntriesCompanion(
          mood: Value(data.mood?.dbValue),
          notes: Value(data.notes),
        ));
        id = existing.id;
      } else {
        id = await _db.into(_db.diaryEntries).insert(
              DiaryEntriesCompanion.insert(
                dateUtc: norm,
                mood: Value(data.mood?.dbValue),
                notes: Value(data.notes),
              ),
            );
      }

      await (_db.delete(_db.diaryEntryTagJoin)
            ..where((t) => t.diaryEntryId.equals(id)))
          .go();
      for (final tagId in tagIds) {
        await _db.into(_db.diaryEntryTagJoin).insert(
              DiaryEntryTagJoinCompanion.insert(
                diaryEntryId: id,
                tagId: tagId,
              ),
            );
      }
      return id;
    });
  }

  /// Deletes the diary entry with [id] and its tag associations.
  Future<bool> deleteEntry(int id) async {
    await (_db.delete(_db.diaryEntryTagJoin)
          ..where((t) => t.diaryEntryId.equals(id)))
        .go();
    final count = await (_db.delete(_db.diaryEntries)
          ..where((t) => t.id.equals(id)))
        .go();
    return count > 0;
  }

  // ── Tags ──────────────────────────────────────────────────────────────────

  /// Stream of all diary tags ordered by name.
  Stream<List<DiaryTag>> watchTags() {
    return (_db.select(_db.diaryTags)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(_tagRowToDomain).toList());
  }

  /// Creates a new tag with [name] (trims whitespace). Returns the new id.
  /// Throws if name is empty or already exists.
  Future<int> createTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Tag name must not be empty');
    }
    final clash = await (_db.select(_db.diaryTags)
          ..where((t) => t.name.equals(trimmed)))
        .getSingleOrNull();
    if (clash != null) {
      throw ArgumentError.value(name, 'name', 'Tag already exists');
    }
    return _db.into(_db.diaryTags).insert(
          DiaryTagsCompanion.insert(name: trimmed),
        );
  }

  /// Renames tag [id] to [newName].
  Future<void> renameTag(int id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(newName, 'newName', 'Tag name must not be empty');
    }
    await (_db.update(_db.diaryTags)..where((t) => t.id.equals(id)))
        .write(DiaryTagsCompanion(name: Value(trimmed)));
  }

  /// Deletes tag [id] and removes all its associations from diary entries.
  Future<void> deleteTag(int id) async {
    await (_db.delete(_db.diaryEntryTagJoin)
          ..where((t) => t.tagId.equals(id)))
        .go();
    await (_db.delete(_db.diaryTags)..where((t) => t.id.equals(id))).go();
  }

  /// Returns how many diary entries use tag [id].
  Future<int> entryCountForTag(int id) async {
    final rows = await (_db.select(_db.diaryEntryTagJoin)
          ..where((t) => t.tagId.equals(id)))
        .get();
    return rows.length;
  }

  // ── Starter tags ──────────────────────────────────────────────────────────

  /// Inserts the predefined starter tags if the tags table is empty.
  Future<void> seedStarterTags() async {
    final existing = await _db.select(_db.diaryTags).get();
    if (existing.isNotEmpty) return;
    const starters = [
      'Exercise', 'Sleep', 'Stress', 'Diet', 'Hydration',
      'Medication', 'Work', 'Social', 'Travel', 'Self-care', 'Family',
    ];
    for (final name in starters) {
      await _db.into(_db.diaryTags).insert(
            DiaryTagsCompanion.insert(name: name),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DateTime _midnight(DateTime d) {
    final u = d.isUtc ? d : d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  Future<List<DiaryTag>> _tagsForEntry(int entryId) async {
    final joins = await (_db.select(_db.diaryEntryTagJoin)
          ..where((t) => t.diaryEntryId.equals(entryId)))
        .get();
    if (joins.isEmpty) return [];
    final tagIds = joins.map((j) => j.tagId).toList();
    final tags = await (_db.select(_db.diaryTags)
          ..where((t) => t.id.isIn(tagIds))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return tags.map(_tagRowToDomain).toList();
  }

  StoredDiaryEntry _rowToStored(DiaryEntryRow row, List<DiaryTag> tags) {
    return StoredDiaryEntry(
      id: row.id,
      data: DiaryEntryData(
        dateUtc: row.dateUtc,
        mood: row.mood != null ? Mood.fromDbValue(row.mood!) : null,
        notes: row.notes,
      ),
      tags: tags,
    );
  }

  DiaryTag _tagRowToDomain(DiaryTagRow row) =>
      DiaryTag(id: row.id, name: row.name);
}

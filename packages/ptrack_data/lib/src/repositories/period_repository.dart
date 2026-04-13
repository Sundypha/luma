import 'dart:async';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../db/ptrack_database.dart';
import '../mappers/day_entry_mapper.dart';
import '../mappers/period_mapper.dart';

/// A persisted period with its ordered day entries (for UI streams).
@immutable
class StoredPeriodWithDays {
  const StoredPeriodWithDays({
    required this.period,
    required this.dayEntries,
  });

  final StoredPeriod period;
  final List<StoredDayEntry> dayEntries;
}

/// A single persisted day entry row with domain payload.
@immutable
class StoredDayEntry {
  const StoredDayEntry({
    required this.id,
    required this.periodId,
    required this.data,
  });

  final int id;
  final int periodId;
  final DayEntryData data;
}

/// A persisted period row with stable [id] for updates.
@immutable
class StoredPeriod {
  const StoredPeriod({required this.id, required this.span});

  final int id;
  final PeriodSpan span;
}

/// Outcome of an insert or update attempt (validation runs before any write).
sealed class PeriodWriteOutcome {
  const PeriodWriteOutcome();
}

/// Row was written inside a single Drift transaction.
final class PeriodWriteSuccess extends PeriodWriteOutcome {
  const PeriodWriteSuccess(this.id);

  final int id;
}

/// Domain validation failed; the database was not modified.
final class PeriodWriteRejected extends PeriodWriteOutcome {
  const PeriodWriteRejected(this.issues);

  final List<PeriodValidationIssue> issues;
}

/// [updatePeriod] only: no row with the given id.
final class PeriodWriteNotFound extends PeriodWriteOutcome {
  const PeriodWriteNotFound(this.id);

  final int id;
}

/// [updatePeriod] only: day entries would fall outside the new span unless
/// resolved (delete or split into another period).
final class PeriodWriteBlockedByOrphanDayEntries extends PeriodWriteOutcome {
  const PeriodWriteBlockedByOrphanDayEntries({
    required this.periodId,
    required this.orphanEntryIds,
    required this.orphanDatesUtc,
  });

  final int periodId;
  final List<int> orphanEntryIds;
  final List<DateTime> orphanDatesUtc;
}

/// Result of [PeriodRepository.markDay] or [PeriodRepository.unmarkDay].
sealed class DayMarkOutcome {
  const DayMarkOutcome();
}

/// Day mark/unmark completed without a blocking error.
final class DayMarkSuccess extends DayMarkOutcome {
  const DayMarkSuccess({this.periodId});

  /// Primary period affected, when applicable (e.g. merge keeps the lower id).
  final int? periodId;
}

/// Transactional day mark/unmark failed (unexpected DB state).
final class DayMarkFailure extends DayMarkOutcome {
  const DayMarkFailure(this.reason);

  final String reason;
}

/// Validates against existing rows and persists using Drift transactions.
class PeriodRepository {
  PeriodRepository({
    required PtrackDatabase database,
    required PeriodCalendarContext calendar,
  })  : _db = database,
        _calendar = calendar;

  final PtrackDatabase _db;
  final PeriodCalendarContext _calendar;

  /// Direct database access for export and similar tooling.
  PtrackDatabase get database => _db;

  /// All periods ordered by [PeriodSpan.startUtc] ascending.
  Future<List<StoredPeriod>> listOrderedByStartUtc() async {
    final query = _db.select(_db.periods)
      ..orderBy([(t) => OrderingTerm.asc(t.startUtc)]);
    final rows = await query.get();
    return [
      for (final r in rows) StoredPeriod(id: r.id, span: periodRowToDomain(r)),
    ];
  }

  /// Inserts [candidate] after validation, or returns [PeriodWriteRejected].
  Future<PeriodWriteOutcome> insertPeriod(PeriodSpan candidate) {
    return _db.transaction(() async {
      final rows = await (_db.select(_db.periods)
            ..orderBy([(t) => OrderingTerm.asc(t.startUtc)]))
          .get();
      final existing = rows.map(periodRowToDomain).toList();
      final result = PeriodValidation.validateForSave(
        candidate: candidate,
        existing: existing,
        calendar: _calendar,
      );
      if (!result.isValid) {
        return PeriodWriteRejected(result.issues);
      }
      final id = await _db.into(_db.periods).insert(
            periodSpanToInsertCompanion(candidate),
          );
      return PeriodWriteSuccess(id);
    });
  }

  /// Updates the row [id] to [candidate] after validation, or rejects / not-found.
  ///
  /// If any day entry's calendar day falls outside the inclusive new span,
  /// returns [PeriodWriteBlockedByOrphanDayEntries] without writing.
  Future<PeriodWriteOutcome> updatePeriod(int id, PeriodSpan candidate) {
    return _db.transaction(() async {
      final rows = await (_db.select(_db.periods)
            ..orderBy([(t) => OrderingTerm.asc(t.startUtc)]))
          .get();
      final byId = {for (final r in rows) r.id: r};
      if (!byId.containsKey(id)) {
        return PeriodWriteNotFound(id);
      }
      final existing = <PeriodSpan>[
        for (final r in rows)
          if (r.id != id) periodRowToDomain(r),
      ];
      final result = PeriodValidation.validateForSave(
        candidate: candidate,
        existing: existing,
        calendar: _calendar,
      );
      if (!result.isValid) {
        return PeriodWriteRejected(result.issues);
      }
      final blocked = await _orphanDayEntriesOutsideSpan(id, candidate);
      if (blocked != null) {
        return blocked;
      }
      final updated = await (_db.update(_db.periods)
            ..where((t) => t.id.equals(id)))
          .write(periodSpanToUpdateCompanion(candidate));
      if (updated == 0) {
        return PeriodWriteNotFound(id);
      }
      return PeriodWriteSuccess(id);
    });
  }

  /// Deletes listed day rows (must match [updatePeriod]'s orphan report), then
  /// applies the period update.
  Future<PeriodWriteOutcome> updatePeriodDeletingOrphanDayEntries(
    int id,
    PeriodSpan candidate,
    List<int> orphanDayEntryIds,
  ) {
    return _db.transaction(() async {
      final blocked = await _orphanDayEntriesOutsideSpan(id, candidate);
      if (blocked == null) {
        return _updatePeriodAfterOrphansHandled(id, candidate);
      }
      final expected = blocked.orphanEntryIds.toSet();
      if (expected.length != orphanDayEntryIds.length ||
          !orphanDayEntryIds.every(expected.contains)) {
        return PeriodWriteNotFound(id);
      }
      for (final oid in orphanDayEntryIds) {
        await (_db.delete(_db.dayEntries)..where((t) => t.id.equals(oid))).go();
      }
      return _updatePeriodAfterOrphansHandled(id, candidate);
    });
  }

  /// Moves orphan day rows to a new period spanning their min–max calendar
  /// days (inclusive), then applies [candidate] to the original period.
  Future<PeriodWriteOutcome> updatePeriodSplittingOrphansIntoNewPeriod(
    int id,
    PeriodSpan candidate,
    List<int> orphanDayEntryIds,
  ) {
    return _db.transaction(() async {
      final blocked = await _orphanDayEntriesOutsideSpan(id, candidate);
      if (blocked == null) {
        return _updatePeriodAfterOrphansHandled(id, candidate);
      }
      final expected = blocked.orphanEntryIds.toSet();
      if (expected.length != orphanDayEntryIds.length ||
          !orphanDayEntryIds.every(expected.contains)) {
        return PeriodWriteNotFound(id);
      }

      final rows = await (_db.select(_db.periods)
            ..orderBy([(t) => OrderingTerm.asc(t.startUtc)]))
          .get();
      if (!rows.any((r) => r.id == id)) {
        return PeriodWriteNotFound(id);
      }

      final orphanRows = await (_db.select(_db.dayEntries)
            ..where((t) => t.id.isIn(orphanDayEntryIds)))
          .get();
      if (orphanRows.length != orphanDayEntryIds.length) {
        return PeriodWriteNotFound(id);
      }
      for (final r in orphanRows) {
        if (r.periodId != id) {
          return PeriodWriteNotFound(id);
        }
      }

      DateTime cal(DateTime d) => DateTime.utc(d.year, d.month, d.day);

      var minD = cal(orphanRows.first.dateUtc);
      var maxD = minD;
      for (final r in orphanRows) {
        final c = cal(r.dateUtc);
        if (c.isBefore(minD)) minD = c;
        if (c.isAfter(maxD)) maxD = c;
      }
      final newChildSpan = PeriodSpan(startUtc: minD, endUtc: maxD);

      final existingForNewChild = <PeriodSpan>[
        for (final r in rows)
          if (r.id == id) candidate else periodRowToDomain(r),
      ];
      final newChildResult = PeriodValidation.validateForSave(
        candidate: newChildSpan,
        existing: existingForNewChild,
        calendar: _calendar,
      );
      if (!newChildResult.isValid) {
        return PeriodWriteRejected(newChildResult.issues);
      }

      final existingForShrink = <PeriodSpan>[
        for (final r in rows)
          if (r.id != id) periodRowToDomain(r),
      ];
      final shrinkResult = PeriodValidation.validateForSave(
        candidate: candidate,
        existing: existingForShrink,
        calendar: _calendar,
      );
      if (!shrinkResult.isValid) {
        return PeriodWriteRejected(shrinkResult.issues);
      }

      final newPeriodId = await _db.into(_db.periods).insert(
            periodSpanToInsertCompanion(newChildSpan),
          );
      for (final oid in orphanDayEntryIds) {
        await (_db.update(_db.dayEntries)..where((t) => t.id.equals(oid)))
            .write(DayEntriesCompanion(periodId: Value(newPeriodId)));
      }

      final updated = await (_db.update(_db.periods)
            ..where((t) => t.id.equals(id)))
          .write(periodSpanToUpdateCompanion(candidate));
      if (updated == 0) {
        return PeriodWriteNotFound(id);
      }
      return PeriodWriteSuccess(id);
    });
  }

  Future<PeriodWriteOutcome> _updatePeriodAfterOrphansHandled(
    int id,
    PeriodSpan candidate,
  ) async {
    final rows = await (_db.select(_db.periods)
          ..orderBy([(t) => OrderingTerm.asc(t.startUtc)]))
        .get();
    if (!rows.any((r) => r.id == id)) {
      return PeriodWriteNotFound(id);
    }
    final existing = <PeriodSpan>[
      for (final r in rows)
        if (r.id != id) periodRowToDomain(r),
    ];
    final result = PeriodValidation.validateForSave(
      candidate: candidate,
      existing: existing,
      calendar: _calendar,
    );
    if (!result.isValid) {
      return PeriodWriteRejected(result.issues);
    }
    final blocked = await _orphanDayEntriesOutsideSpan(id, candidate);
    if (blocked != null) {
      return blocked;
    }
    final updated = await (_db.update(_db.periods)
          ..where((t) => t.id.equals(id)))
        .write(periodSpanToUpdateCompanion(candidate));
    if (updated == 0) {
      return PeriodWriteNotFound(id);
    }
    return PeriodWriteSuccess(id);
  }

  Future<PeriodWriteBlockedByOrphanDayEntries?> _orphanDayEntriesOutsideSpan(
    int periodId,
    PeriodSpan span,
  ) async {
    final dayRows = await (_db.select(_db.dayEntries)
          ..where((t) => t.periodId.equals(periodId)))
        .get();
    final orphans = <DayEntry>[];
    for (final r in dayRows) {
      final d = DateTime.utc(
        r.dateUtc.year,
        r.dateUtc.month,
        r.dateUtc.day,
      );
      if (!span.containsCalendarDayUtc(d)) {
        orphans.add(r);
      }
    }
    if (orphans.isEmpty) return null;
    return PeriodWriteBlockedByOrphanDayEntries(
      periodId: periodId,
      orphanEntryIds: [for (final o in orphans) o.id],
      orphanDatesUtc: [
        for (final o in orphans)
          DateTime.utc(
            o.dateUtc.year,
            o.dateUtc.month,
            o.dateUtc.day,
          ),
      ],
    );
  }

  Future<void> _pruneDiaryIfNoDayEntryOnCalendarDay(DateTime calendarUtc) async {
    final cal = DateTime.utc(
      calendarUtc.year,
      calendarUtc.month,
      calendarUtc.day,
    );
    final remaining = await (_db.select(_db.dayEntries)
          ..where((t) => t.dateUtc.equals(cal)))
        .get();
    if (remaining.isEmpty) {
      await (_db.delete(_db.diaryEntries)..where((t) => t.dateUtc.equals(cal)))
          .go();
    }
  }

  Future<bool> _diaryHasNonEmptyNotes(DateTime calendarUtc) async {
    final cal = DateTime.utc(
      calendarUtc.year,
      calendarUtc.month,
      calendarUtc.day,
    );
    final d = await (_db.select(_db.diaryEntries)
          ..where((t) => t.dateUtc.equals(cal)))
        .getSingleOrNull();
    final t = d?.notes?.trim();
    return t != null && t.isNotEmpty;
  }

  /// Reactive list of periods (newest [PeriodSpan.startUtc] first) with nested
  /// day entries ([dateUtc] ascending). Updates when either table changes.
  Stream<List<StoredPeriodWithDays>> watchPeriodsWithDays() {
    final controller = StreamController<List<StoredPeriodWithDays>>();
    StreamSubscription<void>? periodSub;
    StreamSubscription<void>? daySub;
    List<StoredPeriodWithDays>? lastEmitted;

    bool sameSnapshot(
      List<StoredPeriodWithDays>? a,
      List<StoredPeriodWithDays> b,
    ) {
      if (a == null) return false;
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i].period.id != b[i].period.id) return false;
        if (a[i].period.span != b[i].period.span) return false;
        final ad = a[i].dayEntries;
        final bd = b[i].dayEntries;
        if (ad.length != bd.length) return false;
        for (var j = 0; j < ad.length; j++) {
          if (ad[j].id != bd[j].id || ad[j].data != bd[j].data) {
            return false;
          }
        }
      }
      return true;
    }

    Future<List<StoredPeriodWithDays>> load() async {
      // Two SQL round-trips per refresh: periods + batched day_entries for all ids.
      final periodRows = await (_db.select(_db.periods)
            ..orderBy([(t) => OrderingTerm.desc(t.startUtc)]))
          .get();
      if (periodRows.isEmpty) {
        return [];
      }

      final periodIds = [for (final r in periodRows) r.id];
      final allDayRows = await (_db.select(_db.dayEntries)
            ..where((t) => t.periodId.isIn(periodIds))
            ..orderBy([
              (t) => OrderingTerm.asc(t.periodId),
              (t) => OrderingTerm.asc(t.dateUtc),
            ]))
          .get();

      final byPeriodId = <int, List<DayEntry>>{};
      for (final d in allDayRows) {
        byPeriodId.putIfAbsent(d.periodId, () => []).add(d);
      }

      return [
        for (final r in periodRows)
          StoredPeriodWithDays(
            period: StoredPeriod(id: r.id, span: periodRowToDomain(r)),
            dayEntries: () {
              final out = <StoredDayEntry>[];
              for (final d in (byPeriodId[r.id] ?? const <DayEntry>[])) {
                out.add(
                  StoredDayEntry(
                    id: d.id,
                    periodId: d.periodId,
                    data: dayEntryRowToDomain(d),
                  ),
                );
              }
              return out;
            }(),
          ),
      ];
    }

    void scheduleEmit() {
      scheduleMicrotask(() async {
        if (controller.isClosed) return;
        try {
          final next = await load();
          if (sameSnapshot(lastEmitted, next)) return;
          lastEmitted = next;
          controller.add(next);
        } on Object catch (e, st) {
          if (!controller.isClosed) {
            controller.addError(e, st);
          }
        }
      });
    }

    controller.onListen = () {
      periodSub = (_db.select(_db.periods)
            ..orderBy([(t) => OrderingTerm.desc(t.startUtc)]))
          .watch()
          .map((_) {})
          .listen((_) => scheduleEmit());
      daySub = _db.select(_db.dayEntries).watch().map((_) {}).listen((_) {
        scheduleEmit();
      });
    };

    controller.onCancel = () {
      periodSub?.cancel();
      daySub?.cancel();
      periodSub = null;
      daySub = null;
    };

    return controller.stream;
  }

  /// Deletes [periodId] and all of its day entries in one transaction.
  Future<bool> deletePeriod(int periodId) {
    return _db.transaction(() async {
      final days = await (_db.select(_db.dayEntries)
            ..where((t) => t.periodId.equals(periodId)))
          .get();
      final affectedDates = <DateTime>{
        for (final d in days)
          DateTime.utc(d.dateUtc.year, d.dateUtc.month, d.dateUtc.day),
      };
      await (_db.delete(_db.dayEntries)
            ..where((t) => t.periodId.equals(periodId)))
          .go();
      final removed = await (_db.delete(_db.periods)
            ..where((t) => t.id.equals(periodId)))
          .go();
      for (final date in affectedDates) {
        await _pruneDiaryIfNoDayEntryOnCalendarDay(date);
      }
      return removed > 0;
    });
  }

  /// Inserts a day entry under [periodId]; throws [StateError] if the period
  /// does not exist.
  Future<int> saveDayEntry(int periodId, DayEntryData data) {
    return _db.transaction(() async {
      final rows = await (_db.select(_db.periods)
            ..where((t) => t.id.equals(periodId)))
          .get();
      if (rows.isEmpty) {
        throw StateError('No period with id $periodId');
      }
      final id = await _db
          .into(_db.dayEntries)
          .insert(dayEntryDataToInsertCompanion(periodId, data));
      return id;
    });
  }

  /// Inserts or updates the row for [periodId] on the calendar day of
  /// [data.dateUtc] (unique with period). Throws [StateError] if the period
  /// does not exist.
  Future<int> upsertDayEntryForPeriod(int periodId, DayEntryData data) {
    return _db.transaction(() async {
      final periodRows = await (_db.select(_db.periods)
            ..where((t) => t.id.equals(periodId)))
          .get();
      if (periodRows.isEmpty) {
        throw StateError('No period with id $periodId');
      }
      final dateUtc = DateTime.utc(
        data.dateUtc.year,
        data.dateUtc.month,
        data.dateUtc.day,
      );
      final dayRows = await (_db.select(_db.dayEntries)
            ..where((t) => t.periodId.equals(periodId)))
          .get();
      DayEntry? match;
      for (final r in dayRows) {
        final rd = DateTime.utc(r.dateUtc.year, r.dateUtc.month, r.dateUtc.day);
        if (rd == dateUtc) {
          match = r;
          break;
        }
      }
      if (match == null) {
        final id = await _db
            .into(_db.dayEntries)
            .insert(dayEntryDataToInsertCompanion(periodId, data));
        return id;
      }
      final id = match.id;
      await (_db.update(_db.dayEntries)..where((t) => t.id.equals(id)))
          .write(dayEntryDataToUpdateCompanion(data));
      return id;
    });
  }

  /// Updates an existing day entry row; returns whether a row was updated.
  Future<bool> updateDayEntry(int dayEntryId, DayEntryData data) async {
    final updated = await (_db.update(_db.dayEntries)
          ..where((t) => t.id.equals(dayEntryId)))
        .write(dayEntryDataToUpdateCompanion(data));
    return updated > 0;
  }

  /// Deletes a single day entry row; returns whether a row was removed.
  Future<bool> deleteDayEntry(int dayEntryId) async {
    final row = await (_db.select(_db.dayEntries)
          ..where((t) => t.id.equals(dayEntryId)))
        .getSingleOrNull();
    if (row == null) return false;
    final cal = DateTime.utc(
      row.dateUtc.year,
      row.dateUtc.month,
      row.dateUtc.day,
    );
    final count = await (_db.delete(_db.dayEntries)
          ..where((t) => t.id.equals(dayEntryId)))
        .go();
    if (count > 0) {
      await _pruneDiaryIfNoDayEntryOnCalendarDay(cal);
    }
    return count > 0;
  }

  /// Clears flow, pain, mood, and clinical notes for [dayEntryId].
  ///
  /// If a non-empty diary note exists for that calendar day, the row is kept
  /// with only symptoms cleared. Otherwise the row is deleted.
  Future<bool> clearClinicalSymptoms(int dayEntryId) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.dayEntries)
            ..where((t) => t.id.equals(dayEntryId)))
          .getSingleOrNull();
      if (row == null) return false;
      final cal = DateTime.utc(
        row.dateUtc.year,
        row.dateUtc.month,
        row.dateUtc.day,
      );
      final hasPersonal = await _diaryHasNonEmptyNotes(cal);
      if (hasPersonal) {
        await (_db.update(_db.dayEntries)..where((t) => t.id.equals(dayEntryId)))
            .write(
          DayEntriesCompanion(
            flowIntensity: const Value<int?>(null),
            painScore: const Value<int?>(null),
            mood: const Value<int?>(null),
            notes: const Value<String?>(null),
          ),
        );
        return true;
      }
      final count = await (_db.delete(_db.dayEntries)
            ..where((t) => t.id.equals(dayEntryId)))
          .go();
      return count > 0;
    });
  }

  /// Marks [day] (UTC calendar date) as bleeding: create, extend, merge, or no-op.
  Future<DayMarkOutcome> markDay(DateTime day) {
    return _db.transaction(() async {
      final dayN = _utcCalendarDay(day);
      final records = await _spanRecordsOrderedByStart();
      final op = computeMarkDay(records, dayN);
      switch (op) {
        case MarkNoOp():
          return const DayMarkSuccess();
        case MarkCreate(:final day):
          final id = await _db.into(_db.periods).insert(
                periodSpanToInsertCompanion(
                  PeriodSpan(startUtc: day, endUtc: day),
                ),
              );
          return DayMarkSuccess(periodId: id);
        case MarkExtend(:final periodId, :final newStart, :final newEnd):
          await (_db.update(_db.periods)..where((t) => t.id.equals(periodId)))
              .write(
            periodSpanToUpdateCompanion(
              PeriodSpan(startUtc: newStart, endUtc: newEnd),
            ),
          );
          return DayMarkSuccess(periodId: periodId);
        case MarkMerge(:final keepId, :final absorbId, :final newStart, :final newEnd):
          await (_db.update(_db.periods)..where((t) => t.id.equals(keepId)))
              .write(
            periodSpanToUpdateCompanion(
              PeriodSpan(startUtc: newStart, endUtc: newEnd),
            ),
          );
          await (_db.update(_db.dayEntries)
                ..where((t) => t.periodId.equals(absorbId)))
              .write(DayEntriesCompanion(periodId: Value(keepId)));
          await (_db.delete(_db.periods)..where((t) => t.id.equals(absorbId)))
              .go();
          return DayMarkSuccess(periodId: keepId);
      }
    });
  }

  /// Unmarks [day] (UTC calendar date): delete, shrink, split, or no-op.
  Future<DayMarkOutcome> unmarkDay(DateTime day) {
    return _db.transaction(() async {
      final dayN = _utcCalendarDay(day);
      final records = await _spanRecordsOrderedByStart();
      final op = computeUnmarkDay(records, dayN);
      switch (op) {
        case UnmarkNoOp():
          return const DayMarkSuccess();
        case UnmarkDelete(:final periodId):
          await (_db.delete(_db.dayEntries)
                ..where((t) => t.periodId.equals(periodId)))
              .go();
          await (_db.delete(_db.periods)..where((t) => t.id.equals(periodId)))
              .go();
          return const DayMarkSuccess();
        case UnmarkShrink(:final periodId, :final newStart, :final newEnd):
          await _deleteDayEntriesOnUtcDay(periodId, dayN);
          await (_db.update(_db.periods)..where((t) => t.id.equals(periodId)))
              .write(
            periodSpanToUpdateCompanion(
              PeriodSpan(startUtc: newStart, endUtc: newEnd),
            ),
          );
          return DayMarkSuccess(periodId: periodId);
        case UnmarkSplit(
            :final originalId,
            :final leftStart,
            :final leftEnd,
            :final rightStart,
            :final rightEnd,
          ):
          final newId = await _db.into(_db.periods).insert(
                periodSpanToInsertCompanion(
                  PeriodSpan(startUtc: rightStart, endUtc: rightEnd),
                ),
              );
          await _moveDayEntriesInUtcRange(
            fromPeriodId: originalId,
            toPeriodId: newId,
            rangeStartUtc: rightStart,
            rangeEndUtc: rightEnd,
          );
          await (_db.update(_db.periods)..where((t) => t.id.equals(originalId)))
              .write(
            periodSpanToUpdateCompanion(
              PeriodSpan(startUtc: leftStart, endUtc: leftEnd),
            ),
          );
          await _deleteDayEntriesOnUtcDay(originalId, dayN);
          return DayMarkSuccess(periodId: originalId);
      }
    });
  }

  DateTime _utcCalendarDay(DateTime d) {
    final u = d.isUtc ? d : d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  Future<List<SpanRecord>> _spanRecordsOrderedByStart() async {
    final rows = await (_db.select(_db.periods)
          ..orderBy([(t) => OrderingTerm.asc(t.startUtc)]))
        .get();
    return [
      for (final r in rows)
        SpanRecord(
          id: r.id,
          start: _utcCalendarDay(r.startUtc),
          end: _utcCalendarDay(r.endUtc ?? r.startUtc),
        ),
    ];
  }

  Future<void> _deleteDayEntriesOnUtcDay(int periodId, DateTime dayUtc) async {
    final target = _utcCalendarDay(dayUtc);
    final rows = await (_db.select(_db.dayEntries)
          ..where((t) => t.periodId.equals(periodId)))
        .get();
    for (final r in rows) {
      if (_utcCalendarDay(r.dateUtc) == target) {
        await (_db.delete(_db.dayEntries)..where((t) => t.id.equals(r.id)))
            .go();
      }
    }
  }

  Future<void> _moveDayEntriesInUtcRange({
    required int fromPeriodId,
    required int toPeriodId,
    required DateTime rangeStartUtc,
    required DateTime rangeEndUtc,
  }) async {
    final rs = _utcCalendarDay(rangeStartUtc);
    final re = _utcCalendarDay(rangeEndUtc);
    final rows = await (_db.select(_db.dayEntries)
          ..where((t) => t.periodId.equals(fromPeriodId)))
        .get();
    for (final r in rows) {
      final d = _utcCalendarDay(r.dateUtc);
      if (!d.isBefore(rs) && !d.isAfter(re)) {
        await (_db.update(_db.dayEntries)..where((t) => t.id.equals(r.id)))
            .write(DayEntriesCompanion(periodId: Value(toPeriodId)));
      }
    }
  }
}

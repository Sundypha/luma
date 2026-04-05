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

/// Validates against existing rows and persists using Drift transactions.
class PeriodRepository {
  PeriodRepository({
    required PtrackDatabase database,
    required PeriodCalendarContext calendar,
  })  : _db = database,
        _calendar = calendar;

  final PtrackDatabase _db;
  final PeriodCalendarContext _calendar;

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
      final updated = await (_db.update(_db.periods)
            ..where((t) => t.id.equals(id)))
          .write(periodSpanToUpdateCompanion(candidate));
      if (updated == 0) {
        return PeriodWriteNotFound(id);
      }
      return PeriodWriteSuccess(id);
    });
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
      final periodRows = await (_db.select(_db.periods)
            ..orderBy([(t) => OrderingTerm.desc(t.startUtc)]))
          .get();
      final result = <StoredPeriodWithDays>[];
      for (final r in periodRows) {
        final dayRows = await (_db.select(_db.dayEntries)
              ..where((t) => t.periodId.equals(r.id))
              ..orderBy([(t) => OrderingTerm.asc(t.dateUtc)]))
            .get();
        final days = [
          for (final d in dayRows)
            StoredDayEntry(
              id: d.id,
              periodId: d.periodId,
              data: dayEntryRowToDomain(d),
            ),
        ];
        result.add(
          StoredPeriodWithDays(
            period: StoredPeriod(id: r.id, span: periodRowToDomain(r)),
            dayEntries: days,
          ),
        );
      }
      return result;
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
      await (_db.delete(_db.dayEntries)
            ..where((t) => t.periodId.equals(periodId)))
          .go();
      final removed = await (_db.delete(_db.periods)
            ..where((t) => t.id.equals(periodId)))
          .go();
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
      return _db
          .into(_db.dayEntries)
          .insert(dayEntryDataToInsertCompanion(periodId, data));
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
    final count = await (_db.delete(_db.dayEntries)
          ..where((t) => t.id.equals(dayEntryId)))
        .go();
    return count > 0;
  }
}

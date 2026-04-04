import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../db/ptrack_database.dart';
import '../mappers/period_mapper.dart';

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
      final rows = await _db.select(_db.periods).get();
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
      final rows = await _db.select(_db.periods).get();
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
}

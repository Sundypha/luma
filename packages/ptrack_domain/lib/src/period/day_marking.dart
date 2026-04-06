import 'package:meta/meta.dart';

/// Lightweight period span for day-marking (no data-layer types).
@immutable
class SpanRecord {
  const SpanRecord({
    required this.id,
    required this.start,
    required this.end,
  });

  /// Stable period identifier from persistence.
  final int id;

  /// Inclusive UTC calendar midnight (start day).
  final DateTime start;

  /// Inclusive UTC calendar midnight (end day).
  final DateTime end;
}

sealed class DayMarkOp {
  const DayMarkOp();
}

/// Mark request is a no-op (already marked or invalid state).
@immutable
final class MarkNoOp extends DayMarkOp {
  const MarkNoOp();
}

/// Create a new single-day period on [day].
@immutable
final class MarkCreate extends DayMarkOp {
  const MarkCreate({required this.day});

  final DateTime day;
}

/// Extend an existing period to include [newStart]..[newEnd] (inclusive UTC days).
@immutable
final class MarkExtend extends DayMarkOp {
  const MarkExtend({
    required this.periodId,
    required this.newStart,
    required this.newEnd,
  });

  final int periodId;
  final DateTime newStart;
  final DateTime newEnd;
}

/// Merge [absorbId] into [keepId]; resulting span is [newStart]..[newEnd].
@immutable
final class MarkMerge extends DayMarkOp {
  const MarkMerge({
    required this.keepId,
    required this.absorbId,
    required this.newStart,
    required this.newEnd,
  });

  final int keepId;
  final int absorbId;
  final DateTime newStart;
  final DateTime newEnd;
}

sealed class DayUnmarkOp {
  const DayUnmarkOp();
}

/// Unmark request is a no-op (day not in any period).
@immutable
final class UnmarkNoOp extends DayUnmarkOp {
  const UnmarkNoOp();
}

/// Remove a single-day period.
@immutable
final class UnmarkDelete extends DayUnmarkOp {
  const UnmarkDelete({required this.periodId});

  final int periodId;
}

/// Shorten a period by moving one edge inward.
@immutable
final class UnmarkShrink extends DayUnmarkOp {
  const UnmarkShrink({
    required this.periodId,
    required this.newStart,
    required this.newEnd,
  });

  final int periodId;
  final DateTime newStart;
  final DateTime newEnd;
}

/// Split a period by removing an interior day into two spans.
@immutable
final class UnmarkSplit extends DayUnmarkOp {
  const UnmarkSplit({
    required this.originalId,
    required this.leftStart,
    required this.leftEnd,
    required this.rightStart,
    required this.rightEnd,
  });

  final int originalId;
  final DateTime leftStart;
  final DateTime leftEnd;
  final DateTime rightStart;
  final DateTime rightEnd;
}

DateTime _utcDay(DateTime d) {
  final u = d.isUtc ? d : d.toUtc();
  return DateTime.utc(u.year, u.month, u.day);
}

DateTime _nextDay(DateTime dayUtc) => dayUtc.add(const Duration(days: 1));

DateTime _prevDay(DateTime dayUtc) => dayUtc.subtract(const Duration(days: 1));

SpanRecord _normalizeSpan(SpanRecord r) => SpanRecord(
      id: r.id,
      start: _utcDay(r.start),
      end: _utcDay(r.end),
    );

bool _containsDay(SpanRecord r, DateTime dayN) =>
    !dayN.isBefore(r.start) && !dayN.isAfter(r.end);

bool _adjacentAfterEnd(SpanRecord r, DateTime dayN) =>
    _nextDay(r.end) == dayN;

bool _adjacentBeforeStart(SpanRecord r, DateTime dayN) =>
    _prevDay(r.start) == dayN;

List<SpanRecord> _sortedById(Iterable<SpanRecord> xs) {
  final list = xs.toList()..sort((a, b) => a.id.compareTo(b.id));
  return list;
}

/// Derives the span operation for marking [day] (toggle on).
///
/// [existingPeriods] spans are normalized to UTC calendar midnights.
/// Assumes each [SpanRecord] has [start] <= [end].
DayMarkOp computeMarkDay(List<SpanRecord> existingPeriods, DateTime day) {
  // RED stub — replaced in feat commit.
  return const MarkNoOp();
}

/// Derives the span operation for unmarking [day] (toggle off).
DayUnmarkOp computeUnmarkDay(List<SpanRecord> existingPeriods, DateTime day) {
  return const UnmarkNoOp();
}

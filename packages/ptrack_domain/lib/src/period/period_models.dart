import 'package:meta/meta.dart';

/// A stored period as UTC instants: [startUtc] is inclusive; [endUtc], when set,
/// is the inclusive end of bleeding (same-day spans are allowed).
///
/// When [endUtc] is `null`, the period is **open** (ongoing). Open periods must
/// not be passed to helpers that operate on **completed** cycles only—use
/// [PeriodSpan.completedOnly] to filter.
@immutable
class PeriodSpan {
  const PeriodSpan._(this.startUtc, this.endUtc);

  /// Normalizes [startUtc] and [endUtc] to UTC.
  factory PeriodSpan({
    required DateTime startUtc,
    DateTime? endUtc,
  }) {
    final s = startUtc.isUtc ? startUtc : startUtc.toUtc();
    final e = endUtc == null
        ? null
        : (endUtc.isUtc ? endUtc : endUtc.toUtc());
    return PeriodSpan._(s, e);
  }

  final DateTime startUtc;

  /// Inclusive end instant in UTC, or `null` if the period is still open.
  final DateTime? endUtc;

  bool get isOpen => endUtc == null;

  bool get isCompleted => endUtc != null;

  /// Returns only periods with a non-null [endUtc], preserving iteration order.
  static Iterable<PeriodSpan> completedOnly(Iterable<PeriodSpan> periods) sync* {
    for (final p in periods) {
      if (p.isCompleted) yield p;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodSpan &&
          runtimeType == other.runtimeType &&
          startUtc == other.startUtc &&
          endUtc == other.endUtc;

  @override
  int get hashCode => Object.hash(startUtc, endUtc);

  @override
  String toString() => 'PeriodSpan(startUtc: $startUtc, endUtc: $endUtc)';
}

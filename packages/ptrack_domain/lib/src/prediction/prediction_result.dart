import 'package:meta/meta.dart';

/// Structured prediction outcome tiers (Phase 2 CONTEXT). No UI copy.
sealed class PredictionResult {
  const PredictionResult();
}

/// Not enough completed cycles to emit a specific next-start date.
@immutable
final class PredictionInsufficientHistory extends PredictionResult {
  const PredictionInsufficientHistory({
    required this.completedCyclesAvailable,
    required this.minCompletedCyclesNeeded,
  });

  final int completedCyclesAvailable;
  final int minCompletedCyclesNeeded;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionInsufficientHistory &&
          completedCyclesAvailable == other.completedCyclesAvailable &&
          minCompletedCyclesNeeded == other.minCompletedCyclesNeeded;

  @override
  int get hashCode =>
      Object.hash(completedCyclesAvailable, minCompletedCyclesNeeded);
}

/// Range-only / high-variability: no point estimate, uncertainty as an interval.
@immutable
final class PredictionRangeOnly extends PredictionResult {
  const PredictionRangeOnly({
    required this.rangeStartUtc,
    required this.rangeEndUtc,
    this.reasonCode,
  });

  final DateTime rangeStartUtc;
  final DateTime rangeEndUtc;

  /// Optional machine code (e.g. `high_variability`) for UI mapping.
  final String? reasonCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionRangeOnly &&
          rangeStartUtc == other.rangeStartUtc &&
          rangeEndUtc == other.rangeEndUtc &&
          reasonCode == other.reasonCode;

  @override
  int get hashCode =>
      Object.hash(rangeStartUtc, rangeEndUtc, reasonCode);
}

/// Point next-start estimate with optional uncertainty band.
@immutable
final class PredictionPointWithRange extends PredictionResult {
  const PredictionPointWithRange({
    required this.pointStartUtc,
    this.rangeStartUtc,
    this.rangeEndUtc,
  });

  final DateTime pointStartUtc;
  final DateTime? rangeStartUtc;
  final DateTime? rangeEndUtc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionPointWithRange &&
          pointStartUtc == other.pointStartUtc &&
          rangeStartUtc == other.rangeStartUtc &&
          rangeEndUtc == other.rangeEndUtc;

  @override
  int get hashCode =>
      Object.hash(pointStartUtc, rangeStartUtc, rangeEndUtc);
}

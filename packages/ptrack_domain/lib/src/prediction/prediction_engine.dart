import 'package:meta/meta.dart';

import 'explanation_step.dart';
import 'prediction_result.dart';

/// Hard-coded defaults; see [prediction_rules.md].
@immutable
class PredictionThresholds {
  const PredictionThresholds({
    this.longGapDays = 45,
    this.longBleedDays = 10,
    this.outlierMaxDeviationFromMedianDays = 7,
    this.highVariabilityMinSpreadDays = 12,
    this.minCompletedCyclesForPoint = 2,
    this.maxCyclesInWindow = 6,
  });

  /// Cycles longer than this (days) are excluded with reason `long_gap`.
  final int longGapDays;

  /// When [PredictionCycleInput.bleedingDays] is set and exceeds this, exclude as `long_bleed`.
  final int longBleedDays;

  /// Within-window outlier if \|length − median\| exceeds this (days).
  final int outlierMaxDeviationFromMedianDays;

  /// When max(include lengths) − min(include lengths) ≥ this → range-only tier.
  final int highVariabilityMinSpreadDays;

  final int minCompletedCyclesForPoint;
  final int maxCyclesInWindow;

  static const PredictionThresholds standard = PredictionThresholds();
}

/// One completed cycle available for prediction (oldest-first list in [PredictionEngine.predict]).
@immutable
class PredictionCycleInput {
  const PredictionCycleInput({
    required this.periodStartUtc,
    required this.lengthInDays,
    this.bleedingDays,
  });

  final DateTime periodStartUtc;
  final int lengthInDays;

  /// When set, compared to [PredictionThresholds.longBleedDays].
  final int? bleedingDays;
}

/// Engine output: sealed [PredictionResult] plus ordered explanation (PRED-03).
@immutable
class PredictionEngineResult {
  const PredictionEngineResult({
    required this.result,
    required this.explanation,
  });

  final PredictionResult result;
  final List<ExplanationStep> explanation;
}

class _WindowEntry {
  _WindowEntry({
    required this.input,
    required this.windowIndex,
  });

  final PredictionCycleInput input;
  final int windowIndex;
  String? exclusionReason;
}

/// Deterministic median-based next-start prediction (Phase 02-03).
class PredictionEngine {
  const PredictionEngine({this.thresholds = PredictionThresholds.standard});

  final PredictionThresholds thresholds;

  /// Predicts next period start from [completedCyclesOldestFirst] (full history, oldest first).
  PredictionEngineResult predict(
    List<PredictionCycleInput> completedCyclesOldestFirst,
  ) {
    if (completedCyclesOldestFirst.isEmpty) {
      return PredictionEngineResult(
        result: PredictionInsufficientHistory(
          completedCyclesAvailable: 0,
          minCompletedCyclesNeeded: thresholds.minCompletedCyclesForPoint,
        ),
        explanation: [
          ExplanationStep(
            kind: ExplanationFactKind.insufficientHistory,
            payload: {
              'completedCyclesAvailable': 0,
              'minCompletedCyclesNeeded': thresholds.minCompletedCyclesForPoint,
            },
          ),
        ],
      );
    }

    final anchorInput = completedCyclesOldestFirst.last;
    final anchorUtc = anchorInput.periodStartUtc.toUtc();

    final n = completedCyclesOldestFirst.length;
    final start =
        n > thresholds.maxCyclesInWindow ? n - thresholds.maxCyclesInWindow : 0;
    final windowInputs = completedCyclesOldestFirst.sublist(start);

    final entries = <_WindowEntry>[
      for (var i = 0; i < windowInputs.length; i++)
        _WindowEntry(input: windowInputs[i], windowIndex: i),
    ];

    for (final e in entries) {
      final c = e.input;
      if (c.lengthInDays > thresholds.longGapDays) {
        e.exclusionReason = 'long_gap';
      } else if (c.bleedingDays != null &&
          c.bleedingDays! > thresholds.longBleedDays) {
        e.exclusionReason = 'long_bleed';
      }
    }

    var pool = entries.where((e) => e.exclusionReason == null).toList();
    if (pool.length >= 3) {
      final med = _medianInts(
        pool.map((e) => e.input.lengthInDays).toList(),
      );
      for (final e in pool) {
        if ((e.input.lengthInDays - med).abs() >
            thresholds.outlierMaxDeviationFromMedianDays) {
          e.exclusionReason = 'statistical_outlier';
        }
      }
    }

    final included = entries.where((e) => e.exclusionReason == null).toList();
    if (included.length < thresholds.minCompletedCyclesForPoint) {
      return _insufficientWithContext(
        includedCount: included.length,
        entries: entries,
        windowInputs: windowInputs,
        anchorUtc: anchorUtc,
      );
    }

    final lengths = included.map((e) => e.input.lengthInDays).toList();
    final median = _medianInts(lengths);
    final minLen = lengths.reduce((a, b) => a < b ? a : b);
    final maxLen = lengths.reduce((a, b) => a > b ? a : b);
    final spread = maxLen - minLen;

    final explanation = _buildExplanation(
      entries: entries,
      windowInputs: windowInputs,
      median: median,
      minLen: minLen,
      maxLen: maxLen,
      spread: spread,
      anchorUtc: anchorUtc,
    );

    if (spread >= thresholds.highVariabilityMinSpreadDays) {
      final rangeStart = addUtcCalendarDays(anchorUtc, minLen);
      final rangeEnd = addUtcCalendarDays(anchorUtc, maxLen);
      explanation.add(
        ExplanationStep(
          kind: ExplanationFactKind.highVariabilityRange,
          payload: {
            'reasonCode': 'high_variability',
            'rangeStartUtc': rangeStart.toIso8601String(),
            'rangeEndUtc': rangeEnd.toIso8601String(),
            'spreadDays': spread,
            'minLengthDays': minLen,
            'maxLengthDays': maxLen,
          },
        ),
      );
      return PredictionEngineResult(
        result: PredictionRangeOnly(
          rangeStartUtc: rangeStart,
          rangeEndUtc: rangeEnd,
          reasonCode: 'high_variability',
        ),
        explanation: explanation,
      );
    }

    final point = addUtcCalendarDays(anchorUtc, median);
    final rangeStart = addUtcCalendarDays(anchorUtc, minLen);
    final rangeEnd = addUtcCalendarDays(anchorUtc, maxLen);

    return PredictionEngineResult(
      result: PredictionPointWithRange(
        pointStartUtc: point,
        rangeStartUtc: rangeStart,
        rangeEndUtc: rangeEnd,
      ),
      explanation: explanation,
    );
  }

  PredictionEngineResult _insufficientWithContext({
    required int includedCount,
    required List<_WindowEntry> entries,
    required List<PredictionCycleInput> windowInputs,
    required DateTime anchorUtc,
  }) {
    final explanation = <ExplanationStep>[
      _cyclesConsideredStep(windowInputs),
      ..._exclusionSteps(entries),
      ExplanationStep(
        kind: ExplanationFactKind.insufficientHistory,
        payload: {
          'completedCyclesAvailable': includedCount,
          'minCompletedCyclesNeeded': thresholds.minCompletedCyclesForPoint,
          'anchorUtc': anchorUtc.toIso8601String(),
        },
      ),
    ];
    return PredictionEngineResult(
      result: PredictionInsufficientHistory(
        completedCyclesAvailable: includedCount,
        minCompletedCyclesNeeded: thresholds.minCompletedCyclesForPoint,
      ),
      explanation: explanation,
    );
  }

  List<ExplanationStep> _buildExplanation({
    required List<_WindowEntry> entries,
    required List<PredictionCycleInput> windowInputs,
    required int median,
    required int minLen,
    required int maxLen,
    required int spread,
    required DateTime anchorUtc,
  }) {
    return [
      _cyclesConsideredStep(windowInputs),
      ..._exclusionSteps(entries),
      ExplanationStep(
        kind: ExplanationFactKind.medianCycleLength,
        payload: {
          'medianDays': median,
          'includedMinDays': minLen,
          'includedMaxDays': maxLen,
          'spreadDays': spread,
          'anchorUtc': anchorUtc.toIso8601String(),
        },
      ),
    ];
  }

  static ExplanationStep _cyclesConsideredStep(
    List<PredictionCycleInput> windowInputs,
  ) {
    return ExplanationStep(
      kind: ExplanationFactKind.cyclesConsidered,
      payload: {
        'count': windowInputs.length,
        'lengthsInDays': windowInputs.map((c) => c.lengthInDays).toList(),
        'periodStartsUtc':
            windowInputs.map((c) => c.periodStartUtc.toIso8601String()).toList(),
      },
    );
  }

  static Iterable<ExplanationStep> _exclusionSteps(List<_WindowEntry> entries) {
    return entries.where((e) => e.exclusionReason != null).map(
          (e) => ExplanationStep(
            kind: ExplanationFactKind.cycleExcluded,
            payload: {
              'windowIndex': e.windowIndex,
              'lengthInDays': e.input.lengthInDays,
              'exclusionReason': e.exclusionReason,
            },
          ),
        );
  }
}

/// Strips the time component; returns the same calendar day at UTC midnight.
DateTime utcCalendarDateOnly(DateTime utc) {
  final u = utc.toUtc();
  return DateTime.utc(u.year, u.month, u.day);
}

/// Adds [days] whole calendar days in UTC to [utcInstant]'s UTC calendar date.
DateTime addUtcCalendarDays(DateTime utcInstant, int days) {
  final d = utcCalendarDateOnly(utcInstant);
  return d.add(Duration(days: days));
}

int _medianInts(List<int> values) {
  if (values.isEmpty) {
    throw ArgumentError('median of empty list');
  }
  final s = [...values]..sort();
  final n = s.length;
  final mid = n ~/ 2;
  if (n.isOdd) {
    return s[mid];
  }
  return ((s[mid - 1] + s[mid]) / 2).round();
}

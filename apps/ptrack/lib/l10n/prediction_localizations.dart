import 'package:intl/intl.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import 'app_localizations.dart';

/// Localized prediction copy (PRED-04). All user-facing ensemble / coordinator
/// strings are built here from structured domain types.
class PredictionLocalizations {
  PredictionLocalizations._();

  static String _localCalendarDateLabel(AppLocalizations l10n, DateTime utc) {
    final u = utc.toUtc();
    final d = DateTime(u.year, u.month, u.day);
    return DateFormat.yMMMd(l10n.localeName).format(d);
  }

  static String _formatFixedDecimals(
    AppLocalizations l10n,
    double value,
    int fractionDigits,
  ) {
    final fmt = NumberFormat.decimalPattern(l10n.localeName);
    fmt.minimumFractionDigits = fractionDigits;
    fmt.maximumFractionDigits = fractionDigits;
    return fmt.format(value);
  }

  static String _formatIntList(
    AppLocalizations l10n,
    List<Object?> lengths,
  ) {
    final fmt = NumberFormat.decimalPattern(l10n.localeName);
    return lengths.map((e) => fmt.format((e as num).toInt())).join(', ');
  }

  static String algorithmName(AppLocalizations l10n, AlgorithmId id) => switch (id) {
        AlgorithmId.median => l10n.algoNameMedian,
        AlgorithmId.ewma => l10n.algoNameEwma,
        AlgorithmId.bayesian => l10n.algoNameBayesian,
        AlgorithmId.linearTrend => l10n.algoNameLinearTrend,
      };

  static AlgorithmId? _parseAlgorithmId(String? name) {
    if (name == null) return null;
    for (final v in AlgorithmId.values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static String formatDayAgreementSummary(
    AppLocalizations l10n, {
    required int agreementCount,
    required int activeCount,
  }) =>
      l10n.predictionDayAgreement(agreementCount, activeCount);

  static String formatEnsembleMilestone(
    AppLocalizations l10n,
    EnsembleMilestone milestone,
  ) =>
      switch (milestone.kind) {
        EnsembleMilestoneKind.trendDetectionActive => l10n.ensembleMilestoneTrend,
        EnsembleMilestoneKind.allCoreMethodsActive => l10n.ensembleMilestoneAllCore,
        EnsembleMilestoneKind.expandedMethodCount => l10n.ensembleMilestoneExpanded(
            milestone.cycleCount,
            milestone.activeAlgorithmCount,
          ),
      };

  /// Multi-line narrative for the ensemble bottom sheet (mirrors legacy coordinator output).
  static String formatEnsembleExplanation(
    AppLocalizations l10n,
    EnsemblePredictionResult ensemble,
  ) {
    final lines = <String>[l10n.predictionDisclaimer, ''];

    if (ensemble.totalAlgorithmCount == 0) {
      lines.add(l10n.predictionNoMethodsEnabled);
    } else {
      lines.add(
        l10n.predictionNOfMTotalMethods(
          ensemble.algorithmOutputs.length,
          ensemble.totalAlgorithmCount,
        ),
      );
    }

    for (final o in ensemble.algorithmOutputs) {
      final name = algorithmName(l10n, o.algorithmId);
      final date = _localCalendarDateLabel(l10n, o.predictedStartUtc);
      lines.add(l10n.predictionAlgoExpectsLine(name, date));
    }

    lines.add('');
    lines.add(l10n.predictionAgreementClosing);

    final m = ensemble.milestone;
    if (m != null) {
      lines.add('');
      lines.add(formatEnsembleMilestone(l10n, m));
    }

    final text = lines.join('\n').trim();
    assert(predictionCopyTextPassesGuard(text));
    return text;
  }

  /// Single-engine explanation from median path coordinator output.
  static String formatCoordinatorExplanation(
    AppLocalizations l10n, {
    required PredictionResult result,
    required List<ExplanationStep> steps,
  }) {
    final lines = <String>[l10n.predictionDisclaimer, ''];

    for (final step in steps) {
      final line = _formatStep(l10n, step);
      if (line != null && line.isNotEmpty) {
        lines.add(line);
      }
    }

    lines.add('');
    lines.add(_closingForResult(l10n, result));

    final text = lines.join('\n').trim();
    assert(predictionCopyTextPassesGuard(text));
    return text;
  }

  static String _closingForResult(
    AppLocalizations l10n,
    PredictionResult result,
  ) {
    return switch (result) {
      PredictionInsufficientHistory() => l10n.predictionClosingInsufficientHistory,
      PredictionRangeOnly(:final rangeStartUtc, :final rangeEndUtc) =>
        l10n.predictionClosingRangeOnly(
          _localCalendarDateLabel(l10n, rangeStartUtc),
          _localCalendarDateLabel(l10n, rangeEndUtc),
        ),
      PredictionPointWithRange(
        :final pointStartUtc,
        :final rangeStartUtc,
        :final rangeEndUtc,
      ) =>
        () {
          final bandStart = rangeStartUtc ?? pointStartUtc;
          final bandEnd = rangeEndUtc ?? pointStartUtc;
          return l10n.predictionClosingPointWithRange(
            _localCalendarDateLabel(l10n, pointStartUtc),
            _localCalendarDateLabel(l10n, bandStart),
            _localCalendarDateLabel(l10n, bandEnd),
          );
        }(),
    };
  }

  static String? _formatStep(AppLocalizations l10n, ExplanationStep step) {
    switch (step.kind) {
      case ExplanationFactKind.cyclesConsidered:
        final count = step.payload['count'] as int?;
        final lengths = step.payload['lengthsInDays'] as List<Object?>?;
        if (count == null || lengths == null) return null;
        return l10n.predStepCyclesConsidered(
          count,
          _formatIntList(l10n, lengths),
        );

      case ExplanationFactKind.cycleExcluded:
        final reason = step.payload['exclusionReason'] as String?;
        if (reason == null) return null;
        return l10n.predStepCycleExcluded(reason);

      case ExplanationFactKind.medianCycleLength:
        final median = step.payload['medianDays'] as int?;
        final spread = step.payload['spreadDays'] as int?;
        if (median == null || spread == null) return null;
        return l10n.predStepMedianCycleLength(median, spread);

      case ExplanationFactKind.insufficientHistory:
        final avail = step.payload['completedCyclesAvailable'] as int?;
        final need = step.payload['minCompletedCyclesNeeded'] as int?;
        if (avail == null || need == null) return null;
        return l10n.predStepInsufficientHistory(avail, need);

      case ExplanationFactKind.highVariabilityRange:
        final start = step.payload['rangeStartUtc'] as String?;
        final end = step.payload['rangeEndUtc'] as String?;
        if (start == null || end == null) return null;
        final ds = _localCalendarDateLabel(l10n, DateTime.parse(start).toUtc());
        final de = _localCalendarDateLabel(l10n, DateTime.parse(end).toUtc());
        return l10n.predStepHighVariability(ds, de);

      case ExplanationFactKind.enginePending:
        return null;

      case ExplanationFactKind.ewmaSmoothedLength:
        final days = step.payload['smoothedDays'] as int?;
        final alpha = step.payload['alpha'] as double?;
        if (days == null || alpha == null) return null;
        return l10n.predStepEwma(
          _formatFixedDecimals(l10n, alpha, 2),
          days,
        );

      case ExplanationFactKind.bayesianPosteriorMean:
        final mean = step.payload['posteriorMeanDays'] as double?;
        final n = step.payload['observationCount'] as int?;
        if (mean == null || n == null) return null;
        return l10n.predStepBayesian(
          _formatFixedDecimals(l10n, mean, 1),
          n,
        );

      case ExplanationFactKind.linearTrendProjection:
        final proj = step.payload['projectedDays'] as int?;
        final r2 = step.payload['rSquared'] as double?;
        final slope = step.payload['slope'] as double?;
        if (proj == null || r2 == null || slope == null) return null;
        return l10n.predStepLinearTrend(
          _formatFixedDecimals(l10n, r2, 2),
          _formatFixedDecimals(l10n, slope, 2),
          proj,
        );

      case ExplanationFactKind.algorithmContribution:
        final idName = step.payload['algorithmId'] as String?;
        final start = step.payload['predictedStartUtc'] as String?;
        if (idName == null || start == null) return null;
        final id = _parseAlgorithmId(idName);
        final name =
            id != null ? algorithmName(l10n, id) : idName;
        final ds = _localCalendarDateLabel(l10n, DateTime.parse(start).toUtc());
        return l10n.predStepAlgoContrib(name, ds);

      case ExplanationFactKind.ensembleConsensus:
        return null;

      case ExplanationFactKind.milestoneReached:
        return null;
    }
  }
}

import 'explanation_step.dart';
import 'prediction_result.dart';

/// Phrases that must never appear in user-facing prediction copy (PRED-04 guardrails).
const List<String> predictionCopyForbiddenPhrasesLowercase = [
  'guarantee',
  '100% effective',
  'prevent pregnancy',
  'contraception',
  'fertility awareness',
  'medical diagnosis',
];

/// Short disclaimer repeated in narratives (conservative framing).
String predictionDisclaimerSentence() =>
    'This is a calendar-based estimate for personal planning only, not medical advice.';

/// Formats a UTC instant as a neutral YYYY-MM-DD (calendar day in UTC).
String formatUtcCalendarDate(DateTime utc) {
  final u = utc.toUtc();
  final y = u.year.toString().padLeft(4, '0');
  final m = u.month.toString().padLeft(2, '0');
  final d = u.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Builds a multi-line, plain-language explanation from engine output.
String formatPredictionExplanation({
  required PredictionResult result,
  required List<ExplanationStep> steps,
}) {
  final lines = <String>[predictionDisclaimerSentence(), ''];

  for (final step in steps) {
    final line = _formatStep(step);
    if (line != null && line.isNotEmpty) {
      lines.add(line);
    }
  }

  lines.add('');
  lines.add(_closingForResult(result));

  return lines.join('\n').trim();
}

String _closingForResult(PredictionResult result) {
  return switch (result) {
    PredictionInsufficientHistory() =>
      'Add more completed cycles over time to get a clearer estimate. Numbers here are not a substitute for care from a qualified clinician.',
    PredictionRangeOnly(
      :final rangeStartUtc,
      :final rangeEndUtc,
    ) =>
      'For planning purposes, a broad estimate window runs from '
      '${formatUtcCalendarDate(rangeStartUtc)} through '
      '${formatUtcCalendarDate(rangeEndUtc)}. Treat these dates as uncertain.',
    PredictionPointWithRange(
      :final pointStartUtc,
      :final rangeStartUtc,
      :final rangeEndUtc,
    ) =>
      () {
        final bandStart = rangeStartUtc ?? pointStartUtc;
        final bandEnd = rangeEndUtc ?? pointStartUtc;
        return 'A rough estimate for your next period start is '
            '${formatUtcCalendarDate(pointStartUtc)}. '
            'Based on similar past spacing, a wider planning band might be '
            '${formatUtcCalendarDate(bandStart)} to '
            '${formatUtcCalendarDate(bandEnd)}.';
      }(),
  };
}

String? _formatStep(ExplanationStep step) {
  switch (step.kind) {
    case ExplanationFactKind.cyclesConsidered:
      final count = step.payload['count'] as int?;
      final lengths = step.payload['lengthsInDays'] as List<Object?>?;
      if (count == null || lengths == null) return null;
      return 'Based on $count recent cycle lengths from your history '
          '(${lengths.join(', ')} days).';

    case ExplanationFactKind.cycleExcluded:
      final reason = step.payload['exclusionReason'] as String?;
      if (reason == null) return null;
      return 'One logged cycle was left out of the average for this estimate '
          '(reason: $reason).';

    case ExplanationFactKind.medianCycleLength:
      final median = step.payload['medianDays'] as int?;
      final spread = step.payload['spreadDays'] as int?;
      if (median == null || spread == null) return null;
      return 'Across included cycles, a typical spacing is about $median days '
          '(spread about $spread days).';

    case ExplanationFactKind.insufficientHistory:
      final avail = step.payload['completedCyclesAvailable'] as int?;
      final need = step.payload['minCompletedCyclesNeeded'] as int?;
      if (avail == null || need == null) return null;
      return 'There are not enough completed cycles yet to estimate a next start. '
          '$avail cycle(s) are available after filtering; at least $need are '
          'typically needed.';

    case ExplanationFactKind.highVariabilityRange:
      final start = step.payload['rangeStartUtc'] as String?;
      final end = step.payload['rangeEndUtc'] as String?;
      if (start == null || end == null) return null;
      final ds = formatUtcCalendarDate(DateTime.parse(start).toUtc());
      final de = formatUtcCalendarDate(DateTime.parse(end).toUtc());
      return 'Because variability is high, a range is shown instead of a single '
          'day: approximately $ds through $de.';

    case ExplanationFactKind.enginePending:
      return null;

    case ExplanationFactKind.ewmaSmoothedLength:
      final days = step.payload['smoothedDays'] as int?;
      final alpha = step.payload['alpha'] as double?;
      if (days == null || alpha == null) return null;
      return 'Recent-weighted spacing (EWMA, α=$alpha) suggests about $days days.';

    case ExplanationFactKind.bayesianPosteriorMean:
      final mean = step.payload['posteriorMeanDays'] as double?;
      final n = step.payload['observationCount'] as int?;
      if (mean == null || n == null) return null;
      return 'Pattern-learning estimate (posterior mean) is about '
          '${mean.toStringAsFixed(1)} days from $n cycle lengths.';

    case ExplanationFactKind.linearTrendProjection:
      final proj = step.payload['projectedDays'] as int?;
      final r2 = step.payload['rSquared'] as double?;
      final slope = step.payload['slope'] as double?;
      if (proj == null || r2 == null || slope == null) return null;
      return 'Trend line (R²=${r2.toStringAsFixed(2)}, slope=${slope.toStringAsFixed(2)} '
          'days per cycle) projects about $proj days for the next spacing.';
  }
}

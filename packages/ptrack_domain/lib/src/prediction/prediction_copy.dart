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
      return 'We reviewed $count recent cycle lengths from your saved history '
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
      return 'Right now there are not enough comparable completed cycles to '
          'pin a next start. After filters, $avail cycle(s) are available; '
          'we usually look for at least $need for this estimate.';

    case ExplanationFactKind.highVariabilityRange:
      final start = step.payload['rangeStartUtc'] as String?;
      final end = step.payload['rangeEndUtc'] as String?;
      if (start == null || end == null) return null;
      final ds = formatUtcCalendarDate(DateTime.parse(start).toUtc());
      final de = formatUtcCalendarDate(DateTime.parse(end).toUtc());
      return 'Because variability is high, we show a range instead of a single '
          'day: about $ds through $de (UTC calendar days).';

    case ExplanationFactKind.enginePending:
      return null;
  }
}

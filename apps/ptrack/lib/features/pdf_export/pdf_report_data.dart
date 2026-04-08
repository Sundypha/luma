import 'package:flutter/foundation.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

@immutable
class CycleStatsSummary {
  const CycleStatsSummary({
    required this.cycleCount,
    this.avgCycleLengthDays,
    this.avgPeriodDurationDays,
    this.shortestCycleDays,
    this.longestCycleDays,
  });

  final int cycleCount;
  final double? avgCycleLengthDays;
  final double? avgPeriodDurationDays;
  final int? shortestCycleDays;
  final int? longestCycleDays;
}

@immutable
class FlowDistribution {
  const FlowDistribution({required this.counts});

  final Map<FlowIntensity, int> counts;
}

@immutable
class PainDistribution {
  const PainDistribution({required this.counts});

  final Map<PainScore, int> counts;
}

@immutable
class MoodDistribution {
  const MoodDistribution({required this.counts});

  final Map<Mood, int> counts;
}

@immutable
class DaySummaryRow {
  const DaySummaryRow({
    required this.dateUtc,
    this.flow,
    this.pain,
    this.mood,
    required this.hasNotes,
  });

  final DateTime dateUtc;
  final FlowIntensity? flow;
  final PainScore? pain;
  final Mood? mood;
  final bool hasNotes;
}

@immutable
class NoteEntry {
  const NoteEntry({
    required this.dateUtc,
    required this.notes,
  });

  final DateTime dateUtc;
  final String notes;
}

@immutable
class CycleLengthEntry {
  const CycleLengthEntry({
    required this.periodStartUtc,
    required this.lengthDays,
  });

  final DateTime periodStartUtc;
  final int lengthDays;
}

@immutable
class PdfReportData {
  const PdfReportData({
    required this.generatedAt,
    required this.rangeStart,
    required this.rangeEnd,
    required this.locale,
    required this.stats,
    required this.flowDist,
    required this.painDist,
    required this.moodDist,
    required this.cycleLengths,
    required this.daySummaryRows,
    required this.noteEntries,
  });

  final DateTime generatedAt;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String locale;
  final CycleStatsSummary stats;
  final FlowDistribution flowDist;
  final PainDistribution painDist;
  final MoodDistribution moodDist;
  final List<CycleLengthEntry> cycleLengths;
  final List<DaySummaryRow> daySummaryRows;
  final List<NoteEntry> noteEntries;
}

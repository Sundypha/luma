import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/timezone.dart' as tz;

import 'pdf_report_data.dart';
import 'pdf_section_config.dart';

/// Builds [PdfReportData] from stored periods for a configured date range.
class PdfDataCollector {
  PdfReportData collect({
    required List<StoredPeriodWithDays> periodsWithDays,
    required PdfSectionConfig config,
    required PeriodCalendarContext calendar,
    required String locale,
  }) {
    final rangeStart = _utcDateOnly(config.rangeStart);
    final rangeEnd = _utcDateOnly(config.rangeEnd);

    final filtered = [
      for (final p in periodsWithDays)
        if (_periodStartInRange(p, rangeStart, rangeEnd)) p,
    ]..sort(
        (a, b) => a.period.span.startUtc.compareTo(b.period.span.startUtc),
      );

    final cycleLengths = <CycleLengthEntry>[];
    var sumCycle = 0;
    int? shortest;
    int? longest;
    if (filtered.length >= 2) {
      for (var i = 0; i < filtered.length - 1; i++) {
        final a = filtered[i].period.span.startUtc;
        final b = filtered[i + 1].period.span.startUtc;
        final c = completedCycleBetweenStarts(
          periodStartUtc: a,
          nextPeriodStartUtc: b,
          calendar: calendar,
        );
        cycleLengths.add(
          CycleLengthEntry(
            periodStartUtc: c.periodStartUtc,
            lengthDays: c.lengthInDays,
          ),
        );
        sumCycle += c.lengthInDays;
        shortest = shortest == null
            ? c.lengthInDays
            : (c.lengthInDays < shortest ? c.lengthInDays : shortest);
        longest = longest == null
            ? c.lengthInDays
            : (c.lengthInDays > longest ? c.lengthInDays : longest);
      }
    }

    final cycleCount = cycleLengths.length;
    final avgCycle = cycleCount > 0 ? sumCycle / cycleCount : null;

    final periodDurations = <int>[
      for (final p in filtered)
        if (p.period.span.isCompleted)
          _inclusiveBleedingDaysLocal(
            calendar,
            p.period.span.startUtc,
            p.period.span.endUtc!,
          ),
    ];
    final avgPeriod = periodDurations.isEmpty
        ? null
        : periodDurations.reduce((a, b) => a + b) / periodDurations.length;

    final flowCounts = {
      for (final f in FlowIntensity.values) f: 0,
    };
    final painCounts = {
      for (final p in PainScore.values) p: 0,
    };
    final moodCounts = {
      for (final m in Mood.values) m: 0,
    };

    final dayRows = <DateTime, DaySummaryRow>{};
    final noteByDay = <DateTime, String>{};

    for (final p in filtered) {
      for (final d in p.dayEntries) {
        final day = _utcDateOnly(d.data.dateUtc);
        if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) continue;

        final rawNotes = d.data.notes?.trim();
        if (rawNotes != null && rawNotes.isNotEmpty) {
          final prevNote = noteByDay[day];
          noteByDay[day] =
              prevNote == null ? rawNotes : '$prevNote\n$rawNotes';
        }

        if (d.data.flowIntensity != null) {
          flowCounts[d.data.flowIntensity!] =
              (flowCounts[d.data.flowIntensity!] ?? 0) + 1;
        }
        if (d.data.painScore != null) {
          painCounts[d.data.painScore!] =
              (painCounts[d.data.painScore!] ?? 0) + 1;
        }
        if (d.data.mood != null) {
          moodCounts[d.data.mood!] = (moodCounts[d.data.mood!] ?? 0) + 1;
        }

        final hasNotes = rawNotes != null && rawNotes.isNotEmpty;
        final prev = dayRows[day];
        if (prev == null) {
          dayRows[day] = DaySummaryRow(
            dateUtc: day,
            flow: d.data.flowIntensity,
            pain: d.data.painScore,
            mood: d.data.mood,
            hasNotes: hasNotes,
          );
        } else {
          dayRows[day] = DaySummaryRow(
            dateUtc: day,
            flow: d.data.flowIntensity ?? prev.flow,
            pain: d.data.painScore ?? prev.pain,
            mood: d.data.mood ?? prev.mood,
            hasNotes: prev.hasNotes || hasNotes,
          );
        }
      }
    }

    final sortedDays = dayRows.keys.toList()..sort();
    final daySummaryRows = [
      for (final k in sortedDays) dayRows[k]!,
    ];

    final noteDays = noteByDay.keys.toList()..sort();
    final noteEntries = [
      for (final day in noteDays) NoteEntry(dateUtc: day, notes: noteByDay[day]!),
    ];

    return PdfReportData(
      generatedAt: DateTime.now().toUtc(),
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      locale: locale,
      stats: CycleStatsSummary(
        cycleCount: cycleCount,
        avgCycleLengthDays: avgCycle,
        avgPeriodDurationDays: avgPeriod,
        shortestCycleDays: shortest,
        longestCycleDays: longest,
      ),
      flowDist: FlowDistribution(counts: flowCounts),
      painDist: PainDistribution(counts: painCounts),
      moodDist: MoodDistribution(counts: moodCounts),
      cycleLengths: cycleLengths,
      daySummaryRows: daySummaryRows,
      noteEntries: noteEntries,
    );
  }

  static DateTime _utcDateOnly(DateTime d) {
    final u = d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  static bool _periodStartInRange(
    StoredPeriodWithDays p,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final start = _utcDateOnly(p.period.span.startUtc);
    return !start.isBefore(rangeStart) && !start.isAfter(rangeEnd);
  }

  static int _inclusiveBleedingDaysLocal(
    PeriodCalendarContext calendar,
    DateTime startUtc,
    DateTime endUtc,
  ) {
    final loc = calendar.location;
    final startDay = calendar.localCalendarDateForUtc(startUtc);
    final endDay = calendar.localCalendarDateForUtc(endUtc);
    final startMidnight =
        tz.TZDateTime(loc, startDay.year, startDay.month, startDay.day);
    final endMidnight =
        tz.TZDateTime(loc, endDay.year, endDay.month, endDay.day);
    return endMidnight.difference(startMidnight).inDays + 1;
  }
}

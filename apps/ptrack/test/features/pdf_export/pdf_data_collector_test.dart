import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:luma/features/pdf_export/pdf_data_collector.dart';
import 'package:luma/features/pdf_export/pdf_section_config.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  late PeriodCalendarContext calendar;

  setUp(() {
    calendar = PeriodCalendarContext(tz.UTC);
  });

  PdfSectionConfig range(DateTime start, DateTime end) => PdfSectionConfig(
        enabledSections: PdfSection.values.toSet(),
        rangeStart: start,
        rangeEnd: end,
      );

  StoredPeriodWithDays period({
    required int id,
    required DateTime startUtc,
    required DateTime endUtc,
    List<StoredDayEntry> dayEntries = const [],
  }) {
    return StoredPeriodWithDays(
      period: StoredPeriod(
        id: id,
        span: PeriodSpan(startUtc: startUtc, endUtc: endUtc),
      ),
      dayEntries: dayEntries,
    );
  }

  StoredDayEntry day(int id, int periodId, DayEntryData data) =>
      StoredDayEntry(id: id, periodId: periodId, data: data);

  group('PdfDataCollector', () {
    test('empty periods yields empty report shape', () {
      final c = PdfDataCollector();
      final report = c.collect(
        periodsWithDays: [],
        config: range(DateTime.utc(2026, 1, 1), DateTime.utc(2026, 12, 31)),
        calendar: calendar,
        locale: 'en',
      );
      expect(report.stats.cycleCount, 0);
      expect(report.stats.avgCycleLengthDays, isNull);
      expect(report.stats.avgPeriodDurationDays, isNull);
      expect(report.stats.shortestCycleDays, isNull);
      expect(report.stats.longestCycleDays, isNull);
      expect(report.cycleLengths, isEmpty);
      expect(report.daySummaryRows, isEmpty);
      expect(report.noteEntries, isEmpty);
      for (final v in report.flowDist.counts.values) {
        expect(v, 0);
      }
    });

    test('periods whose period start is outside range are excluded', () {
      final c = PdfDataCollector();
      final report = c.collect(
        periodsWithDays: [
          period(
            id: 1,
            startUtc: DateTime.utc(2025, 12, 1),
            endUtc: DateTime.utc(2025, 12, 3),
          ),
          period(
            id: 2,
            startUtc: DateTime.utc(2026, 6, 1),
            endUtc: DateTime.utc(2026, 6, 2),
          ),
        ],
        config: range(DateTime.utc(2026, 1, 1), DateTime.utc(2026, 3, 31)),
        calendar: calendar,
        locale: 'en',
      );
      expect(report.stats.cycleCount, 0);
      expect(report.daySummaryRows, isEmpty);
    });

    test('cycle stats for three consecutive period starts', () {
      final c = PdfDataCollector();
      final report = c.collect(
        periodsWithDays: [
          period(
            id: 1,
            startUtc: DateTime.utc(2026, 1, 1),
            endUtc: DateTime.utc(2026, 1, 5),
          ),
          period(
            id: 2,
            startUtc: DateTime.utc(2026, 1, 29),
            endUtc: DateTime.utc(2026, 2, 2),
          ),
          period(
            id: 3,
            startUtc: DateTime.utc(2026, 2, 26),
            endUtc: DateTime.utc(2026, 3, 2),
          ),
        ],
        config: range(DateTime.utc(2026, 1, 1), DateTime.utc(2026, 12, 31)),
        calendar: calendar,
        locale: 'en',
      );
      expect(report.stats.cycleCount, 2);
      expect(report.stats.avgCycleLengthDays, closeTo(28.0, 0.001));
      expect(report.stats.shortestCycleDays, 28);
      expect(report.stats.longestCycleDays, 28);
      expect(report.stats.avgPeriodDurationDays, closeTo(5.0, 0.001));
      expect(report.cycleLengths, hasLength(2));
      expect(report.cycleLengths[0].lengthDays, 28);
      expect(report.cycleLengths[1].lengthDays, 28);
    });

    test('flow, pain, mood distributions count days in range', () {
      final c = PdfDataCollector();
      final report = c.collect(
        periodsWithDays: [
          period(
            id: 1,
            startUtc: DateTime.utc(2026, 3, 1),
            endUtc: DateTime.utc(2026, 3, 3),
            dayEntries: [
              day(
                1,
                1,
                DayEntryData(
                  dateUtc: DateTime.utc(2026, 3, 1),
                  flowIntensity: FlowIntensity.light,
                  painScore: PainScore.mild,
                  mood: Mood.good,
                ),
              ),
              day(
                2,
                1,
                DayEntryData(
                  dateUtc: DateTime.utc(2026, 3, 2),
                  flowIntensity: FlowIntensity.heavy,
                  painScore: PainScore.mild,
                  mood: Mood.neutral,
                ),
              ),
            ],
          ),
        ],
        config: range(DateTime.utc(2026, 3, 1), DateTime.utc(2026, 3, 31)),
        calendar: calendar,
        locale: 'en',
      );
      expect(report.flowDist.counts[FlowIntensity.light], 1);
      expect(report.flowDist.counts[FlowIntensity.heavy], 1);
      expect(report.flowDist.counts[FlowIntensity.medium], 0);
      expect(report.painDist.counts[PainScore.mild], 2);
      expect(report.moodDist.counts[Mood.good], 1);
      expect(report.moodDist.counts[Mood.neutral], 1);
    });

    test('day summary rows sorted ascending by date', () {
      final c = PdfDataCollector();
      final report = c.collect(
        periodsWithDays: [
          period(
            id: 1,
            startUtc: DateTime.utc(2026, 4, 10),
            endUtc: DateTime.utc(2026, 4, 12),
            dayEntries: [
              day(
                2,
                1,
                DayEntryData(dateUtc: DateTime.utc(2026, 4, 12)),
              ),
              day(
                1,
                1,
                DayEntryData(dateUtc: DateTime.utc(2026, 4, 10)),
              ),
            ],
          ),
        ],
        config: range(DateTime.utc(2026, 4, 1), DateTime.utc(2026, 4, 30)),
        calendar: calendar,
        locale: 'en',
      );
      expect(report.daySummaryRows, hasLength(2));
      expect(report.daySummaryRows[0].dateUtc, DateTime.utc(2026, 4, 10));
      expect(report.daySummaryRows[1].dateUtc, DateTime.utc(2026, 4, 12));
    });

    test('note entries omit empty and null notes', () {
      final c = PdfDataCollector();
      final report = c.collect(
        periodsWithDays: [
          period(
            id: 1,
            startUtc: DateTime.utc(2026, 5, 1),
            endUtc: DateTime.utc(2026, 5, 3),
            dayEntries: [
              day(
                1,
                1,
                DayEntryData(dateUtc: DateTime.utc(2026, 5, 1), notes: '  hello  '),
              ),
              day(
                2,
                1,
                DayEntryData(dateUtc: DateTime.utc(2026, 5, 2), notes: ''),
              ),
              day(
                3,
                1,
                DayEntryData(dateUtc: DateTime.utc(2026, 5, 3)),
              ),
            ],
          ),
        ],
        config: range(DateTime.utc(2026, 5, 1), DateTime.utc(2026, 5, 31)),
        calendar: calendar,
        locale: 'en',
      );
      expect(report.noteEntries, hasLength(1));
      expect(report.noteEntries.single.notes, 'hello');
    });

    test('single completed period: no completed cycle but period stats and days', () {
      final c = PdfDataCollector();
      final report = c.collect(
        periodsWithDays: [
          period(
            id: 1,
            startUtc: DateTime.utc(2026, 7, 1),
            endUtc: DateTime.utc(2026, 7, 5),
            dayEntries: [
              day(
                1,
                1,
                DayEntryData(
                  dateUtc: DateTime.utc(2026, 7, 3),
                  flowIntensity: FlowIntensity.medium,
                ),
              ),
            ],
          ),
        ],
        config: range(DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 31)),
        calendar: calendar,
        locale: 'en',
      );
      expect(report.stats.cycleCount, 0);
      expect(report.stats.avgCycleLengthDays, isNull);
      expect(report.stats.shortestCycleDays, isNull);
      expect(report.stats.longestCycleDays, isNull);
      expect(report.stats.avgPeriodDurationDays, closeTo(5.0, 0.001));
      expect(report.cycleLengths, isEmpty);
      expect(report.daySummaryRows, hasLength(1));
      expect(report.flowDist.counts[FlowIntensity.medium], 1);
    });
  });
}

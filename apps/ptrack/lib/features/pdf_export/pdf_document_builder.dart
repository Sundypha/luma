import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ptrack_domain/ptrack_domain.dart';

import 'pdf_report_data.dart';
import 'pdf_section_config.dart';

/// Two centimeters in PDF points (72 pt per inch).
const double _kPdfMarginPt = 2 * 72 / 2.54;

/// All user-visible PDF copy comes from here (typically filled from [AppLocalizations]).
@immutable
class PdfContentStrings {
  const PdfContentStrings({
    required this.disclaimer,
    required this.reportTitle,
    required this.overviewHeading,
    required this.cycleHistoryHeading,
    required this.cycleChartHeading,
    required this.daySummaryHeading,
    required this.notesHeading,
    required this.generatedOn,
    required this.dateRange,
    required this.nDays,
    required this.totalCycles,
    required this.avgCycleLength,
    required this.avgPeriodDuration,
    required this.shortestCycle,
    required this.longestCycle,
    required this.flowDistribution,
    required this.painDistribution,
    required this.moodDistribution,
    required this.flowLabel,
    required this.painLabel,
    required this.moodLabel,
    required this.dateLabel,
    required this.cycleStartLabel,
    required this.cycleLengthLabel,
    required this.noDataForRange,
    required this.noDayData,
    required this.noNotes,
    required this.metadataOnlyNote,
    required this.footerGenerated,
    required this.flowLight,
    required this.flowMedium,
    required this.flowHeavy,
    required this.painNone,
    required this.painMild,
    required this.painModerate,
    required this.painSevere,
    required this.painVerySevere,
    required this.moodVeryBad,
    required this.moodBad,
    required this.moodNeutral,
    required this.moodGood,
    required this.moodVeryGood,
  });

  final String disclaimer;
  final String reportTitle;
  final String overviewHeading;
  final String cycleHistoryHeading;
  final String cycleChartHeading;
  final String daySummaryHeading;
  final String notesHeading;

  final String Function(String date) generatedOn;
  final String Function(String start, String end) dateRange;
  final String Function(int count) nDays;

  final String totalCycles;
  final String avgCycleLength;
  final String avgPeriodDuration;
  final String shortestCycle;
  final String longestCycle;
  final String flowDistribution;
  final String painDistribution;
  final String moodDistribution;

  final String flowLabel;
  final String painLabel;
  final String moodLabel;
  final String dateLabel;
  final String cycleStartLabel;
  final String cycleLengthLabel;

  final String noDataForRange;
  final String noDayData;
  final String noNotes;
  final String metadataOnlyNote;
  final String footerGenerated;

  final String flowLight;
  final String flowMedium;
  final String flowHeavy;
  final String painNone;
  final String painMild;
  final String painModerate;
  final String painSevere;
  final String painVerySevere;
  final String moodVeryBad;
  final String moodBad;
  final String moodNeutral;
  final String moodGood;
  final String moodVeryGood;
}

/// Builds a printable PDF from collected report data and section toggles.
class PdfDocumentBuilder {
  const PdfDocumentBuilder();

  Future<Uint8List> build({
    required PdfReportData data,
    required PdfSectionConfig config,
    required PdfContentStrings strings,
  }) async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        fontFallback: [pw.Font.helveticaOblique()],
      ),
    );

    final localeName = Intl.canonicalizedLocale(data.locale);
    final dateFmt = DateFormat.yMMMd(localeName);
    final shortDateFmt = DateFormat.MMMd(localeName);
    final numFmt = NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: 1,
    );

    String fmtUtcDate(DateTime d) =>
        dateFmt.format(DateTime.utc(d.year, d.month, d.day));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_kPdfMarginPt),
        footer: (ctx) => _buildFooter(ctx, data, strings, fmtUtcDate),
        build: (ctx) => [
          _buildHeader(data, strings, fmtUtcDate, dateFmt),
          pw.SizedBox(height: 8),
          _buildDisclaimer(strings),
          pw.SizedBox(height: 12),
          if (!config.hasAnySections) ...[
            pw.Text(strings.metadataOnlyNote, style: pw.TextStyle(fontSize: 10)),
          ] else ...[
            if (config.isEnabled(PdfSection.overviewStats))
              ..._buildOverview(ctx, data, strings, numFmt),
            if (config.isEnabled(PdfSection.cycleHistory))
              ..._buildCycleHistory(ctx, data, strings, fmtUtcDate),
            if (config.isEnabled(PdfSection.cycleChart) &&
                data.cycleLengths.length >= 2)
              ..._buildCycleChart(data, strings, shortDateFmt),
            if (config.isEnabled(PdfSection.daySummaryTable))
              ..._buildDaySummary(ctx, data, strings, fmtUtcDate),
            if (config.isEnabled(PdfSection.notesLog))
              ..._buildNotes(data, strings, fmtUtcDate),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(
    PdfReportData data,
    PdfContentStrings strings,
    String Function(DateTime d) fmtUtcDate,
    DateFormat longFmt,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          strings.reportTitle,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          strings.generatedOn(longFmt.format(data.generatedAt.toLocal())),
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          strings.dateRange(fmtUtcDate(data.rangeStart), fmtUtcDate(data.rangeEnd)),
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildDisclaimer(PdfContentStrings strings) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 0.5, color: PdfColors.grey400),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        strings.disclaimer,
        style: pw.TextStyle(
          fontSize: 8,
          font: pw.Font.helveticaOblique(),
        ),
      ),
    );
  }

  pw.Widget _buildFooter(
    pw.Context ctx,
    PdfReportData data,
    PdfContentStrings strings,
    String Function(DateTime d) fmtUtcDate,
  ) {
    final when = fmtUtcDate(data.generatedAt);
    return pw.Footer(
      title: pw.Text(
        '${strings.footerGenerated} · $when · ${ctx.pageNumber}/${ctx.pagesCount}',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    );
  }

  List<pw.Widget> _buildOverview(
    pw.Context ctx,
    PdfReportData data,
    PdfContentStrings strings,
    NumberFormat numFmt,
  ) {
    final children = <pw.Widget>[
      pw.Text(
        strings.overviewHeading,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
    ];

    if (!_hasOverviewContent(data)) {
      children.add(pw.Text(strings.noDataForRange, style: _bodyStyle()));
      children.add(pw.SizedBox(height: 12));
      return children;
    }

    final s = data.stats;
    if (s.cycleCount > 0) {
      children.add(_kv(strings.totalCycles, '${s.cycleCount}'));
      if (s.avgCycleLengthDays != null) {
        children.add(_kv(
          strings.avgCycleLength,
          '${numFmt.format(s.avgCycleLengthDays)} (${strings.nDays(s.avgCycleLengthDays!.round())})',
        ));
      }
      if (s.avgPeriodDurationDays != null) {
        children.add(_kv(
          strings.avgPeriodDuration,
          '${numFmt.format(s.avgPeriodDurationDays)} (${strings.nDays(s.avgPeriodDurationDays!.round())})',
        ));
      }
      if (s.shortestCycleDays != null) {
        children.add(_kv(strings.shortestCycle, strings.nDays(s.shortestCycleDays!)));
      }
      if (s.longestCycleDays != null) {
        children.add(_kv(strings.longestCycle, strings.nDays(s.longestCycleDays!)));
      }
      children.add(pw.SizedBox(height: 4));
    }

    children.add(pw.Text(
      '${strings.flowDistribution}: ${_flowInline(data.flowDist, strings)}',
      style: _bodyStyle(),
    ));
    children.add(pw.Text(
      '${strings.painDistribution}: ${_painInline(data.painDist, strings)}',
      style: _bodyStyle(),
    ));
    children.add(pw.Text(
      '${strings.moodDistribution}: ${_moodInline(data.moodDist, strings)}',
      style: _bodyStyle(),
    ));
    children.add(pw.SizedBox(height: 12));
    return children;
  }
}

pw.TextStyle _bodyStyle() => pw.TextStyle(fontSize: 10);

pw.Widget _kv(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(label, style: _bodyStyle()),
        ),
        pw.Expanded(child: pw.Text(value, style: _bodyStyle())),
      ],
    ),
  );
}

bool _hasOverviewContent(PdfReportData data) {
  if (data.stats.cycleCount > 0) return true;
  for (final c in data.flowDist.counts.values) {
    if (c > 0) return true;
  }
  for (final c in data.painDist.counts.values) {
    if (c > 0) return true;
  }
  for (final c in data.moodDist.counts.values) {
    if (c > 0) return true;
  }
  return false;
}

String _flowInline(FlowDistribution d, PdfContentStrings s) {
  return FlowIntensity.values
      .map((f) => '${_flowLabel(f, s)}: ${d.counts[f] ?? 0}')
      .join(', ');
}

String _painInline(PainDistribution d, PdfContentStrings s) {
  return PainScore.values
      .map((p) => '${_painLabel(p, s)}: ${d.counts[p] ?? 0}')
      .join(', ');
}

String _moodInline(MoodDistribution d, PdfContentStrings s) {
  return Mood.values
      .map((m) => '${_moodLabel(m, s)}: ${d.counts[m] ?? 0}')
      .join(', ');
}

String _flowLabel(FlowIntensity f, PdfContentStrings s) => switch (f) {
      FlowIntensity.light => s.flowLight,
      FlowIntensity.medium => s.flowMedium,
      FlowIntensity.heavy => s.flowHeavy,
    };

String _painLabel(PainScore p, PdfContentStrings s) => switch (p) {
      PainScore.none => s.painNone,
      PainScore.mild => s.painMild,
      PainScore.moderate => s.painModerate,
      PainScore.severe => s.painSevere,
      PainScore.verySevere => s.painVerySevere,
    };

String _moodLabel(Mood m, PdfContentStrings s) => switch (m) {
      Mood.veryBad => s.moodVeryBad,
      Mood.bad => s.moodBad,
      Mood.neutral => s.moodNeutral,
      Mood.good => s.moodGood,
      Mood.veryGood => s.moodVeryGood,
    };

List<pw.Widget> _buildCycleHistory(
  pw.Context ctx,
  PdfReportData data,
  PdfContentStrings strings,
  String Function(DateTime d) fmtUtcDate,
) {
  final out = <pw.Widget>[
    pw.Text(
      strings.cycleHistoryHeading,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 6),
  ];

  if (data.cycleLengths.isEmpty) {
    out.add(pw.Text(strings.noDataForRange, style: _bodyStyle()));
    out.add(pw.SizedBox(height: 12));
    return out;
  }

  out.add(
    pw.TableHelper.fromTextArray(
      context: ctx,
      headers: [strings.cycleStartLabel, strings.cycleLengthLabel],
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      data: [
        for (final e in data.cycleLengths)
          [fmtUtcDate(e.periodStartUtc), '${e.lengthDays}'],
      ],
    ),
  );
  out.add(pw.SizedBox(height: 12));
  return out;
}

List<pw.Widget> _buildCycleChart(
  PdfReportData data,
  PdfContentStrings strings,
  DateFormat shortFmt,
) {
  final entries = data.cycleLengths;
  final labels = [
    for (final e in entries)
      shortFmt.format(
        DateTime.utc(e.periodStartUtc.year, e.periodStartUtc.month, e.periodStartUtc.day),
      ),
  ];
  final maxDays = entries.map((e) => e.lengthDays).reduce(math.max);
  final yTicks = _yAxisTicks(maxDays);
  final barWidth = math.min(14.0, 280 / math.max(1, entries.length * 2));

  return [
    pw.Text(
      strings.cycleChartHeading,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 6),
    pw.SizedBox(
      height: 160,
      width: double.infinity,
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis.fromStrings(
            labels,
            textStyle: const pw.TextStyle(fontSize: 7),
          ),
          yAxis: pw.FixedAxis(
            yTicks,
            format: (n) => n.toInt().toString(),
            textStyle: const pw.TextStyle(fontSize: 8),
            divisions: true,
          ),
        ),
        datasets: [
          pw.BarDataSet(
            data: [
              for (var i = 0; i < entries.length; i++)
                pw.PointChartValue(i.toDouble(), entries[i].lengthDays.toDouble()),
            ],
            color: PdfColors.teal700,
            width: barWidth,
            drawPoints: false,
          ),
        ],
      ),
    ),
    pw.SizedBox(height: 12),
  ];
}

List<num> _yAxisTicks(int maxVal) {
  if (maxVal <= 0) return [0, 1];
  final roughStep = math.max(1, (maxVal / 5).ceil());
  var top = ((maxVal / roughStep).ceil()) * roughStep;
  if (top < maxVal) top += roughStep;
  final ticks = <num>[0];
  for (var v = roughStep; v <= top; v += roughStep) {
    ticks.add(v);
  }
  if (ticks.length < 2) ticks.add(top);
  return ticks;
}

List<pw.Widget> _buildDaySummary(
  pw.Context ctx,
  PdfReportData data,
  PdfContentStrings strings,
  String Function(DateTime d) fmtUtcDate,
) {
  final out = <pw.Widget>[
    pw.Text(
      strings.daySummaryHeading,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 6),
  ];

  if (data.daySummaryRows.isEmpty) {
    out.add(pw.Text(strings.noDayData, style: _bodyStyle()));
    out.add(pw.SizedBox(height: 12));
    return out;
  }

  out.add(
    pw.TableHelper.fromTextArray(
      context: ctx,
      headers: [
        strings.dateLabel,
        strings.flowLabel,
        strings.painLabel,
        strings.moodLabel,
      ],
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      data: [
        for (final row in data.daySummaryRows)
          [
            fmtUtcDate(row.dateUtc),
            row.flow != null ? _flowLabel(row.flow!, strings) : '–',
            row.pain != null ? _painLabel(row.pain!, strings) : '–',
            row.mood != null ? _moodLabel(row.mood!, strings) : '–',
          ],
      ],
    ),
  );
  out.add(pw.SizedBox(height: 12));
  return out;
}

List<pw.Widget> _buildNotes(
  PdfReportData data,
  PdfContentStrings strings,
  String Function(DateTime d) fmtUtcDate,
) {
  final out = <pw.Widget>[
    pw.Text(
      strings.notesHeading,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 6),
  ];

  if (data.noteEntries.isEmpty) {
    out.add(pw.Text(strings.noNotes, style: _bodyStyle()));
    return out;
  }

  for (final n in data.noteEntries) {
    out.add(
      pw.Text(
        fmtUtcDate(n.dateUtc),
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
    out.add(pw.Text(n.notes, style: _bodyStyle()));
    out.add(pw.SizedBox(height: 8));
  }
  return out;
}

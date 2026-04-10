import 'dart:ui' show Canvas, PictureRecorder;

import 'package:flutter/material.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/calendar/calendar_day_data.dart';
import 'package:luma/features/calendar/calendar_painters.dart';

void main() {
  group('ConfidenceHatchedCirclePainter', () {
    // Per-hop opacity decay was removed; tier hatch density alone encodes agreement.

    test('paints without error for tiers 1–3', () {
      for (final tier in [1, 2, 3]) {
        final painter = ConfidenceHatchedCirclePainter(tier: tier);
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, const Size(40, 40));
        expect(painter.shouldRepaint(painter), isFalse);
      }
    });

    test('shouldRepaint when tier or color changes', () {
      final a = ConfidenceHatchedCirclePainter(tier: 1);
      final b = ConfidenceHatchedCirclePainter(tier: 2);
      final c = ConfidenceHatchedCirclePainter(
        tier: 1,
        color: const Color(0xFFFF0000),
      );
      expect(a.shouldRepaint(b), isTrue);
      expect(a.shouldRepaint(c), isTrue);
      expect(a.shouldRepaint(a), isFalse);
    });

    test('fertilityEstimate paints without error', () {
      final painter = ConfidenceHatchedCirclePainter(
        tier: 2,
        fertilityEstimate: true,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(40, 40));
    });

    test('shouldRepaint when fertilityEstimate changes', () {
      final a = ConfidenceHatchedCirclePainter(tier: 2);
      final b = ConfidenceHatchedCirclePainter(
        tier: 2,
        fertilityEstimate: true,
      );
      expect(a.shouldRepaint(b), isTrue);
    });
  });

  testWidgets('buildCalendarDayCell uses ConfidenceHatchedCirclePainter for tier 2',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 48,
              height: 56,
              child: buildCalendarDayCell(
                DateTime(2026, 4, 1),
                const CalendarDayData(predictionConfidenceTier: 2),
              ),
            ),
          ),
        ),
      ),
    );
    final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    expect(
      paints.any((p) => p.painter is ConfidenceHatchedCirclePainter),
      isTrue,
    );
  });

  testWidgets(
      'buildCalendarDayCell uses fertility hatched circle when fertile, no period, no prediction',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 48,
              height: 56,
              child: buildCalendarDayCell(
                DateTime(2026, 4, 1),
                const CalendarDayData(
                  isFertileDay: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    final fertility = paints.where(
      (p) =>
          p.painter is ConfidenceHatchedCirclePainter &&
          (p.painter! as ConfidenceHatchedCirclePainter).fertilityEstimate,
    );
    expect(fertility, isNotEmpty);
  });

  testWidgets('buildCalendarDayCell omits prediction painter when tier is 0',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 48,
              height: 56,
              child: buildCalendarDayCell(
                DateTime(2026, 4, 1),
                const CalendarDayData(predictionConfidenceTier: 0),
              ),
            ),
          ),
        ),
      ),
    );
    final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    expect(
      paints.any((p) => p.painter is ConfidenceHatchedCirclePainter),
      isFalse,
    );
  });

  testWidgets('buildConfidenceLegend shows three labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => buildConfidenceLegend(context),
          ),
        ),
      ),
    );
    expect(find.text('1 method'), findsOneWidget);
    expect(find.text('2 methods'), findsOneWidget);
    expect(find.text('3+ methods'), findsOneWidget);
  });
}

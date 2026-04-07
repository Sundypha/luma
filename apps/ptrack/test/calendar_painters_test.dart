import 'dart:ui' show Canvas, PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/calendar/calendar_day_data.dart';
import 'package:luma/features/calendar/calendar_painters.dart';

void main() {
  group('ConfidenceHatchedCirclePainter', () {
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
  });

  testWidgets('buildCalendarDayCell uses ConfidenceHatchedCirclePainter for tier 2',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
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

  testWidgets('buildCalendarDayCell omits prediction painter when tier is 0',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
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

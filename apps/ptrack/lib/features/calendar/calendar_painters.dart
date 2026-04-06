import 'package:flutter/material.dart';

import 'calendar_day_data.dart';

/// Deep pink/magenta for logged period bands and related accents.
const Color kPeriodColor = Color(0xFFD81B60);

/// Lighter variant for outlines and hatching (NFR-06: pattern + contrast).
const Color kPeriodColorLight = Color(0xFFF48FB1);

/// Solid-fill horizontal band for logged period days; shape follows [PeriodDayState].
class PeriodBandPainter extends CustomPainter {
  PeriodBandPainter({
    required this.state,
    this.color = kPeriodColor,
  });

  final PeriodDayState state;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (state == PeriodDayState.none) return;

    final bandHeight = size.height * 0.52;
    final top = (size.height - bandHeight) / 2;
    final rect = Rect.fromLTWH(0, top, size.width, bandHeight);
    final r = Radius.circular(bandHeight / 2);
    final rrect = _rrectForState(rect, r);
    canvas.drawRRect(rrect, Paint()..color = color);
  }

  RRect _rrectForState(Rect rect, Radius corner) {
    switch (state) {
      case PeriodDayState.none:
        return RRect.fromRectAndRadius(rect, Radius.zero);
      case PeriodDayState.start:
      case PeriodDayState.middleRowStart:
        return RRect.fromRectAndCorners(
          rect,
          topLeft: corner,
          bottomLeft: corner,
          topRight: Radius.zero,
          bottomRight: Radius.zero,
        );
      case PeriodDayState.end:
      case PeriodDayState.middleRowEnd:
        return RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.zero,
          bottomLeft: Radius.zero,
          topRight: corner,
          bottomRight: corner,
        );
      case PeriodDayState.single:
        return RRect.fromRectAndRadius(rect, corner);
      case PeriodDayState.middle:
        return RRect.fromRectAndRadius(rect, Radius.zero);
    }
  }

  @override
  bool shouldRepaint(covariant PeriodBandPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.color != color;
  }
}

/// Diagonal-stripe circle for predicted period days (distinct from solid logged band).
class HatchedCirclePainter extends CustomPainter {
  HatchedCirclePainter({
    this.color = kPeriodColorLight,
    this.stripeSpacing = 4.0,
  });

  final Color color;
  final double stripeSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.36;
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(circlePath);

    final stripePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var offset = -size.height;
        offset < size.width + size.height;
        offset += stripeSpacing) {
      canvas.drawLine(
        Offset(offset, size.height),
        Offset(offset + size.height, 0),
        stripePaint,
      );
    }

    canvas.restore();

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant HatchedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.stripeSpacing != stripeSpacing;
  }
}

/// Small dot below center for days with logged symptoms/notes/mood.
class DotIndicatorPainter extends CustomPainter {
  DotIndicatorPainter({this.color = kPeriodColor});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    canvas.drawCircle(center, 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant DotIndicatorPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Ring around today's date cell.
class TodayRingPainter extends CustomPainter {
  TodayRingPainter({this.color = kPeriodColor});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant TodayRingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Stacks period band, prediction hatch, today ring, day number, and data dot.
Widget buildCalendarDayCell(DateTime day, CalendarDayData data) {
  return Stack(
    alignment: Alignment.center,
    clipBehavior: Clip.none,
    children: [
      if (data.loggedPeriodState != PeriodDayState.none)
        Positioned.fill(
          child: CustomPaint(
            painter: PeriodBandPainter(state: data.loggedPeriodState),
          ),
        ),
      if (data.isPredictedPeriod && data.loggedPeriodState == PeriodDayState.none)
        Positioned.fill(
          child: CustomPaint(painter: HatchedCirclePainter()),
        ),
      if (data.isToday)
        Positioned.fill(
          child: CustomPaint(painter: TodayRingPainter()),
        ),
      Text(
        '${day.day}',
        style: TextStyle(
          color: data.loggedPeriodState != PeriodDayState.none
              ? Colors.white
              : null,
          fontWeight: data.isToday ? FontWeight.bold : null,
        ),
      ),
      if (data.hasLoggedData)
        Positioned.fill(
          child: CustomPaint(painter: DotIndicatorPainter()),
        ),
    ],
  );
}

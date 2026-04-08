import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'calendar_day_data.dart';

/// Deep pink/magenta for logged period bands and related accents.
const Color kPeriodColor = Color(0xFFD81B60);

/// Lighter variant for outlines and hatching (NFR-06: pattern + contrast).
const Color kPeriodColorLight = Color(0xFFF48FB1);

/// Material teal 400 — soft teal/green for optional fertility estimate marker.
const Color kFertilityColor = Color(0xFF26A69A);

/// Solid-fill horizontal band for logged period days; shape follows [PeriodDayState].
class PeriodBandPainter extends CustomPainter {
  PeriodBandPainter({
    required this.state,
    this.color = kPeriodColor,
  });

  final PeriodDayState state;
  final Color color;

  /// Overlap into neighbour cells (table cells are flush; seams come from geometry).
  static double _bleedX(double cellWidth) =>
      (cellWidth * 0.22).clamp(10.0, 18.0);

  Radius _endRadius(double bandHeight) {
    final isRowBreak = state == PeriodDayState.middleRowStart ||
        state == PeriodDayState.middleRowEnd;
    // Full pill on true span ends; subtler arcs at week row breaks so spans feel less "bubbly".
    final cap = isRowBreak ? 5.5 : bandHeight / 2;
    return Radius.circular(cap.clamp(3.0, bandHeight / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (state == PeriodDayState.none) return;

    final bandHeight = (size.height * 0.44).clamp(20.0, 40.0);
    final top = (size.height - bandHeight) / 2;
    final b = _bleedX(size.width);
    final rect = switch (state) {
      PeriodDayState.none => Rect.zero,
      PeriodDayState.start ||
      PeriodDayState.middleRowStart =>
        Rect.fromLTWH(0, top, size.width + b, bandHeight),
      PeriodDayState.end ||
      PeriodDayState.middleRowEnd =>
        Rect.fromLTWH(-b, top, size.width + b, bandHeight),
      PeriodDayState.middle => Rect.fromLTWH(-b, top, size.width + 2 * b, bandHeight),
      PeriodDayState.single =>
        Rect.fromLTWH(-b * 0.25, top, size.width + b * 0.5, bandHeight),
    };
    final r = _endRadius(bandHeight);
    final rrect = _rrectForState(rect, r);
    canvas.drawRRect(rrect, Paint()..color = color);
  }

  RRect _rrectForState(Rect rect, Radius corner) {
    switch (state) {
      case PeriodDayState.none:
        return RRect.fromRectAndRadius(rect, Radius.zero);
      case PeriodDayState.start:
        return RRect.fromRectAndCorners(
          rect,
          topLeft: corner,
          bottomLeft: corner,
          topRight: Radius.zero,
          bottomRight: Radius.zero,
        );
      case PeriodDayState.middleRowStart:
        return RRect.fromRectAndCorners(
          rect,
          topLeft: corner,
          bottomLeft: corner,
          topRight: Radius.zero,
          bottomRight: Radius.zero,
        );
      case PeriodDayState.end:
        return RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.zero,
          bottomLeft: Radius.zero,
          topRight: corner,
          bottomRight: corner,
        );
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

/// Diagonal-stripe circle for predicted days: opacity + hatch density encode agreement
/// tier (NFR-06 — not color alone).
///
/// [cycleIndex] = 0 is the next predicted period, 1 is the one after, etc.
/// [cycleSpreadDays] drives how fast opacity fades per hop (more irregular = faster fade).
class ConfidenceHatchedCirclePainter extends CustomPainter {
  ConfidenceHatchedCirclePainter({
    required int tier,
    this.color = kPeriodColorLight,
    this.cycleIndex = 0,
    this.cycleSpreadDays = 0,
  }) : tier = tier.clamp(1, 3);

  final int tier;
  final Color color;

  /// Which projected cycle hop this day belongs to (0 = next period).
  final int cycleIndex;

  /// Historical cycle-length spread in days; higher = less regular = faster fade.
  final int cycleSpreadDays;

  static const Map<int, ({double opacity, double spacing, double strokeWidth})>
      _tierConfig = {
    1: (opacity: 0.30, spacing: 7.0, strokeWidth: 1.0),
    2: (opacity: 0.55, spacing: 4.5, strokeWidth: 1.3),
    3: (opacity: 0.85, spacing: 3.0, strokeWidth: 1.6),
  };

  /// Decay factor per cycle hop: lower spread = more reliable = slower fade.
  double get _decayFactor {
    if (cycleSpreadDays < 4) return 0.72;
    if (cycleSpreadDays < 8) return 0.52;
    return 0.32;
  }

  double get _opacityMultiplier {
    if (cycleIndex <= 0) return 1.0;
    return _decayFactor.clamp(0.05, 1.0) *
        _opacityMultiplierForIndex(cycleIndex - 1);
  }

  double _opacityMultiplierForIndex(int idx) {
    if (idx <= 0) return _decayFactor;
    return _decayFactor * _opacityMultiplierForIndex(idx - 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cfg = _tierConfig[tier]!;
    final effectiveOpacity = (cfg.opacity * _opacityMultiplier).clamp(0.04, 1.0);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.36;
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final strokeColor = color.withValues(alpha: effectiveOpacity);

    canvas.save();
    canvas.clipPath(circlePath);

    final stripePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = cfg.strokeWidth
      ..style = PaintingStyle.stroke;

    for (var offset = -size.height;
        offset < size.width + size.height;
        offset += cfg.spacing) {
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
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cfg.strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant ConfidenceHatchedCirclePainter oldDelegate) {
    return oldDelegate.tier != tier ||
        oldDelegate.color != color ||
        oldDelegate.cycleIndex != cycleIndex ||
        oldDelegate.cycleSpreadDays != cycleSpreadDays;
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

/// Small diamond below the day number for estimated fertile days (NFR-06: not color-only).
class FertilityDotPainter extends CustomPainter {
  FertilityDotPainter({this.color = kFertilityColor});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 3.0;
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant FertilityDotPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Height reserved under the day number for the optional log marker (keeps grid even).
const double kCalendarLogMarkerStripHeight = 11.0;

/// Logged-symptoms marker: separate from band so spacing stays predictable.
Widget _logMarkerChip() {
  return Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: kPeriodColor,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 1.25),
      boxShadow: [
        BoxShadow(
          color: kPeriodColor.withValues(alpha: 0.35),
          blurRadius: 3,
          spreadRadius: 0,
        ),
      ],
    ),
  );
}

Widget _fertilityDiamondDot() {
  return CustomPaint(
    size: const Size(6, 6),
    painter: FertilityDotPainter(),
  );
}

Widget _calendarBottomMarkers(CalendarDayData data) {
  final fertile = data.isFertileDay;
  final log = data.hasLoggedData;
  if (!fertile && !log) return const SizedBox.shrink();
  if (fertile && log) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _logMarkerChip(),
          const SizedBox(width: 5),
          _fertilityDiamondDot(),
        ],
      ),
    );
  }
  if (fertile) {
    return Center(child: _fertilityDiamondDot());
  }
  return Center(child: _logMarkerChip());
}

/// Stacks period band, prediction hatch, today ring, and day number; marker sits below.
///
/// [cycleSpreadDays] is passed to [ConfidenceHatchedCirclePainter] for
/// variability-aware opacity decay on multi-hop projected days.
Widget buildCalendarDayCell(
  DateTime day,
  CalendarDayData data, {
  int cycleSpreadDays = 0,
}) {
  final hasPeriod = data.loggedPeriodState != PeriodDayState.none;

  return Column(
    mainAxisSize: MainAxisSize.max,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (hasPeriod)
              Positioned.fill(
                child: CustomPaint(
                  painter: PeriodBandPainter(state: data.loggedPeriodState),
                ),
              ),
            if (data.predictionConfidenceTier > 0 && !hasPeriod)
              Positioned.fill(
                child: CustomPaint(
                  painter: ConfidenceHatchedCirclePainter(
                    tier: data.predictionConfidenceTier,
                    cycleIndex: data.predictionCycleIndex,
                    cycleSpreadDays: cycleSpreadDays,
                  ),
                ),
              ),
            if (data.isToday && !hasPeriod)
              Positioned.fill(
                child: CustomPaint(painter: TodayRingPainter()),
              ),
            if (data.isToday && hasPeriod)
              Positioned.fill(
                child: CustomPaint(painter: TodayOnPeriodPainter()),
              ),
            Text(
              '${day.day}',
              style: TextStyle(
                color: hasPeriod ? Colors.white : null,
                fontWeight: data.isToday ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        height: kCalendarLogMarkerStripHeight,
        child: _calendarBottomMarkers(data),
      ),
    ],
  );
}

/// Compact legend for prediction agreement tiers (below calendar grid).
Widget buildConfidenceLegend(
  BuildContext context, {
  bool showFertilityLegend = false,
  bool showPredictionTierLegend = true,
}) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context);
  final style = theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
  Widget swatch(int tier, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CustomPaint(
            painter: ConfidenceHatchedCirclePainter(tier: tier),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }

  final children = <Widget>[];
  if (showPredictionTierLegend) {
    children.addAll([
      swatch(1, '1 method'),
      swatch(2, '2 methods'),
      swatch(3, '3+ methods'),
    ]);
  }
  if (showFertilityLegend) {
    children.add(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Center(
              child: CustomPaint(
                size: const Size(8, 8),
                painter: FertilityDotPainter(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(l10n.fertilityCalendarLegendLabel, style: style),
        ],
      ),
    );
  }

  if (children.isEmpty) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Wrap(
      spacing: 16,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    ),
  );
}

/// Soft outline when today falls on a period band (avoids fighting a full circle ring).
class TodayOnPeriodPainter extends CustomPainter {
  TodayOnPeriodPainter({this.color = Colors.white});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 2.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - 2 * inset,
        size.height - 2 * inset,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75,
    );
  }

  @override
  bool shouldRepaint(covariant TodayOnPeriodPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

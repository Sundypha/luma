---
created: 2026-04-08T09:47:45.030Z
title: Remove opacity for period projection after 3 months
area: ui
files:
  - apps/ptrack/lib/features/calendar/calendar_painters.dart:106-156
---

## Problem

The calendar's period projection uses an opacity-decay model (`_opacityMultiplier`, `_opacityMultiplierForIndex`) that fades hatched-circle markers for cycles beyond the first predicted one. After ~3 months out, the markers become very hard to read — nearly invisible — making the calendar confusing rather than informative.

The opacity decay is unnecessary because the detail view already communicates prediction uncertainty (confidence tiers, spread). The visual encoding via hatch density and tier-based spacing/stroke already differentiates confidence levels without needing opacity reduction.

## Solution

Remove or flatten the per-cycle opacity decay so all projected periods render at the same opacity as the next predicted cycle (cycleIndex 0). Keep the tier-based hatch density/spacing/strokeWidth differentiation — that already encodes confidence. Specifically:
- Make `_opacityMultiplier` always return 1.0 (or remove the decay logic)
- Remove `cycleIndex`-based fading in `ConfidenceHatchedCirclePainter`
- Update tests in `calendar_painters_test.dart` accordingly

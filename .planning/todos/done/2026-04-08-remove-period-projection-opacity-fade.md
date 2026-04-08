---
created: 2026-04-08T09:47:45.030Z
title: Remove period projection opacity fade
area: ui
files:
  - apps/ptrack/lib/features/calendar/calendar_painters.dart:106-156
---

## Problem

The calendar's period projection uses an opacity-decay model (`_opacityMultiplier`, `_opacityMultiplierForIndex`) that fades hatched-circle markers for cycles beyond the first predicted one. That makes later projections harder to read than necessary; the fade does not add clarity.

The opacity decay is unnecessary in general because the detail view already communicates prediction uncertainty (confidence tiers, spread). The visual encoding via hatch density and tier-based spacing/stroke already differentiates confidence levels without needing opacity reduction per projected cycle.

## Solution

Remove per-cycle opacity decay entirely so all projected periods use full tier opacity (same visual weight as the next predicted cycle for a given tier). Keep the tier-based hatch density/spacing/strokeWidth differentiation — that already encodes confidence. Specifically:
- Make `_opacityMultiplier` always return 1.0 (or remove the decay logic)
- Remove `cycleIndex`-based fading in `ConfidenceHatchedCirclePainter`
- Update tests in `calendar_painters_test.dart` accordingly

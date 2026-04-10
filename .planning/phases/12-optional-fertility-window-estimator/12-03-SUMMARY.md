---
phase: 12-optional-fertility-window-estimator
plan: 03
subsystem: ui
tags: [flutter, calendar, fertility, NFR-06, accessibility]

requires:
  - phase: 12-optional-fertility-window-estimator
    provides: FertilityWindowCalculator, FertilitySettings, fertility ARB strings
provides:
  - CalendarDayData.isFertileDay and fertile window integration in buildCalendarDayDataMap
  - CalendarViewModel fertility prefs load, FertilityWindowCalculator wiring, updateFertilityEnabled
  - FertilityDotPainter (teal diamond), legend row, day detail fertility copy
affects:
  - 12-04-PLAN (onFertilityToggled should call updateFertilityEnabled)

tech-stack:
  added: []
  patterns:
    - "Fertile UTC day set from calculator range; suppressed on logged bleeding days like predictions"
    - "Legend composes prediction tier swatches only when ensemble active; fertility row when opt-in on"

key-files:
  created: []
  modified:
    - apps/ptrack/lib/features/calendar/calendar_day_data.dart
    - apps/ptrack/lib/features/calendar/calendar_view_model.dart
    - apps/ptrack/lib/features/calendar/calendar_painters.dart
    - apps/ptrack/lib/features/calendar/calendar_screen.dart
    - apps/ptrack/lib/features/calendar/day_detail_sheet.dart

key-decisions:
  - "buildConfidenceLegend takes showPredictionTierLegend so fertility-only users see the diamond legend without empty prediction tier swatches."
  - "Cycle lengths for the calculator reuse predictionCycleInputsFromStored / completed-cycle extraction already used by the ensemble path."

patterns-established:
  - "Teal diamond in log-marker strip distinct from circular period chip and hatched prediction circles (NFR-06)."

requirements-completed: [FERT-03]

duration: 35min
completed: 2026-04-08
---

# Phase 12 Plan 03: Calendar fertility visuals Summary

**Teal diamond markers on estimated fertile days, conditional legend with localized label, and day-detail explanatory line wired through CalendarViewModel and FertilityWindowCalculator.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-08T10:15:00Z (approx.)
- **Completed:** 2026-04-08T10:50:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- `CalendarDayData.isFertileDay` and optional `fertileDays` on `buildCalendarDayDataMap`, excluding days covered by logged bleeding.
- View model loads fertility enabled / cycle override / luteal phase; builds fertile day set from history average or override; `updateFertilityEnabled` for Plan 04.
- `FertilityDotPainter` diamond under the date; log marker + diamond in a row when both apply; legend and day sheet use existing ARB keys.

## Task Commits

1. **Task 1: CalendarDayData fertility field + CalendarViewModel wiring** — `42c1778` (feat)
2. **Task 2: FertilityDotPainter + calendar cell + legend + day detail label** — `8aa7df7` (feat)

**Plan metadata:** Planning artifacts committed with message `docs(12-03): Complete calendar fertility visuals plan` (see `git log`).

## Files Created/Modified

- `calendar_day_data.dart` — `isFertileDay`, `fertileDays` parameter, merge into day map.
- `calendar_view_model.dart` — fertility prefs, `_fertileDaysForStored`, `fertilityEnabled`, `updateFertilityEnabled`.
- `calendar_painters.dart` — `kFertilityColor`, `FertilityDotPainter`, bottom markers, `buildConfidenceLegend` options.
- `calendar_screen.dart` — legend when predictions or fertility on; pass flags to legend builder.
- `day_detail_sheet.dart` — `_fertilityDetailNote` after date headers across sheet variants.

## Decisions Made

- Split legend visibility: show prediction tier swatches only when `activeAlgorithmCount > 0`; always add fertility row when `fertilityEnabled` so the calendar does not imply fake prediction tiers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] `Future.wait<Object>` rejected `Future<int?>` for cycle override**

- **Found during:** Task 1 verification (`dart analyze`)
- **Issue:** Generic `Future.wait<Object>` could not hold `Future<int?>`.
- **Fix:** Use untyped `Future.wait([...])` with existing casts on results.
- **Files modified:** `calendar_view_model.dart`
- **Verification:** `dart analyze` on modified calendar files — clean
- **Committed in:** `42c1778`

---

**Total deviations:** 1 auto-fixed (blocking)

**Impact on plan:** No product behavior change beyond analyzer compliance.

## Issues Encountered

- Workspace `HEAD` for calendar files differed from the working tree used during implementation; task commits show larger line deltas than the minimal semantic edit (content matches current ensemble/day-data model; `fvm flutter test` for calendar tests passed).

## User Setup Required

None.

## Next Phase Readiness

- Plan 04 can call `CalendarViewModel.updateFertilityEnabled` from `tab_shell` when the fertility tile toggles opt-in.
- Home/suggestion UI can reuse the same calculator/settings patterns.

## Self-Check: PASSED

- `.planning/phases/12-optional-fertility-window-estimator/12-03-SUMMARY.md` exists
- Task commits `42c1778`, `8aa7df7` and docs commit for `docs(12-03): Complete calendar fertility visuals plan` present on branch

---
*Phase: 12-optional-fertility-window-estimator*  
*Completed: 2026-04-08*

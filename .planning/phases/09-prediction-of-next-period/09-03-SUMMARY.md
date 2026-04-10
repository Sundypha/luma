---
phase: 09-prediction-of-next-period
plan: 03
subsystem: ui
tags: [dart, flutter, ensemble, calendar, prediction, shared_preferences, NFR-06, PRED-03, PRED-04]

requires:
  - phase: 09-prediction-of-next-period
    provides: EnsembleCoordinator, buildCalendarDayDataMap ensemble path, PredictionSettings

provides:
  - ConfidenceHatchedCirclePainter (opacity + hatch density tiers) and calendar legend
  - CalendarViewModel / HomeViewModel wired to ensemble + persisted display mode
  - Day detail methods-agree copy with expandable per-algorithm lines
  - Home explanation bottom sheet and dismissible milestone card
  - PredictionSettingsTile in drawer settings with calendar refresh callback

affects:
  - Human UAT for prediction UX; any future copy or accessibility review

tech-stack:
  added: []
  patterns:
    - "CalendarViewModel loads PredictionDisplayMode on startup; updateDisplayMode saves + recomputes"
    - "Milestone dismissal keyed by activeAlgorithmCount in SharedPreferences"
    - "Tests mock SharedPreferences for CalendarViewModel construction"

key-files:
  created:
    - apps/ptrack/test/calendar_painters_test.dart
  modified:
    - apps/ptrack/lib/features/calendar/calendar_painters.dart
    - apps/ptrack/lib/features/calendar/calendar_view_model.dart
    - apps/ptrack/lib/features/calendar/calendar_screen.dart
    - apps/ptrack/lib/features/calendar/day_detail_sheet.dart
    - apps/ptrack/lib/features/home/home_view_model.dart
    - apps/ptrack/lib/features/home/home_screen.dart
    - apps/ptrack/lib/features/settings/prediction_settings.dart
    - apps/ptrack/lib/features/shell/tab_shell.dart
    - apps/ptrack/test/features/calendar/calendar_view_model_test.dart
    - apps/ptrack/test/features/calendar/calendar_screen_test.dart
    - apps/ptrack/test/features/calendar/day_detail_sheet_test.dart

key-decisions:
  - "CalendarViewModel uses _disposed so PredictionSettings.load().then never notifies after dispose"
  - "showAllWithNote settings subtitle avoids the word confidence in user-visible copy (PRED-04)"

patterns-established:
  - "PredictionSettingsTile optional onModeChanged syncs calendar VM without tight coupling to settings widget"

requirements-completed: [PRED-02, PRED-03, PRED-04, NFR-06]

duration: 55min
completed: 2026-04-07
---

# Phase 9 Plan 03: Ensemble UI wiring summary

**Tiered calendar hatching (opacity + density), ensemble-backed ViewModels, day-detail and home explanation UX, prediction display settings, and milestone card — with tests and prefs-safe VM lifecycle.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-04-07 (approx.)
- **Completed:** 2026-04-07
- **Tasks:** 2
- **Files touched:** 11 (app + tests)

## Accomplishments

- Replaced uniform predicted-day hatch with three agreement tiers using dual visual channels (NFR-06).
- Calendar and home tabs consume `EnsembleCoordinator` output; calendar respects loaded/saved `PredictionDisplayMode`.
- Users see methods-agree framing on predicted days, optional algorithm breakdown, home explanation sheet, and dismissible milestones.

## Task Commits

1. **Task 1: ConfidenceHatchedCirclePainter, ViewModel ensemble wiring, legend, tests** — `6041ed6` (feat)
2. **Task 2: Day detail, home UX, PredictionSettingsTile, test prefs + dispose guard** — `0246221` (feat)

**Plan metadata:** (docs commit after STATE/ROADMAP/REQUIREMENTS)

## Files Created/Modified

- `calendar_painters.dart` — `ConfidenceHatchedCirclePainter`, `buildConfidenceLegend`, tier-based cell paint.
- `calendar_view_model.dart` — Ensemble + display mode + `ensembleResult` + async settings load with dispose guard.
- `calendar_screen.dart` — Legend below grid when `activeAlgorithmCount > 0`.
- `home_view_model.dart` — Ensemble, `milestoneMessage`, `ensembleExplanationText`, `activeAlgorithmCount`.
- `home_screen.dart` — “How is this calculated?” sheet, milestone card with prefs dismissal.
- `day_detail_sheet.dart` — Agreement summary, expandable per-method lines for covering algorithms.
- `prediction_settings.dart` — `PredictionSettingsTile`, `subtitleForMode` helper.
- `tab_shell.dart` — Settings tile + `unawaited(updateDisplayMode)`.
- `calendar_painters_test.dart` — Painter and legend widget tests.
- Calendar tests — `SharedPreferences.setMockInitialValues({})` in setUp.

## Decisions Made

- Skipped calling `notifyListeners` after `PredictionSettings.load` when the view model was already disposed (fast unit tests).
- Reframed the `showAllWithNote` settings subtitle to avoid user-facing “confidence” while preserving behavior (PRED-04).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] SharedPreferences plugin missing in tests after CalendarViewModel loads settings**

- **Found during:** Task 2 verification (`flutter test`)
- **Issue:** `PredictionSettings.load()` in `CalendarViewModel` ctor caused `MissingPluginException` in tests.
- **Fix:** `SharedPreferences.setMockInitialValues({})` in calendar-related test `setUp`.
- **Files modified:** `calendar_view_model_test.dart`, `calendar_screen_test.dart`, `day_detail_sheet_test.dart`
- **Committed in:** `0246221`

**2. [Rule 1 - Bug] notifyListeners after dispose from async settings load**

- **Found during:** Task 2 verification
- **Issue:** Fast tests disposed the VM before `PredictionSettings.load` completed.
- **Fix:** `_disposed` flag checked in the load `.then` callback; set in `dispose`.
- **Files modified:** `calendar_view_model.dart`
- **Committed in:** `0246221`

**3. [Rule 2 - Missing critical copy guard] User-visible “low-confidence” in settings subtitle**

- **Found during:** Plan verification grep (PRED-04)
- **Issue:** Plan’s literal subtitle used the word “confidence.”
- **Fix:** Reworded subtitle to describe single-method behavior without “confidence.”
- **Files modified:** `prediction_settings.dart`
- **Committed in:** `0246221`

---

**Total deviations:** 3 auto-fixed (1 blocking, 1 bug, 1 copy guard)
**Impact on plan:** No scope creep; tests and lifecycle correctness only.

## Issues Encountered

None beyond deviations above.

## User Setup Required

None.

## Next Phase Readiness

- Phase 9 plans are complete on disk after roadmap/state sync; optional human UAT on prediction UX and copy.

---
*Phase: 09-prediction-of-next-period*

*Completed: 2026-04-07*

## Self-Check: PASSED

- `09-03-SUMMARY.md` exists at `.planning/phases/09-prediction-of-next-period/09-03-SUMMARY.md`
- Task commits `6041ed6`, `0246221` present on branch
- `fvm flutter analyze --fatal-infos` and `fvm flutter test` passed for `apps/ptrack` after changes

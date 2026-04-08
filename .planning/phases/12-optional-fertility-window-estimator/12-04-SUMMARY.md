---
phase: 12-optional-fertility-window-estimator
plan: 04
subsystem: ui
tags: [flutter, fertility, home, mvvm, shared_preferences]

requires:
  - phase: 12-optional-fertility-window-estimator
    provides: FertilityWindowCalculator, FertilitySettings, fertility ARB strings, CalendarViewModel.updateFertilityEnabled
provides:
  - HomeViewModel fertile window computation aligned with predictionCycleInputsFromStored
  - Home fertility card (teal tint, date range, optional average-cycle line, Estimate only footer)
  - Suggestion card (grayed when <2 completed intervals, dismiss persists, Enable opens settings)
  - Tab shell onFertilityToggled wiring to calendar + home VMs
affects:
  - Phase 12 closure (human UAT pending Task 3)
  - REQUIREMENTS FERT-03 / FERT-04 (not marked complete until Task 3 approved)

tech-stack:
  added: []
  patterns:
    - "Home fertility math mirrors CalendarViewModel: predictionCycleInputsFromStored + FertilityWindowCalculator"
    - "Suggestion card uses fertilitySuggestion* ARB keys; settings entry via HomeScreen.onOpenSettings"

key-files:
  created: []
  modified:
    - apps/ptrack/lib/features/home/home_view_model.dart
    - apps/ptrack/lib/features/home/home_screen.dart
    - apps/ptrack/lib/features/shell/tab_shell.dart

key-decisions:
  - "Average-cycle explanation line on the home fertility card only when computedAverageCycleLength is non-null (override-only estimates omit that line to avoid misleading copy)."
  - "hasEnoughDataForFertility uses ≥2 entries from predictionCycleInputsFromStored (same completed-interval notion as history summary)."

patterns-established:
  - "Settings fertility toggle callbacks fan out to both CalendarViewModel and HomeViewModel for immediate recompute"

requirements-completed: []
requirements-deferred-pending-human-verify: [FERT-03, FERT-04]

execution_status: paused_at_checkpoint_task_3

duration: 35min
completed: 2026-04-08
---

# Phase 12 Plan 04: Home fertility card and tab wiring Summary

**Home surfaces the estimated fertile window with a teal card and persistent “Estimate only” footer, plus a first-run suggestion card; settings fertility toggle now refreshes both calendar and home ViewModels.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-08T11:00:00Z (approx.)
- **Completed:** 2026-04-08T11:35:00Z (approx.) — automation only; **Task 3 not signed off**
- **Tasks completed (automated):** 2 / 3
- **Files modified:** 3

## Accomplishments

- **HomeViewModel** loads fertility prefs with prediction settings, computes `_fertileWindow` with `FertilityWindowCalculator` when enabled, exposes `showSuggestionCard`, `hasEnoughDataForFertility`, `computedAverageCycleLength`, `updateFertilityEnabled`, and `dismissSuggestionCard`.
- **HomeScreen** shows `_FertilitySuggestionCard` above `TodayCard` and `_FertilityWindowHomeCard` below the milestone notice when enabled and a window exists; suggestion navigates via `onOpenSettings`.
- **TabShell** passes `onFertilityToggled` to `_SettingsScreen` so `_calendarVm` and `_homeVm` both call `updateFertilityEnabled`.

## Task Commits (automated)

1. **Task 1: HomeViewModel + home fertility / suggestion UI** — `e9bf84c` (feat)
2. **Task 2: Tab shell fertility toggle wiring** — `c155b9e` (feat)

**Plan metadata:** `docs(12-04): Record plan progress and UAT checkpoint` — this file, `STATE.md`, and `ROADMAP.md` (see `git log` on branch).

## Task 3 — Checkpoint: human-verify (blocking)

**Status:** **Not executed by automation.** No human approval was recorded.

**What was built (full stack for UAT):** Plans 01–04 deliver calculator, settings opt-in, calendar markers, and home card + suggestion + VM refresh on toggle.

**How to verify (from `12-04-PLAN.md`):**

1. Run `cd apps/ptrack && flutter run` (or IDE).
2. **Fresh state:** suggestion card visible (grayed if \<2 completed intervals); no fertility dots on calendar; fertility off in settings.
3. Log 3+ periods; suggestion card active; use **Enable** / settings to complete opt-in; confirm calendar dots, home card with range + footer, disable clears visuals, dismiss (X) on suggestion persists across restart; spot-check German strings.

**Resume signal:** User types `approved` or describes issues (per plan).

## Files Created/Modified

- `apps/ptrack/lib/features/home/home_view_model.dart` — fertility prefs, `_fertileWindow` in `_recompute`, public API for cards and settings sync.
- `apps/ptrack/lib/features/home/home_screen.dart` — `_FertilityWindowHomeCard`, `_FertilitySuggestionCard`, `onOpenSettings`.
- `apps/ptrack/lib/features/shell/tab_shell.dart` — `onFertilityToggled` and `HomeScreen.onOpenSettings`.

## Decisions Made

- Omitted the “average cycle” explanation when only a manual cycle-length override applies (`computedAverageCycleLength` null) so the string is not literally false.
- Treated “enough data” as `predictionCycleInputsFromStored` returning at least two intervals (aligned with plan manual “log 3+ periods” and history summary).

## Deviations from Plan

None — plan Tasks 1–2 executed as written; Task 3 intentionally deferred pending human verification.

## Issues Encountered

- `dart test` without FVM failed (native assets experiment); verification used `fvm flutter test test/features/home/home_view_model_test.dart` — passed.

## User Setup Required

None.

## Next Phase Readiness

- After Task 3 approval: run `requirements mark-complete` for **FERT-03** and **FERT-04** if traceability still ties them to this plan; consider advancing `STATE.md` plan pointer and checking phase 12 for milestone closure.

## Self-Check: PASSED

- `12-04-SUMMARY.md` exists at `.planning/phases/12-optional-fertility-window-estimator/12-04-SUMMARY.md`
- Task commits `e9bf84c`, `c155b9e` and docs commit `docs(12-04): Record plan progress and UAT checkpoint` present (`git log --oneline --grep=12-04`)

---
*Phase: 12-optional-fertility-window-estimator*  
*Automation completed: 2026-04-08 — **Task 3 human-verify outstanding***

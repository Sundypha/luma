---
phase: 12-optional-fertility-window-estimator
plan: 01
subsystem: testing
tags: [dart, flutter, domain, fertility, calendar-method, PRED-04]

requires:
  - phase: 11-german-language-settings
    provides: Stable i18n and domain packages for v2.0 fertility work
provides:
  - On-device FertileWindow model and FertilityWindowCalculator (compute + averageCycleLengthFromHistory)
  - Extended prediction copy forbidden phrases ("safe days", "birth control") and tests
  - predictionCopyTextPassesGuard + formatEnsembleExplanation aligned with EnsembleMilestone
affects:
  - 12-02 through 12-04 (UI and settings consuming calculator)
  - App prediction_localizations (uses predictionCopyTextPassesGuard)

tech-stack:
  added: []
  patterns:
    - "UTC midnight normalization via private _utcMidnight"
    - "TDD RED (stub null) then GREEN full implementation"

key-files:
  created:
    - packages/ptrack_domain/lib/src/prediction/fertility_window.dart
    - packages/ptrack_domain/test/fertility_window_test.dart
  modified:
    - packages/ptrack_domain/lib/ptrack_domain.dart
    - packages/ptrack_domain/lib/src/prediction/prediction_copy.dart
    - packages/ptrack_domain/test/prediction_copy_test.dart

key-decisions:
  - "Ovulation date uses cycle day (cycleLength − luteal), i.e. add (cycleLength − luteal − 1) days after normalized period start, matching the plan’s table vectors."
  - "Domain formatEnsembleExplanation appends English milestone lines via EnsembleMilestone + _formatEnsembleMilestoneEn (replacing removed milestoneMessage string)."

patterns-established:
  - "FertilityWindowCalculator as pure static API for deterministic on-device estimates"

requirements-completed: [FERT-05]

duration: 28min
completed: 2026-04-08
---

# Phase 12 Plan 01: Fertility window engine (TDD) summary

**Calendar-method FertileWindow with validated inputs, documented assumptions, unit-locked table vectors, and PRED-04 phrases extended for fertility-adjacent wording.**

## Performance

- **Duration:** ~28 min
- **Started:** 2026-04-08T09:30:00Z (approx.)
- **Completed:** 2026-04-08T10:00:00Z (approx.)
- **Tasks:** 2 (TDD RED + GREEN)
- **Files touched:** 5

## Accomplishments

- Implemented `FertileWindow` and `FertilityWindowCalculator.compute` / `averageCycleLengthFromHistory` with bounds, UTC normalization, and fertile-start clamping.
- Barrel-exported from `ptrack_domain`; `fertility_window_test.dart` covers plan table rows, invalid inputs, normalization, clamp, and averages.
- Added `"safe days"` and `"birth control"` to `predictionCopyForbiddenPhrasesLowercase` with tests; restored and reconciled `prediction_copy.dart` with `EnsembleMilestone` and public `predictionCopyTextPassesGuard`.

## Task Commits

1. **Task 1: RED — failing tests + stub** — `10f606d` (test)
2. **Task 2: GREEN — implementation + guardrails** — `8d07393` (feat)

**Plan metadata:** Docs commit on branch: `docs(12-01): Complete fertility window engine plan` (see `git log`).

_Note: feat commit amended once to restore full `prediction_copy.dart` and fix `EnsemblePredictionResult` milestone wiring._

## Files Created/Modified

- `packages/ptrack_domain/lib/src/prediction/fertility_window.dart` — model, calculator, doc comments (formula, caveats, clinical shorthand).
- `packages/ptrack_domain/test/fertility_window_test.dart` — scenario tests (≥80 lines).
- `packages/ptrack_domain/lib/ptrack_domain.dart` — export `fertility_window.dart`.
- `packages/ptrack_domain/lib/src/prediction/prediction_copy.dart` — forbidden phrases; `predictionCopyTextPassesGuard`; ensemble milestone English helper.
- `packages/ptrack_domain/test/prediction_copy_test.dart` — fertility phrase coverage.

## Decisions Made

- Matched ovulation placement to the plan’s worked examples using cycle-day indexing (first bleeding day = cycle day 1).
- Kept domain `formatEnsembleExplanation` English-only with structured milestone lines instead of a free-form `milestoneMessage` field.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Truncated `prediction_copy.dart` in initial feat commit**

- **Found during:** Task 2 (post-commit verification)
- **Issue:** Working tree had a shortened `prediction_copy.dart`; the feat commit replaced the full file with the short fragment, breaking the package.
- **Fix:** Restored full file from git history, re-applied phrase list + `predictionCopyTextPassesGuard`, updated `formatEnsembleExplanation` to use `EnsembleMilestone` and `_formatEnsembleMilestoneEn`; amended the feat commit.
- **Files modified:** `prediction_copy.dart`, `prediction_copy_test.dart`
- **Verification:** `fvm flutter test` in `packages/ptrack_domain` — all tests passed
- **Committed in:** `8d07393` (amended feat)

**2. [Rule 3 — Blocking] Stale `milestoneMessage` references**

- **Found during:** Task 2 (restore/compile)
- **Issue:** Restored long `prediction_copy` referenced `ensemble.milestoneMessage`, which no longer exists on `EnsemblePredictionResult`.
- **Fix:** Switched to `ensemble.milestone` with `_formatEnsembleMilestoneEn`.
- **Files modified:** `prediction_copy.dart`
- **Verification:** Same full package test run
- **Committed in:** `8d07393`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)  
**Impact on plan:** Restored intended scope; no product behavior change beyond plan (milestone append now uses structured milestone types).

## Issues Encountered

- Local `dart` SDK 3.9 vs workspace `^3.11.0`: used `fvm flutter test` / `fvm dart analyze` from `packages/ptrack_domain`.

## User Setup Required

None.

## Next Phase Readiness

- Domain calculator and PRED-04 extensions are ready for **12-02** (settings, opt-in, ARB) and later UI plans to call `FertilityWindowCalculator` from the app/data layer.

## Self-Check: PASSED

- `12-01-SUMMARY.md` exists at `.planning/phases/12-optional-fertility-window-estimator/12-01-SUMMARY.md`
- Commits `10f606d`, `8d07393`, and latest `docs(12-01): Complete fertility window engine plan` present on branch (`git log --oneline -5`)

---
*Phase: 12-optional-fertility-window-estimator*  
*Completed: 2026-04-08*

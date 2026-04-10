---
phase: 09-prediction-of-next-period
plan: 02
subsystem: prediction
tags: [dart, flutter, ensemble, calendar, shared_preferences, ptrack_domain, ptrack_data]

requires:
  - phase: 09-prediction-of-next-period
    provides: PredictionAlgorithm implementations, EnsemblePredictionResult, UTC helpers

provides:
  - EnsembleCoordinator with dayConfidenceMap, milestones, median consensus, ensemble explanation text
  - Extended ExplanationFactKind and formatEnsembleExplanation / formatDayAgreementSummary (PRED-04)
  - CalendarDayData predictionConfidenceTier and predictionAgreementCount with legacy prediction adapter
  - PredictionDisplayMode and PredictionSettings (SharedPreferences)
  - Unit tests for ensemble and calendar display-mode filtering

affects:
  - 09-03 UI (painters, ViewModels, settings tile, day detail)

tech-stack:
  added: []
  patterns:
    - "Display mode filtering only in buildCalendarDayDataMap (view-data boundary)"
    - "Shared bleeding-duration median feeds all algorithms' defaultDuration"
    - "Legacy PredictionResult wrapped via legacyEnsembleFromPrediction for gradual migration"

key-files:
  created:
    - packages/ptrack_data/lib/src/prediction/ensemble_coordinator.dart
    - packages/ptrack_data/test/ensemble_coordinator_test.dart
    - apps/ptrack/lib/features/settings/prediction_settings.dart
  modified:
    - packages/ptrack_domain/lib/src/prediction/explanation_step.dart
    - packages/ptrack_domain/lib/src/prediction/prediction_copy.dart
    - packages/ptrack_data/lib/ptrack_data.dart
    - apps/ptrack/lib/features/calendar/calendar_day_data.dart
    - apps/ptrack/test/features/calendar/calendar_day_data_test.dart
    - apps/ptrack/test/features/calendar/day_detail_sheet_test.dart

key-decisions:
  - "Consensus prediction remains PredictionCoordinator / PredictionEngine output for CyclePosition compatibility"
  - "Milestone copy follows plan thresholds (2 methods, 3 core, 4 with trend) using previousActiveCount"
  - "buildCalendarDayDataMap asserts exactly one of ensemble or prediction to avoid silent double-source bugs"

patterns-established:
  - "EnsembleCoordinator builds default algorithm list per run with shared median bleeding duration"
  - "PredictionSettings mirrors MoodSettings static load/save on SharedPreferences"

requirements-completed: [PRED-01, PRED-02, PRED-03, PRED-04]

duration: 45min
completed: 2026-04-07
---

# Phase 9 Plan 02: Ensemble coordinator and calendar tiers summary

**Multi-algorithm EnsembleCoordinator with per-day agreement map, “methods agree” ensemble copy with PRED-04 assertions, calendar tiers plus PredictionDisplayMode persisted like mood settings.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-07T00:00:00Z (approx.)
- **Completed:** 2026-04-07
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Wired default four algorithms through shared-duration construction, `dayConfidenceMap`, milestone detection, and `PredictionCoordinator` consensus.
- Extended domain explanation kinds and user-facing ensemble narrative without forbidden phrases.
- Replaced boolean predicted flag with tier and raw agreement count; filtering by `PredictionDisplayMode` stays in `buildCalendarDayDataMap` with cold-start behavior.

## Task Commits

1. **Task 1: EnsembleCoordinator and multi-algorithm explanation copy** — `2b536af` (feat)
2. **Task 2: CalendarDayData confidence tiers and PredictionSettings** — `07ae588` (feat)

**Plan metadata:** (docs commit after STATE/ROADMAP)

## Files Created/Modified

- `packages/ptrack_domain/lib/src/prediction/explanation_step.dart` — New ensemble-related explanation kinds.
- `packages/ptrack_domain/lib/src/prediction/prediction_copy.dart` — `formatEnsembleExplanation`, `formatDayAgreementSummary`, `_formatStep` cases, forbidden-phrase assert.
- `packages/ptrack_data/lib/src/prediction/ensemble_coordinator.dart` — Orchestration, milestones, formatted text.
- `packages/ptrack_data/lib/ptrack_data.dart` — Export `EnsembleCoordinator`.
- `packages/ptrack_data/test/ensemble_coordinator_test.dart` — Ensemble behavior and fixtures.
- `apps/ptrack/lib/features/calendar/calendar_day_data.dart` — Tiers, ensemble/legacy API, `legacyEnsembleFromPrediction`.
- `apps/ptrack/lib/features/settings/prediction_settings.dart` — `PredictionDisplayMode` + `PredictionSettings`.
- `apps/ptrack/test/features/calendar/calendar_day_data_test.dart` — Ensemble and mode tests.
- `apps/ptrack/test/features/calendar/day_detail_sheet_test.dart` — `CalendarDayData` constructor updates.

## Decisions Made

- Kept `CalendarViewModel` on the legacy `prediction:` path until Plan 03 wires `EnsembleCoordinator` and loaded display mode.
- Used staged custom algorithms in tests to simulate a 1→2 active milestone without fragile real-history tuning.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Linear-trend “six period” fixture did not yield five cycle inputs**

- **Found during:** Task 1 verification (`EnsembleCoordinator` test expected four active algorithms)
- **Issue:** Hand-picked period dates produced fewer than five `PredictionCycleInput` rows, so `LinearTrendAlgorithm` stayed inactive.
- **Fix:** Built stored periods from explicit cycle-length spacing (same as domain linear-trend test data).
- **Files modified:** `packages/ptrack_data/test/ensemble_coordinator_test.dart`
- **Verification:** `fvm flutter test packages/ptrack_data/test/ensemble_coordinator_test.dart`
- **Committed in:** `2b536af`

---

**Total deviations:** 1 auto-fixed (test fixture correctness)
**Impact on plan:** No product behavior change; tests now match real cycle-input derivation.

## Issues Encountered

None beyond the fixture correction above.

## User Setup Required

None.

## Next Phase Readiness

- Plan 03 can consume `EnsembleCoordinator`, `buildCalendarDayDataMap(..., ensemble:, displayMode:)`, `formatDayAgreementSummary`, and `PredictionSettings.load()`.

---

*Phase: 09-prediction-of-next-period*

*Completed: 2026-04-07*

## Self-Check: PASSED

- `09-02-SUMMARY.md` exists at `.planning/phases/09-prediction-of-next-period/09-02-SUMMARY.md`
- Task commits `2b536af`, `07ae588` present on branch
- `fvm flutter test` passed: `packages/ptrack_data`, `packages/ptrack_domain`, `apps/ptrack/test/features/calendar/calendar_day_data_test.dart`, `day_detail_sheet_test.dart`
- `fvm flutter analyze --fatal-infos` passed for `apps/ptrack`; `fvm dart analyze --fatal-infos` passed for `packages/ptrack_domain`

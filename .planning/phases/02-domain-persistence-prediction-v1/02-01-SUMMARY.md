---
phase: 02-domain-persistence-prediction-v1
plan: 01
subsystem: domain
tags: [dart, flutter, timezone, validation, tdd, prediction]

requires:
  - phase: 01-foundation
    provides: Melos monorepo, ptrack_domain package, FVM Flutter
provides:
  - PeriodSpan UTC model with completedOnly filter for open periods
  - PeriodValidation.validateForSave (overlap, end-before-start, duplicate local start day)
  - PeriodCalendarContext + CalendarDate for IANA timezone local-day rules
  - completedCycleBetweenStarts / CompletedCycle (canonical inclusive cycle length)
  - Sealed PredictionResult tiers and ExplanationStep + placeholderExplanationSteps
affects:
  - 02-02-PLAN (Drift mappers)
  - 02-03-PLAN (PredictionEngine)
  - 02-04-PLAN (repository + UI-facing explanation)

tech-stack:
  added: [timezone, meta (direct dep for @immutable)]
  patterns:
    - "Sealed / final prediction variants without UI strings"
    - "Explicit PeriodCalendarContext for deterministic local-day semantics"

key-files:
  created:
    - packages/ptrack_domain/lib/src/period/period_models.dart
    - packages/ptrack_domain/lib/src/period/period_validation.dart
    - packages/ptrack_domain/lib/src/period/cycle_length.dart
    - packages/ptrack_domain/lib/src/prediction/prediction_result.dart
    - packages/ptrack_domain/lib/src/prediction/explanation_step.dart
    - packages/ptrack_domain/test/period_validation_test.dart
    - packages/ptrack_domain/test/cycle_length_test.dart
    - packages/ptrack_domain/test/prediction_result_test.dart
  modified:
    - packages/ptrack_domain/lib/ptrack_domain.dart
    - packages/ptrack_domain/pubspec.yaml
    - pubspec.lock

key-decisions:
  - "Duplicate-start rule uses PeriodCalendarContext (IANA Location) so validation matches explicit local calendar days; apps must call timezone initializeTimeZones() before getLocation."
  - "Cycle length counts inclusive local days from period start day through the local day before the next period start (documented in cycle_length.dart + tests)."
  - "Added meta as a direct dependency to satisfy depend_on_referenced_packages for @immutable."

patterns-established:
  - "Open periods excluded via PeriodSpan.completedOnly naming for stats/prediction inputs"
  - "placeholderExplanationSteps returns stable ExplanationStep rows until Plan 03 engine"

requirements-completed: [PRED-02, PRED-03]

duration: 20 min
completed: 2026-04-04
---

# Phase 2 Plan 01: Domain period & prediction types Summary

**UTC period spans with timezone-scoped validation, documented completed-cycle length in local days, and sealed prediction/explanation models tested without Flutter UI.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-04-04T00:00:00Z (approximate)
- **Completed:** 2026-04-04T00:00:00Z (approximate)
- **Tasks:** 2 completed
- **Files modified:** 11

## Accomplishments

- Immutable `PeriodSpan`, `PeriodValidation.validateForSave`, and `PeriodCalendarContext` encoding CONTEXT overlap, end-before-start, and same-local-day duplicate starts.
- `completedCycleBetweenStarts` pins the inclusive local-day cycle rule with UTC and America/New_York (DST-adjacent) tests.
- `PredictionResult` variants plus `ExplanationStep` / `placeholderExplanationSteps` for later engine and UI.

## Task Commits

1. **Task 1: Period models and validation** — `d031af1` (feat)
2. **Task 2: Cycle length definition and prediction-facing types** — `f989278` (feat)

**Plan metadata:** Closing docs commit includes this file with `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md`.

## Files Created/Modified

- `packages/ptrack_domain/lib/src/period/period_models.dart` — UTC period value type; `completedOnly` helper.
- `packages/ptrack_domain/lib/src/period/period_validation.dart` — Calendar context, validation issues, overlap/duplicate rules.
- `packages/ptrack_domain/lib/src/period/cycle_length.dart` — `CompletedCycle` + `completedCycleBetweenStarts`.
- `packages/ptrack_domain/lib/src/prediction/prediction_result.dart` — Sealed result tiers.
- `packages/ptrack_domain/lib/src/prediction/explanation_step.dart` — Factual steps + placeholder builder.
- `packages/ptrack_domain/lib/ptrack_domain.dart` — Public exports.
- `packages/ptrack_domain/pubspec.yaml` — `timezone`, `meta`.
- Tests under `packages/ptrack_domain/test/` — validation, cycle length, prediction/equality.

## Decisions Made

- Documented that IANA zones require `initializeTimeZones()` (see `timezone` package) before `PeriodCalendarContext.fromTimeZoneName`.
- Canonical cycle length uses local midnight boundaries via `TZDateTime` in the chosen `Location`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for `02-02-PLAN.md` (Drift schema + migrations in `ptrack_data`) using these value types and validation entry points.

---
*Phase: 02-domain-persistence-prediction-v1*
*Completed: 2026-04-04*

## Self-Check: PASSED

- `02-01-SUMMARY.md` present at `.planning/phases/02-domain-persistence-prediction-v1/02-01-SUMMARY.md`
- Commits `d031af1`, `f989278` (tasks) and `docs(02-01): Complete domain period and prediction types plan` (planning bundle) on branch

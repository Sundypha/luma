---
phase: 02-domain-persistence-prediction-v1
plan: 04
subsystem: database
tags: [dart, flutter, drift, prediction, repository, widget-test]

requires:
  - phase: 02-domain-persistence-prediction-v1
    provides: PeriodValidation, Drift schema v1, PredictionEngine, ExplanationStep
provides:
  - PeriodRepository with transactional writes and PeriodWriteOutcome (success / rejected / not found)
  - PredictionCoordinator loading stored periods, deriving completed-cycle inputs (open excluded), engine + PRED-04 narrative
  - prediction_copy helpers, forbidden-phrase list, and tests including insufficient-history without invented dates
  - apps/ptrack widget test proving readable explanation text before Phase 5 UI
affects:
  - Phase 3 onboarding and Phase 5 surfaces that will call repository + coordinator

tech-stack:
  added:
    - meta (ptrack_data direct dependency for @immutable)
    - timezone dev_dependency in ptrack_data and ptrack app tests
  patterns:
    - "Validate in domain, then insert/update inside a single Drift transaction"
    - "User-facing prediction strings only through prediction_copy.formatPredictionExplanation"

key-files:
  created:
    - packages/ptrack_data/lib/src/repositories/period_repository.dart
    - packages/ptrack_data/lib/src/prediction/prediction_coordinator.dart
    - packages/ptrack_data/test/period_repository_test.dart
    - packages/ptrack_data/test/prediction_coordinator_test.dart
    - packages/ptrack_domain/lib/src/prediction/prediction_copy.dart
    - packages/ptrack_domain/test/prediction_copy_test.dart
    - apps/ptrack/test/prediction_explanation_widget_test.dart
  modified:
    - packages/ptrack_data/lib/ptrack_data.dart
    - packages/ptrack_data/pubspec.yaml
    - packages/ptrack_domain/lib/ptrack_domain.dart
    - apps/ptrack/pubspec.yaml

key-decisions:
  - "Repository returns sealed PeriodWriteOutcome instead of throwing on validation failure so callers never rely on parsing exceptions."
  - "Coordinator exposes predictNext for in-memory fixtures and predictNextFromRepository for production wiring; open PeriodSpan rows never feed cycle-length statistics."
  - "Narrative layers disclaimer, per-step lines from ExplanationStep payloads, then a result-specific closing (point/range/insufficient) without contraception or medical authority framing."

patterns-established:
  - "Derive PredictionCycleInput list only from consecutive completed PeriodSpan pairs ordered by startUtc via completedCycleBetweenStarts."

requirements-completed: [PRED-02, PRED-03, PRED-04, NFR-02]

duration: 42 min
completed: 2026-04-04
---

# Phase 2 Plan 04: Repository, coordinator, and PRED-04 copy Summary

**Transactional PeriodRepository with domain validation, PredictionCoordinator composing the engine with completed-cycle derivation and conservative explanation copy, plus a widget test that proves readable estimate language in the app package.**

## Performance

- **Duration:** 42 min
- **Started:** 2026-04-04T15:30:00Z (approximate)
- **Completed:** 2026-04-04T16:12:00Z (approximate)
- **Tasks:** 3 completed
- **Files modified:** 11

## Accomplishments

- Drift-backed `PeriodRepository` validates before write, uses transactions, and covers round-trip, duplicate local start-day rejection, reopen persistence, and updates.
- `PredictionCoordinator` builds completed-cycle inputs (open periods excluded), runs `PredictionEngine`, and formats copy via `prediction_copy`.
- `prediction_copy` encodes PRED-04 guardrails with unit tests (forbidden phrases, no YYYY-MM-DD in insufficient-history narratives).
- Widget test under `apps/ptrack` renders coordinator output in a `MaterialApp` and asserts non-empty estimate wording.

## Task Commits

1. **Task 1: PeriodRepository with validation and transactions** — `c31777e` (feat)
2. **Task 2: Prediction coordinator + PRED-04 copy** — `730a5c5` (feat)
3. **Task 3: Widget test for readable explanation** — `62d441b` (test)

**Plan metadata:** Docs commit bundles this SUMMARY with `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md` (see `git log --grep="docs(02-04)"`).

## Files Created/Modified

- `packages/ptrack_data/lib/src/repositories/period_repository.dart` — `StoredPeriod`, write outcomes, list/insert/update with `PeriodValidation`.
- `packages/ptrack_data/lib/src/prediction/prediction_coordinator.dart` — cycle derivation, `PredictionCoordinator`, `PredictionCoordinatorResult`.
- `packages/ptrack_domain/lib/src/prediction/prediction_copy.dart` — disclaimer, step formatters, `formatPredictionExplanation`, forbidden phrase list.
- `packages/ptrack_data/test/period_repository_test.dart` — persistence and validation rejection tests.
- `packages/ptrack_data/test/prediction_coordinator_test.dart` — engine parity and open-period exclusion.
- `packages/ptrack_domain/test/prediction_copy_test.dart` — PRED-04 scans and insufficient-history date absence.
- `apps/ptrack/test/prediction_explanation_widget_test.dart` — widget-level readable explanation.
- `packages/ptrack_data/lib/ptrack_data.dart`, `packages/ptrack_domain/lib/ptrack_domain.dart` — public exports.
- `packages/ptrack_data/pubspec.yaml`, `apps/ptrack/pubspec.yaml` — `meta`, `timezone` for lint-clean tests.

## Decisions Made

- Chose explicit `PeriodWriteRejected` / `PeriodWriteNotFound` outcomes so invalid saves never touch SQLite and update misses are distinguishable from validation failures.
- Kept bleeding-day optional on `PredictionCycleInput` (null in coordinator) so v1 persistence does not require bleed-length fields.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Analyzer required direct `meta` dependency in ptrack_data**
- **Found during:** Task 3 (CI analyze after widget test)
- **Issue:** `depend_on_referenced_packages` for `package:meta` in `period_repository.dart`
- **Fix:** Added `meta: ^1.16.0` to `packages/ptrack_data/pubspec.yaml`
- **Files modified:** `packages/ptrack_data/pubspec.yaml`
- **Verification:** `melos run ci:analyze` clean for `ptrack_data`
- **Committed in:** `62d441b` (Task 3 commit)

**2. [Rule 1 - Bug] Coordinator test expected wrong next-start date**
- **Found during:** Task 2 verification
- **Issue:** Fixture had three completed periods (two cycle inputs); asserted Mar 26 instead of engine’s Feb 26 anchor behavior
- **Fix:** Expanded fixture to four closed periods (three cycle intervals) to match engine golden; aligned widget test expected date to `2026-03-26`
- **Files modified:** `prediction_coordinator_test.dart`, `prediction_explanation_widget_test.dart`
- **Verification:** `fvm flutter test` on affected packages
- **Committed in:** `730a5c5` / `62d441b`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Minor test/fixture corrections and a declared dependency; no API or schema drift.

## Issues Encountered

None beyond analyzer and test expectation fixes listed above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 2 domain/persistence/prediction loop is integrated with automated tests; Phase 3 can assume repository + coordinator APIs and PRED-04 copy helpers exist. Run `/gsd-verify-work` for phase 2 if required by workflow.

## Self-Check: PASSED

- **Files:** `packages/ptrack_data/lib/src/repositories/period_repository.dart`, `packages/ptrack_data/lib/src/prediction/prediction_coordinator.dart`, `packages/ptrack_domain/lib/src/prediction/prediction_copy.dart`, `apps/ptrack/test/prediction_explanation_widget_test.dart` — all present.
- **Commits:** `c31777e`, `730a5c5`, `62d441b` (tasks); planning metadata in `docs(02-04)` commit on this branch.

---
*Phase: 02-domain-persistence-prediction-v1*
*Completed: 2026-04-04*

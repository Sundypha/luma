---
phase: 15-address-full-app-code-review-findings
plan: 03
subsystem: database
tags: [drift, sqlite, n-plus-one, period-repository, flutter-test]

requires:
  - phase: 14-remove-deprecated-fab
    provides: "Prior UX work; phase 15 depends on phase 14 in roadmap"
provides:
  - "Batched day-entry load in watchPeriodsWithDays (2 SQL round-trips per refresh)"
  - "Multi-period watch regression test vs direct-query expected snapshot"
affects:
  - "HomeViewModel"
  - "CalendarViewModel"
  - "PDF data paths consuming watchPeriodsWithDays"

tech-stack:
  added: []
  patterns:
    - "Batch related rows with periodId.isIn(ids), order by (periodId, dateUtc), group in memory"

key-files:
  created: []
  modified:
    - "packages/ptrack_data/lib/src/repositories/period_repository.dart"
    - "packages/ptrack_data/test/period_repository_test.dart"

key-decisions:
  - "Keep outer period order (startUtc desc) and per-period day order (dateUtc asc) identical to pre-refactor load()"
  - "Empty period list skips day_entries query entirely"

patterns-established:
  - "Regression: compare watch stream to independent DB queries built with the same ordering contract"

requirements-completed: []

duration: 12min
completed: 2026-04-10
---

# Phase 15 Plan 03: watchPeriodsWithDays batch-load Summary

**Removed N+1 day-entry queries in `watchPeriodsWithDays` refresh by batching with `periodId.isIn` and in-memory grouping; added a five-period regression test that matches a direct-query snapshot.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-04-10T00:00:00Z (approx.)
- **Completed:** 2026-04-10T00:12:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Multi-period `watchPeriodsWithDays` test: newest period first, ascending days per period, full id/data parity vs `_expectedWatchSnapshotFromDb`.
- `load()` now uses one periods query + one batched `day_entries` query (empty periods → no day query); `sameSnapshot` unchanged.

## Task Commits

1. **Task 1: TDD — assert watch snapshot matches for N periods** — `75f8319` (test)
2. **Task 2: Batch-load day entries and group by periodId** — `94734e5` (perf)

**Plan metadata:** `c4fcdf8` (docs: complete plan)

## Files Created/Modified

- `packages/ptrack_data/test/period_repository_test.dart` — helpers + `watchPeriodsWithDays matches direct-query snapshot for many periods` test
- `packages/ptrack_data/lib/src/repositories/period_repository.dart` — batched `load()` inside `watchPeriodsWithDays`

## Decisions Made

- Used `OrderingTerm.asc(periodId)` then `asc(dateUtc)` on the batched row set so lists per period stay sorted without a second sort pass.

## Deviations from Plan

None — plan executed exactly as written.

**Verification note:** `dart test` from the package root required FVM Flutter (`fvm flutter test test/period_repository_test.dart`) because plain `dart test` failed on native-assets / `objective_c` in this workspace.

## Issues Encountered

- `import 'package:drift/drift.dart'` conflicted with matcher `isNotNull`; fixed with `show OrderingTerm` only.

## User Setup Required

None.

## Next Phase Readiness

- Finding 5 (CODE_REVIEW) addressed for `watchPeriodsWithDays`; remaining phase 15 plans `15-01`, `15-02` per roadmap.

## Self-Check: PASSED

- `15-03-SUMMARY.md` exists at `.planning/phases/15-address-full-app-code-review-findings/15-03-SUMMARY.md`
- Commits `75f8319`, `94734e5`, `c4fcdf8` present in `git log`

---
*Phase: 15-address-full-app-code-review-findings*  
*Completed: 2026-04-10*

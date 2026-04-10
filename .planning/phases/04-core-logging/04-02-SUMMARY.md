---
phase: 04-core-logging
plan: "02"
subsystem: database
tags: [drift, repository, stream, flutter, period-list, ptrack_data, ptrack]

requires:
  - phase: 04-core-logging
    provides: DayEntries table, day_entry mappers, schema v2 (04-01)
provides:
  - PeriodRepository.watchPeriodsWithDays with deduped emissions from periods + dayEntries watches
  - Transactional deletePeriod (cascade day rows) and day entry save/update/delete APIs
  - HomeScreen with StreamBuilder, ExpansionTile period rows, empty state, FAB placeholder snackbar
  - PtrackApp wires PtrackDatabase + PeriodRepository into HomeScreen; placeholder HomePage removed
affects:
  - 04-03-PLAN (logging bottom sheet on FAB)

tech-stack:
  added: []
  patterns:
    - "Combine Drift watches on parent and child tables with snapshot dedupe to avoid duplicate stream events"
    - "Home list consumes repository stream for automatic refresh after writes"

key-files:
  created:
    - apps/ptrack/lib/features/logging/home_screen.dart
  modified:
    - packages/ptrack_data/lib/src/repositories/period_repository.dart
    - packages/ptrack_data/lib/ptrack_data.dart
    - packages/ptrack_data/pubspec.yaml
    - packages/ptrack_data/test/period_repository_test.dart
    - apps/ptrack/lib/main.dart
    - apps/ptrack/test/widget_test.dart

key-decisions:
  - "Widget tests stub watchPeriodsWithDays with Stream.value([]) so UI settles without Drift isolate timing"
  - "Stream snapshot dedupe compares period ids, spans, and day entry ids/data to satisfy emitsInOrder-style expectations"

patterns-established:
  - "StoredPeriodWithDays / StoredDayEntry as repository-level read models for logging UI"

requirements-completed: [LOG-01, LOG-04, LOG-06]

duration: 45min
completed: 2026-04-05
---

# Phase 4 Plan 02: Repository watch, cascade delete, day CRUD, and home list Summary

**Reactive period+day snapshot stream with transactional cascade delete, full day-entry CRUD in PeriodRepository, and a Material home list wired from main—replacing the placeholder home page.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-04-05T12:00:00Z (approximate)
- **Completed:** 2026-04-05T14:30:00Z (approximate)
- **Tasks:** 2
- **Files modified:** 7 (including new home_screen.dart)

## Accomplishments

- Extended `PeriodRepository` with `watchPeriodsWithDays`, `deletePeriod`, `saveDayEntry`, `updateDayEntry`, `deleteDayEntry`, plus `StoredPeriodWithDays` / `StoredDayEntry` types and barrel exports (including `DayEntryData`).
- Added repository integration tests, including `StreamQueue`-based ordering for the watch stream and explicit `async` dev_dependency for `depend_on_referenced_packages`.
- Shipped `HomeScreen` (empty state, expandable period rows, day summaries, About action, FAB snackbar) and passed `PtrackDatabase` through `PtrackApp` from `main()`.

## Task Commits

1. **Task 1: Repository extensions — watch, delete, day entry CRUD** — `482e74b` (feat)
2. **Task 2: Home screen with period history list and main.dart wiring** — `64a9206` (feat)

**Plan metadata:** Planning docs commit with message `docs(04-02): complete repository and home list plan`

## Files Created/Modified

- `packages/ptrack_data/lib/src/repositories/period_repository.dart` — watch stream (dual-table watch + dedupe), cascade delete, day CRUD
- `packages/ptrack_data/lib/ptrack_data.dart` — export new types and `DayEntryData`
- `packages/ptrack_data/pubspec.yaml` — dev `async` for tests
- `packages/ptrack_data/test/period_repository_test.dart` — day entry and watch tests
- `apps/ptrack/lib/features/logging/home_screen.dart` — logging home UI
- `apps/ptrack/lib/main.dart` — `HomeScreen` wiring, `database` on `PtrackApp`, remove `HomePage`
- `apps/ptrack/test/widget_test.dart` — mocks for stable `watchPeriodsWithDays`; About navigation

## Decisions Made

- Used mocktail stubs returning `Stream.value(<StoredPeriodWithDays>[])` in widget tests so `StreamBuilder` reaches the empty state without waiting on background Drift.
- Suppressed duplicate watch emissions by comparing last emitted snapshot to the newly loaded list (period span + nested day rows).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Watch stream emitted duplicate snapshots and raced the save in tests**

- **Found during:** Task 1 (`watchPeriodsWithDays emits updated list after insert`)
- **Issue:** Initial `scheduleEmit` plus both `watch()` listeners produced multiple identical events; `expectLater`/`emitsInOrder` also raced with `saveDayEntry` when the save was scheduled too early.
- **Fix:** Removed eager emit on listen; dedupe consecutive identical snapshots; switched the test to `StreamQueue.next` after the first event, then `saveDayEntry`.
- **Files modified:** `packages/ptrack_data/lib/src/repositories/period_repository.dart`, `packages/ptrack_data/test/period_repository_test.dart`
- **Verification:** `fvm flutter test test/period_repository_test.dart`
- **Committed in:** `482e74b`

**2. [Rule 3 - Blocking] `depend_on_referenced_packages` for `package:async`**

- **Found during:** Task 2 (repo-wide `melos exec -- fvm dart analyze`)
- **Issue:** `period_repository_test` imports `package:async` for `StreamQueue` without a direct dependency.
- **Fix:** Added `async` under `dev_dependencies` in `packages/ptrack_data/pubspec.yaml`.
- **Files modified:** `packages/ptrack_data/pubspec.yaml`
- **Verification:** `melos exec -- fvm dart analyze`
- **Committed in:** `64a9206`

**3. [Rule 3 - Blocking] Widget tests hung or missed empty state with real Drift**

- **Found during:** Task 2 (`pumpAndSettle` / missing empty-state text)
- **Issue:** Background executor delayed first stream event; `CircularProgressIndicator` kept frames pending.
- **Fix:** Mock `PeriodRepository.watchPeriodsWithDays` to emit an immediate empty list (and `PtrackDatabase` unused).
- **Files modified:** `apps/ptrack/test/widget_test.dart`
- **Verification:** `fvm flutter test`, `fvm flutter analyze`
- **Committed in:** `64a9206`

---

**Total deviations:** 3 auto-fixed (1 bug, 2 blocking)

**Impact on plan:** No product scope change; correctness, analyzer cleanliness, and test determinism only.

## Issues Encountered

None beyond deviations above.

## User Setup Required

None.

## Next Phase Readiness

Ready for `04-03-PLAN.md` to wire the FAB to the logging bottom sheet and hook saves into the repository APIs delivered here.

## Self-Check: PASSED

- `apps/ptrack/lib/features/logging/home_screen.dart` — FOUND
- `.planning/phases/04-core-logging/04-02-SUMMARY.md` — FOUND
- Task commits `482e74b`, `64a9206` and planning docs commit — FOUND (`git log --oneline --grep=04-02`)

---
*Phase: 04-core-logging*
*Completed: 2026-04-05*

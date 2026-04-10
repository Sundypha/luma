---
phase: 04-core-logging
plan: "01"
subsystem: database
tags: [drift, sqlite, migration, domain, enums, ptrack_domain, ptrack_data]

requires:
  - phase: 03-onboarding
    provides: Phase 3 complete; app reaches logging milestone focus
provides:
  - FlowIntensity, PainScore, Mood enums with 1-based DB mapping and labels/emojis
  - DayEntryData immutable value type
  - DayEntries Drift table (FK periods, unique periodId+dateUtc)
  - Schema v2 migration from v1, PRAGMA foreign_keys ON in beforeOpen
  - day_entry mappers and tests; ptrack_v2.sqlite fixture + generator tool
affects:
  - 04-02-PLAN (repository / UI consumers)
  - 04-03-PLAN (logging bottom sheet)

tech-stack:
  added: []
  patterns:
    - "Per-day symptoms in child table with nullable columns (LOG-02 optional fields)"
    - "Calendar-day fidelity: normalize dateUtc to UTC midnight in day entry mapper"

key-files:
  created:
    - packages/ptrack_domain/lib/src/period/logging_types.dart
    - packages/ptrack_domain/test/logging_types_test.dart
    - packages/ptrack_data/lib/src/mappers/day_entry_mapper.dart
    - packages/ptrack_data/test/day_entry_mapper_test.dart
    - packages/ptrack_data/test/fixtures/ptrack_v2.sqlite
    - packages/ptrack_data/tool/create_v2_fixture.dart
  modified:
    - packages/ptrack_domain/lib/ptrack_domain.dart
    - packages/ptrack_data/lib/src/db/tables.dart
    - packages/ptrack_data/lib/src/db/ptrack_database.dart
    - packages/ptrack_data/lib/src/db/ptrack_database.g.dart
    - packages/ptrack_data/lib/ptrack_data.dart
    - packages/ptrack_data/test/migration_test.dart

key-decisions:
  - "create_v2_fixture uses raw sqlite3 SQL (same pattern as v1) so fvm dart run works on the VM without dart:ui"
  - "day_entry mapper normalizes dateUtc to UTC calendar date on read/write so Drift local-wall DateTime round-trips match DayEntryData equality"

patterns-established:
  - "DayEntries 1-based int columns map to domain enums via fromDbValue/dbValue"
  - "Migration tests use try/finally to close DB before temp-dir tearDown (Windows file locks)"

requirements-completed: [LOG-02, LOG-03, LOG-06]

duration: 40min
completed: 2026-04-05
---

# Phase 4 Plan 01: Core logging data foundation Summary

**DayEntries at Drift schema v2 with domain enums (flow, pain, mood), FK enforcement, bidirectional mappers, and committed v2 SQLite fixture—foundation for per-day logging UI and repositories.**

## Performance

- **Duration:** 40 min
- **Started:** 2026-04-05T00:00:00Z (approximate execution window)
- **Completed:** 2026-04-05
- **Tasks:** 2
- **Files touched:** 12 (excluding generated drift churn counted once)

## Accomplishments

- Domain enums and `DayEntryData` with tests and barrel export
- `DayEntries` table, v1→v2 migration, `beforeOpen` foreign keys, Drift codegen
- Mappers, migration/mapper tests, raw-SQL v2 fixture script and binary fixture

## Task Commits

1. **Task 1: Domain enums and DayEntryData value type** — `fac31d5` (feat)
2. **Task 2: DayEntries table, schema v2 migration, and mappers** — `1febf73` (feat)

**Plan metadata:** `docs(04-01): Complete core logging data foundation plan` (same commit as this SUMMARY)

## Files Created/Modified

- `packages/ptrack_domain/lib/src/period/logging_types.dart` — enums + `DayEntryData`
- `packages/ptrack_domain/lib/ptrack_domain.dart` — export logging types
- `packages/ptrack_domain/test/logging_types_test.dart` — enum and value-type tests
- `packages/ptrack_data/lib/src/db/tables.dart` — `DayEntries` table
- `packages/ptrack_data/lib/src/db/ptrack_database.dart` — schema 2, migration, `beforeOpen`
- `packages/ptrack_data/lib/src/db/ptrack_database.g.dart` — generated
- `packages/ptrack_data/lib/src/mappers/day_entry_mapper.dart` — row ↔ domain
- `packages/ptrack_data/lib/ptrack_data.dart` — export mapper API
- `packages/ptrack_data/test/day_entry_mapper_test.dart` — mapper tests
- `packages/ptrack_data/test/migration_test.dart` — v1 upgrade, v2 fixture, FK violation
- `packages/ptrack_data/tool/create_v2_fixture.dart` — regenerates `ptrack_v2.sqlite`
- `packages/ptrack_data/test/fixtures/ptrack_v2.sqlite` — committed fixture

## Decisions Made

- Raw SQL for `create_v2_fixture` (not `openPtrackDatabase`) so maintainers can run `fvm dart run tool/create_v2_fixture.dart` without Flutter’s UI embedding.
- Normalize `dateUtc` to UTC midnight in the day-entry mapper so stored calendar days match `DayEntryData` equality across platforms after Drift reads local-wall `DateTime` values.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Calendar-day drift after Drift DateTime read**

- **Found during:** Task 2 (migration / mapper tests on Windows)
- **Issue:** Round-trip tests failed because SQLite/Drift returned non-UTC wall `DateTime` for UTC midnight writes, breaking `DayEntryData` equality.
- **Fix:** `_calendarDateAsUtc` in `day_entry_mapper.dart` on read and on insert/update companion `dateUtc`.
- **Files modified:** `packages/ptrack_data/lib/src/mappers/day_entry_mapper.dart`
- **Verification:** `fvm flutter test` for `ptrack_data` and `ptrack_domain`; `fvm dart analyze` clean.
- **Committed in:** `1febf73`

**2. [Rule 3 - Blocking] Temp sqlite path locked when DB left open after assertion failure**

- **Found during:** Task 2 (migration test run)
- **Issue:** Failed `expect` left `PtrackDatabase` open; tearDown could not delete the temp directory on Windows.
- **Fix:** `try`/`finally` with `await db.close()` in upgrade and round-trip tests.
- **Files modified:** `packages/ptrack_data/test/migration_test.dart`, `packages/ptrack_data/test/day_entry_mapper_test.dart`
- **Verification:** Full `ptrack_data` test suite.
- **Committed in:** `1febf73`

**3. [Rule 3 - Blocking] v2 fixture tool could not run with `dart run`**

- **Found during:** Task 2 (running `create_v2_fixture` as specified)
- **Issue:** Importing `ptrack_data` pulled Flutter/`dart:ui`, which the standalone Dart VM cannot load.
- **Fix:** Rewrote `tool/create_v2_fixture.dart` to mirror `create_v1_fixture` (raw `sqlite3` DDL + inserts). Added migration test `committed v2 fixture opens at schema 2 with expected rows` to validate the file against Drift.
- **Files modified:** `packages/ptrack_data/tool/create_v2_fixture.dart`, `packages/ptrack_data/test/migration_test.dart`
- **Verification:** `fvm dart run tool/create_v2_fixture.dart`; new migration test passes.
- **Committed in:** `1febf73`

---

**Total deviations:** 3 auto-fixed (1 bug, 2 blocking)

**Impact on plan:** No scope expansion; correctness and runnable tooling only.

## Issues Encountered

None beyond deviations above.

## User Setup Required

None.

## Next Phase Readiness

Ready for `04-02-PLAN.md` (repository extensions and home list) using `DayEntries` and exported mappers.

## Self-Check: PASSED

- `packages/ptrack_domain/lib/src/period/logging_types.dart` — FOUND
- `packages/ptrack_data/test/fixtures/ptrack_v2.sqlite` — FOUND
- Task commits `fac31d5`, `1febf73` and docs commit for `04-01` — FOUND via `git log --oneline --grep=04-01`

---
*Phase: 04-core-logging*
*Completed: 2026-04-05*

---
phase: 18-diary-table-migration
plan: "01"
subsystem: database
tags: [drift, sqlite, migration, sqlcipher, diary]

# Dependency graph
requires:
  - phase: v1 persistence
    provides: periods + day_entries schema and fixtures through v4
provides:
  - Schema v5 with diary_entries, diary_tags, diary_entry_tag_join
  - Transactional v4→v5 migration copying non-empty personal_notes into diary_entries
  - Application-layer sync of diary rows with day save/update/import/export
affects: [18-02, 18-03, 18-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Diary keyed by UTC calendar date; symptom rows stay on day_entries without personal_notes"
    - "TableMigration(dayEntries) to drop a column under Drift 2.32"

key-files:
  created: []
  modified:
    - packages/ptrack_data/lib/src/db/tables.dart
    - packages/ptrack_data/lib/src/db/ptrack_database.dart
    - packages/ptrack_data/lib/src/db/ptrack_database.g.dart
    - packages/ptrack_data/lib/src/mappers/day_entry_mapper.dart
    - packages/ptrack_data/lib/src/export/export_service.dart
    - packages/ptrack_data/lib/src/export/import_service.dart
    - packages/ptrack_data/lib/src/repositories/period_repository.dart
    - packages/ptrack_data/test/migration_test.dart

key-decisions:
  - "Use alterTable(TableMigration(dayEntries)) instead of plan’s recreateTable (API unavailable in Drift 2.32)."

patterns-established:
  - "Merge diary notes into DayEntryData via dayEntryRowToDomain(row, personalNotes: …) and repository batch map."

requirements-completed: [DIARY-01, DIARY-09]

# Metrics
duration: 45min
completed: 2026-04-14
---

# Phase 18 Plan 01: Diary schema v5 Summary

**Standalone Drift diary tables (`DiaryEntries` / `DiaryTags` / `DiaryEntryTagJoin`) at schema v5, with a transactional v4→v5 migration that copies non-empty `personal_notes` into `diary_entries` and drops the column from `day_entries`.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-14T00:00:00Z (approx.)
- **Completed:** 2026-04-14T00:45:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 12 (+ generated)

## Accomplishments

- Added three Drift tables and bumped `ptrackSupportedSchemaVersion` to 5.
- Implemented v4→v5 migration inside the existing `onUpgrade` transaction: ensure legacy column, create diary tables, `INSERT INTO diary_entries … SELECT`, then `TableMigration` to rebuild `day_entries` without `personal_notes`.
- Wired minimal app behavior: repository save/upsert/update syncs `diary_entries`; export reads diary by calendar day; import restores personal notes into diary; `watchPeriodsWithDays` listens to diary changes.

## Task Commits

1. **Task 1 (RED): Write failing migration tests for v4→v5** — `c9e684f` (test)
2. **Task 2 (GREEN): Implement v5 schema and migration** — `9b65c48` (feat)

**Plan metadata:** Same commit as this file on branch `feat/18-01-diary-schema-migration` (`docs(18-01): Record diary schema plan completion`).

## Files Created/Modified

- `packages/ptrack_data/lib/src/db/tables.dart` — New diary tables; removed `personalNotes` from `DayEntries`.
- `packages/ptrack_data/lib/src/db/ptrack_database.dart` — Schema version 5, v5 migration block, removed `beforeOpen` column heal.
- `packages/ptrack_data/lib/src/db/ptrack_database.g.dart` — Regenerated Drift accessors.
- `packages/ptrack_data/lib/src/mappers/day_entry_mapper.dart` — `personalNotes` passed explicitly from diary layer.
- `packages/ptrack_data/lib/src/export/export_service.dart` — Personal notes sourced from `diary_entries`.
- `packages/ptrack_data/lib/src/export/import_service.dart` — Writes diary when backup includes `personal_notes`.
- `packages/ptrack_data/lib/src/repositories/period_repository.dart` — Diary sync, prune on delete, diary-aware `clearClinicalSymptoms`, watch subscription.
- `packages/ptrack_data/test/migration_test.dart` — v4→v5 and fresh v5 assertions; v2 fixture expectation updated for v5.
- Related tests under `test/day_entry_mapper_test.dart`, `test/export/`, `test/period_repository_test.dart`.

## Decisions Made

- Used **`m.alterTable(TableMigration(dayEntries))`** to drop `personal_notes` because **`Migrator.recreateTable` is not available** in this Drift version (deviation documented below).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Drift API: `recreateTable` missing**

- **Found during:** Task 2 (GREEN)
- **Issue:** Plan specified `await m.recreateTable(dayEntries)`; Drift 2.32 `Migrator` has no such method (compile error).
- **Fix:** Replaced with `await m.alterTable(TableMigration(dayEntries))` so SQLite rebuild copies all retained columns and omits `personal_notes`.
- **Files modified:** `packages/ptrack_data/lib/src/db/ptrack_database.dart`
- **Verification:** `fvm flutter test` in `packages/ptrack_data`; `fvm flutter analyze --no-fatal-infos` in `apps/ptrack`
- **Committed in:** `9b65c48`

**2. [Rule 1 - Bug] List comprehension parsed `]` inside map subscript**

- **Found during:** Task 2
- **Issue:** `dayEntryRowToDomain(d, personalNotes: map[DateTime.utc(...)])` inside `[for (...)]` closed the outer list at `]` of `DateTime.utc`.
- **Fix:** Used explicit loops / IIFEs in `period_repository.dart` and `_expectedWatchSnapshotFromDb` in tests.
- **Files modified:** `period_repository.dart`, `period_repository_test.dart`
- **Committed in:** `9b65c48`

---

**Total deviations:** 2 auto-fixed (1 blocking API mismatch, 1 parser/syntax)
**Impact on plan:** Same observable outcome as `recreateTable`; no schema intent change.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None.

## Next Phase Readiness

- v5 schema and migration tests green; fixtures v1/v2 still upgrade to v5.
- **18-02** can introduce domain types and a dedicated `DiaryRepository` without re-touching the migration path.

---
*Phase: 18-diary-table-migration*
*Completed: 2026-04-14*

## Self-Check: PASSED

- Confirmed `d:\CODE\ptrack\.planning\phases\18-diary-table-migration\18-01-SUMMARY.md` exists.
- Confirmed task commits `c9e684f` (test) and `9b65c48` (feat); latest `docs(18-01): …` commit contains this SUMMARY + STATE + ROADMAP.

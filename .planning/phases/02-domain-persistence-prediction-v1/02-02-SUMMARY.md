---
phase: 02-domain-persistence-prediction-v1
plan: 02
subsystem: database
tags: [drift, sqlite, flutter, migrations, ptrack_data]

requires:
  - phase: 02-domain-persistence-prediction-v1
    provides: PeriodSpan and domain validation from plan 01
provides:
  - PtrackDatabase with schema v1 (periods table, UTC instants)
  - openPtrackDatabase / openPtrackQueryExecutor entry points
  - Period row ↔ PeriodSpan mappers and companions
  - Newer-schema guard and PtrackUnsupportedDatabaseSchemaException
  - Committed v1 SQLite fixture plus migration and mapper tests
affects:
  - 02-04 repository and prediction wiring
  - apps/ptrack once persistence is integrated

tech-stack:
  added: [drift, drift_dev, sqlite3, sqlite3_flutter_libs, build_runner, path, path_provider]
  patterns:
    - LazyDatabase + NativeDatabase.createInBackground for Flutter/desktop paths
    - Transaction-wrapped onUpgrade stub for future schema bumps
    - assertSupportedSchemaUpgrade at start of onUpgrade for fail-closed newer DBs

key-files:
  created:
    - packages/ptrack_data/lib/src/db/tables.dart
    - packages/ptrack_data/lib/src/db/ptrack_database.g.dart
    - packages/ptrack_data/lib/src/db/migrations.dart
    - packages/ptrack_data/lib/src/mappers/period_mapper.dart
    - packages/ptrack_data/test/migration_test.dart
    - packages/ptrack_data/test/period_mapper_test.dart
    - packages/ptrack_data/test/test_utils.dart
    - packages/ptrack_data/test/fixtures/ptrack_v1.sqlite
    - packages/ptrack_data/drift_schemas/README.md
    - packages/ptrack_data/tool/create_v1_fixture.dart
  modified:
    - packages/ptrack_data/pubspec.yaml
    - packages/ptrack_data/lib/ptrack_data.dart
    - packages/ptrack_data/lib/src/db/ptrack_database.dart
    - pubspec.lock
    - apps/ptrack/linux/flutter/generated_plugin_registrant.cc
    - apps/ptrack/linux/flutter/generated_plugins.cmake
    - apps/ptrack/macos/Flutter/GeneratedPluginRegistrant.swift

key-decisions:
  - Reject databases with user_version greater than ptrackSupportedSchemaVersion inside onUpgrade before any migration work; surface PtrackUnsupportedDatabaseSchemaException (wrapped by Drift isolate as DriftRemoteException in tests).
  - Keep table minimal (id, start_utc, end_utc); local-day validation stays in domain when saving.

patterns-established:
  - "Fixture discipline: regenerate test/fixtures via tool/create_v*_fixture.dart and drift_schemas/README.md when bumping schemaVersion."
  - "Mapper layer maps Drift Period rows to ptrack_domain PeriodSpan without denormalized calendar fields."

requirements-completed: [NFR-02]

duration: 38min
completed: 2026-04-04
---

# Phase 2 Plan 2: Drift persistence and migration safety Summary

**Drift-backed SQLite v1 for periods with transactional upgrade stub, domain mappers, committed fixture migration coverage, and explicit failure when the on-disk schema is newer than the app supports.**

## Performance

- **Duration:** 38 min
- **Started:** 2026-04-04 (execution session)
- **Completed:** 2026-04-04
- **Tasks:** 2
- **Files touched:** 19 (including generated and plugin registrant updates)

## Accomplishments

- `PtrackDatabase` at `schemaVersion` / `ptrackSupportedSchemaVersion` 1 with `periods` table storing UTC instants as Drift `dateTime` columns.
- `openPtrackDatabase` / `openPtrackQueryExecutor` with platform-appropriate default paths and `sqlite3_flutter_libs` Android workaround.
- Bidirectional mapping between Drift rows and `PeriodSpan` via `periodRowToDomain`, `periodSpanToInsertCompanion`, and `periodSpanToUpdateCompanion`.
- `assertSupportedSchemaUpgrade` prevents silent opens when `user_version` exceeds the supported cap; tests cover fixture survival and guard behavior.
- `test/fixtures/ptrack_v1.sqlite` plus `tool/create_v1_fixture.dart` and `drift_schemas/README.md` document how to refresh fixtures on future bumps.

## Task Commits

Each task was committed atomically:

1. **Task 1: Dependencies and Drift schema v1** — `35d2c63` (feat)
2. **Task 2: Mappers, newer-schema guard, and migration fixture test** — `3a0042e` (feat)

**Plan metadata:** docs(02-02) completion commit (includes this SUMMARY plus STATE, ROADMAP, REQUIREMENTS).

## Files Created/Modified

- `packages/ptrack_data/lib/src/db/ptrack_database.dart` — Database class, migration strategy, executor factory.
- `packages/ptrack_data/lib/src/db/ptrack_database.g.dart` — Drift generated code.
- `packages/ptrack_data/lib/src/db/tables.dart` — `Periods` table definition.
- `packages/ptrack_data/lib/src/db/migrations.dart` — Unsupported schema exception and upgrade assertion.
- `packages/ptrack_data/lib/src/mappers/period_mapper.dart` — Row ↔ `PeriodSpan` mapping.
- `packages/ptrack_data/test/migration_test.dart` — Fresh DB, fixture open, newer `user_version` guard.
- `packages/ptrack_data/test/period_mapper_test.dart` — Mapper behavior.
- `packages/ptrack_data/test/test_utils.dart` — Temp SQLite path helper for tests.
- `packages/ptrack_data/test/fixtures/ptrack_v1.sqlite` — On-disk v1 fixture with sample rows.
- `packages/ptrack_data/drift_schemas/README.md` — Fixture regeneration notes.
- `packages/ptrack_data/tool/create_v1_fixture.dart` — Script to rebuild the v1 fixture.

## Decisions Made

- Fail closed on newer schema via `onUpgrade` entry guard (not a silent open); tests accept Drift’s wrapped exception shape by matching message content where needed.
- Follow Drift’s default DateTime storage (Unix seconds in SQLite) for fixtures and raw sqlite3 scripts.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Drift’s background isolate surfaces `PtrackUnsupportedDatabaseSchemaException` as a wrapped error in tests; matcher updated to accept the stable error message. Windows required explicit `db.close()` before re-opening the file for `user_version` assertions to avoid file locks on temp directory teardown.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `ptrack_data` is ready for repository/coordinator work in `02-04` and prediction wiring; integrate `openPtrackDatabase` in the app when UI consumes persistence.

---
*Phase: 02-domain-persistence-prediction-v1*  
*Completed: 2026-04-04*

## Self-Check: PASSED

- `test/fixtures/ptrack_v1.sqlite` exists on disk.
- `packages/ptrack_data/lib/src/db/migrations.dart` exists on disk.
- Commits `35d2c63` and `3a0042e` present in `git log --oneline --all`.

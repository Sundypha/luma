---
phase: 15-address-full-app-code-review-findings
plan: 02
subsystem: database
tags: [flutter, sqlite, factory-reset, sealed-class, testing]

requires:
  - phase: 15-address-full-app-code-review-findings
    provides: Code review finding 4 scope (reset / DB delete trust)
provides:
  - Structured PtrackDbDeleteResult (deleted / notFound / failed) for SQLite file removal
  - closeAndDeletePtrackDatabaseFile helper with failure logging and optional test hook
  - LumaApp deletePtrackDatabaseOverride and onAfterPtrackDbDelete for tests
  - reset_flow_test.dart unit coverage for failed delete and ordering
affects:
  - phase 15 plan 15-01 (remaining code review items)

tech-stack:
  added: []
  patterns:
    - "Sealed result types for IO outcomes instead of silent catch"
    - "Test hooks on LumaApp mirroring homeOverride pattern"

key-files:
  created:
    - apps/ptrack/lib/features/lock/ptrack_db_delete_result.dart
    - apps/ptrack/lib/features/lock/reset_ptrack_database_file.dart
    - apps/ptrack/test/features/lock/reset_flow_test.dart
  modified:
    - apps/ptrack/lib/features/lock/delete_ptrack_db_file_io.dart
    - apps/ptrack/lib/features/lock/delete_ptrack_db_file_stub.dart
    - apps/ptrack/lib/features/lock/delete_ptrack_db_file.dart
    - apps/ptrack/lib/main.dart

key-decisions:
  - "Used sealed classes (deleted / notFound / failed with cause) for exhaustive switches and test clarity"
  - "Centralized close+delete+logging in closeAndDeletePtrackDatabaseFile to keep _resetApp ordered and unit-testable"

patterns-established:
  - "Factory reset DB removal: close database, await delete result, debugPrint on failure, optional onAfterDelete"

requirements-completed: []

duration: 18min
completed: 2026-04-10
---

# Phase 15 Plan 02: Factory reset DB delete observability Summary

**Structured SQLite file delete outcomes (`PtrackDbDeleteResult`), `debugPrint` on failure, and unit tests for the close-then-delete reset step via `closeAndDeletePtrackDatabaseFile`.**

## Performance

- **Duration:** 18 min (estimated)
- **Started:** 2026-04-10T08:49:30Z
- **Completed:** 2026-04-10T09:07:30Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Replaced empty catch in `delete_ptrack_db_file_io.dart` with explicit deleted / notFound / failed results.
- `_resetApp` keeps order (lock → prefs → onboarding reload → close → delete → navigation) while routing delete through `closeAndDeletePtrackDatabaseFile`.
- Automated tests assert failed deletes reach the post-delete hook and that close runs before delete.

## Task Commits

1. **Task 1: Return result from DB file delete (no silent failure)** — `c6ab336` (feat)
2. **Task 2: Tests + _resetApp handles failed delete** — `9577d5b` (feat)

**Plan metadata:** Docs commit message `docs(15-02): Complete factory reset DB delete observability plan` (same commit as STATE/ROADMAP updates).

## Files Created/Modified

- `apps/ptrack/lib/features/lock/ptrack_db_delete_result.dart` — Sealed result hierarchy for delete attempts.
- `apps/ptrack/lib/features/lock/delete_ptrack_db_file_io.dart` — Returns result; maps exceptions to `PtrackDbDeleteFailed`.
- `apps/ptrack/lib/features/lock/delete_ptrack_db_file_stub.dart` — Returns `PtrackDbNotFound` for non-IO platforms.
- `apps/ptrack/lib/features/lock/delete_ptrack_db_file.dart` — Exports result type; delegates to IO/stub.
- `apps/ptrack/lib/features/lock/reset_ptrack_database_file.dart` — Shared close + delete + logging + optional callback.
- `apps/ptrack/lib/main.dart` — `_resetApp` uses helper; optional test overrides on `LumaApp`.
- `apps/ptrack/test/features/lock/reset_flow_test.dart` — Unit tests for failure path and ordering.

## Decisions Made

- Kept UX minimal: `debugPrint` on failure (no SnackBar) to match existing reset patterns and avoid navigator/context coupling.
- Test surface: optional `deletePtrackDatabaseOverride` and `onAfterPtrackDbDelete` on `LumaApp`; regression signal primarily from `closeAndDeletePtrackDatabaseFile` unit tests.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `flutter` not on PATH in automation shell; verification used `fvm flutter test` and `fvm flutter analyze` from `apps/ptrack`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Finding 4 reset/DB-delete path is observable and covered by unit tests.
- Phase 15 plan `15-01` remains open for import-integrity work.

---
*Phase: 15-address-full-app-code-review-findings*
*Completed: 2026-04-10*

## Self-Check: PASSED

- `15-02-SUMMARY.md` present at `.planning/phases/15-address-full-app-code-review-findings/15-02-SUMMARY.md`
- Commits `c6ab336`, `9577d5b`, and latest `docs(15-02)` on branch `chore/gsd-project-init`
- `apps/ptrack/lib/features/lock/reset_ptrack_database_file.dart` and `apps/ptrack/test/features/lock/reset_flow_test.dart` exist

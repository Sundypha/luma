---
phase: 15-address-full-app-code-review-findings
plan: 01
subsystem: database
tags: [luma, import, drift, period-validation, testing]

requires:
  - phase: 15-address-full-app-code-review-findings
    provides: Code review findings 1–3 (import integrity)
provides:
  - PeriodValidation on every imported period before insert; LumaImportValidationException
  - Day entry upsert keyed on (periodId, dateUtc); LumaInvalidPeriodRefException for orphan refs
  - ImportService requires PeriodCalendarContext; app passes same context as PeriodRepository via DataSettingsScreen
affects:
  - Any future import preview or duplicate-count UX (ImportPreview still date-only for duplicates)

tech-stack:
  added: []
  patterns:
    - "Treat backups as untrusted: domain validation + typed import failures inside one transaction"
    - "Composite (periodId, dateUtc) for import idempotency, not calendar date alone"

key-files:
  created: []
  modified:
    - packages/ptrack_data/lib/src/export/import_service.dart
    - packages/ptrack_data/lib/ptrack_data.dart
    - packages/ptrack_data/test/export/import_service_test.dart
    - packages/ptrack_data/test/export/backup_service_test.dart
    - apps/ptrack/lib/features/backup/data_settings_screen.dart
    - apps/ptrack/test/features/backup/import_view_model_test.dart

key-decisions:
  - "English user-facing strings in new exceptions; ARB wiring deferred to a follow-up"
  - "Accumulated PeriodSpan list for validation includes DB periods plus prior rows from the same import file, in start order"

patterns-established:
  - "ImportService(…, calendar: same as PeriodRepository) for consistent duplicate-start-day checks"

requirements-completed: []

duration: 35min
completed: 2026-04-10
---

# Phase 15 Plan 01: Luma import integrity Summary

**Domain-backed period checks on `.luma` import, `(periodId, dateUtc)` day upserts, typed orphan-ref errors, and device calendar wiring from data settings — with Drift regression tests.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-10T09:36:00Z (approx.)
- **Completed:** 2026-04-10T10:11:00Z (approx.)
- **Tasks:** 3 (Tasks 1–2 automated; Task 3 `human-verify` pending manual smoke)
- **Files modified:** 6

## Accomplishments

- Imported periods run through `PeriodValidation.validateForSave` against existing DB spans and earlier rows in the same file before any insert.
- Day entries resolve duplicates with `periodId` + normalized UTC calendar `dateUtc`; orphan `period_ref_id` throws `LumaInvalidPeriodRefException` and rolls back the transaction.
- `DataSettingsScreen` passes the same `PeriodCalendarContext` used elsewhere (`calendar` from the parent) into `ImportService`.

## Task Commits

1. **Task 1–2 (implementation)** — `b3df094` — `feat(15-01): Validate Luma imports with domain rules and device calendar`
2. **Task 2 (tests)** — `69e59a4` — `test(15-01): Cover hardened import path and update backup VM tests`

**Task 3:** No additional code commit — wiring is in `data_settings_screen.dart`; **manual** export/re-import smoke test still recommended (plan `human-verify`).

_Note: Implementation and automated tests are split across two commits (library vs tests)._

## Files Created/Modified

- `packages/ptrack_data/lib/src/export/import_service.dart` — validation, exceptions, composite day query
- `packages/ptrack_data/lib/ptrack_data.dart` — export new exception types
- `packages/ptrack_data/test/export/import_service_test.dart` — `applyImport` regression group
- `packages/ptrack_data/test/export/backup_service_test.dart` — calendar ctor; updated skip/replace/orphan expectations
- `apps/ptrack/lib/features/backup/data_settings_screen.dart` — `ImportService(..., calendar: calendar, ...)`
- `apps/ptrack/test/features/backup/import_view_model_test.dart` — UTC test calendar on all `ImportService` constructions

## Decisions Made

- Reused English exception messages for now; plan allows a later ARB pass.
- Left `ImportPreview.analyze` duplicate counting date-only (out of scope for this plan); `applyImport` behavior is the source of truth for writes.

## Deviations from Plan

None — plan executed as written. Task 3 automated verification used `dart analyze` on `ptrack_data` (Flutter SDK / `flutter analyze` not available in this environment for `import_view_model.dart`).

## Issues Encountered

- `dart test` for `ptrack_data` on the executor host failed with a native-assets / objective_c tooling message; analysis passed locally for changed packages. Run `dart test packages/ptrack_data/test/export/import_service_test.dart` and `flutter test` on a full Flutter 3.11+ toolchain to confirm.

## User Setup Required

None.

## Next Phase Readiness

- After optional **Task 3** smoke (export small backup → re-import with skip/replace), phase 15 import-related review items 1–3 are fully closed in code.
- Consider aligning `ImportPreview` duplicate semantics with `(periodId, dateUtc)` in a follow-up if preview counts should match apply behavior.

## Self-Check: PASSED

- `15-01-SUMMARY.md` present at `.planning/phases/15-address-full-app-code-review-findings/15-01-SUMMARY.md`
- Commits `b3df094`, `69e59a4` on branch `chore/gsd-project-init`

---
*Phase: 15-address-full-app-code-review-findings*  
*Completed: 2026-04-10*

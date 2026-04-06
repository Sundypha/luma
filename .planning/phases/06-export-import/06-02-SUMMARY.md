---
phase: 06-export-import
plan: "02"
subsystem: database
tags: [drift, import, backup, json, transaction, luma]

requires:
  - phase: 06-export-import
    provides: Export schema, LumaCrypto, ExportService from plan 01
provides:
  - ImportService parse/validate/decrypt and transactional applyImport with ref_id remapping
  - ImportPreview duplicate counts by UTC calendar day and period overlap stats
  - BackupService auto-backups under app support with keep-3 pruning
  - Barrel exports for import/backup public API
affects:
  - 06-03, 06-04 (UI consumes ImportService, BackupService, ImportPreview)

tech-stack:
  added: []
  patterns:
    - Typed LumaImportException hierarchy for IMPT-02 readable errors
    - Injectable ApplicationSupportDirectory for BackupService tests

key-files:
  created:
    - packages/ptrack_data/lib/src/export/import_service.dart
    - packages/ptrack_data/lib/src/export/import_preview.dart
    - packages/ptrack_data/lib/src/export/backup_service.dart
    - packages/ptrack_data/test/export/import_service_test.dart
    - packages/ptrack_data/test/export/backup_service_test.dart
  modified:
    - packages/ptrack_data/lib/ptrack_data.dart

key-decisions:
  - "ImportService accepts optional BackupService so applyImport tests avoid real path_provider while production uses default app support dir."
  - "LumaVersionException carries fileVersion and supportedVersion for both format_version and schema_version mismatch cases with distinct messages."

patterns-established:
  - "applyImport always calls createBackup before opening the Drift transaction; duplicate handling keys on global calendar day via dateUtc equality."

requirements-completed: [IMPT-02]

duration: 45min
completed: 2026-04-06
---

# Phase 6 Plan 02: Import data layer summary

**Full import pipeline: typed parse/validation/decrypt, duplicate preview, auto-backup before atomic transactional apply with skip-or-replace by calendar day (IMPT-02).**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-06 (executor session)
- **Completed:** 2026-04-06
- **Tasks:** 2
- **Files modified:** 6 (library + tests + barrel)

## Accomplishments

- `ImportService.parseFileMeta` / `parseFileData` reject bad JSON, missing structure, version skew, and bad passwords with `LumaInvalidFileException`, `LumaVersionException`, and `LumaDecryptionException`.
- `ImportPreview.analyze` compares imported day rows to existing DB dates and summarizes period overlap vs net-new periods.
- `BackupService` writes `luma_backups/auto-backup-YYYY-MM-DD-HHmmss.luma` via `ExportService`, lists/prunes to three files.
- `applyImport` remaps exported `ref_id` to new `periods` rows, applies day entries inside one Drift transaction, and reports `ImportResult` plus optional `ProgressCallback`.

## Task Commits

1. **Task 1: ImportService validation and ImportPreview duplicate detection** — `29c6883` (feat)
2. **Task 2: BackupService and atomic import apply** — `02b59ef` (feat)

**Plan metadata:** `docs(06-02): Complete import data layer plan` (SUMMARY, STATE, ROADMAP, REQUIREMENTS).

## Files Created/Modified

- `packages/ptrack_data/lib/src/export/import_service.dart` — Exceptions, parse, `applyImport`, `DuplicateStrategy`, `ImportResult`.
- `packages/ptrack_data/lib/src/export/import_preview.dart` — `ImportPreview`, `ImportPreviewResult`.
- `packages/ptrack_data/lib/src/export/backup_service.dart` — `BackupService`, `BackupInfo`, `pruneBackups`.
- `packages/ptrack_data/lib/ptrack_data.dart` — Public exports for new types.
- `packages/ptrack_data/test/export/import_service_test.dart` — Parse, decrypt chain, preview tests.
- `packages/ptrack_data/test/export/backup_service_test.dart` — Apply import, backup path, pruning, progress, rollback.

## Decisions Made

- Optional `BackupService` injection on `ImportService` keeps integration tests hermetic without mocking `path_provider`.
- Public `pruneBackups` supports retention testing; `createBackup` invokes it after each write.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

- Data layer ready for plan 03 (export UI) and plan 04 (import UI) to call `ExportService`, `ImportService`, `ImportPreview`, and `BackupService`.

## Self-Check: PASSED

- Verified paths exist: `packages/ptrack_data/lib/src/export/import_service.dart`, `import_preview.dart`, `backup_service.dart`, `test/export/import_service_test.dart`, `test/export/backup_service_test.dart`.
- Verified commits: `29c6883`, `02b59ef` present in `git log`.

---
*Phase: 06-export-import*
*Completed: 2026-04-06*

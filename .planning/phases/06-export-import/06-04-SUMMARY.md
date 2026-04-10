---
phase: 06-export-import
plan: "04"
subsystem: ui
tags: [flutter, import, backup, mvvm, file_picker, drift]

requires:
  - phase: 06-export-import
    provides: ImportService, BackupService, ImportPreview, Data settings shell
provides:
  - ImportViewModel and ImportScreen multi-step import UX
  - Data → Import Backup navigation with shared ImportService/BackupService
  - import_file_bytes conditional IO/web helper for picker paths without bytes
affects:
  - Phase 7 app protection (no direct dependency)

tech-stack:
  added: []
  patterns:
    - "ChangeNotifier + ListenableBuilder for import wizard (matches export)"
    - "SegmentedButton for duplicate strategy (avoids deprecated RadioListTile)"

key-files:
  created:
    - apps/ptrack/lib/features/backup/import_view_model.dart
    - apps/ptrack/lib/features/backup/import_screen.dart
    - apps/ptrack/lib/features/backup/import_file_bytes.dart
    - apps/ptrack/lib/features/backup/import_file_bytes_io.dart
    - apps/ptrack/lib/features/backup/import_file_bytes_web.dart
    - apps/ptrack/test/features/backup/import_view_model_test.dart
  modified:
    - apps/ptrack/lib/features/backup/data_settings_screen.dart

key-decisions:
  - "Use FilePicker.pickFiles (file_picker 11.x static API), not FilePicker.platform"
  - "Do not call BackupService.createBackup from the view model before applyImport; ImportService.applyImport already creates the auto-backup once"
  - "Canceling the system file picker pops ImportScreen via onPickerCancelled"
  - "ImportScreen takes importService + db only; BackupService is injected into ImportService at the call site for a single shared instance"

patterns-established:
  - "visible test seam: handlePickedFile(bytes, fileName) for unit tests without mocking FilePicker"

requirements-completed: []

duration: 45min
completed: 2026-04-06
---

# Phase 6: Export/Import Summary

**Multi-step import UI (.luma picker, encryption password, preview, duplicate strategy with explained copy, progress, result) wired from Data settings, with view model unit tests.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-06 (executor session)
- **Completed:** 2026-04-06
- **Tasks:** 1 automated complete; 1 human verification **pending** (see below)
- **Files modified:** 7 (6 created, 1 modified)

## Accomplishments

- `ImportViewModel` drives idle → picking → password (if encrypted) → preview → strategy (if duplicates) → importing → done/error.
- `ImportScreen` opens the file picker on first frame; duplicate handling uses `SegmentedButton` plus inline explanatory copy (IMPT-03 product copy).
- Data settings **Import Backup** tile pushes `ImportScreen` with `ImportService(db, backupService: backup)` and `BackupService(db)` so auto-backup uses one service instance.
- `import_view_model_test.dart` covers unencrypted/encrypted paths, wrong password, apply success/failure, strategy, reset, extension validation, and `proceedToImport` when duplicates exist.

## Task Commits

1. **Task 1: ImportViewModel, ImportScreen, wiring, tests** — `6f20f79` (feat)

**Plan metadata:** `docs(06-04)` commit on this branch (updates STATE.md + ROADMAP.md + this file; locate with `git log --oneline -- .planning/phases/06-export-import/06-04-SUMMARY.md`)

## Task 2: Human verification (export/import round-trip) — **PENDING**

Automation cannot run the full device/emulator UAT below. **Do not mark plan 06-04 or requirements IMPT-01 / IMPT-03 complete in REQUIREMENTS.md until this checklist is signed off.**

**Prerequisites:** `cd apps/ptrack` then `fvm flutter run`. Log at least 2–3 periods with symptoms/notes.

**Step 1 — Export flow**

1. Drawer → **Data** → **Export Backup**
2. Confirm wizard presets and content toggles
3. **Everything** → Next → skip password → export runs
4. Progress bar during export; share sheet with `.luma`; save file

**Step 2 — Export with encryption**

1. Export again with password (e.g. `test123`)
2. Confirm completion and share sheet; save encrypted file separately

**Step 3 — Import unencrypted**

1. Data → **Import Backup**
2. Pick unencrypted `.luma` from step 1
3. Preview shows counts; if duplicates, strategy step shows explanatory text
4. **Keep existing** → Import → progress and completion summary
5. Confirm calendar/home data

**Step 4 — Import encrypted**

1. Data → **Import Backup** → pick encrypted file
2. Password screen copy; wrong password → **Incorrect password. Please try again.**
3. Correct password → preview → **Use imported** → completion and data integrity

**Step 5 — Error handling**

1. Try non-`.luma` / invalid content → readable errors
2. Optional: `.txt` renamed to `.luma` → validation error
3. Confirm auto-backup exists under app support `luma_backups/` (or product surface when built)

**Step 6 — Edge cases**

1. Export **Periods only** → import expectations for missing symptom data
2. Import with existing data → duplicate behavior matches chosen strategy

Reply **pass** or file issues; then update ROADMAP checkbox for `06-04-PLAN.md`, run `gsd-tools requirements mark-complete IMPT-01 IMPT-03` if appropriate, and add a final docs commit.

## Files Created/Modified

- `import_view_model.dart` — import flow state, `FilePicker.pickFiles`, `handlePickedFile` for tests
- `import_screen.dart` — UI per step; `PopScope` blocks back during import
- `import_file_bytes*.dart` — read bytes from path on IO when picker omits in-memory bytes
- `data_settings_screen.dart` — Import tile navigation
- `import_view_model_test.dart` — view model tests with temp `BackupService` support dir

## Decisions Made

- Skipped redundant `backupService.createBackup()` in the view model because `ImportService.applyImport` already performs the auto-backup (avoids double backup).
- Replaced plan’s `RadioListTile` with `SegmentedButton` to satisfy current Flutter analyzer (Radio group API deprecation).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] file_picker 11.x API**

- **Found during:** Task 1 (pickFile)
- **Issue:** `FilePicker.platform.pickFiles` does not exist on file_picker 11.x
- **Fix:** Use static `FilePicker.pickFiles`
- **Files modified:** `import_view_model.dart`
- **Committed in:** `6f20f79`

**2. [Rule 1 - Bug] Layout and analyzer**

- **Found during:** Task 1 (ImportScreen)
- **Issue:** `Spacer` in unbounded `Column`; deprecated `RadioListTile` group value API
- **Fix:** `Expanded` + `SingleChildScrollView` for preview/strategy; `SegmentedButton` for strategy
- **Files modified:** `import_screen.dart`
- **Committed in:** `6f20f79`

**3. [Rule 2 - Clarity] ImportScreen constructor**

- **Found during:** Task 1
- **Issue:** Unused `backupService` parameter if only `ImportService` consumed it
- **Fix:** Construct `ImportService(db, backupService: backup)` at navigation site; `ImportScreen` takes `importService` + `db` only
- **Files modified:** `import_screen.dart`, `data_settings_screen.dart`
- **Committed in:** `6f20f79`

---

**Total deviations:** 3 auto-fixed (1 blocking, 1 bug, 1 API clarity)

## Issues Encountered

None beyond deviations above.

## User Setup Required

None.

## Next Phase Readiness

- Code ready for human UAT on Task 2; IMPT-01 / IMPT-03 remain **pending verification** in REQUIREMENTS until sign-off.
- After UAT pass: mark plan complete in ROADMAP, optionally add lightweight widget test for Import navigation.

---

*Phase: 06-export-import*

*Completed (automation): 2026-04-06*

## Self-Check: PASSED

- `06-04-SUMMARY.md` present at `.planning/phases/06-export-import/06-04-SUMMARY.md`
- Task commit `6f20f79` on branch `chore/gsd-project-init`; docs commit is the latest touching this SUMMARY file

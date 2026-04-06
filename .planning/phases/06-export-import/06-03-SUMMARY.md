---
phase: 06-export-import
plan: "03"
subsystem: ui
tags: [flutter, export, share_plus, file_picker, path_provider, mvvm, changenotifier]

# Dependency graph
requires:
  - phase: 06-export-import
    provides: ExportService, ExportOptions, ExportResult (06-01)
provides:
  - Export wizard UI with content toggles, optional encryption, progress, and share/save delivery
  - Data settings screen and drawer navigation entry
  - PeriodRepository.database for constructing ExportService in the shell
affects:
  - 06-04 (import UI will wire Import tiles on same Data screen)

# Tech tracking
tech-stack:
  added: [share_plus ^12, file_picker ^11, path_provider ^2.1.5]
  patterns: [ListenableBuilder wizard, conditional dart.library.html delivery split, ExportDataRun test hook]

key-files:
  created:
    - apps/ptrack/lib/features/backup/export_view_model.dart
    - apps/ptrack/lib/features/backup/export_wizard_screen.dart
    - apps/ptrack/lib/features/backup/data_settings_screen.dart
    - apps/ptrack/lib/features/backup/luma_export_delivery.dart
    - apps/ptrack/lib/features/backup/luma_export_delivery_io.dart
    - apps/ptrack/lib/features/backup/luma_export_delivery_web.dart
    - apps/ptrack/test/features/backup/export_view_model_test.dart
  modified:
    - apps/ptrack/lib/features/shell/tab_shell.dart
    - apps/ptrack/pubspec.yaml
    - packages/ptrack_data/lib/src/repositories/period_repository.dart
    - pubspec.lock

key-decisions:
  - "Added public runExport(ExportDataRun) alongside startExport(ExportService) so tests can simulate failures without a closed Drift handle (closed DB still completed export in tests)."
  - "file_picker v11 uses FilePicker.saveFile (static), not FilePicker.platform.saveFile."
  - "Linux uses saveFile with bytes; non-Linux uses temp file + SharePlus; web build uses share from bytes via conditional import."

patterns-established:
  - "Backup feature lives under lib/features/backup/ with delivery split luma_export_delivery_io vs _web."

requirements-completed: [XPRT-01]

# Metrics
duration: 45min
completed: 2026-04-06
---

# Phase 6 Plan 03: Export UI Summary

**Export wizard with ChangeNotifier state, optional AES password, progress, and share/save delivery, plus a Data drawer screen that starts the flow and leaves Import/Auto-backup tiles for plan 06-04.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-06 (executor session)
- **Completed:** 2026-04-06
- **Tasks:** 2
- **Files modified:** 14 (including generated plugin registrants)

## Accomplishments

- `ExportViewModel` with presets, per-type toggles, password step, `runExport` / `startExport`, and platform delivery entry point.
- `ExportWizardScreen` with `ListenableBuilder` for all steps and drawer-safe back behavior (confirm leave when past content step).
- `DataSettingsScreen` with Export → `ExportWizardScreen`, placeholder Import and Auto-backups tiles.
- Drawer order: Settings → Data → About; `PeriodRepository.database` exposes Drift for `ExportService`.

## Task Commits

1. **Task 1: ExportViewModel and ExportWizardScreen** — `eb1f956` (feat)
2. **Task 2: Data settings screen and drawer navigation** — `b72d902` (feat)

3. **Plan documentation** — `docs(06-export-import-03)` commit on branch (includes this SUMMARY, STATE, ROADMAP, REQUIREMENTS)

## Files Created/Modified

- `apps/ptrack/lib/features/backup/export_view_model.dart` — Wizard state, `ExportDataRun`, delivery hook.
- `apps/ptrack/lib/features/backup/export_wizard_screen.dart` — UI for select → password → progress → done/error.
- `apps/ptrack/lib/features/backup/luma_export_delivery*.dart` — IO vs web sharing/saving.
- `apps/ptrack/lib/features/backup/data_settings_screen.dart` — Data hub screen.
- `apps/ptrack/lib/features/shell/tab_shell.dart` — Data drawer destination.
- `packages/ptrack_data/lib/src/repositories/period_repository.dart` — `database` getter.
- `apps/ptrack/pubspec.yaml` / `pubspec.lock` — New dependencies and lockfile.
- `apps/ptrack/test/features/backup/export_view_model_test.dart` — ViewModel tests.
- Linux/macOS generated plugin registrants updated for new plugins.

## Decisions Made

- See `key-decisions` in frontmatter (testable export failure path, file_picker v11 API, Linux save vs share).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] file_picker v11 API**
- **Found during:** Task 1 (delivery implementation)
- **Issue:** `FilePicker.platform.saveFile` does not exist in file_picker 11.x.
- **Fix:** Use `FilePicker.saveFile` with `bytes` for Linux.
- **Files modified:** `luma_export_delivery_io.dart`
- **Verification:** `fvm flutter test` / analyze clean
- **Committed in:** `eb1f956`

**2. [Rule 1 - Bug / test design] Closed-database error test**
- **Found during:** Task 1 (tests)
- **Issue:** `ExportService` on a closed in-memory DB still returned `done`, so the planned “failure” test did not fail.
- **Fix:** Introduced `runExport(ExportDataRun)` and tested with a throwing callback; kept `startExport(ExportService)` for production callers.
- **Files modified:** `export_view_model.dart`, `export_view_model_test.dart`
- **Verification:** Unit tests pass
- **Committed in:** `eb1f956`

---

**Total deviations:** 2 auto-fixed (1 blocking API, 1 test/correctness)
**Impact on plan:** Behavior matches intent; small public API extension (`runExport`) for testability.

## Issues Encountered

None beyond deviations above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan **06-04** can wire Import and Auto-backup tiles to `ImportWizard` / backup flows using the same `DataSettingsScreen`.
- `XPRT-01` marked complete in `REQUIREMENTS.md` via `gsd-tools requirements mark-complete`.

## Self-Check: PASSED

- `06-03-SUMMARY.md` exists at `.planning/phases/06-export-import/06-03-SUMMARY.md`.
- Task commits `eb1f956`, `b72d902` and docs commit updating planning files present on branch.

---
*Phase: 06-export-import*
*Completed: 2026-04-06*

---
phase: 18-diary-table-migration
plan: 03
subsystem: database
tags: [drift, luma, export, import, json, diary]

requires:
  - phase: 18-diary-table-migration
    provides: "Diary tables and DiaryRepository from 18-01/18-02"
provides:
  - ".luma format version 2 with top-level diary_entries and tag names"
  - "Import of v2 diary payloads plus v1 personal_notes fallback into diary_entries"
  - "Export wizard Diary toggle and ExportOptions.includeDiary (everything() includes diary)"
affects:
  - "18-04 and later UI plans consuming export/import"

tech-stack:
  added: []
  patterns:
    - "Legacy personal_notes on day_entries only applied when meta.formatVersion < 2"
    - "parseFileMeta accepts any format_version from 1 through current lumaFormatVersion"

key-files:
  created: []
  modified:
    - "packages/ptrack_data/lib/src/export/export_schema.dart"
    - "packages/ptrack_data/lib/src/export/export_service.dart"
    - "packages/ptrack_data/lib/src/export/import_service.dart"
    - "packages/ptrack_data/lib/ptrack_data.dart"
    - "apps/ptrack/lib/features/backup/export_view_model.dart"
    - "apps/ptrack/lib/features/backup/export_wizard_screen.dart"

key-decisions:
  - "parseFileMeta allows format 1 and 2 so older backups import; reject only newer or <1"
  - "Day-entry personal_notes sync during import runs only for formatVersion < 2 to avoid clashing with diary_entries on v2 files"

patterns-established:
  - "content_types uses diary (not personal_notes) when includeDiary is true"

requirements-completed: [DIARY-08]

duration: 32min
completed: 2026-04-14
---

# Phase 18 Plan 03: Luma v2 diary export/import Summary

**.luma format v2** adds a `diary_entries` array with denormalized tag names, bumps `lumaFormatVersion` to 2, wires `ExportService`/`ImportService`, accepts v1 backups in `parseFileMeta`, and routes legacy `personal_notes` into `diary_entries` when the file meta is still v1.

## Performance

- **Duration:** 32 min
- **Started:** 2026-04-14T14:30:00Z (approx.)
- **Completed:** 2026-04-14T15:02:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Schema: `ExportedDiaryEntry`, `ExportedDiaryTag`, `LumaExportData.diaryEntries`, `ExportOptions.includeDiary`, `lumaFormatVersion == 2`
- Export writes `diary_entries` with moods, notes, and tag names; day JSON no longer embeds diary as `personal_notes`
- Import merges `diary_entries` with duplicate skip/replace; v1 `personal_notes` backfill when no row exists for that UTC day
- Backup wizard **Diary** switch + EN/DE ARB; `ExportOptions.everything()` keeps `includeDiary: true`

## Task Commits

1. **Task 1: Export schema v2 — ExportedDiaryEntry, ExportedDiaryTag, version bump** — `3d7b175` (feat)
2. **Task 2: Export service writes diary; import service reads diary + backward-compat** — `746516b` (feat)

**Plan metadata:** Same commit as `.planning/STATE.md` + `.planning/ROADMAP.md` updates (message `docs(18-03): Complete Luma v2 diary export/import plan`).

## Files Created/Modified

- `packages/ptrack_data/lib/src/export/export_schema.dart` — v2 types, `includeDiary`, `diary_entries` JSON
- `packages/ptrack_data/lib/src/export/export_service.dart` — diary export, `_contentTypes` diary flag
- `packages/ptrack_data/lib/src/export/import_service.dart` — diary import, v1 compat, relaxed format gate
- `packages/ptrack_data/lib/ptrack_data.dart` — export public types
- `packages/ptrack_data/test/export/export_schema_test.dart`, `export_service_test.dart`, `import_service_test.dart` — coverage including v1 regression
- `apps/ptrack/lib/features/backup/export_view_model.dart`, `export_wizard_screen.dart` — Diary toggle
- `apps/ptrack/lib/l10n/app_en.arb`, `app_de.arb`, generated `app_localizations*.dart`

## Decisions Made

- **parseFileMeta** accepts `1 <= format_version <= lumaFormatVersion` so v1 backups parse; reject `>` newer and `<` 1
- **Legacy sync guard:** `_syncDiaryFromImportedDayEntry` runs the personal-notes path only when `meta.formatVersion < 2`, so v2 files rely on `diary_entries` instead of day-level notes

## Deviations from Plan

None — plan executed as specified. Additional UI/l10n wiring for the Diary toggle is required by plan must-haves (not only `ptrack_data`).

## Issues Encountered

- Windows timezone storage made strict `DateTime.utc` equality flaky for diary `dateUtc`; the v1 compat test compares `rows.first.dateUtc.toUtc()` to the expected UTC calendar day.

## User Setup Required

None.

## Next Phase Readiness

- Data layer can round-trip diary through `.luma` v2; v1 restores still populate `diary_entries`
- **Next:** `18-04-PLAN.md` (diary form sheet / symptom cleanup) can assume export/import diary plumbing exists

---
*Phase: 18-diary-table-migration*
*Completed: 2026-04-14*

## Self-Check: PASSED

- `18-03-SUMMARY.md` exists at `.planning/phases/18-diary-table-migration/18-03-SUMMARY.md`
- Task commits `3d7b175`, `746516b` are ancestors of `HEAD`; SUMMARY + STATE + ROADMAP updated in docs commit on branch

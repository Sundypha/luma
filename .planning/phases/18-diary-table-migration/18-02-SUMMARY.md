---
phase: 18-diary-table-migration
plan: 02
subsystem: database
tags: [drift, sqlite, ptrack_domain, repository, diary]

requires:
  - phase: 18-diary-table-migration
    provides: "Schema v5 diary tables from 18-01 (diary_entries, diary_tags, join)"
provides:
  - "DiaryEntryData and DiaryTag domain value types"
  - "DiaryRepository with reactive streams, pagination, tag CRUD, seedStarterTags"
  - "Symptom form persists personal diary via DiaryRepository; DayEntryData has no personalNotes"
  - "PeriodRepository watchPeriodsWithDays no longer merges diary text into day payload"
affects:
  - "18-03 export/import"
  - "18-04–18-07 UI plans consuming DiaryRepository"

tech-stack:
  added: []
  patterns:
    - "Drift @DataClassName on diary tables to avoid DiaryTag/DiaryEntry name clashes with domain"
    - "Personal diary IO only through DiaryRepository; clinical day rows stay in PeriodRepository"

key-files:
  created:
    - "packages/ptrack_domain/lib/src/period/diary_types.dart"
    - "packages/ptrack_data/lib/src/repositories/diary_repository.dart"
  modified:
    - "packages/ptrack_domain/lib/src/period/logging_types.dart"
    - "packages/ptrack_domain/lib/ptrack_domain.dart"
    - "packages/ptrack_data/lib/src/db/tables.dart"
    - "packages/ptrack_data/lib/src/db/ptrack_database.g.dart"
    - "packages/ptrack_data/lib/src/mappers/day_entry_mapper.dart"
    - "packages/ptrack_data/lib/src/repositories/period_repository.dart"
    - "packages/ptrack_data/lib/ptrack_data.dart"
    - "apps/ptrack/lib/features/logging/symptom_form_view_model.dart"
    - "apps/ptrack/lib/features/logging/symptom_form_sheet.dart"

key-decisions:
  - "DiaryRepository is a non-final class so Mocktail can implement it in widget/unit tests (plan had final)."

patterns-established:
  - "Calendar widget tests locate “today” using the same UTC calendar day as buildCalendarDayDataMap (UTC y/m/d of DateTime.now().toUtc())."

requirements-completed: [DIARY-01, DIARY-03, DIARY-07]

duration: 40min
completed: 2026-04-14
---

# Phase 18 Plan 02: Diary domain + DiaryRepository Summary

**Standalone diary domain types, Drift-backed DiaryRepository with streams and tag management, and symptom logging wired to persist personal notes in diary_entries instead of DayEntryData.**

## Performance

- **Duration:** 40 min (estimate)
- **Started:** 2026-04-14T12:00:00Z
- **Completed:** 2026-04-14T12:40:00Z
- **Tasks:** 2
- **Files modified:** 17 (including generated Drift output)

## Accomplishments

- Added `DiaryEntryData` / `DiaryTag` in `ptrack_domain` and removed `personalNotes` from `DayEntryData`.
- Implemented `DiaryRepository` (watch/get/save/delete entries, tag CRUD, filtered stream, pagination, starter tags).
- Regenerated Drift with `DiaryEntryRow` / `DiaryTagRow` data class names to avoid clashing with domain `DiaryTag`.
- App symptom sheet preloads diary text and saves mood+notes to `diary_entries` after period row writes.

## Task Commits

1. **Task 1: Diary domain types + DayEntryData cleanup** - `e5628b6` (feat)
2. **Task 2: DiaryRepository + mapper fix + ptrack_data exports + app/test wiring** - `2b7cb08` (feat)

**Plan metadata:** docs commit bundles this SUMMARY with `.planning/STATE.md` and `.planning/ROADMAP.md` updates (`docs(18-diary-table-migration-02): Record plan 02 completion`).

## Files Created/Modified

- `packages/ptrack_domain/lib/src/period/diary_types.dart` — Domain diary entry and tag types.
- `packages/ptrack_data/lib/src/repositories/diary_repository.dart` — Drift CRUD and streams for diary + tags.
- `packages/ptrack_data/lib/src/db/tables.dart` — `@DataClassName` for diary Drift rows.
- `packages/ptrack_data/lib/src/repositories/period_repository.dart` — Removed diary sync from day-entry writes; simplified watch snapshot.
- `apps/ptrack/lib/features/logging/symptom_form_sheet.dart` — Async preload + `DiaryRepository` for sheet.
- `apps/ptrack/test/logging_test.dart` — In-memory DB for `repository.database`; UTC-aligned today cell finder.

## Decisions Made

- Dropped `final` on `DiaryRepository` (plan specified `final`) so `implements DiaryRepository` mocks compile under Dart’s class modifier rules.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] App and tests required wiring beyond listed PLAN files**

- **Found during:** Task 2 (DiaryRepository + exports)
- **Issue:** Removing `DayEntryData.personalNotes` broke `SymptomFormViewModel`, `PeriodRepository` diary sync, and multiple tests; `showSymptomFormSheet` needed `repository.database`.
- **Fix:** Persist personal diary via `DiaryRepository` in the VM; removed `_syncDiaryFromDayData` from `PeriodRepository`; updated mapper/tests; stubbed `PtrackDatabase` in `logging_test`; aligned “today” finders with UTC calendar semantics used by `buildCalendarDayDataMap`.
- **Files modified:** `symptom_form_view_model.dart`, `symptom_form_sheet.dart`, `period_repository.dart`, `*_test.dart` files under `apps/ptrack` and `packages/ptrack_data`.
- **Verification:** `fvm flutter test` in `packages/ptrack_domain`, `packages/ptrack_data`, `apps/ptrack`; `fvm flutter analyze` on app.
- **Committed in:** `2b7cb08` (Task 2)

**2. [Rule 2 - Testability] DiaryRepository not final**

- **Found during:** Task 2 (analyzer / tests)
- **Issue:** `final class DiaryRepository` cannot be `implements`d by Mocktail mocks (`invalid_use_of_type_outside_library`).
- **Fix:** Use a non-final `class DiaryRepository`.
- **Files modified:** `diary_repository.dart`
- **Verification:** `fvm flutter analyze` clean; `symptom_form_view_model_test` loads.
- **Committed in:** `2b7cb08`

**3. [Rule 1 - Bug] Flaky home/logging tests around “today”**

- **Found during:** Task 2 verification
- **Issue:** `HomeViewModel` / calendar use `_utcMidnight(DateTime.now())` while tests used local `DateTime.utc(now.year, …)` or `DateTime.now().day` for bold-cell lookup.
- **Fix:** Align fixtures and `findTodayCalendarDayCell` with UTC calendar day of `DateTime.now().toUtc()`.
- **Files modified:** `home_view_model_test.dart`, `logging_test.dart`
- **Verification:** Re-ran affected tests; full `apps/ptrack` test suite green.
- **Committed in:** `2b7cb08`

---

**Total deviations:** 3 auto-fixed (1 blocking scope expansion for wiring, 1 testability, 1 test flake)
**Impact on plan:** Deliverables match plan intent; extra files were required for a compiling app and green CI.

## Issues Encountered

None beyond deviations above.

## User Setup Required

None.

## Next Phase Readiness

- `DiaryRepository` and domain diary types are ready for export/import (18-03) and dedicated diary UI (18-04+).
- Symptom form still exposes a “personal notes” field in UI; full UX removal is deferred to later phase plans as scoped.

---
*Phase: 18-diary-table-migration*
*Completed: 2026-04-14*

## Self-Check: PASSED

- Confirmed files exist: `packages/ptrack_data/lib/src/repositories/diary_repository.dart`, `packages/ptrack_domain/lib/src/period/diary_types.dart`.
- Confirmed task commits in history: `e5628b6`, `2b7cb08`; latest `docs(18-diary-table-migration-02)` commit includes this file with STATE and ROADMAP.

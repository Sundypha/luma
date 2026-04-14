---
phase: 18-diary-table-migration
verified: 2026-04-14T12:00:00Z
status: human_needed
score: 41/42 plan must-have truths verified (1 partial — see Observable Truths)
re_verification: false
human_verification:
  - test: "Fresh install and v4 upgrade on device or emulator"
    expected: "Diary tab, calendar blue dot, home shortcut, day-detail hub, and tag settings behave as designed; no personal diary field on symptom form."
    why_human: "Full apps/ptrack test run failed on this Windows host during native asset copy (sqlite3.dll); UI flows need interactive confirmation."
  - test: "Export a backup with Diary enabled, re-import on clean DB"
    expected: "diary_entries round-trip; v1 .luma still imports personal notes into diary table."
    why_human: "Automated import/export tests passed in ptrack_data only; end-to-end wizard UX not exercised."
---

# Phase 18: Diary table migration — verification report

**Phase goal (ROADMAP):** Extract personal diary/notes from the symptom log into a standalone table so users can add a diary entry on any day; migrate existing data; keep export/import backward-compatible; diary UI (tab, calendar, home, settings tags), domain/repository layer, schema v5.

**Verified:** 2026-04-14T12:00:00Z  
**Status:** human_needed  
**Re-verification:** No (no prior `18-VERIFICATION.md`)

## Requirements traceability

**ROADMAP** lists requirements **DIARY-01 through DIARY-09** for this phase.  
**`.planning/REQUIREMENTS.md`** was searched for `DIARY-` / `Phase 18` / diary-related IDs: **no matching requirement entries found.** Plans still declare `requirements: [DIARY-…]` in frontmatter, so **formal REQ ↔ implementation traceability is missing in REQUIREMENTS.md** (documentation gap, not evidence that code is wrong).

## Goal achievement

### Observable truths (cross-check vs plans 18-01–18-07)

| # | Truth (source) | Status | Evidence |
|---|----------------|--------|----------|
| 1 | v4 `personal_notes` → v5 `diary_entries` rows (18-01) | VERIFIED | `migration_test.dart` v4 fixture test; `ptrack_database.dart` `INSERT INTO diary_entries … WHERE personal_notes …` |
| 2 | Diary mood copied only when notes non-empty (18-01) | VERIFIED | SQL `CASE WHEN personal_notes … THEN mood ELSE NULL END` in `ptrack_database.dart` |
| 3 | After migration, `day_entries` has no `personal_notes` (18-01) | VERIFIED | `migration_test.dart` asserts column absent; `tables.dart` `DayEntries` has no personal notes column |
| 4 | Migration fully transactional; mid-migration failure rolls back (18-01) | PARTIAL | **Code:** entire `onUpgrade` path wrapped in `m.database.transaction` (`ptrack_database.dart`). **Tests:** no test injects failure mid-migration; rollback behavior not empirically proven in repo tests. |
| 5 | Fresh install → five tables at schema v5 (18-01) | VERIFIED | `migration_test.dart` "fresh database creates all five tables…"; `ptrackSupportedSchemaVersion = 5` |
| 6 | v1/v2 fixtures migrate to v5 (18-01) | VERIFIED | `migration_test.dart` committed fixture tests |
| 7 | Diary domain types; `DayEntryData` without personal notes (18-02) | VERIFIED | `diary_types.dart`; `logging_types.dart` / mapper omit personal diary |
| 8 | `DiaryRepository` CRUD + streams + paging (18-02) | VERIFIED | `diary_repository.dart`: `watchAllEntries`, `getEntriesPage`, `saveEntry`, `deleteEntry`, `watchTags`, tag CRUD |
| 9 | `ptrack_data` exports diary symbols (18-02) | VERIFIED | `ptrack_data.dart` exports `DiaryRepository`, `StoredDiaryEntry`, re-exports domain diary types |
| 10 | Luma v2 `diary_entries`; v1 import routes notes to diary (18-03) | VERIFIED | `lumaFormatVersion = 2`, `ExportOptions.includeDiary`; `import_service_test.dart` backward-compat test |
| 11 | Backup / export wizard includes diary when configured (18-03) | VERIFIED | `ExportOptions.everything(includeDiary: true)`; `export_service.dart` gates on `includeDiary` |
| 12 | Diary form: save/delete + tags; symptom form no personal notes (18-04) | VERIFIED | `diary_form_sheet.dart` `saveEntry` / `deleteEntry` / `watchTags`; no `personalNotes` under `apps/ptrack/lib/features/logging` |
| 13 | EN/DE strings for diary (18-04) | VERIFIED | `app_en.arb` / `app_de.arb` contain matching diary keys (e.g. `diaryFormTitleNew`, `homeDiaryNewEntry`, `calendarLegendDiaryEntry`, `settingsMenuDiaryTagsTitle`) |
| 14 | Calendar blue dot + legend (18-05) | VERIFIED | `calendar_day_data.dart` `hasDiaryEntry`; `calendar_painters.dart` `_diaryDotChip` / legend `calendarLegendDiaryEntry` |
| 15 | Calendar merges `watchAllEntries` (18-05) | VERIFIED | `calendar_view_model.dart` `_diaryRepository.watchAllEntries()` |
| 16 | Home Today diary shortcut → `showDiaryFormSheet` (18-05) | VERIFIED | `today_card.dart`; `home_view_model.dart` subscribes to diary stream (`todayDiaryEntry` — plan text said `hasTodayDiaryEntry`; equivalent via nullable entry) |
| 17 | Day detail four-state hub + dual mood + diary actions (18-06) | VERIFIED | `day_detail_sheet.dart` branches and `dayDetailSymptomMoodLabel` / `dayDetailDiaryMoodLabel`; `showDiaryFormSheet` / `diaryEntryForDay` |
| 18 | `DiaryTagsSettingsScreen` CRUD (18-06) | VERIFIED | File exists; `watchTags` stream; navigation from `tab_shell.dart` settings list |
| 19 | Diary tab, paginated list, search, tag chips, date filter, FAB, settings tile (18-07) | VERIFIED | `tab_shell.dart` `IndexedStack` + `NavigationBar` diary destination; `diary_screen.dart` + `diary_view_model.dart` (`filteredEntries`, `ListenableBuilder`, scroll pagination); `diaryTabFloatingActionButton`; settings `DiaryTagsSettingsScreen` tile |

**Score:** 41 truths fully verified + 1 partial (row 4) → **41/42** if counting partial as unmet; implementation confidence for row 4 remains high from transaction wrapper.

### Required artifacts (existence + substantive + wiring)

| Artifact | Status | Details |
|----------|--------|---------|
| `packages/ptrack_data/lib/src/db/tables.dart` | VERIFIED | `DiaryEntries`, `DiaryTags`, `DiaryEntryTagJoin`; `DayEntries` without personal notes |
| `packages/ptrack_data/lib/src/db/migrations.dart` | VERIFIED | `assertSupportedSchemaUpgrade` used at start of `onUpgrade` |
| `packages/ptrack_data/lib/src/db/ptrack_database.dart` | VERIFIED | Schema 5, `@DriftDatabase` lists all tables, v4→v5 migration inside transaction |
| `packages/ptrack_data/test/migration_test.dart` | VERIFIED | v4→v5 + fresh v5 tests (no mid-migration failure injection) |
| `packages/ptrack_domain/.../diary_types.dart` | VERIFIED | `DiaryEntryData`, `DiaryTag` |
| `packages/ptrack_data/.../diary_repository.dart` | VERIFIED | Drift queries on `diaryEntries` / `diaryTags` / `diaryEntryTagJoin` |
| Export/import trio | VERIFIED | `export_schema.dart`, `export_service.dart`, `import_service.dart` wired to diary tables / v1 compat |
| `apps/ptrack/.../diary_form_sheet.dart` | VERIFIED | Wired to `DiaryRepository` |
| Calendar / home / shell / diary screens | VERIFIED | Imports and runtime wiring through `TabShell` / view models |

### Key links

| From | To | Via | Status |
|------|-----|-----|--------|
| `ptrack_database.dart` | Diary tables + migration SQL | `@DriftDatabase` + `onUpgrade` | WIRED |
| `export_service.dart` | `diaryEntries` | `includeDiary` branch | WIRED |
| `import_service.dart` | `diaryEntries` | v1/v2 paths | WIRED |
| `diary_form_sheet.dart` | `DiaryRepository` | `saveEntry`, `watchTags`, `deleteEntry` | WIRED |
| `calendar_view_model.dart` | `DiaryRepository` | `watchAllEntries` | WIRED |
| `today_card.dart` | `showDiaryFormSheet` | `onTap` | WIRED |
| `day_detail_sheet.dart` | `showDiaryFormSheet` / `diaryEntryForDay` | Hub buttons | WIRED |
| `diary_screen.dart` | `DiaryViewModel.filteredEntries` | `ListenableBuilder` + `ListView.builder` | WIRED |
| `tab_shell.dart` | `DiaryScreen`, `DiaryTagsSettingsScreen` | `IndexedStack` / settings `ListTile` | WIRED |

### Automated tests run

- **Command:** `fvm flutter test` in `packages/ptrack_data` on files: `test/migration_test.dart`, `test/export/import_service_test.dart`, `test/export/export_service_test.dart`, `test/export/export_schema_test.dart`  
- **Result:** **All passed** (48 tests in that invocation).

### apps/ptrack tests on Windows (sqlite3.dll)

- **Command:** `fvm flutter test` from `apps/ptrack`  
- **Result:** Flutter tool exited with **`PathExistsException`**: cannot copy native `sqlite3.dll` into `apps/ptrack/build/native_assets/windows/` because the destination already exists (**errno = 183** — Windows “file already exists”).  
- **Interpretation:** This is an **environment / Flutter native-assets + filesystem state** issue (stale or locked build output), **not proof that phase-18 diary code is incorrect.** Clearing `build/` and `.dart_tool` under the app, or running tests on Android/macOS/Linux CI, is the usual workaround. For that reason, **widget/integration tests for `apps/ptrack` were not used** in this verification pass.

### Anti-patterns (quick scan)

- No `TODO` / `FIXME` / placeholder returns found in `diary_form_sheet.dart` from a targeted search.  
- Drift **debug warning** in `import_service_test` about multiple `PtrackDatabase` instances on same executor (test-only; not a phase-18 functional defect).

### Human verification required

See YAML `human_verification` above: device/emulator passes for diary UX and backup round-trip; Windows desktop test runner may need a clean build directory if sqlite3 copy errors persist.

### Gaps summary (narrative)

- **Requirements.md:** DIARY-01…09 not defined in `REQUIREMENTS.md` → traceability gap for auditors.  
- **18-01 must-have:** Transaction atomicity is implemented; **explicit mid-migration failure test** described in the plan truth is **not present** in `migration_test.dart`.  
- **apps/ptrack automated tests:** Not executed successfully on this host due to **sqlite3.dll** copy failure.

---

_Verified: 2026-04-14T12:00:00Z_  
_Verifier: Claude (gsd-verifier)_

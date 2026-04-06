# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-04)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** Phase 5 (calendar surfaces) and **Phase 05.1** (day-marking UX + MVVM refactor) in parallel until 05-04 sign-off; **Phase 6 plan 06-04** Task 2 (export/import UAT) pending.

## Current Position

Phase: **5** of 8 (Calendar, home & cycle surfaces) — **05.1-05 Task 1 (automation) complete**; **05.1-05 Task 2 human verify pending** (see below).

**Current Plan (Phase 5):** 4 (`05-04`)

**Total Plans in Phase 5:** 4

Plan: **05-04** — Task 1 (day detail sheet + calendar routing) **complete** 2026-04-06; **Task 2 human verification pending** (see `05-04-SUMMARY.md`).

**Phase 05.1 (inserted):** Plans **01–04** complete; **`05.1-05` Task 1** complete (`f14ed5f`) — removed `logging_bottom_sheet.dart`, first log uses `markDay`, home quick actions + FAB use `SymptomFormSheet`. **Task 2** (full UX checklist) **pending** — see `05.1-05-SUMMARY.md`.

Status: **Phase 5 in progress** — same as above; **Phase 05.1** automation done for plan 05; **human UAT** outstanding for `05.1-05`.

Last activity: 2026-04-06 — **`06-04-PLAN.md` Task 1** complete (`6f20f79` import UI + tests; IMPT-01/IMPT-03 **await Task 2 human UAT** — see `06-04-SUMMARY.md`). Earlier **`06-03-PLAN.md`** (export UI); `05-04` and `05.1-05` Task 2 human checkpoints still open.

**Progress:** [█████████░] 92%

## Performance Metrics

**Velocity:**

- Total plans completed: 17
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 3 | 3 | — |
| 2 | 4 | 4 | 20 min (02-01); 38 min (02-02); 35 min (02-03); 42 min (02-04) |
| 3 | 3 | 3 | 28 min (03-01); 35 min (03-02 T1); 15 min (03-03) |
| 4 | 3 | 3 | 40 min (04-01); 45 min (04-02); — (04-03 + UAT) |

**Recent Trend:**

- Last 5 plans: 06-03, 06-02, 05.1-05 T1, 05.1-04, 05.1-03
- Trend: —

*Updated after each plan completion*

| Phase / plan | Duration | Tasks | Files |
|--------------|----------|-------|-------|
| Phase 3 P01 | 28min | 3 tasks | 8 files |
| Phase 03-onboarding P02 | 35min | 1 tasks | 7 files |
| Phase 03-onboarding P03 (gap_closure) | 15min | 3 tasks | 4 files |
| Phase 04-core-logging P01 | 40min | 2 tasks | 12 files |
| Phase 04-core-logging P02 | 45min | 2 tasks | 7 files |
| Phase 04-core-logging P03 | — | 3 tasks (incl. Task 3 pass); UAT gaps `1856a99`, `28f0d25` | 7+ files |
| Phase 05-calendar-home-cycle-surfaces P02 | 30min | 2 tasks | 3 files |
| Phase 05-calendar-home-cycle-surfaces P01 | 25 min | 2 tasks | 8 files |
| Phase 05-calendar-home-cycle-surfaces P03 | 35min | 2 tasks | 5 files |
| Phase 05.1 P01 | 25min | 2 tasks | 3 files |
| Phase 05.1 P02 | 30min | 2 tasks | 5 files |
| Phase 05.1 P03 | 30min | 2 tasks | 11 files |
| Phase 05.1 P05 T1 | 25min | 1 task (auto) | 8 files |
| Phase 06-export-import P01 | 35min | 2 tasks | 11 files |
| Phase 06-export-import P02 | 45min | 2 tasks | 6 files |
| Phase 06-export-import P03 | 45min | 2 tasks | 14 files |
| Phase 06-export-import P04 T1 | 45min | 1 task (auto); Task 2 UAT pending | 7 files |

## Accumulated Context

### Decisions

Decisions are logged in `PROJECT.md` Key Decisions table.

- Phase 1 (2026-04-04): Dart pub workspace + Melos 7; Flutter 3.41.2 via FVM; CI uses FVM then `melos exec`; pubspec policy script runs with **uv** (`uv run --with pyyaml`), not pip.
- [Phase 2]: Period validation uses PeriodCalendarContext (IANA Location) for duplicate start-day checks; call timezone initializeTimeZones() before fromTimeZoneName.
- [Phase 2]: Completed-cycle length is inclusive local days from period start through the day before next start (see completedCycleBetweenStarts).
- [Phase 02-domain-persistence-prediction-v1]: Prediction thresholds: long gap >45d, long bleed >10d, outlier |L-median|>7, high-variability spread >=12d, six-cycle window.
- [Phase 02]: PeriodRepository returns PeriodWriteOutcome (success/rejected/not found) instead of throwing on validation failures. — Stable error typing for UI and tests; no silent drops.
- [Phase 3]: First-run routing: wizard completion flag plus empty period list gates first-log vs home on cold start.
- [Phase 3]: Onboarding step index persisted on PageView onPageChanged (swipe or button).
- [Phase 03-onboarding]: Onboarding tests use InMemorySharedPreferencesAsync for SharedPreferencesWithCache.
- [Phase 03 gap closure]: UAT gaps resolved in `37471f7` + `03-03` planning.
- [Phase 3 closeout 2026-04-05]: **`03-02` Task 2** human verification approved by user (“pass”); phase milestone finalized.
- [Phase 04-core-logging]: create_v2_fixture uses raw sqlite3 so fvm dart run works without dart:ui
- [Phase 04-core-logging]: day_entry mapper normalizes dateUtc to UTC calendar midnight for Drift DateTime round-trip
- [Phase 04-core-logging]: watchPeriodsWithDays dedupes consecutive identical snapshots when both periods and dayEntries Drift watches fire
- [Phase 04-core-logging]: Home widget tests stub watchPeriodsWithDays with Stream.value([]) for stable HomeScreen empty-state coverage
- [Phase 04 closeout 2026-04-05]: **`04-03` Task 3** human verification **pass**; LOG-01–LOG-06 complete; Phase 4 marked complete in roadmap.
- [Phase 04 UAT]: Per-period day logging (`addDayEntryForPeriod`), orphan day handling on span shrink (`PeriodWriteBlockedByOrphanDayEntries`), upsert by calendar day.
- [Phase 05-calendar]: Calendar painters use kPeriodColorLight for predicted hatch/outline vs solid kPeriodColor band for logged days (pattern + tone, NFR-06)
- [Phase 05-calendar]: buildCalendarDayCell uses Positioned.fill around CustomPaint layers for valid Stack constraints
- [Phase 05-calendar-home-cycle-surfaces]: 05-01 Task 1: minimal HomeScreen stub required so TabShell compiles before Task 2 full home
- [Phase 05-calendar-home-cycle-surfaces]: 05-01: cycle_position uses flutter/foundation @immutable for analyzer depend_on_referenced_packages
- [Phase 05-calendar-home-cycle-surfaces]: 05-01: drawer Settings widget test uses bounded pump instead of pumpAndSettle after openDrawer
- [Phase 05-calendar-home-cycle-surfaces]: 05-03: month-change widget test taps header chevron (horizontal PageView drag unreliable in tests)
- [Phase 05-calendar-home-cycle-surfaces]: 05-04 Task 1: calendar tap routing uses `!hasLoggedData && !isPredictedPeriod` so period-band days without a day entry open logging directly; day detail uses `anchorContext` after pop for `showLoggingBottomSheet`
- [Phase 05.1]: Day-marking merge: keepId=min(adjacent ids), absorbId=max for deterministic DB apply order
- [Phase 05.1]: Schema v3 closes NULL `end_utc` via SQL; Drift column stays nullable so `PeriodSpan(endUtc: null)` remains valid for in-memory use until all writers use closed spans
- [Phase 05.1]: 05.1-03 ViewModels expose `hasInitialEvent`/`loadError` and `repository`/`calendar` for sheet parity after removing StreamBuilder from calendar/home screens
- [Phase 05.1]: TabShell FAB marks today via `HomeViewModel.markToday` when `!isTodayMarked`; otherwise opens `showSymptomFormSheet` with `todayPeriodId` / `todayStoredEntry` (tooltip Mark today / Add symptoms)
- [Phase 05.1]: 05.1-04 Calendar opens `showDayDetailSheet` for every day tap; symptoms use `showSymptomFormSheet` from period day actions; CAL-03 marked complete in REQUIREMENTS
- [Phase 06-export-import]: 06-01 complete — `ExportService`, `LumaCrypto` (AES-256-GCM + Argon2id), export schema types, `docs/luma-export-format.md`; commits `87cb5a2`, `a365889`; XPRT-02/XPRT-03 marked complete in REQUIREMENTS
- [Phase 06-export-import]: 06-02 complete — `ImportService` (parse/validate/decrypt, transactional `applyImport`), `ImportPreview`, `BackupService` with keep-3 pruning; commits `29c6883`, `02b59ef`; IMPT-02 marked complete in REQUIREMENTS
- [Phase 06-export-import]: 06-03 complete — `ExportViewModel`, `ExportWizardScreen`, `DataSettingsScreen`, drawer Data entry, `PeriodRepository.database`; commits `eb1f956`, `b72d902`; XPRT-01 marked complete in REQUIREMENTS
- [Phase 06-export-import]: 06-04 Task 1 complete — `ImportViewModel`, `ImportScreen`, Data import tile wiring, `import_view_model_test.dart`; `FilePicker.pickFiles` (v11); shared `BackupService` injected into `ImportService` at navigation; commit `6f20f79`; **Task 2 full export/import UAT pending** (`06-04-SUMMARY.md` checklist)
- [Phase 06-export-import]: ImportService optional BackupService injection for testable applyImport without path_provider.
- [Phase 06-export-import]: 06-03: runExport(ExportDataRun) supplements startExport for testable failure path; file_picker v11 uses FilePicker.saveFile with bytes on Linux

### Pending Todos

- Run **06-04 Task 2** manual checklist (`06-04-SUMMARY.md`) for full export → import round-trip; reply `pass` or file issues. After pass: mark `06-04` complete in ROADMAP, run `gsd-tools requirements mark-complete IMPT-01 IMPT-03` if appropriate.
- Run **05-04 Task 2** manual checklist (`05-04-SUMMARY.md`); reply `pass` or file issues.
- Run **05.1-05 Task 2** manual checklist (`05.1-05-SUMMARY.md`); reply `pass` or file issues. After pass: check off `05.1-05` in ROADMAP, run `gsd-tools requirements mark-complete` for plan requirement IDs if appropriate.
- After pass: mark `05-04` complete in ROADMAP, mark CAL-03 in REQUIREMENTS, optionally run `gsd-tools` state/roadmap sync.

### Roadmap Evolution

- Phase 05.1 inserted after Phase 5: UX refactor - day-marking model and MVVM (URGENT) — replaces explicit start/end period actions with day-toggle model; refactors presentation layer to MVVM with ChangeNotifier ViewModels. Investigation document: `.planning/phases/05.1-ux-refactor-day-marking-model-and-mvvm/INVESTIGATION.md`.

### Blockers/Concerns

None.

## Session Continuity

**Last session:** 2026-04-06T18:31:40.211Z

**Stopped at:** Phase 7 context gathered

**Resume file:** .planning/phases/07-app-protection-lock/07-CONTEXT.md

**Next (Phase 6):** Human verification for **06-04 Task 2**; then close plan and IMPT-01 / IMPT-03 when signed off.

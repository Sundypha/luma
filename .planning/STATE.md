# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-04)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Phase 1 (v1) roadmap phases 1–8 are complete** through release-quality / offline / copy (2026-04-07). Residual human UATs for **05-04**, **05.1-05**, **06-04**, **07-03**, and **07-04** are **signed off** (user 2026-04-07); **IMPT-01**, **IMPT-03**, **LOCK-01**, **LOCK-02** marked complete in REQUIREMENTS. **Phase 9** is in active execution — multi-algorithm prediction and confidence calendar (see `.planning/phases/09-prediction-of-next-period/09-CONTEXT.md`).

## Current Position

Phase: **9** of 9 (Prediction of next period) — **executing** (`09-01` complete; next **`09-02`**).

**Current plan:** **`09-02-PLAN.md`** — ensemble coordinator, confidence map, settings (see ROADMAP).

**Prior phases (closed):** Phases **5**, **05.1**, **6**, **7**, **8** marked complete in ROADMAP with all plan checkboxes and pending UATs cleared per user confirmation.

Status: **Phase 9 in progress** — algorithm foundation (Plan 01) shipped in domain package; ensemble + UI plans remain.

Last activity: 2026-04-07 — Executed **`09-01-PLAN.md`**: `PredictionAlgorithm` layer, four algorithms, tests; see `09-01-SUMMARY.md`.

**Progress:** [█████████░] Phase 9: **1/3** plans complete (09-01 done; 09-02 / 09-03 pending)

## Performance Metrics

**Velocity:**

- Total plans completed: 26+ (all plans through Phase 8; see ROADMAP)
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
| Phase 06-export-import P04 | 45min | Task 1 auto; Task 2 UAT **pass** 2026-04-07 | 7 files |
| Phase 05-calendar P04 | — | Task 2 UAT **pass** 2026-04-07 | see `05-04-SUMMARY.md` |
| Phase 05.1 P05 | 25min | Task 2 UAT **pass** 2026-04-07 | see `05.1-05-SUMMARY.md` |
| Phase 07-app-protection-lock P02 | 45min | 2 tasks | 7 files |
| Phase 07-app-protection-lock P03–04 | — | Task 2 / Task 3 UAT **pass** 2026-04-07 | see SUMMARYs |
| Phase 08-release-quality-offline-assurance-inclusive-copy P02 | 12 min | 1 tasks | 4 files |
| Phase 08-release-quality-offline-assurance-inclusive-copy P01 | 18 min | 2 tasks | 11 files |
| Phase 08-release-quality-offline-assurance-inclusive-copy P03 | 12 min | Task 1 auto; Task 2 UAT **pass** | see `08-03-SUMMARY.md` |
| Phase 09-prediction-of-next-period P01 | 28 min | 2 tasks | see `09-01-SUMMARY.md` |

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
- [Phase 06-export-import]: 06-04 complete — import UI + **Task 2** export→import UAT **pass** 2026-04-07; **IMPT-01**, **IMPT-03** complete in REQUIREMENTS (`6f20f79` + UAT).
- [Phase 07-app-protection-lock]: 07-01 complete — `local_auth` + `flutter_secure_storage`, Android `FlutterFragmentActivity` + `USE_BIOMETRIC` + `allowBackup=false`, iOS Face ID + keychain entitlements; `LockService` with Argon2id PIN + unit tests; commits `ce72342`, `4082ebb` (see `07-01-SUMMARY.md`).
- [Phase 07-app-protection-lock]: 07-02 complete — `PinEntryWidget`, `LockViewModel`, `LockScreen`, `showPinSetupSheet`, `showForgotPinSheet`, `LockSettingsScreen`, `lock_view_model_test.dart`; commits `4ab53aa`, `630ace9` (see `07-02-SUMMARY.md`). **LOCK-03** complete in REQUIREMENTS.
- [Phase 07-app-protection-lock]: 07-03 / 07-04 complete — LockGate + gap closure; **Tasks 2–3** human UAT **pass** 2026-04-07; **LOCK-01**, **LOCK-02** complete in REQUIREMENTS (`993a892`, `273e1bc`, `a423f43`).
- [Phase 05 / 05.1 closeout 2026-04-07]: **05-04** Task 2 and **05.1-05** Task 2 human UAT **pass** (user); phases closed in ROADMAP.
- [Phase 06-export-import]: ImportService optional BackupService injection for testable applyImport without path_provider.
- [Phase 06-export-import]: 06-03: runExport(ExportDataRun) supplements startExport for testable failure path; file_picker v11 uses FilePicker.saveFile with bytes on Linux
- [Phase 07-app-protection-lock]: 07-02: LockViewModel tests use real LockService with mocked storage/local_auth because LockService is final.
- [Phase 07-app-protection-lock]: 07-02: showPinSetupSheet supports skipAck and changePinOnly for change-PIN without enableLock.
- [Phase 08]: Stream-backed ViewModels accept optional initialData; seed via _applyData without notifyListeners in ctor; main awaits watchPeriodsWithDays().first before runApp
- [Phase 08-release-quality-offline-assurance-inclusive-copy]: User-facing errors use fixed plain-language strings instead of DayMarkFailure.reason or Exception.toString() for NFR-05/NFR-07 alignment.
- [Phase 08 closeout 2026-04-07]: **08-03 Task 2** airplane-mode walkthrough human **pass**; NFR-08 complete; Phase 8 milestone complete in ROADMAP.

### Pending Todos

- **Phase 9:** Execute **`09-02-PLAN.md`**, then **`09-03-PLAN.md`**; run **`/gsd-execute-phase 9`** continuation as needed.

### Roadmap Evolution

- Phase 05.1 inserted after Phase 5: UX refactor - day-marking model and MVVM (URGENT) — replaces explicit start/end period actions with day-toggle model; refactors presentation layer to MVVM with ChangeNotifier ViewModels. Investigation document: `.planning/phases/05.1-ux-refactor-day-marking-model-and-mvvm/INVESTIGATION.md`.
- Phase 9 added: Prediction of next period — multi-algorithm prediction (3+ algorithms), confidence-based calendar visualization showing agreement level across algorithms
- 2026-04-07: User confirmed all remaining v1 human UATs (05-04, 05.1-05, 06-04, 07-03, 07-04); `requirements mark-complete` for IMPT-01, IMPT-03, LOCK-01, LOCK-02; `phase complete` for 5, 05.1, 6, 7; ROADMAP/STATE reconciled — **only Phase 9 remains in planning**.
- [Phase 9 / 09-01]: Multi-algorithm domain foundation — `PredictionAlgorithm`, `MedianBaselineAlgorithm` (wraps `PredictionEngine`), `EwmaAlgorithm`, `BayesianAlgorithm`, `LinearTrendAlgorithm`, `EnsemblePredictionResult`; UTC helpers `addUtcCalendarDays` / `utcCalendarDateOnly` on `prediction_engine.dart`; tests in `prediction_algorithm_test.dart`.

### Blockers/Concerns

None.

## Session Continuity

**Last session:** 2026-04-07

**Stopped at:** **09-01** plan complete — domain algorithms + tests; next **09-02** ensemble coordinator

**Resume file:** `.planning/phases/09-prediction-of-next-period/09-CONTEXT.md`

**Next:** Execute **`09-02-PLAN.md`** (ensemble coordinator, confidence tiers, PredictionSettings).

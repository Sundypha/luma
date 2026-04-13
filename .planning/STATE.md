# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-07)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Milestone v2.0** — Phase **18** diary table migration (`18-06` complete; next `18-07`). Phase **17** still has optional `17-02` Task 3 human-verify.

## Current Position

**Milestone:** v2.0 — i18n, German locale, optional fertility window (**complete**).

**Phase:** **18** — Diary table migration (schema v5 + data path from v4).

**Plan:** `18-06` — **complete** (see `18-06-SUMMARY.md`). **Next:** `18-07` — diary tab + tab shell integration.

**Status:** Phase **18** in progress — 6/7 plans complete on branch `feat/18-01-diary-schema-migration`.

Last activity: 2026-04-14 — **18-06**: day detail period/diary routing hub; `DiaryTagsSettingsScreen`; `diaryEntryForDay` on calendar VM.

**Progress (v2.0):** Phase 18 **in progress** (6/7 plans). Phase 17 optional checkpoint remains. See `ROADMAP.md`.

## Performance Metrics

| Phase | Duration | Detail |
|-------|----------|--------|
| 17 P01 | 12 min | 2 tasks, 2 files — see `17-01-SUMMARY.md` |
| 18-diary-table-migration P01 | 45 min | 2 tasks, 12 files — see `18-01-SUMMARY.md` |
| 18-diary-table-migration P02 | 40 min | 2 tasks, 17 files — see `18-02-SUMMARY.md` |
| 18-diary-table-migration P03 | 32 min | 2 tasks, 15 files — see `18-03-SUMMARY.md` |
| 18-diary-table-migration P04 | 28 min | 2 tasks, 9 files — see `18-04-SUMMARY.md` |
| 18-diary-table-migration P05 | 35 min | 2 tasks, 20+ files — see `18-05-SUMMARY.md` |
| 18-diary-table-migration P06 | 50 min | 2 tasks, 8 files — see `18-06-SUMMARY.md` |

*Also reset when v2.0 execution starts; track per-phase durations in phase SUMMARY files.*

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions. v1 decisions and phase notes remain under `.planning/phases/` and `milestones/v1/`.

**2026-04-07 (11-03):** Calendar week start follows material locale only; ARB DE keys must cover all EN message keys (`tool/arb_de_key_parity.dart` + CI).

**2026-04-08 (12-01):** Fertile window uses cycle-day ovulation placement `(cycleLength − luteal)` from CD1; domain `formatEnsembleExplanation` uses `EnsembleMilestone` + English helper (no `milestoneMessage`).

**2026-04-08 (12-02):** Fertility opt-in uses bottom-sheet disclaimer then setup form; `SharedPreferences` stores all prefs when disabled; full fertility strings in EN/DE ARB for parallel Plans 03–04.

**2026-04-08 (12-03):** Calendar fertile days use the same **hatched-circle** visualization as period predictions, in a **teal** palette (`ConfidenceHatchedCirclePainter.fertilityEstimate`); legend matches. *(Earlier plan text described a diamond; superseded for consistency.)*

**2026-04-08 (12-04):** Home card shows average-cycle explanation only when `computedAverageCycleLength` is non-null; `hasEnoughDataForFertility` uses ≥2 `predictionCycleInputsFromStored` intervals; settings fertility toggle fans out to **both** VMs via `tab_shell`.

**2026-04-08 (13-01):** PDF export data layer: presets + `SharedPreferences` for sections and range; `PdfDataCollector` filters by period **start** in UTC date range and uses `completedCycleBetweenStarts` + local inclusive bleeding spans.

**2026-04-08 (13-02):** PDF document builder: `pdf` package `MultiPage` layout, conditional sections from `PdfSectionConfig`, disclaimer + footer with page numbers, cycle bar chart (`BarDataSet`), tables via `TableHelper`; all strings via `PdfContentStrings` / `pdf*` ARB keys + `toPdfContentStrings()`.

**2026-04-08 (14-01):** Removed global `TabShell` FAB; logging via Home Today card + calendar `DayDetailSheet`. Dropped `fabTooltip*` ARBs; `logging_test` uses bold today-cell finder in `TableCalendar` for calendar flows (mark-only path uses day sheet **I had my period** because Home Today CTA can open the symptom sheet immediately after mark).

**2026-04-10 (15-01):** `.luma` import uses `PeriodValidation.validateForSave` before period inserts, `PeriodCalendarContext` required on `ImportService` (wired from `DataSettingsScreen`), day upserts on `(periodId, dateUtc)`, orphan `period_ref_id` → `LumaInvalidPeriodRefException`; `ImportPreview` duplicate preview still date-only (apply path is authoritative).

**2026-04-10 (16-01):** Release signingConfig is null (not debug) when key.properties absent — unsigned builds fail explicitly; CI uses `printf` to write key.properties from individual secrets; `apksigner verify --print-certs` grepped for "Android Debug" as release-signing guard.

**2026-04-10 (17-01):** Root `CHANGELOG.md` follows Keep a Changelog; `tool/bump_version.dart` bumps `apps/ptrack/pubspec.yaml` semver + monotonic build, prepends a dated section after `## [Unreleased]`, optional `--tag` (git commit + annotated tag). Run with **`fvm dart run tool/bump_version.dart`** so the SDK matches workspace `^3.11` (plain `dart run` fails on older system Dart).

**2026-04-14 (18-01):** Dropped `personal_notes` from `day_entries` via Drift `alterTable(TableMigration(dayEntries))` (Drift 2.32 has no `Migrator.recreateTable`); diary text lives in `diary_entries` keyed by UTC calendar day.

**2026-04-14 (18-02):** `DiaryRepository` is a non-final class so Mocktail mocks compile in app tests; personal diary persistence moved out of `PeriodRepository` into `DiaryRepository` + symptom form preload.

**2026-04-14 (18-03):** `.luma` `lumaFormatVersion` 2 with `diary_entries`; `parseFileMeta` accepts v1 and v2; legacy `personal_notes` only synced from day entries when `formatVersion < 2`; export wizard maps **Diary** to `ExportOptions.includeDiary`.

**2026-04-14 (18-04):** `DiaryFormSheet` / `showDiaryFormSheet` for notes + mood + tags via `DiaryRepository`; symptom form no longer edits diary text (personal-notes field and `_persistPersonalDiary` removed). Diary mood slider uses direct enum ticks; symptom sheet keeps inverted mood for clinical logging.

**2026-04-14 (18-05):** Calendar shows `hasDiaryEntry` primary dot (with symptom chip when both); legend always includes diary line; `HomeViewModel` tracks `todayDiaryEntry`; Today card opens `showDiaryFormSheet`; `DiaryRepository` created in `main` and passed through `TabShell`.

**2026-04-14 (18-06):** Day detail past/today is a routing hub (period × diary presence) with dual mood labels when both exist; diary actions use `showDiaryFormSheet` after sheet pop; `DiaryTagsSettingsScreen` for tag CRUD (navigation wiring deferred to 18-07).

### Pending Todos

- **Phase 17** — Complete **17-02** Task 3: human verification of unified Release workflow (see `17-02-PLAN.md`); then finalize `17-02-SUMMARY.md` and mark REL-02–REL-04 if checks pass.
- **Optional:** `15-01` Task 3 — manual export/re-import smoke (skip/replace) on device.
- **Phase 13** — Complete **13-03** Task 3: human verification of PDF export flow (see `13-03-PLAN.md`). Then finalize `13-03-SUMMARY.md` and ROADMAP if not already done.
- **Phase 14** — **14-01** Task 4 `human-verify` per `14-01-PLAN.md` if still open.
- Phase 10 plans remain available if i18n foundation still needs execution on other branches.

### Roadmap Evolution

- **2026-04-07:** v2.0 opened — engineering phases **10–12** (i18n foundation → German + language settings → fertility window module).
- Phase 13 added: PDF export of period statistics and details (user selectable if all or none). Goal is to have a PDF ready for a physician or gynecologist.
- Phase 14 added: remove deprecated FAB. clicking on a day of the calendar opens the same widget as the FAB and is clearer in the intent than the FAB
- Phase 15 added: Address full app code review findings
- Phase 16 added: Security audit findings remediation
- Phase 17 added: release management with release bumps, release apks iin github release, and ran apk push to firebase app distribution
- Phase 18 added: Diary table migration — decouple personal diary from symptom logging so users can add diary entries on any day

### Blockers/Concerns

None.

## Session Continuity

**Last session:** 2026-04-14T18:30:00.000Z

**Stopped at:** Completed 18-06-PLAN.md

**Resume file:** None

**Next:** Execute **18-07-PLAN.md** (diary tab + tab shell). Optionally complete **17-02 Task 3** verification on GitHub or continue Phase **16** as prioritized.

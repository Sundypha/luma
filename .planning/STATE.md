# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-07)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Milestone v2.0** — Phase **17** release management (executing plan 02 next).

## Current Position

**Milestone:** v2.0 — i18n, German locale, optional fertility window (**complete**).

**Phase:** **17** — Release management (GitHub Release + Firebase App Distribution).

**Plan:** 01 complete — root CHANGELOG + `tool/bump_version.dart`. Next: `17-02-PLAN.md`.

**Status:** Phase **17** in progress — plan 01 complete (version management foundation, REL-01).

Last activity: 2026-04-10 — Phase **17-01** execution: `CHANGELOG.md` (Keep a Changelog + v1.0.0 retrospective), cross-platform `tool/bump_version.dart` (`3c36bd3`, `980eb23`).

**Progress (v2.0):** Phase 17 **in progress** (1/2 plans). See `ROADMAP.md`.

## Performance Metrics

| Phase | Duration | Detail |
|-------|----------|--------|
| 17 P01 | 12 min | 2 tasks, 2 files — see `17-01-SUMMARY.md` |

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

### Pending Todos

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

### Blockers/Concerns

None.

## Session Continuity

**Last session:** 2026-04-10T18:08:13.120Z

**Stopped at:** Completed 17-01-PLAN.md

**Resume file:** .planning/phases/17-release-management-with-release-bumps-release-apks-iin-github-release-and-ran-apk-push-to-firebase-app-distribution/17-02-PLAN.md

**Next:** Execute **17-02** (unified release workflow), or continue Phase **16** plans (e.g. **16-02** PIN lockout) as prioritized.

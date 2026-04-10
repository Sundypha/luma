# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-07)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Milestone v2.0** — Phase **15** code review remediation — plan **`15-03` complete** (`15-03-SUMMARY.md`); plans **15-01**, **15-02** still open. (Phase **13** PDF **13-03** still awaiting Task 3 human-verify elsewhere.)

## Current Position

**Milestone:** v2.0 — i18n, German locale, optional fertility window (**complete**).

**Phase:** **15** — Address full app code review findings.

**Plan:** **`15-03`** — `watchPeriodsWithDays` batch-load + regression tests — **complete** — see `.planning/phases/15-address-full-app-code-review-findings/15-03-SUMMARY.md` (commits `75f8319`, `94734e5`).

**Status:** Phase **15** **1/3** plans with completed execution for **`15-03`**; **`15-01`**, **`15-02`** not executed in this session. Phase **13** **13-03** still blocked on Task 3 human-verify.

Last activity: 2026-04-10 — Completed **15-03**: batched day entries in `PeriodRepository.watchPeriodsWithDays`, multi-period watch test. Earlier: 2026-04-08 — **14-01** / **13-03** as below.

**Progress (v2.0):** Phase 15 **in progress** (1/3 plans closed with SUMMARY for **03**). See `ROADMAP.md`.

## Performance Metrics

*Reset when v2.0 execution starts; track per-phase durations in phase SUMMARY files.*

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

**2026-04-10 (15-03):** `watchPeriodsWithDays` `load()` uses two SQL round-trips (all periods + `day_entries` where `periodId` in ids); ordering unchanged. Regression test seeds five periods with multiple days and compares stream to direct-query snapshot.

### Pending Todos

- **Phase 14** — **14-01** Tasks 1–3 **done** (FAB removed, ARB/tests updated); **Task 4** `human-verify` per `14-01-PLAN.md`. Then check **UXFAB-01/02** in `REQUIREMENTS.md`, finalize `14-01-SUMMARY.md`, and close the plan in `ROADMAP.md`.
- **Phase 13** — Complete **13-03** Task 3: human verification of PDF export flow (see `13-03-PLAN.md`). Then write `13-03-SUMMARY.md`, advance STATE/ROADMAP, and final docs commit.
- Phase 10 plans remain available if i18n foundation still needs execution on other branches.
### Roadmap Evolution

- **2026-04-07:** v2.0 opened — engineering phases **10–12** (i18n foundation → German + language settings → fertility window module).
- Phase 13 added: PDF export of period statistics and details (user selectable if all or none). Goal is to have a PDF ready for a physician or gynecologist.
- Phase 14 added: remove deprecated FAB. clicking on a day of the calendar opens the same widget as the FAB and is clearer in the intent than the FAB
- Phase 15 added: Address full app code review findings
- Phase 16 added: Security audit findings remediation

### Blockers/Concerns

None.

## Session Continuity

**Last session:** 2026-04-10

**Stopped at:** Phase **15** plan **`15-03`** — complete (`15-03-SUMMARY.md`, STATE/ROADMAP updated).

**Resume file:** `.planning/phases/15-address-full-app-code-review-findings/15-01-PLAN.md` (or **15-02** per priority) for remaining code-review remediation; optional **13-03** Task 3 UAT per prior note.

**Next:** Execute **15-01** / **15-02** as planned, or resume **13-03** human-verify / **14-01** Task 4 UAT per product priority.

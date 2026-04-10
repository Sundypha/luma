# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-07)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Milestone v2.0** — Phase **16** security audit findings remediation (planning / execution next).

## Current Position

**Milestone:** v2.0 — i18n, German locale, optional fertility window (**complete**).

**Phase:** **16** — Security audit findings remediation.

**Plan:** TBD — run `/gsd-plan-phase 16` or open `.planning/phases/16-security-audit-findings-remediation/`.

**Status:** Phase **15** complete (verified `15-VERIFICATION.md`); optional **15-01** Task 3 import smoke on device.

Last activity: 2026-04-10 — Phase **15** execution + verification: import hardening, reset DB delete observability, `watchPeriodsWithDays` batch load; test fix `fc3cd1a`; docs `5751276`.

**Progress (v2.0):** Phase 15 **complete** (3/3 plans). See `ROADMAP.md`.

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

**2026-04-10 (15-01):** `.luma` import uses `PeriodValidation.validateForSave` before period inserts, `PeriodCalendarContext` required on `ImportService` (wired from `DataSettingsScreen`), day upserts on `(periodId, dateUtc)`, orphan `period_ref_id` → `LumaInvalidPeriodRefException`; `ImportPreview` duplicate preview still date-only (apply path is authoritative).

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

### Blockers/Concerns

None.

## Session Continuity

**Last session:** 2026-04-10

**Stopped at:** Completed **15-01** automated tasks and planning artifacts (`15-01-SUMMARY.md`, STATE/ROADMAP).

**Resume file:** `.planning/phases/15-address-full-app-code-review-findings/15-01-PLAN.md` (Task 3 smoke only, if desired)

**Next:** Optional import smoke UAT; or continue **13-03** / **14-01** human-verify items.

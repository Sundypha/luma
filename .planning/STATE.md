# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-07)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Milestone v2.0** — Phase **13** PDF export — plan **13-01** complete; next **13-02** document builder.

## Current Position

**Milestone:** v2.0 — i18n, German locale, optional fertility window (**complete**).

**Phase:** **13** — PDF export of period statistics and details.

**Plan:** **13-02** — PDF document builder (next). **13-01** done — see `13-01-SUMMARY.md`.

**Status:** Phase **12** complete; phase **13** in progress (**1/3** plans done).

Last activity: 2026-04-08 — Completed **`13-01`**: PDF section config, `PdfReportData`, `PdfDataCollector` + tests (`6b7efbc`, `81a61a4`).

**Progress (v2.0):** Phase 13 **in progress** (1/3 plans). See `ROADMAP.md`.

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

### Pending Todos

- **Phase 13** — Continue with `13-02`, `13-03` per `ROADMAP.md`.
- Phase 10 plans remain available if i18n foundation still needs execution on other branches.
- **Remove period projection opacity fade** — no per-cycle opacity decay; tier hatch/spacing already encodes confidence; details view conveys uncertainty (area: ui).

### Roadmap Evolution

- **2026-04-07:** v2.0 opened — engineering phases **10–12** (i18n foundation → German + language settings → fertility window module).
- Phase 13 added: PDF export of period statistics and details (user selectable if all or none). Goal is to have a PDF ready for a physician or gynecologist.
- Phase 14 added: remove deprecated FAB. clicking on a day of the calendar opens the same widget as the FAB and is clearer in the intent than the FAB

### Blockers/Concerns

None.

## Session Continuity

**Last session:** 2026-04-08

**Stopped at:** Phase **13** plan **13-01** complete; execute **13-02** when ready.

**Resume file:** `.planning/phases/13-pdf-export-of-period-statistics-and-details-user-selectable-if-all-or-none-goal-is-to-have-a-pdf-ready-for-a-physician-or-gynecologist/13-02-PLAN.md`

**Next:** `/gsd-execute-phase 13` (plan 02) or manual execution of `13-02-PLAN.md`.

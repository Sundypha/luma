# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-07)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Milestone v2.0** — i18n, **German** secondary locale, **optional fertility window** (opt-in, prompts for missing assumptions).

## Current Position

**Milestone:** v2.0 — i18n, German locale, optional fertility window.

**Phase:** **12** — Optional fertility window (in progress).

**Plan:** `12-03-PLAN.md` next (calendar fertility visuals).

**Status:** Phase **12** plans **01–02** complete (`12-01-SUMMARY.md`, `12-02-SUMMARY.md`); phase **11** complete (3/3 plans + verification).

Last activity: 2026-04-08 — phase **12** plan **02** executed: fertility settings persistence, opt-in sheets, full fertility ARB (**FERT-01**, **FERT-02**, **FERT-04** satisfied).

**Progress (v2.0):** Phase 12 **2/4** plans; remaining `12-03`–`12-04` (see `ROADMAP.md`).

## Performance Metrics

*Reset when v2.0 execution starts; track per-phase durations in phase SUMMARY files.*

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions. v1 decisions and phase notes remain under `.planning/phases/` and `milestones/v1/`.

**2026-04-07 (11-03):** Calendar week start follows material locale only; ARB DE keys must cover all EN message keys (`tool/arb_de_key_parity.dart` + CI).

**2026-04-08 (12-01):** Fertile window uses cycle-day ovulation placement `(cycleLength − luteal)` from CD1; domain `formatEnsembleExplanation` uses `EnsembleMilestone` + English helper (no `milestoneMessage`).

**2026-04-08 (12-02):** Fertility opt-in uses bottom-sheet disclaimer then setup form; `SharedPreferences` stores all prefs when disabled; full fertility strings in EN/DE ARB for parallel Plans 03–04.

### Pending Todos

- Phase **12** plans **03–04** (calendar/home fertility UI, suggestion card wiring) per `ROADMAP.md`
- Phase 10 plans remain available if i18n foundation still needs execution on other branches
- Optional: domain research pass if product/legal copy for **FERT-*** needs tightening before implementation

### Roadmap Evolution

- **2026-04-07:** v2.0 opened — engineering phases **10–12** (i18n foundation → German + language settings → fertility window module).
- Phase 13 added: PDF export of period statistics and details (user selectable if all or none). Goal is to have a PDF ready for a physician or gynecologist.
- Phase 14 added: remove deprecated FAB. clicking on a day of the calendar opens the same widget as the FAB and is clearer in the intent than the FAB

### Blockers/Concerns

None at milestone definition time.

## Session Continuity

**Last session:** 2026-04-08T11:45:00.000Z

**Stopped at:** Completed `12-02-PLAN.md` (fertility settings, opt-in, ARB)

**Resume file:** .planning/phases/12-optional-fertility-window-estimator/12-03-PLAN.md

**Next:** Execute `12-03-PLAN.md` or `/gsd-execute-phase 12` continuation

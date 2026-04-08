# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-07)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Milestone v2.0** — i18n, **German** secondary locale, **optional fertility window** (opt-in, prompts for missing assumptions).

## Current Position

**Milestone:** v2.0 — i18n, German locale, optional fertility window.

**Phase:** **12** — Optional fertility window (**UAT checkpoint** on plan `12-04`).

**Plan:** `12-04-PLAN.md` — **Tasks 1–2 complete**; **Task 3 (`checkpoint:human-verify`) not approved** (see `12-04-SUMMARY.md`).

**Status:** Phase **12** plans **01–03** complete; plan **04** code landed; **FERT-03 / FERT-04** for the home/disable path remain **pending human sign-off** per Task 3. Phase **11** complete (3/3 plans + verification).

Last activity: 2026-04-08 — **`12-04` Tasks 1–2**: home fertile-window card + suggestion card + `tab_shell` `onFertilityToggled` to calendar and home VMs (`e9bf84c`, `c155b9e`).

**Progress (v2.0):** Phase 12 — **awaiting `12-04` Task 3** before treating plan 04 / phase 12 as closed (see `ROADMAP.md`).

## Performance Metrics

*Reset when v2.0 execution starts; track per-phase durations in phase SUMMARY files.*

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions. v1 decisions and phase notes remain under `.planning/phases/` and `milestones/v1/`.

**2026-04-07 (11-03):** Calendar week start follows material locale only; ARB DE keys must cover all EN message keys (`tool/arb_de_key_parity.dart` + CI).

**2026-04-08 (12-01):** Fertile window uses cycle-day ovulation placement `(cycleLength − luteal)` from CD1; domain `formatEnsembleExplanation` uses `EnsembleMilestone` + English helper (no `milestoneMessage`).

**2026-04-08 (12-02):** Fertility opt-in uses bottom-sheet disclaimer then setup form; `SharedPreferences` stores all prefs when disabled; full fertility strings in EN/DE ARB for parallel Plans 03–04.

**2026-04-08 (12-03):** Calendar shows fertile days with a teal **diamond** (not color-only vs period circle / prediction hatch); legend adds fertility row when opt-in on; `CalendarViewModel.updateFertilityEnabled` persists for Plan 04 wiring.

**2026-04-08 (12-04):** Home card shows average-cycle explanation only when `computedAverageCycleLength` is non-null; `hasEnoughDataForFertility` uses ≥2 `predictionCycleInputsFromStored` intervals; settings fertility toggle fans out to **both** VMs via `tab_shell`.

### Pending Todos

- **`12-04` Task 3** — Human verification of full fertility flow (steps in `12-04-PLAN.md` / `12-04-SUMMARY.md`); reply `approved` or file issues.
- After UAT: mark **FERT-03** / **FERT-04** in `REQUIREMENTS.md` if satisfied; then treat phase **12** plan **04** as fully complete.
- Phase 10 plans remain available if i18n foundation still needs execution on other branches
- **Remove period projection opacity fade** — no per-cycle opacity decay; tier hatch/spacing already encodes confidence; details view conveys uncertainty (area: ui)
- Optional: domain research pass if product/legal copy for **FERT-*** needs tightening before implementation

### Roadmap Evolution

- **2026-04-07:** v2.0 opened — engineering phases **10–12** (i18n foundation → German + language settings → fertility window module).
- Phase 13 added: PDF export of period statistics and details (user selectable if all or none). Goal is to have a PDF ready for a physician or gynecologist.
- Phase 14 added: remove deprecated FAB. clicking on a day of the calendar opens the same widget as the FAB and is clearer in the intent than the FAB

### Blockers/Concerns

None technical; **product sign-off** waits on **`12-04` Task 3** UAT.

## Session Continuity

**Last session:** 2026-04-08T12:00:00.000Z

**Stopped at:** **`12-04-PLAN.md` Task 3 — `checkpoint:human-verify` (blocking)**

**Resume file:** `.planning/phases/12-optional-fertility-window-estimator/12-04-PLAN.md` (Task 3)

**Next:** User runs manual checks from `12-04-SUMMARY.md` → `approved` or issues → then optional `requirements mark-complete` for FERT-03/FERT-04 and phase closure.

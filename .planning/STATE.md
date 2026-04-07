# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-07)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Milestone v2.0** — i18n, **German** secondary locale, **optional fertility window** (opt-in, prompts for missing assumptions).

## Current Position

**Milestone:** v2.0 — i18n, German locale, optional fertility window.

**Phase:** **11** — German locale + language settings.

**Plan:** **11-03** complete — see `11-03-SUMMARY.md`.

**Status:** Phase **11** plans **11-01**–**11-03** executed. **I18N-04** and **I18N-05** marked complete in `REQUIREMENTS.md`.

Last activity: 2026-04-07 — executed **11-03-PLAN** (gsd-executor).

**Progress (v2.0):** Phase 11: **3/3** plans complete (see `ROADMAP.md`).

## Performance Metrics

*Reset when v2.0 execution starts; track per-phase durations in phase SUMMARY files.*

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions. v1 decisions and phase notes remain under `.planning/phases/` and `milestones/v1/`.

**2026-04-07 (11-03):** Calendar week start follows material locale only; ARB DE keys must cover all EN message keys (`tool/arb_de_key_parity.dart` + CI).

### Pending Todos

- Phase **12** (fertility window) per `ROADMAP.md`
- Phase 10 plans remain available if i18n foundation still needs execution on other branches
- Optional: domain research pass if product/legal copy for **FERT-*** needs tightening before implementation

### Roadmap Evolution

- **2026-04-07:** v2.0 opened — engineering phases **10–12** (i18n foundation → German + language settings → fertility window module).
- Phase 13 added: PDF export of period statistics and details (user selectable if all or none). Goal is to have a PDF ready for a physician or gynecologist.

### Blockers/Concerns

None at milestone definition time.

## Session Continuity

**Last session:** 2026-04-07T23:59:00.000Z

**Stopped at:** Completed 11-03-PLAN.md

**Resume file:** `.planning/phases/12-*` or `/gsd-execute-phase 12` when ready

**Next:** Begin **phase 12** (fertility window) or execute phase 10 plans if still needed on branch

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-07)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** **Milestone v2.0** — i18n, **German** secondary locale, **optional fertility window** (opt-in, prompts for missing assumptions).

## Current Position

**Milestone:** v2.0 — i18n, German locale, optional fertility window.

**Phase:** **12** — Optional fertility window (next).

**Plan:** Run `/gsd-plan-phase 12` or `/gsd-execute-phase 12` when plans exist.

**Status:** Phase **11** complete (3/3 plans + verification); automated checks green; optional human checks in `11-VERIFICATION.md`.

Last activity: 2026-04-07 — phase **11** execution complete; backup timestamps localized (`fix(i18n)`).

**Progress (v2.0):** Phase 11 **complete**; next milestone engineering phase is **12** (see `ROADMAP.md`).

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

**Stopped at:** Phase 11 closed; `11-VERIFICATION.md` status **human_needed** (native ARB review + device language UX).

**Resume file:** `.planning/phases/12-*` when created

**Next:** `/gsd-plan-phase 12` then `/gsd-execute-phase 12`, or finish phase 10 on branches that still need it

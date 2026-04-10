# Period Tracker (ptrack)

## Current Milestone: v2.0 — i18n, German, optional fertility window

**Goal:** Ship first-class internationalization with **German (de)** as the secondary locale, and an **opt-in** fertility-window estimate that prompts for missing cycle assumptions—without contradicting local-first, offline, or non-medical positioning.

**Target features:**

- Flutter **i18n** (template locale **en**, generated l10n, locale-aware dates/numbers/plurals).
- **German** as the first additional locale for agreed user-facing scope (shell, onboarding, logging, calendar/home, settings, export/import flows, lock, prediction copy).
- **Language choice** in settings (explicit selection and/or follow device, per implementation plan).
- **Optional fertility window** module: user enables in settings; if typical cycle / luteal assumptions are unknown, **prompt to supply or confirm defaults**; show estimated window on calendar and/or home with **plain-language disclaimers** (not medical, not contraception guidance); fully disable-able.

## What This Is

A FOSS, privacy-first, **local-first** menstrual cycle tracker for mobile. **v1 (Phase 1 MVP)** shipped as a daily-use app that works fully **offline**, requires **no account**, supports **period and symptom logging**, a **calendar** with clear actual vs predicted days, a **home** summary, **rules-based explainable predictions** (including multi-method ensemble display), **full export/import**, and optional **local lock**—aligned with `period_tracker_prds/PRD_Phase_1_MVP.md`. **v2.0** adds localization and an optional fertility awareness layer that remains estimate-only and user-controlled.

## Core Value

A user can trust the app with sensitive health data because it runs **without accounts**, **without required network access**, and offers **verifiable data ownership** through documented export/import—while still feeling like a polished everyday tracker, not a prototype.

## Requirements

### Validated

- [x] **v1 Phase 1 MVP** (closed 2026-04-07): onboarding, logging, calendar, home, prediction (deterministic + ensemble UI), export/import, optional lock — see `.planning/milestones/v1/REQUIREMENTS.md`

### Active (v2.0)

- [ ] **I18n + German** — See `.planning/REQUIREMENTS.md` (I18N-*)
- [ ] **Optional fertility window estimator** — See `.planning/REQUIREMENTS.md` (FERT-*)

### Out of Scope

- **Cloud backup, multi-device sync, accounts** — Product Phase 3 PRD; excluded from v1–v2.0 planning here
- **ML / opaque “black box” prediction** — Product Phase 4 PRD; v2.0 keeps fertility math **explainable** and on-device
- **Medical diagnosis, ovulation confirmation hardware, fertility treatment workflows, partner/clinician flows** — not in scope; fertility feature is **informational estimate only**
- **Contraception efficacy or “safe days” claims** — explicit non-goal; copy must stay aligned with **PRED-04**-style framing

## Context

- **Source of truth for product scope:** `period_tracker_prds/` plus active `.planning/REQUIREMENTS.md` for v2.0.
- **Repository:** Flutter monorepo (`apps/ptrack`, `packages/ptrack_domain`, `packages/ptrack_data`), FVM-pinned SDK, Melos workspace.
- **Users:** Primary — privacy-conscious people wanting straightforward cycle tracking without commercial cloud dependency. Secondary — contributors who care about open formats and inspectable behavior. **v2.0** adds **German-speaking** users as an explicit audience for secondary locale quality.

## Constraints

- **Tech stack:** **Flutter** for mobile, toolchain pinned with **FVM**; prefer **`gen-l10n`** / official Flutter i18n patterns unless a documented exception is recorded in phase plans.
- **Quality:** **TDD** where feasible; new domain logic for fertility estimates needs **unit tests** and clear documentation of formulas/assumptions.
- **Privacy / network:** No new mandatory network dependencies; strings and logic stay on-device.
- **Legal/ethical framing:** Fertility window is **optional**, **non-authoritative**, and must not read as medical or contraception advice; align with existing prediction disclaimer posture.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **Flutter + FVM** | Cross-platform mobile with a single codebase; FVM pins SDK for reproducible builds and CI. | **Delivered** (v1) |
| **TDD** | Deterministic prediction, safe migrations, and no silent data loss—tests as guardrail. | **Delivered** (v1) |
| **v1 scope = PRD Phase 1 MVP** | Narrow MVP so storage, dates, prediction, and export semantics stay correct before sync/ML. | **Shipped** 2026-04-07 |
| **Requirements trace PRD acceptance tests** | Phase 1 completion criteria map to verifiable engineering work. | **Complete** for v1 (see archived REQUIREMENTS) |
| **v2.0: gen-l10n + ARB workflow** | Maintainable translations, CI-friendly generation, aligns with Flutter defaults. | **— Pending** (phase 10) |
| **v2.0: fertility opt-in + prompts** | Reduces accidental medical framing; honors “prompt if not provided” product ask. | **— Pending** (phase 12) |

---
*Last updated: 2026-04-07 — `/gsd-new-milestone` v2.0 (i18n, de, optional fertility window).*

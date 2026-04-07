# Period Tracker (ptrack)

## What This Is

A FOSS, privacy-first, **local-first** menstrual cycle tracker for mobile. **v1 (Phase 1 MVP)** shipped as a daily-use app that works fully **offline**, requires **no account**, supports **period and symptom logging**, a **calendar** with clear actual vs predicted days, a **home** summary, **rules-based explainable predictions** (including multi-method ensemble display), **full export/import**, and optional **local lock**—aligned with `period_tracker_prds/PRD_Phase_1_MVP.md`. Later product phases (PRD Phase 2–4) cover usability/trust depth, optional secure sync, and advanced on-device prediction; **v2 roadmap is not yet opened** in `.planning/ROADMAP.md`.

## Core Value

A user can trust the app with sensitive health data because it runs **without accounts**, **without required network access**, and offers **verifiable data ownership** through documented export/import—while still feeling like a polished everyday tracker, not a prototype.

## Requirements

### Validated

- [x] **v1 Phase 1 MVP** (closed 2026-04-07): onboarding, logging, calendar, home, prediction (deterministic + ensemble UI), export/import, optional lock — see `.planning/milestones/v1/REQUIREMENTS.md`

### Active

- [ ] **v2+**: To be defined from `PRD_Phase_2_Usability_and_Trust.md` and follow-on PRDs when the next milestone is planned

### Out of Scope

- **Cloud backup, multi-device sync, accounts** — Product Phase 3 PRD; excluded from v1
- **ML / opaque “black box” prediction** — Product Phase 4 PRD; v1 stays explainable on-device rules
- **Medical claims, fertility-treatment mode, partner/clinician flows, wearables, social** — explicit v1 non-goals per PRD

## Context

- **Source of truth for product scope:** `period_tracker_prds/` (README plus Phase 1–4 PRDs). **v1** matched PRD Phase 1 MVP.
- **Repository:** Flutter monorepo (`apps/ptrack`, `packages/ptrack_domain`, `packages/ptrack_data`), FVM-pinned SDK, Melos workspace.
- **Users:** Primary — privacy-conscious people wanting straightforward cycle tracking without commercial cloud dependency. Secondary — contributors who care about open formats and inspectable behavior.

## Constraints

- **Tech stack:** **Flutter** for mobile, toolchain pinned with **FVM**.
- **Quality:** **Test-Driven Development** where feasible; migrations and prediction paths covered by automated tests.
- **Privacy / network:** Core flows must not depend on connectivity; avoid default telemetry/ads (see PRD §7.3).
- **Legal/ethical framing:** No contraception reliability or medical-authority claims; predictions labeled as estimates.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **Flutter + FVM** | Cross-platform mobile with a single codebase; FVM pins SDK for reproducible builds and CI. | **Delivered** (v1) |
| **TDD** | Deterministic prediction, safe migrations, and no silent data loss—tests as guardrail. | **Delivered** (v1) |
| **v1 scope = PRD Phase 1 MVP** | Narrow MVP so storage, dates, prediction, and export semantics stay correct before sync/ML. | **Shipped** 2026-04-07 |
| **Requirements trace PRD acceptance tests** | Phase 1 completion criteria map to verifiable engineering work. | **Complete** for v1 (see archived REQUIREMENTS) |

---
*Last updated: 2026-04-07 — v1 milestone archived; PROJECT evolved for post-v1 planning.*

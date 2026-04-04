# Period Tracker (ptrack)

## What This Is

A FOSS, privacy-first, **local-first** menstrual cycle tracker for mobile. Phase 1 delivers a daily-use app that works fully **offline**, requires **no account**, supports **period and symptom logging**, a **calendar** with clear actual vs predicted days, a **home** summary, **rules-based explainable predictions**, **full export/import**, and optional **local lock**—aligned with `period_tracker_prds/PRD_Phase_1_MVP.md`. Later phases (documented separately) add usability/trust depth, optional secure sync, and advanced on-device prediction.

## Core Value

A user can trust the app with sensitive health data because it runs **without accounts**, **without required network access**, and offers **verifiable data ownership** through documented export/import—while still feeling like a polished everyday tracker, not a prototype.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Phase 1 MVP: onboarding, logging, calendar, home, prediction v1, export/import, optional lock
- [ ] Engineering: Flutter app managed with **FVM**; features delivered with **TDD** (tests first where practical)
- [ ] Non-functional: performance, reliability (migrations), privacy-by-default (no analytics/ads SDKs), accessibility/clarity per Phase 1 PRD

### Out of Scope

- **Cloud backup, multi-device sync, accounts** — Phase 3 PRD; would violate Phase 1 local-first promise if shipped early
- **ML / “smart” opaque prediction** — Phase 4; Phase 1 requires deterministic, explainable rules only
- **Medical claims, fertility-treatment mode, partner/clinician flows, wearables, social** — explicit Phase 1 non-goals per PRD

## Context

- **Source of truth for product scope:** `period_tracker_prds/` (README plus Phase 1–4 PRDs). Phase 1 MVP is the initial build target.
- **Existing repo state:** PRDs and exploratory `.planning/analysis/` from codebase mapping; **no Flutter app scaffold yet**.
- **Users:** Primary — privacy-conscious people wanting straightforward cycle tracking without commercial cloud dependency. Secondary — contributors who care about open formats and inspectable behavior.

## Constraints

- **Tech stack:** **Flutter** for mobile, toolchain pinned with **FVM** (consistent dev/CI Flutter SDK).
- **Quality:** **Test-Driven Development** — new behavior specified by tests where feasible; migrations and prediction rules especially require automated tests per PRD reliability themes.
- **Privacy / network:** Phase 1 must not depend on connectivity for core flows; dependency choices must avoid default telemetry/ads (see PRD §7.3).
- **Legal/ethical framing:** No contraception reliability or medical-authority claims; predictions labeled as estimates.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **Flutter + FVM** | Cross-platform mobile with a single codebase; FVM pins SDK for reproducible builds and CI. | — Pending |
| **TDD** | PRD stresses deterministic prediction, safe migrations, and no silent data loss—tests are the primary guardrail. | — Pending |
| **Phase 1 scope = PRD Phase 1 only** | Narrow MVP so storage, dates, prediction, and export semantics stay correct before sync/ML. | — Pending |
| **Requirements trace PRD acceptance tests** | Phase 1 completion criteria in PRD §10 map to verifiable engineering work. | — Pending |

---
*Last updated: 2026-04-04 after initialization (gsd-new-project; input: period_tracker_prds/; stack: Flutter FVM; TDD)*

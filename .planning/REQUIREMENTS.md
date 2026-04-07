# Requirements: Period Tracker (ptrack)

**Defined:** 2026-04-04  
**Core Value:** Trustworthy local-first cycle tracking without accounts or required network access, with verifiable data ownership via export/import.

## Shipped — v1.0 (frozen)

All v1 acceptance criteria are archived at **[`.planning/milestones/v1/REQUIREMENTS.md`](milestones/v1/REQUIREMENTS.md)**. Do not edit the archive.

## Milestone v2.0 (active)

Scope: **internationalization**, **German (de)** as secondary language, **optional fertility window** (opt-in; prompt when assumptions missing). Aligned with `PROJECT.md` Current Milestone.

### Internationalization (i18n)

- [ ] **I18N-01**: App uses Flutter `gen_l10n` (or equivalent documented toolchain) with English template ARB; generated localizations are wired through `MaterialApp` (and relevant delegates); user-visible strings in v2.0-agreed surfaces are sourced from ARB, not hard-coded English literals
- [x] **I18N-02**: User can choose app display language from settings (including **English** and **German**, and an option to follow the device locale where technically supported)
- [x] **I18N-03**: **German** locale provides complete translations for the same string catalog as English for the agreed in-scope screens and flows (shell, onboarding, logging, calendar, home, settings, export/import, lock, prediction/fertility-related copy surfaced in this milestone)
- [ ] **I18N-04**: Dates, numbers, and plural forms in user-visible UI respect the active locale conventions
- [ ] **I18N-05**: Repository guardrail prevents silent English fallbacks for **de** in production paths (e.g. CI test, arb check, or documented automation—exact mechanism chosen in phase plan)

### Optional fertility window (FERT)

- [ ] **FERT-01**: Fertility window feature is **opt-in**; enabling it requires an explicit user action and shows **plain-language limitations** (educational estimate only; not medical advice; not contraception guidance)
- [ ] **FERT-02**: When the feature is enabled and required assumptions are not already known, the app **prompts** the user to supply or confirm values needed for the estimate (e.g. typical cycle length, luteal-phase default—exact fields in phase plan)
- [ ] **FERT-03**: User sees an estimated fertile window on the **calendar** and/or **home** in a form that meets accessibility expectations consistent with **NFR-06** (not color-only)
- [ ] **FERT-04**: User can **disable** the feature; when disabled, fertility visuals and prompts are not shown; period and prediction data remain intact
- [ ] **FERT-05**: Fertile-window math runs **on-device**, is **deterministic** and **documented** (code comments and/or `docs/`), and is covered by **automated tests** for representative scenarios

## Deferred (after v2.0)

Tracked ideas—not committed in this milestone:

- Additional locales beyond **de**
- `PRD_Phase_2_Usability_and_Trust.md` initiatives not covered above
- Secure sync / advanced prediction PRDs

## Out of scope (v2.0)

| Item | Reason |
|------|--------|
| Ovulation lab/hardware integration | Scope and validation complexity |
| Partner/clinician modes | Explicit prior non-goal |
| Cloud-backed translation updates | Local-first; strings ship with app |
| Opaque ML for ovulation | Must stay explainable per **FERT-05** |

## Traceability

| Requirement | Phase | Status |
|---------------|-------|--------|
| I18N-01 | Phase 10 | Pending |
| I18N-02 | Phase 11 | Complete |
| I18N-03 | Phase 11 | Complete |
| I18N-04 | Phase 11 | Pending |
| I18N-05 | Phase 11 | Pending |
| FERT-01 | Phase 12 | Pending |
| FERT-02 | Phase 12 | Pending |
| FERT-03 | Phase 12 | Pending |
| FERT-04 | Phase 12 | Pending |
| FERT-05 | Phase 12 | Pending |

**Coverage:**

- v2.0 requirements: **10** total  
- Mapped to phases: **10**  
- Unmapped: **0** ✓  

---
*Last updated: 2026-04-07 — I18N-02 complete (`11-02-PLAN`).*  

# Roadmap: Period Tracker (ptrack)

## Shipped milestones

### v1 — Phase 1 MVP (closed 2026-04-07)

Local-first menstrual cycle tracker (Flutter, FVM, TDD): engineering guardrails, persistence, onboarding, logging, calendar/home, export/import, optional lock, release-quality/offline/inclusive copy, and ensemble next-period prediction with agreement-based calendar tiers. No accounts; no required network.

**Frozen planning artifacts:**

- [Milestone summary](milestones/v1/MILESTONE.md)
- [Roadmap at ship](milestones/v1/ROADMAP.md)
- [Requirements at ship](milestones/v1/REQUIREMENTS.md)

Phase implementation detail remains under `.planning/phases/` for history.

---

## Active roadmap: v2.0

**Milestone:** v2.0 — **i18n**, **German**, **optional fertility window**  
**Engineering phases:** **10 → 12** (continues after v1 phase 9). See [`.planning/MILESTONES.md`](MILESTONES.md).

### Overview

| Phase | Name | Requirements | Goal (one line) |
|-------|------|--------------|-----------------|
| **10** | i18n foundation | I18N-01 | gen_l10n, English ARB, migrate strings, wire delegates |
| **11** | German + language settings | I18N-02 — I18N-05 | de translations, settings, locale formatting, CI guard |
| **12** | Optional fertility window | FERT-01 — FERT-05 | Opt-in, prompts, on-device estimate, UI, tests, docs |

### Phase 10: Internationalization foundation

**Depends on:** v1 complete  

**Requirements:** I18N-01  

**Success criteria (observable):**

1. `flutter gen-l10n` (or chosen equivalent) runs clean in CI / documented dev workflow; l10n outputs are generated and committed or built deterministically per repo policy.
2. `MaterialApp` (and any required Cupertino/localizations delegates) resolves the **English** catalog from ARB for the migrated surfaces.
3. A defined subset of screens (listed in phase plan) shows **no user-visible hard-coded English** for strings in scope—those strings come from ARB.
4. `melos`/test/analyze still pass after migration (no regression in v1 behavior aside from string sourcing).

### Phase 11: German locale + language settings

**Depends on:** Phase 10  

**Requirements:** I18N-02, I18N-03, I18N-04, I18N-05  

**Success criteria (observable):**

1. User can open **Settings**, choose **language** (en, de, follow device as specified in plan), and the choice persists across restarts.
2. With **German** selected, in-scope flows display **German** strings with parity to English (no missing-key crashes in covered paths).
3. Sample dates/numbers/plurals in UI reflect **German** conventions where applicable (phase plan lists concrete widgets or formats).
4. Automated or scripted check fails CI if **de** ARB is missing keys required for the in-scope catalog (**I18N-05**).

**Plans:**

1/3 plans executed
- [x] `11-01-PLAN.md` — German `app_de.arb` key parity, gen-l10n, `de` smoke tests (**I18N-03**)
- [ ] `11-02-PLAN.md` — Settings language choice (follow device / en / de), persistence, `MaterialApp` locale, restart UX (**I18N-02**)
- [ ] `11-03-PLAN.md` — Locale-aware dates/numbers/plurals; ARB parity CI script + workflow (**I18N-04**, **I18N-05**)

### Phase 12: Optional fertility window estimator

**Depends on:** Phase 11  

**Requirements:** FERT-01, FERT-02, FERT-03, FERT-04, FERT-05  

**Success criteria (observable):**

1. **Off by default:** fresh or upgraded user does not see fertility UI until they opt in; first opt-in shows **limitations** copy (**FERT-01**).
2. If enabled and assumptions missing, a **prompt** collects or confirms required inputs before showing a window (**FERT-02**).
3. Calendar and/or home shows the estimated window with **non-color-only** distinction vs other day states (**FERT-03**).
4. Disabling removes fertility visuals and stops prompts without corrupting period/export data (**FERT-04**).
5. **Unit tests** document expected outputs for fixed inputs; **docs or comments** state the formula/assumptions (**FERT-05**).

## Progress (v2.0)

| Phase | Plans | Status |
|-------|-------|--------|
| 10 — i18n foundation | 2/? | Planned (`10-01`, `10-02`) |
| 11 — German + language settings | 1/3 | In progress (`11-01` done) |
| 12 — Fertility window | 0/? | Not started |

### Phase 13: PDF export of period statistics and details (user selectable if all or none). Goal is to have a PDF ready for a physician or gynecologist.

**Goal:** [To be planned]
**Depends on:** Phase 12
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd:plan-phase 13 to break down)

---
*Roadmap updated: 2026-04-07 — v2.0 phases 10–12; requirements traceability in `REQUIREMENTS.md`.*  

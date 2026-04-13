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
| **18** | Diary table migration | DIARY-01 — DIARY-09 | Decouple diary from symptom; standalone table, data migration |

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

3/3 plans complete
- [x] `11-01-PLAN.md` — German `app_de.arb` key parity, gen-l10n, `de` smoke tests (**I18N-03**)
- [x] `11-02-PLAN.md` — Settings language choice (follow device / en / de), persistence, `MaterialApp` locale, restart UX (**I18N-02**)
- [x] `11-03-PLAN.md` — Locale-aware dates/numbers/plurals; ARB parity CI script + workflow (**I18N-04**, **I18N-05**)

### Phase 12: Optional fertility window estimator

**Depends on:** Phase 11  

**Requirements:** FERT-01, FERT-02, FERT-03, FERT-04, FERT-05  

**Success criteria (observable):**

1. **Off by default:** fresh or upgraded user does not see fertility UI until they opt in; first opt-in shows **limitations** copy (**FERT-01**).
2. If enabled and assumptions missing, a **prompt** collects or confirms required inputs before showing a window (**FERT-02**).
3. Calendar and/or home shows the estimated window with **non-color-only** distinction vs other day states (**FERT-03**).
4. Disabling removes fertility visuals and stops prompts without corrupting period/export data (**FERT-04**).
5. **Unit tests** document expected outputs for fixed inputs; **docs or comments** state the formula/assumptions (**FERT-05**).

**Plans:** 4/4 plans complete

Plans:
- [x] `12-01-PLAN.md` — TDD fertility window calculation engine + tests (FERT-05) — see `12-01-SUMMARY.md`
- [x] `12-02-PLAN.md` — Fertility settings, opt-in flow, input collection, all ARB strings (FERT-01, FERT-02, FERT-04) — see `12-02-SUMMARY.md`
- [x] `12-03-PLAN.md` — Calendar fertility visuals: teal hatched circle (same pattern as predictions), legend, day detail label (FERT-03) — see `12-03-SUMMARY.md`
- [x] `12-04-PLAN.md` — Home fertility card, suggestion card, tab shell wiring (FERT-03, FERT-04) — see `12-04-SUMMARY.md` — *Task 3 UAT approved 2026-04-08*

## Progress (v2.0)

| Phase | Plans | Status |
|-------|-------|--------|
| 10 — i18n foundation | 2/? | Planned (`10-01`, `10-02`) |
| 11 — German + language settings | 3/3 | Complete — 2026-04-07 |
| 12 — Fertility window | 4/4 | Complete — 2026-04-08 (UAT approved) |
| 13 — PDF export | 2/3 | In progress — `13-03` Tasks 1–2 done; Task 3 human-verify pending (2026-04-08) |
| 15 — Code review remediation | 3/3 | Complete — `15-01`–`15-03` (`15-01-SUMMARY.md` … `15-03-SUMMARY.md`); optional `15-01` Task 3 import smoke UAT |
| 16 — Security audit remediation | 1/8 | In progress — `16-01` complete (Android release signing) |
| 17 — release management (GitHub + Firebase) | 2/2 | Complete — 2026-04-10 (`17-UAT.md`; `17-01-SUMMARY.md`, `17-02-SUMMARY.md`) |
| 18 - Diary table migration | 1/7 | In progress — `18-01` complete (see `18-01-SUMMARY.md`) |

### Phase 13: PDF export of period statistics and details (user selectable if all or none). Goal is to have a PDF ready for a physician or gynecologist.

**Goal:** On-device PDF export of tracked cycle data with user-selectable sections (presets + per-section toggles), locale-aware formatting, scrollable in-app preview, and system share sheet delivery — producing a clinician-readable report for a physician or gynecologist.
**Depends on:** Phase 12
**Requirements:** PDF-01, PDF-02, PDF-03, PDF-04, PDF-05, PDF-06, PDF-07, PDF-08
**Plans:** 3 plans

Plans:
- [x] `13-01-PLAN.md` — TDD section config model, report data model, data collector with stats computation (PDF-01, PDF-02, PDF-04, PDF-05) — see `13-01-SUMMARY.md`
- [x] `13-02-PLAN.md` — PDF document builder with all content sections + EN/DE ARB strings (PDF-03, PDF-04, PDF-05, PDF-08) — see `13-02-SUMMARY.md`
- [ ] `13-03-PLAN.md` — Export UI (presets, toggles, date range), preview, share, entry points + UI ARB strings (PDF-01, PDF-02, PDF-06, PDF-07, PDF-08) — **implemented;** awaiting Task 3 UAT before SUMMARY

### Phase 14: remove deprecated FAB. clicking on a day of the calendar opens the same widget as the FAB and is clearer in the intent than the FAB

**Goal:** Remove the global FAB from the main shell so logging uses **Home Today card** and **calendar day detail** only — same underlying flows (`markDay`, symptom sheet) with clearer, date-scoped affordances.
**Depends on:** Phase 13
**Requirements:** UXFAB-01, UXFAB-02
**Plans:** 1 plan

Plans:
- [ ] `14-01-PLAN.md` — Remove `TabShell` FAB, drop `fabTooltip*` ARBs, migrate `logging_test.dart` off FAB (UXFAB-01, UXFAB-02) — **implemented;** Task 4 (`human-verify`) pending before SUMMARY final / requirements checkboxes

### Phase 15: Address full app code review findings

**Goal:** Resolve documented full-app code review items: harden `.luma` import (validation, duplicate keys, orphan refs), make factory-reset / DB delete failures observable, and batch-load day entries in `watchPeriodsWithDays` to remove N+1 queries. Source: [`docs/CODE_REVIEW.md`](../docs/CODE_REVIEW.md).

**Depends on:** Phase 14

**Success criteria (observable):**

1. Invalid or malicious import payloads fail with typed `LumaImportException` and do not leave partial period/entry data; valid round-trip exports still import.
2. Day entry merge during import keys on `(periodId, dateUtc)`; no ambiguous `getSingleOrNull` on date alone.
3. Factory reset reports or logs when SQLite file deletion fails; tests cover the failure path where feasible.
4. `watchPeriodsWithDays` refresh uses batched day-entry reads; repository tests prove snapshot parity for multi-period fixtures.

**Plans:** 3/3 plans complete

Plans:
- [x] `15-01-PLAN.md` — Import integrity: domain validation, `(periodId, dateUtc)` conflicts, orphan `periodRefId` (see `docs/CODE_REVIEW.md` findings 1–3) — see `15-01-SUMMARY.md`
- [x] `15-02-PLAN.md` — Reset flow: structured DB delete result, `_resetApp` handling, tests (finding 4) — see `15-02-SUMMARY.md`
- [x] `15-03-PLAN.md` — `watchPeriodsWithDays` batch query refactor + regression tests (finding 5) — see `15-03-SUMMARY.md`

### Phase 16: Security audit findings remediation

**Goal:** Remediate all 8 security audit findings — encrypting the database and auto-backups at rest (SQLCipher + backup encryption key), hardening PIN lockout against brute force, configuring proper Android release signing, enforcing export password strength with KDF tuning and AEAD metadata binding, adding import size/complexity guardrails, securing temp-file cleanup in share flows, including backup artifacts in the factory-reset flow — with automated regression tests, CI signing checks, and documented threat model.
**Depends on:** Phase 15
**Requirements:** SEC-F1 through SEC-F8, SEC-CC (from `docs/SECURITY_AUDIT_FINDINGS.md`)
**Plans:** 8 plans

Plans:
- [x] `16-01-PLAN.md` — Android release signing + CI signing guard (SEC-F3) — see `16-01-SUMMARY.md`
- [ ] `16-02-PLAN.md` — PIN lockout, throttling, stronger PIN minimum (SEC-F2)
- [ ] `16-03-PLAN.md` — Import size/complexity limits + reset backup cleanup (SEC-F5, SEC-F7)
- [ ] `16-04-PLAN.md` — Export crypto: password policy, KDF tuning, AEAD metadata binding (SEC-F4, SEC-F8)
- [ ] `16-05-PLAN.md` — Database encryption at rest via SQLCipher (SEC-F1, DB)
- [ ] `16-06-PLAN.md` — Temp file hygiene + pre-share consent dialog (SEC-F6)
- [ ] `16-07-PLAN.md` — Encrypted auto-backups by default (SEC-F1, backups)
- [ ] `16-08-PLAN.md` — Threat model, release checklist, audit findings closure (SEC-CC)

### Phase 17: release management with release bumps, release apks iin github release, and ran apk push to firebase app distribution

**Goal:** Automated release pipeline where a version tag on main triggers signed APK build, draft GitHub Release with CHANGELOG notes, and Firebase App Distribution upload to Beta group — with Environment gate, workflow_dispatch fallback, and all-or-nothing failure semantics.
**Depends on:** Phase 16
**Requirements:** REL-01, REL-02, REL-03, REL-04
**Plans:** 2/2 plans complete

Plans:
- [x] `17-01-PLAN.md` — Version management tooling: CHANGELOG.md + cross-platform bump script (REL-01) — see `17-01-SUMMARY.md`
- [x] `17-02-PLAN.md` — Unified release workflow: build → GitHub Release + Firebase App Distribution (REL-02, REL-03, REL-04) — verified end-to-end (`release.yml`, FAD cross-ref, artifact/notes path fix) — see `17-02-SUMMARY.md`, `17-UAT.md`

### Phase 18: Diary table migration — decouple personal diary from symptom logging

**Goal:** Extract the personal diary/notes from the symptom log into its own standalone table so users can add a diary entry on any day — not only during their period. Requires a careful data migration that moves existing diary entries out of the symptom table into the new diary table without data loss, updates all read/write paths, and keeps export/import backward-compatible.
**Depends on:** Phase 17
**Requirements:** DIARY-01 through DIARY-09 (derived from phase goal)
**Plans:** 2/7 plans executed

Plans:
- [x] `18-01-PLAN.md` — DB schema v5: DiaryEntries/Tags/Join tables, v4→v5 migration (TDD) — see `18-01-SUMMARY.md`
- [x] `18-02-PLAN.md` — Domain models (DiaryEntryData, DiaryTag), DiaryRepository CRUD + streams — see `18-02-SUMMARY.md`
- [ ] `18-03-PLAN.md` — Export/import: .luma format v2 with diary_entries, backward-compat v1 import
- [ ] `18-04-PLAN.md` — Diary form sheet (text + mood + tags), symptom form personalNotes removal
- [ ] `18-05-PLAN.md` — Calendar blue diary dot + legend; Home Today card diary shortcut
- [ ] `18-06-PLAN.md` — Day detail routing hub (4 states), DiaryTagsSettingsScreen
- [ ] `18-07-PLAN.md` — Diary tab screen (paginated list, search, tag filter) + tab shell integration

---
*Roadmap updated: 2026-04-14 — Phase **18** planned (7 plans, 5 waves). Phase **17** complete (2/2 plans; UAT in `17-UAT.md`). Phase **16-01** (Android release signing) noted above. **`13-03`** export UI still awaiting Task 3 human verification.*  

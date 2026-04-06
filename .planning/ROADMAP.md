# Roadmap: Period Tracker (ptrack)

## Overview

Phase 1 delivers a local-first menstrual cycle tracker in Flutter (FVM, TDD): engineering guardrails and persistence first, then explainable prediction wired to data, onboarding and logging, calendar and home surfaces, documented round-trip export/import, optional app lock, and a closing pass for performance, clarity, inclusive copy, and full offline assurance—without accounts or required network access.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation & engineering guardrails** — FVM-pinned Flutter scaffold, CI test gate, dependency policy aligned with privacy NFRs
- [x] **Phase 2: Domain, persistence & prediction v1** — Schema, migrations, deterministic explainable prediction, no silent data loss
- [x] **Phase 3: Onboarding** — Local-first and estimates messaging, fast path to first log, offline-capable (completed 2026-04-05)
- [x] **Phase 4: Core logging** — Period, flow, symptoms, notes, validation, reliable day context and edits
 (completed 2026-04-05)
- [ ] **Phase 5: Calendar, home & cycle surfaces** — Month navigation, actual vs predicted distinction, home summary and quick actions
- [ ] **Phase 6: Export & import** — Documented full export, validated import, deterministic duplicate handling
- [ ] **Phase 7: App protection (lock)** — Optional PIN/biometric lock with honest limitations
- [ ] **Phase 8: Release quality, offline assurance & inclusive copy** — Snappy UX, clear actions, non-gendered non-medical copy, airplane-mode verification

## Phase Details

### Phase 1: Foundation & engineering guardrails

**Goal**: The project is reproducibly buildable and testable with pinned tooling, and dependency choices are demonstrably consistent with a privacy-first, no-telemetry product posture.

**Depends on**: Nothing (first phase)

**Requirements**: NFR-03, NFR-04

**Success Criteria** (what must be TRUE):

1. A fresh checkout builds and runs tests using the FVM-pinned Flutter SDK documented for the repo.
2. Continuous integration (or an equivalent automated gate) runs the test suite on changes and fails the pipeline when tests fail.
3. The app bundle does not include analytics, ad identifiers, or third-party ads/profiling SDKs as shipped for Phase 1.
4. There is a documented, reviewable way to verify dependency choices against the privacy constraints (e.g. policy checklist or automated check referenced in repo docs).

**Plans**: 3 plans

Plans:

- [x] `01-01-PLAN.md` — Melos monorepo, FVM stable pin, `packages/ptrack_domain` + `packages/ptrack_data`, minimal `apps/ptrack` with lints, mocktail, and tests (no Riverpod)
- [x] `01-02-PLAN.md` — GitHub Actions (Ubuntu, PR + main), FVM + Melos CI, Python `tool/ci/verify_pubspec_policy.py`, README CI parity
- [x] `01-03-PLAN.md` — `SECURITY.md` + README link, Dependabot pub entries, final analyze/test/policy verification

### Phase 2: Domain, persistence & prediction v1

**Goal**: Local data and deterministic prediction behavior are correct, test-driven, and survive app upgrades without silent loss—before the full UI stack depends on them.

**Depends on**: Phase 1

**Requirements**: PRED-01, PRED-02, PRED-03, PRED-04, NFR-02

**Success Criteria** (what must be TRUE):

1. Given sufficient period history, the app derives a next-period estimate using the documented deterministic rules (averages, basic outlier handling), not opaque ML.
2. When history is insufficient or highly variable, the user sees uncertainty rather than false precision in prediction-related outputs.
3. The user can read a plain-language explanation of how the current prediction was derived from their history.
4. All prediction-related copy and UI avoid framing results as contraception guidance or medically authoritative.
5. After simulated or real app upgrades that include schema migrations, existing user data round-trips without silent loss; migration and critical persistence paths are covered by automated tests.

**Plans**: 4 plans

Plans:

- [x] `02-01-PLAN.md` — Domain period types, validation, cycle-length definition, prediction/explanation value types (`ptrack_domain`) — complete 2026-04-04
- [x] `02-02-PLAN.md` — Drift SQLite schema v1, mappers, transactional migrations, fixture migration tests, newer-schema guard (`ptrack_data`) — complete 2026-04-04
- [x] `02-03-PLAN.md` — TDD deterministic `PredictionEngine` (median, exclusions, uncertainty tiers, explanation steps) — complete 2026-04-04
- [x] `02-04-PLAN.md` — Repository + prediction coordinator, PRED-04 copy helpers, integration tests, widget test for readable explanation — complete 2026-04-04

### Phase 3: Onboarding

**Goal**: A new user understands local storage and non-medical estimates, reaches first logging quickly, and can complete or skip onboarding fully offline.

**Depends on**: Phase 2

**Requirements**: ONBD-01, ONBD-02, ONBD-03, ONBD-04

**Success Criteria** (what must be TRUE):

1. During onboarding, the user sees that data stays on the device and no account is required.
2. The user sees that predictions are estimates from entered history, not medical advice.
3. The user can reach the first logging action in under one minute along the intended minimal path.
4. The user can skip non-essential education and continue; the entire onboarding flow works with network disabled.

**Plans**: 3 plans

Plans:

- [x] `03-01-PLAN.md` — Onboarding wizard (privacy + estimates + quick-start screens), first-log screen, app-launch routing with state persistence — complete 2026-04-05
- [x] `03-02-PLAN.md` — Settings About replay screen, comprehensive widget tests, human-verify checkpoint — complete 2026-04-05 (Task 2 human-verify: approved)
- [x] `03-03-PLAN.md` — Gap closure: reconcile `03-UAT.md` with shipped onboarding/first-log UX (post-`37471f7`), CI verify — complete 2026-04-05

### Phase 4: Core logging

**Goal**: Users can record and edit period and symptom data with validation that prevents impossible ranges and preserves adjacent cycle integrity.

**Depends on**: Phase 3

**Requirements**: LOG-01, LOG-02, LOG-03, LOG-04, LOG-05, LOG-06

**Success Criteria** (what must be TRUE):

1. The user can mark a period start (today or past), add or change the end date later, and log flow intensity for days or spans without being forced to enter symptoms.
2. The user can add or edit notes, pain score, and mood on relevant days.
3. Editing a past period does not corrupt or scramble data for neighboring cycles in the timeline.
4. Impossible or inconsistent date ranges are prevented or clearly flagged before they are saved.
5. Entries save reliably and appear on the correct calendar day, including when entered retroactively.

**Plans**: 3 plans

Plans:

- [x] `04-01-PLAN.md` — Domain enums (flow/pain/mood), DayEntries Drift table, schema v1→v2 migration with FK enforcement, mappers — complete 2026-04-05
- [x] `04-02-PLAN.md` — Repository extensions (watch, delete, day entry CRUD), home screen with period history list — complete 2026-04-05
- [x] `04-03-PLAN.md` — Logging bottom sheet (create + edit), delete with confirmation, hybrid validation, widget tests, human-verify — complete 2026-04-05 (Task 3: pass)

### Phase 5: Calendar, home & cycle surfaces

**Goal**: Users navigate time, distinguish logged from predicted days accessibly, drill into days from the calendar, and see an honest home summary with a quick path back to logging.

**Depends on**: Phase 4

**Requirements**: CAL-01, CAL-02, CAL-03, CAL-04, CAL-05, HOME-01, HOME-02, HOME-03, HOME-04, NFR-06

**Success Criteria** (what must be TRUE):

1. The user can view a month-based calendar, move across months smoothly, and the view stays responsive with multi-year local history on supported devices.
2. Logged period days and predicted future days are visually distinguishable without relying on color alone; after edits to underlying data, prediction display on the calendar updates accordingly.
3. Tapping a day opens that day’s detail so the user can view or edit entries.
4. The home screen shows cycle position and next expected period status (or a clear insufficient-data state), what was logged today at a glance, and a visible quick action to log or edit without deep navigation—without unsupported “cycle health” scores or overconfident precision.

**Plans**: 3 complete; `05-04` Task 1 done — Task 2 (human verify) pending

Plans:

- [x] `05-01-PLAN.md` — Tab shell (Home + Calendar tabs, drawer, FAB) and refactored home summary with cycle position, today card, prediction range — complete 2026-04-06
- [x] `05-02-PLAN.md` — Calendar day-data model (PeriodDayState, CalendarDayData, buildCalendarDayDataMap) and custom painters (solid band, hatched circle, dot, today ring) — complete 2026-04-06
- [x] `05-03-PLAN.md` — Calendar screen with table_calendar integration, reactive stream, month navigation, "Today" button, widget tests — complete 2026-04-06
- [ ] `05-04-PLAN.md` — Day detail bottom sheet (read-only view, adjacent-day swipe, edit bridge, predicted day info) and human verification — **Task 1 complete 2026-04-06 (`f6658f1`); Task 2 human verification pending** (do not mark plan complete until user signs off)

### Phase 05.1: UX refactor - day-marking model and MVVM (INSERTED)

**Goal:** Replace explicit start/end period actions with a day-marking toggle model (mark/unmark days, system derives spans) and refactor the presentation layer from ad-hoc StatefulWidget state to MVVM with ChangeNotifier ViewModels — consistent day-tap behavior, future-day gating, simplified symptom form, no open periods.

**Depends on:** Phase 5

**Requirements:** LOG-01, LOG-02, LOG-03, LOG-04, LOG-05, LOG-06, CAL-01, CAL-03, CAL-05, HOME-01, HOME-02, HOME-03, HOME-04

**Plans:** 5 plans; **05.1-05** Task 1 (automation) complete 2026-04-06 (`f14ed5f`); **Task 2 human verification pending** — do not treat phase as closed until UAT passes (see `05.1-05-SUMMARY.md`).

Plans:
- [x] `05.1-01-PLAN.md` — TDD: Day-marking domain pure functions (computeMarkDay, computeUnmarkDay — 6 span operations) — complete 2026-04-06 (`83703d0` test, `5d88893` feat; see `05.1-01-SUMMARY.md`)
- [x] `05.1-02-PLAN.md` — Repository markDay/unmarkDay + DB migration v2→v3 (close open periods) — complete 2026-04-06 (`0698c49` migration, `c0a8b4f` repository; see `05.1-02-SUMMARY.md`)
- [x] `05.1-03-PLAN.md` — CalendarViewModel + HomeViewModel + view refactor to MVVM (ListenableBuilder) — complete 2026-04-06 (`260727a` ViewModels + tests, `950520a` shell/screens; see `05.1-03-SUMMARY.md`)
- [x] `05.1-04-PLAN.md` — SymptomFormSheet + DayDetailSheet rewrite (new action model, future-day gating) — complete 2026-04-06 (`7f84edb` symptom form, `35abfde` day detail + routing; see `05.1-04-SUMMARY.md`)
- [ ] `05.1-05-PLAN.md` — Dead code removal + first_log + human verification — **Task 1 complete 2026-04-06 (`f14ed5f`); Task 2 human verification pending** (see `05.1-05-SUMMARY.md`)

### Phase 6: Export & import

**Goal**: Users own their data through a documented full export and a safe import path with readable errors and explained duplicate behavior.

**Depends on**: Phase 5.1

**Requirements**: XPRT-01, XPRT-02, XPRT-03, IMPT-01, IMPT-02, IMPT-03

**Success Criteria** (what must be TRUE):

1. The user can start a full local data export without an account; the file includes periods, symptoms, notes, and restoration metadata with schema/version markers, and the format is documented in the repository.
2. The user can import from a prior valid export file and see data restored according to the documented semantics.
3. Invalid or corrupted import files fail with readable validation errors and do not silently corrupt existing data.
4. Duplicate-handling during import is deterministic and explained in product copy.

**Plans**: 4 plans

Plans:

- [x] `06-01-PLAN.md` — Export schema types, AES-256-GCM crypto, ExportService, and format documentation (XPRT-02, XPRT-03) — complete 2026-04-06 (`87cb5a2`, `a365889`; see `06-01-SUMMARY.md`)
- [x] `06-02-PLAN.md` — ImportService validation, ImportPreview duplicate detection, BackupService, atomic import apply (IMPT-02) — complete 2026-04-06 (`29c6883`, `02b59ef`; see `06-02-SUMMARY.md`)
- [x] `06-03-PLAN.md` — ExportViewModel, ExportWizardScreen, DataSettingsScreen, drawer integration (XPRT-01) — complete 2026-04-06 (`eb1f956`, `b72d902`; see `06-03-SUMMARY.md`)
- [ ] `06-04-PLAN.md` — ImportViewModel, ImportScreen, DataSettingsScreen wiring, human verification (IMPT-01, IMPT-03)

### Phase 7: App protection (lock)

**Goal**: Users who want extra privacy can opt into PIN or biometric lock without being forced, with reliable resume behavior and honest limitations.

**Depends on**: Phase 6

**Requirements**: LOCK-01, LOCK-02, LOCK-03

**Success Criteria** (what must be TRUE):

1. From settings, the user can enable an optional PIN or biometric lock (not required on first launch).
2. With lock enabled, returning from background reliably prompts for unlock on supported devices.
3. Product copy does not claim full cryptographic protection; failure modes are described so users are not stranded without a credible recovery narrative where applicable.

**Plans**: TBD

### Phase 8: Release quality, offline assurance & inclusive copy

**Goal**: The Phase 1 feature set feels immediate, understandable, and respectful in language, and works end-to-end without network after install.

**Depends on**: Phase 7

**Requirements**: NFR-01, NFR-05, NFR-07, NFR-08

**Success Criteria** (what must be TRUE):

1. Common screens and primary logging actions feel immediate on mainstream supported devices.
2. Primary actions and labels are understandable without dense tutorial text.
3. Copy across the app avoids unnecessary gendered assumptions and unsupported medical claims (beyond what earlier phases already enforced for prediction).
4. With network disabled after install, the full Phase 1 feature set (onboarding through lock) works without login and without network-required errors on core flows.

**Plans**: TBD

## Progress

**Execution Order:**

Phases execute in numeric order: 2 → 2.1 → 2.2 → 3 → 3.1 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & engineering guardrails | 3/3 | Complete   | 2026-04-04 |
| 2. Domain, persistence & prediction v1 | 4/4 | Complete | 2026-04-04 |
| 3. Onboarding | 3/3 | Complete    | 2026-04-05 |
| 4. Core logging | 3/3 | Complete    | 2026-04-05 |
| 5. Calendar, home & cycle surfaces | 3/4 | In Progress|  |
| 6. Export & import | 1/4 | In Progress|  |
| 7. App protection (lock) | 0/TBD | Not started | - |
| 8. Release quality, offline assurance & inclusive copy | 0/TBD | Not started | - |

---
*Roadmap created: 2026-04-04 — depth: standard; 40/40 v1 requirements mapped.*

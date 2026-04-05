# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-04)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** Phase 4 (Core logging) — next milestone after completed onboarding.

## Current Position

Phase: **4** of 8 (Core logging)

**Current Plan:** 3 — **`04-03-PLAN.md`** blocked at **Task 3** (`checkpoint:human-verify`)

**Total Plans in Phase:** 3

Plan: **2** of **3** automated tasks complete for `04-03` (Tasks 1–2 committed); **Task 3** awaits on-device verification per `04-03-PLAN.md`.

Status: **Phase 4 in progress** — logging bottom sheet, list edit/delete, and widget tests are shipped; **human verification** of the full logging flow is **pending** (see `.planning/phases/04-core-logging/04-03-SUMMARY.md`).

Last activity: 2026-04-05 — **`04-03`** Tasks 1–2 executed; checkpoint documented.

**Progress:** [█████████░] 92%

## Performance Metrics

**Velocity:**

- Total plans completed: 11
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 3 | 3 | — |
| 2 | 4 | 4 | 20 min (02-01); 38 min (02-02); 35 min (02-03); 42 min (02-04) |
| 3 | 3 | 3 | 28 min (03-01); 35 min (03-02 T1); 15 min (03-03) |

**Recent Trend:**

- Last 5 plans: 04-02, 04-01, 03-03, —
- Trend: —

*Updated after each plan completion*

| Phase / plan | Duration | Tasks | Files |
|--------------|----------|-------|-------|
| Phase 3 P01 | 28min | 3 tasks | 8 files |
| Phase 03-onboarding P02 | 35min | 1 tasks | 7 files |
| Phase 03-onboarding P03 (gap_closure) | 15min | 3 tasks | 4 files |
| Phase 04-core-logging P01 | 40min | 2 tasks | 12 files |
| Phase 04-core-logging P02 | 45min | 2 tasks | 7 files |
| Phase 04-core-logging P03 (partial) | — | 2 tasks auto; Task 3 verify pending | 7 files |

## Accumulated Context

### Decisions

Decisions are logged in `PROJECT.md` Key Decisions table.

- Phase 1 (2026-04-04): Dart pub workspace + Melos 7; Flutter 3.41.2 via FVM; CI uses FVM then `melos exec`; pubspec policy script runs with **uv** (`uv run --with pyyaml`), not pip.
- [Phase 2]: Period validation uses PeriodCalendarContext (IANA Location) for duplicate start-day checks; call timezone initializeTimeZones() before fromTimeZoneName.
- [Phase 2]: Completed-cycle length is inclusive local days from period start through the day before next start (see completedCycleBetweenStarts).
- [Phase 02-domain-persistence-prediction-v1]: Prediction thresholds: long gap >45d, long bleed >10d, outlier |L-median|>7, high-variability spread >=12d, six-cycle window.
- [Phase 02]: PeriodRepository returns PeriodWriteOutcome (success/rejected/not found) instead of throwing on validation failures. — Stable error typing for UI and tests; no silent drops.
- [Phase 3]: First-run routing: wizard completion flag plus empty period list gates first-log vs home on cold start.
- [Phase 3]: Onboarding step index persisted on PageView onPageChanged (swipe or button).
- [Phase 03-onboarding]: Onboarding tests use InMemorySharedPreferencesAsync for SharedPreferencesWithCache.
- [Phase 03 gap closure]: UAT gaps resolved in `37471f7` + `03-03` planning.
- [Phase 3 closeout 2026-04-05]: **`03-02` Task 2** human verification approved by user (“pass”); phase milestone finalized.
- [Phase 04-core-logging]: create_v2_fixture uses raw sqlite3 so fvm dart run works without dart:ui
- [Phase 04-core-logging]: day_entry mapper normalizes dateUtc to UTC calendar midnight for Drift DateTime round-trip
- [Phase 04-core-logging]: watchPeriodsWithDays dedupes consecutive identical snapshots when both periods and dayEntries Drift watches fire
- [Phase 04-core-logging]: Home widget tests stub watchPeriodsWithDays with Stream.value([]) for stable HomeScreen empty-state coverage

### Pending Todos

**`04-03` Task 3 (human-verify):** Run `fvm flutter run` in `apps/ptrack` and follow the manual checklist in **`04-03-PLAN.md`** (Task 3). Confirm with “approved” or file issues. Until then, do not mark LOG requirements complete for this plan.

After approval: refresh `04-03-SUMMARY.md` frontmatter (`requirements-completed`, remove checkpoint), advance plan state, and mark requirements in `REQUIREMENTS.md` if applicable.

### Blockers/Concerns

**Checkpoint:** `04-03` Task 3 requires human verification on a real device/emulator (not automatable approval).

## Session Continuity

Last session: 2026-04-05

Stopped at: **`04-03-PLAN.md` Task 3** — human-verify checkpoint (Tasks 1–2 committed; see `04-03-SUMMARY.md`).

Resume: Complete Task 3 manual steps, then update planning docs / requirements; or continue other work with checkpoint noted above.

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-04)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** Phase 5 (Calendar, home & cycle surfaces) — next after completed core logging.

## Current Position

Phase: **5** of 8 (Calendar, home & cycle surfaces)

**Current Plan:** 4

**Total Plans in Phase:** 4

Plan: **05-04** next (`05-01`–`05-03` complete 2026-04-06).

Status: **Phase 5 in progress** — Tab shell + home (`05-01`); calendar day model + painters (`05-02`); `table_calendar` CalendarScreen + tests (`05-03`); HOME-01–HOME-04; CAL-01, CAL-04, CAL-05.

Last activity: 2026-04-06 — Plan `05-03` executed (CalendarScreen, TabShell integration, widget tests).

**Progress:** [█████████░] 88%

## Performance Metrics

**Velocity:**

- Total plans completed: 13
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 3 | 3 | — |
| 2 | 4 | 4 | 20 min (02-01); 38 min (02-02); 35 min (02-03); 42 min (02-04) |
| 3 | 3 | 3 | 28 min (03-01); 35 min (03-02 T1); 15 min (03-03) |
| 4 | 3 | 3 | 40 min (04-01); 45 min (04-02); — (04-03 + UAT) |

**Recent Trend:**

- Last 5 plans: 05-02, 04-03, 04-02, 04-01, 03-03
- Trend: —

*Updated after each plan completion*

| Phase / plan | Duration | Tasks | Files |
|--------------|----------|-------|-------|
| Phase 3 P01 | 28min | 3 tasks | 8 files |
| Phase 03-onboarding P02 | 35min | 1 tasks | 7 files |
| Phase 03-onboarding P03 (gap_closure) | 15min | 3 tasks | 4 files |
| Phase 04-core-logging P01 | 40min | 2 tasks | 12 files |
| Phase 04-core-logging P02 | 45min | 2 tasks | 7 files |
| Phase 04-core-logging P03 | — | 3 tasks (incl. Task 3 pass); UAT gaps `1856a99`, `28f0d25` | 7+ files |
| Phase 05-calendar-home-cycle-surfaces P02 | 30min | 2 tasks | 3 files |
| Phase 05-calendar-home-cycle-surfaces P01 | 25 min | 2 tasks | 8 files |
| Phase 05-calendar-home-cycle-surfaces P03 | 35min | 2 tasks | 5 files |

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
- [Phase 04 closeout 2026-04-05]: **`04-03` Task 3** human verification **pass**; LOG-01–LOG-06 complete; Phase 4 marked complete in roadmap.
- [Phase 04 UAT]: Per-period day logging (`addDayEntryForPeriod`), orphan day handling on span shrink (`PeriodWriteBlockedByOrphanDayEntries`), upsert by calendar day.
- [Phase 05-calendar]: Calendar painters use kPeriodColorLight for predicted hatch/outline vs solid kPeriodColor band for logged days (pattern + tone, NFR-06)
- [Phase 05-calendar]: buildCalendarDayCell uses Positioned.fill around CustomPaint layers for valid Stack constraints
- [Phase 05-calendar-home-cycle-surfaces]: 05-01 Task 1: minimal HomeScreen stub required so TabShell compiles before Task 2 full home
- [Phase 05-calendar-home-cycle-surfaces]: 05-01: cycle_position uses flutter/foundation @immutable for analyzer depend_on_referenced_packages
- [Phase 05-calendar-home-cycle-surfaces]: 05-01: drawer Settings widget test uses bounded pump instead of pumpAndSettle after openDrawer
- [Phase 05-calendar-home-cycle-surfaces]: 05-03: month-change widget test taps header chevron (horizontal PageView drag unreliable in tests)

### Pending Todos

Continue Phase 5: `05-04` per `ROADMAP.md`.

### Blockers/Concerns

None.

## Session Continuity

**Last session:** 2026-04-06T12:21:29.426Z

**Stopped at:** Completed 05-03-PLAN.md

**Resume file:** None

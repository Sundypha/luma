# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-04)

**Core value:** Trustworthy local-first cycle tracking without accounts or required network, with verifiable data ownership via export/import.

**Current focus:** Phase 2 — Domain, persistence & prediction v1

## Current Position

Phase: 2 of 8 (Domain, persistence & prediction v1)

**Current Plan:** 4

**Total Plans in Phase:** 4

Plan: 4 of 4 in current phase (next: 02-04)

Status: Ready to execute

Last activity: 2026-04-04 — Completed 02-02 Drift persistence, mappers, and migration tests (`ptrack_data`).

**Progress:** [███████░░░] 71%

## Performance Metrics

**Velocity:**

- Total plans completed: 6
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 3 | 3 | — |
| 2 | 3 | 4 | 20 min (02-01); 38 min (02-02); 35 min (02-03) |

**Recent Trend:**

- Last 5 plans: 01-02, 01-03, 02-01, 02-03, 02-02
- Trend: —

*Updated after each plan completion*

| Phase / plan | Duration | Tasks | Files |
|--------------|----------|-------|-------|
| 02-domain-persistence-prediction-v1 P03 | 35 min | 3 | 5 |

## Accumulated Context

### Decisions

Decisions are logged in `PROJECT.md` Key Decisions table.

- Phase 1 (2026-04-04): Dart pub workspace + Melos 7; Flutter 3.41.2 via FVM; CI uses FVM then `melos exec`; pubspec policy script runs with **uv** (`uv run --with pyyaml`), not pip.
- [Phase 2]: Period validation uses PeriodCalendarContext (IANA Location) for duplicate start-day checks; call timezone initializeTimeZones() before fromTimeZoneName.
- [Phase 2]: Completed-cycle length is inclusive local days from period start through the day before next start (see completedCycleBetweenStarts).
- [Phase 02-domain-persistence-prediction-v1]: Prediction thresholds: long gap >45d, long bleed >10d, outlier |L-median|>7, high-variability spread >=12d, six-cycle window.

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-04-04

Stopped at: Completed `02-02-PLAN.md` (Drift persistence); next `02-04-PLAN.md` or `/gsd-execute-phase`.

Resume file: `.planning/phases/02-domain-persistence-prediction-v1/02-04-PLAN.md`

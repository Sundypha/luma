---
phase: 08-release-quality-offline-assurance-inclusive-copy
plan: 02
subsystem: ui
tags: [flutter, mvvm, performance, drift, changenotifier]

requires:
  - phase: 07-app-protection-lock
    provides: TabShell, LockGate, app shell wiring
provides:
  - Pre-fetched periods-with-days threaded from main() into Home and Calendar ViewModels
  - Optional initialData seeding pattern for stream-backed ViewModels (no ctor notifyListeners)
affects:
  - 08-03-offline-assurance
  - Future ViewModels that mirror the same stream + seed pattern

tech-stack:
  added: []
  patterns:
    - "Optional initialData on ViewModels: _applyData without notify in constructor; stream still drives updates"

key-files:
  created: []
  modified:
    - apps/ptrack/lib/main.dart
    - apps/ptrack/lib/features/shell/tab_shell.dart
    - apps/ptrack/lib/features/home/home_view_model.dart
    - apps/ptrack/lib/features/calendar/calendar_view_model.dart

key-decisions:
  - "Split _applyData from _onData so seeding sets hasInitialEvent without notifyListeners in the constructor"
  - "Always await watchPeriodsWithDays().first in main (per plan); pass list through LumaApp even when initial route is not home"

patterns-established:
  - "TabShell accepts optional initialPeriodsWithDays for tests and alternate entry points without seed"

requirements-completed: [NFR-01]

duration: 12min
completed: 2026-04-07
---

# Phase 8 Plan 2: Performance feel — initial-load spinner elimination Summary

**Home and Calendar tabs seed from `watchPeriodsWithDays().first` in `main()` so `hasInitialEvent` is true before the first frame; stream subscription keeps data reactive.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-07T13:50:00Z
- **Completed:** 2026-04-07T14:02:30Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Eliminated the startup path where Home and Calendar waited on the first stream emission before showing content (no `CircularProgressIndicator` flash when data is already in SQLite).
- Preserved optional construction for widget tests: `initialData` / `initialPeriodsWithDays` default to omitted behavior (stream-only).
- Confirmed UI transition `Duration(milliseconds: …)` values in `lib/` remain 200ms (`pin_setup_sheet` AnimatedSize) and 300ms (`onboarding_screen` page transition); calendar custom painters still implement `shouldRepaint`.

## Task Commits

1. **Task 1: Seed ViewModels with initial data to eliminate spinner flash** — `5fe3b43` (feat)

**Plan metadata:** Same commit as SUMMARY/STATE/ROADMAP/REQUIREMENTS update (search `git log` for `docs(08-02):`).

## Files Created/Modified

- `apps/ptrack/lib/main.dart` — Awaits `watchPeriodsWithDays().first`, passes `initialPeriodsWithDays` into `LumaApp`.
- `apps/ptrack/lib/features/shell/tab_shell.dart` — Optional `initialPeriodsWithDays` forwarded to both ViewModels.
- `apps/ptrack/lib/features/home/home_view_model.dart` — Optional `initialData`; `_applyData` + stream `listen`.
- `apps/ptrack/lib/features/calendar/calendar_view_model.dart` — Same pattern as home.

## Decisions Made

- Applied `_applyData` for constructor seeding and `_onData` → `_applyData` + `notifyListeners()` for stream updates, matching the plan constraint to avoid `notifyListeners()` during construction.

## Deviations from Plan

None - plan executed exactly as written (implementation uses `_applyData` to satisfy the explicit “do not notifyListeners from constructor when seeding” constraint).

## Issues Encountered

- **`fvm flutter test --no-pub`:** One failure in `test/features/logging/symptom_form_view_model_test.dart` (`save() records error and returns false on failure` — expects error text to contain `'bad'` but UI shows `'Could not save symptoms. Please try again.'`). **Reproduces on the same test with all 08-02 changes reverted** (stash baseline), so it is **pre-existing** and out of scope for this plan. All other tests passed (108).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **08-03** can proceed on offline assurance; **manual** checks from this plan still apply: cold start and tab switch on device/emulator to confirm no spinner flash.

## Self-Check: PASSED

- Verified modified files exist: `main.dart`, `tab_shell.dart`, `home_view_model.dart`, `calendar_view_model.dart`.
- Verified task commit: `5fe3b43` present in `git log`.
- Verified planning files committed (message `docs(08-02):`).

---
*Phase: 08-release-quality-offline-assurance-inclusive-copy*
*Completed: 2026-04-07*

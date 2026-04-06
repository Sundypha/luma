---
phase: 05-calendar-home-cycle-surfaces
plan: 01
subsystem: ui
tags: [flutter, material3, navigation, tabbar, prediction]

requires:
  - phase: 04-core-logging
    provides: PeriodRepository.watchPeriodsWithDays, logging bottom sheet, day entries
provides:
  - TabShell with Home/Calendar tabs, NavigationDrawer, global FAB
  - HomeScreen cycle position + next-period range + TodayCard
  - Pure computeCyclePosition helper for tests and UI
affects:
  - 05-03 calendar screen integration
  - 05-04 day detail flows

tech-stack:
  added: []
  patterns:
    - "IndexedStack preserves tab state; FAB hosted on TabShell Scaffold"
    - "Home tab body is Scaffold-less; shell owns app bar and navigation"

key-files:
  created:
    - apps/ptrack/lib/features/shell/tab_shell.dart
    - apps/ptrack/lib/features/home/cycle_position.dart
    - apps/ptrack/lib/features/home/today_card.dart
  modified:
    - apps/ptrack/lib/features/home/home_screen.dart
    - apps/ptrack/lib/main.dart
    - apps/ptrack/test/widget_test.dart
    - apps/ptrack/test/logging_test.dart

key-decisions:
  - "Task 1 shipped a minimal HomeScreen placeholder so TabShell compiles before the full home refactor lands in Task 2"
  - "cycle_position uses flutter/foundation @immutable to satisfy depend_on_referenced_packages without adding meta to app pubspec"
  - "Drawer Settings test uses bounded pump delays instead of pumpAndSettle after openDrawer to avoid animation settle timeout"

requirements-completed:
  - HOME-01
  - HOME-02
  - HOME-03
  - HOME-04

duration: 25min
completed: 2026-04-06
---

# Phase 5 Plan 01: Tab shell and home cycle summary

**Material 3 TabShell (Home + Calendar placeholder, drawer, FAB) routes from `main.dart`, with a cycle-position home surface, ranged next-period copy, and a today-at-a-glance card—no period list or health metrics.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-04-06T00:00:00Z (approx.)
- **Completed:** 2026-04-06T00:25:00Z (approx.)
- **Tasks:** 2
- **Files touched:** 8 (6 in Task 2 delta + 2 new dirs from Task 1)

## Accomplishments

- TabShell centralizes bottom navigation, drawer (Settings dialog + About route), and logging FAB for both tabs.
- Home tab streams `watchPeriodsWithDays`, runs `PredictionCoordinator`, and renders cycle/period day, honest next-window or insufficient-history copy, and `TodayCard`.
- Tests target TabShell; list/menu logging tests were replaced with cycle summary, drawer Settings, calendar-tab FAB, and today-card coverage.

## Task Commits

1. **Task 1: Create TabShell and update app routing** — `b2b3d3e` (feat)
2. **Task 2: Refactor HomeScreen with cycle position and today card** — `5e323ab` (feat)

**Plan metadata:** `docs(05-01): complete tab shell and home cycle summary plan` (repository commit on branch)

## Files Created/Modified

- `apps/ptrack/lib/features/shell/tab_shell.dart` — Scaffold, `NavigationDrawer`, `NavigationBar`, `IndexedStack`, FAB → `showLoggingBottomSheet`
- `apps/ptrack/lib/features/home/cycle_position.dart` — `CyclePosition`, `computeCyclePosition`
- `apps/ptrack/lib/features/home/today_card.dart` — Today's log card or empty CTA
- `apps/ptrack/lib/features/home/home_screen.dart` — StreamBuilder home body (no Scaffold)
- `apps/ptrack/lib/main.dart` — `AppScreen.home` → `TabShell`
- `apps/ptrack/test/widget_test.dart` — TabShell, insufficient-data copy, drawer → About
- `apps/ptrack/test/logging_test.dart` — TabShell pump helper; refreshed assertions
- `apps/ptrack/lib/features/logging/home_screen.dart` — **removed** (replaced by `features/home/`)

## Decisions Made

- Kept explicit app version string `1.0.0+1` in the drawer header to match `pubspec.yaml` without adding `package_info_plus`.
- Replaced `pumpAndSettle` after `openDrawer` in the Settings widget test with fixed-duration pumps where the drawer animation did not settle within the default timeout.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Task 1 compile dependency on HomeScreen**

- **Found during:** Task 1 (TabShell references `HomeScreen` before Task 2 files existed)
- **Issue:** Plan listed only `tab_shell.dart` and `main.dart` for Task 1, but `TabShell` imports `features/home/home_screen.dart`.
- **Fix:** Added a minimal `HomeScreen` in Task 1, then replaced it entirely in Task 2 with the full implementation.
- **Files modified:** `apps/ptrack/lib/features/home/home_screen.dart` (stub then full)
- **Verification:** `flutter analyze`; Task 2 commit completes the intended surface.
- **Committed in:** `b2b3d3e` (stub) / `5e323ab` (full)

**2. [Rule 3 - Blocking] `depend_on_referenced_packages` on `package:meta`**

- **Found during:** Task 2 (`cycle_position.dart`)
- **Issue:** Analyzer reported `meta` as a direct import without a pubspec dependency.
- **Fix:** Switched to `package:flutter/foundation.dart` for `@immutable`.
- **Files modified:** `apps/ptrack/lib/features/home/cycle_position.dart`
- **Verification:** `flutter analyze` clean
- **Committed in:** `5e323ab`

**3. [Rule 1 - Bug] Drawer test `pumpAndSettle` timeout**

- **Found during:** Task 2 (`logging_test.dart` Settings drawer test)
- **Issue:** `pumpAndSettle` after `openDrawer` timed out (drawer animation did not reach idle).
- **Fix:** Used explicit `pump` + `Duration` steps before/after tapping Settings.
- **Files modified:** `apps/ptrack/test/logging_test.dart`
- **Verification:** `flutter test test/widget_test.dart test/logging_test.dart`
- **Committed in:** `5e323ab`

---

**Total deviations:** 3 auto-fixed (1 blocking sequencing, 1 blocking lint, 1 bug/test flake)

**Impact on plan:** No product scope change; tests and analyzer gates satisfied.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None.

## Next Phase Readiness

- Calendar placeholder tab is ready for Plan 03 screen swap-in.
- Home requirements HOME-01–HOME-04 addressed in this plan’s UI; remaining CAL-\* work continues in Plans 02–04.

## Self-Check: PASSED

- Verified on disk: `apps/ptrack/lib/features/shell/tab_shell.dart`, `apps/ptrack/lib/features/home/cycle_position.dart`, `apps/ptrack/lib/features/home/today_card.dart`, `05-01-SUMMARY.md`
- Verified commits: `b2b3d3e`, `5e323ab` on current branch; planning bundle in `docs(05-01)` completion commit
- `flutter analyze` and targeted tests pass in `apps/ptrack`

---
*Phase: 05-calendar-home-cycle-surfaces*

*Completed: 2026-04-06*

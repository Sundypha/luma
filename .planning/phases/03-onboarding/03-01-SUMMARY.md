---
phase: 03-onboarding
plan: 01
subsystem: ui
tags: [flutter, onboarding, shared_preferences, smooth_page_indicator, drift, offline]

requires:
  - phase: 02-domain-persistence-prediction-v1
    provides: PeriodRepository, PeriodSpan, PeriodCalendarContext, openPtrackDatabase, validation outcomes
provides:
  - Three-step onboarding wizard with required/optional gating and dot indicator
  - OnboardingState persistence via SharedPreferencesWithCache
  - FirstLogScreen wired to PeriodRepository.insertPeriod
  - App launch routing onboarding → first log → home
affects:
  - phase 4 core logging
  - phase 5 calendar/home (first-run completion assumptions)

tech-stack:
  added: [smooth_page_indicator ^2.0.1, shared_preferences ^2.5.5, timezone moved to app runtime deps]
  patterns:
    - "SharedPreferencesWithCache allowList for onboarding keys"
    - "PtrackApp.homeOverride for lightweight widget tests"
    - "Cold-start routing uses wizard completion plus empty period list for first-log gate"

key-files:
  created:
    - apps/ptrack/lib/features/onboarding/onboarding_content.dart
    - apps/ptrack/lib/features/onboarding/onboarding_state.dart
    - apps/ptrack/lib/features/onboarding/onboarding_page.dart
    - apps/ptrack/lib/features/onboarding/onboarding_screen.dart
    - apps/ptrack/lib/features/onboarding/first_log_screen.dart
  modified:
    - apps/ptrack/pubspec.yaml
    - apps/ptrack/lib/main.dart
    - apps/ptrack/test/widget_test.dart

key-decisions:
  - "After the wizard, route to first log when no periods exist; otherwise home — avoids treating onboarding_completed as full first-run done while keeping a single wizard flag."
  - "calendarForDevice tries tz.local.name and DateTime.now().timeZoneName then falls back to UTC for invalid IANA abbreviations."

patterns-established:
  - "Onboarding step saved on PageView onPageChanged so optional swipe keeps resume position."
  - "Async main: WidgetsFlutterBinding, initializeTimeZones, OnboardingState.create, DB + repository, derive initial AppScreen."

requirements-completed: [ONBD-01, ONBD-02, ONBD-03, ONBD-04]

duration: 28min
completed: 2026-04-05
---

# Phase 3 Plan 01: Onboarding wizard and first-log Summary

**Offline-first three-screen onboarding with SharedPreferences resume, animated dots, first period save via PeriodRepository, and launch routing that hands off to first log until data exists.**

## Performance

- **Duration:** 28 min (estimated execution window)
- **Started:** 2026-04-05T00:00:00Z (approximate — executor session)
- **Completed:** 2026-04-05 (date authoritative per project)
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Wizard covers local-only storage, estimates-not-advice copy, and optional quick-start with Continue vs Skip gating.
- Step persistence and completion use SharedPreferencesWithCache with an explicit allowList.
- First log screen defaults to today, supports date picker, and surfaces PeriodWriteSuccess / PeriodWriteRejected via SnackBar.
- `melos run ci:analyze` and `melos run ci:test` pass for the workspace.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add dependencies, create onboarding data model and state persistence** - `d937b6d` (feat)
2. **Task 2: Build onboarding page layout and wizard screen** - `6cca899` (feat)
3. **Task 3: First-log screen, app routing, and existing test update** - `a71c8c6` (feat)

**Plan metadata:** Single docs commit bundling this SUMMARY with STATE, ROADMAP, and REQUIREMENTS updates (see repository history for hash).

**Supporting:** `727fd38` (chore: workspace lockfile and macOS plugin registrant after `pub get`)

## Files Created/Modified

- `apps/ptrack/pubspec.yaml` — smooth_page_indicator, shared_preferences; timezone in dependencies for runtime init.
- `apps/ptrack/lib/features/onboarding/onboarding_content.dart` — `OnboardingPageData` and `onboardingPages`.
- `apps/ptrack/lib/features/onboarding/onboarding_state.dart` — wizard completion and step keys.
- `apps/ptrack/lib/features/onboarding/onboarding_page.dart` — per-step layout.
- `apps/ptrack/lib/features/onboarding/onboarding_screen.dart` — PageView, physics, indicator, controls.
- `apps/ptrack/lib/features/onboarding/first_log_screen.dart` — first insert and UX.
- `apps/ptrack/lib/main.dart` — async bootstrap, `calendarForDevice`, `PtrackApp` routing.
- `apps/ptrack/test/widget_test.dart` — `homeOverride` smoke test.

## Decisions Made

- Treat `onboarding_completed` as wizard-only; if it is true and there are no stored periods, show first log on cold start (plan text implied home immediately after wizard, which would skip first log on relaunch).
- Persist the visible step when the user swipes on the optional page (`onPageChanged` → `saveStep`), not only on button taps.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] First-log routing on relaunch**
- **Found during:** Task 3 (main / routing)
- **Issue:** Plan specified `isCompleted` → home, but the wizard calls `markCompleted` before first log; that would send returning users to home without logging.
- **Fix:** After wizard completion, cold start uses `periods.isEmpty` to show first log until at least one period exists.
- **Files modified:** `apps/ptrack/lib/main.dart`
- **Verification:** `fvm flutter test`, manual reasoning against success criteria
- **Committed in:** `a71c8c6` (Task 3)

**2. [Rule 2 - Missing critical] Step persistence when swiping optional screen**
- **Found during:** Task 2 (onboarding_screen)
- **Issue:** Plan only persisted on Continue; swipe on optional page would not update saved step.
- **Fix:** Call `onboardingState.saveStep(index)` from `onPageChanged`.
- **Files modified:** `apps/ptrack/lib/features/onboarding/onboarding_screen.dart`
- **Verification:** `fvm flutter analyze`
- **Committed in:** `6cca899` (Task 2)

**3. [Rule 3 - Plan wording] Database open is synchronous**
- **Found during:** Task 3
- **Issue:** Plan referenced `await openPtrackDatabase()`; API is synchronous.
- **Fix:** Use `openPtrackDatabase()` without await.
- **Files modified:** `apps/ptrack/lib/main.dart`
- **Verification:** analyzer
- **Committed in:** `a71c8c6` (Task 3)

---

**Total deviations:** 3 auto-fixed (2 missing critical, 1 blocking/plan mismatch)
**Impact on plan:** Aligns behavior with ONBD-03/04 and resume semantics without adding network or scope.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Onboarding and first-log handoff are in place for Phase 4 logging work.
- Phase 3 plan `03-02` remains (About replay, broader widget tests, human-verify).

---

*Phase: 03-onboarding*
*Completed: 2026-04-05*

## Self-Check: PASSED

- `03-01-SUMMARY.md` present at `.planning/phases/03-onboarding/03-01-SUMMARY.md`
- Task and chore commits `d937b6d`, `6cca899`, `a71c8c6`, `727fd38` on branch `chore/gsd-project-init`; planning bundle follows in a docs commit
- Key implementation files exist under `apps/ptrack/lib/features/onboarding/` and `apps/ptrack/lib/main.dart`

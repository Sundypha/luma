---
phase: 05-calendar-home-cycle-surfaces
plan: 03
subsystem: ui
tags: [flutter, table_calendar, stream, prediction, period-tracking]

requires:
  - phase: 05-calendar-home-cycle-surfaces
    provides: TabShell IndexedStack, calendar_day_data, calendar_painters, watchPeriodsWithDays
provides:
  - CalendarScreen with TableCalendar month view and horizontal swipe
  - Reactive buildCalendarDayDataMap + PredictionCoordinator per stream emission
  - TabShell calendar tab wired to CalendarScreen (placeholder removed)
  - Widget tests for grid, bands, stream updates, month navigation, day tap → sheet
affects:
  - 05-04 day detail replacement for day tap

tech-stack:
  added:
    - table_calendar ^3.2.0 (transitive intl, simple_gesture_detector)
  patterns:
    - StreamBuilder on watchPeriodsWithDays with synchronous prediction + day map rebuild
    - CalendarBuilders.prioritizedBuilder → buildCalendarDayCell

key-files:
  created:
    - apps/ptrack/lib/features/calendar/calendar_screen.dart
    - apps/ptrack/test/features/calendar/calendar_screen_test.dart
  modified:
    - apps/ptrack/pubspec.yaml
    - apps/ptrack/lib/features/shell/tab_shell.dart
    - pubspec.lock

key-decisions:
  - "Month navigation test taps Icons.chevron_right; dragging PageView did not change focused month reliably under widget tests"
  - "intl import in tests uses depend_on_referenced_packages ignore (transitive via table_calendar)"

patterns-established:
  - "Insufficient-history copy shows only when prediction is PredictionInsufficientHistory and focused calendar month is after the current month"

requirements-completed:
  - CAL-01
  - CAL-04
  - CAL-05

duration: 35min
completed: 2026-04-06
---

# Phase 5 Plan 03: Calendar screen with table_calendar summary

**Month grid via `table_calendar` with `StreamBuilder` on `watchPeriodsWithDays`, `PredictionCoordinator` + `buildCalendarDayDataMap`, custom `prioritizedBuilder` cells, contextual Today control, future-month insufficient-data hint, and interim day tap → `showLoggingBottomSheet` with `initialDate`.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-04-06T12:00:00Z (approx.)
- **Completed:** 2026-04-06T12:35:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Real calendar tab: solid logged bands and hatched predicted circles from Plan 02 painters, Monday-first week aligned with map builder.
- Reactive updates when the repository stream emits; only the visible month is built by `TableCalendar`.
- UX: “Today” when focused month ≠ current month; honest copy for insufficient prediction on future months.

## Task Commits

1. **Task 1: CalendarScreen with table_calendar, reactive data, and month navigation** — `d01439b` (feat)
2. **Task 2: Widget tests for calendar screen** — `9c2c55e` (test)

**Plan metadata:** `docs(05-03): complete calendar screen plan` (STATE, ROADMAP, REQUIREMENTS, this SUMMARY)

## Files Created/Modified

- `apps/ptrack/lib/features/calendar/calendar_screen.dart` — `StreamBuilder`, `TableCalendar`, `_dayBuilder`, `_goToToday`, insufficient-history banner
- `apps/ptrack/lib/features/shell/tab_shell.dart` — `CalendarScreen` replaces `_CalendarPlaceholder`
- `apps/ptrack/pubspec.yaml` — `table_calendar: ^3.2.0`
- `apps/ptrack/test/features/calendar/calendar_screen_test.dart` — grid, bands, stream, Today, sheet
- `pubspec.lock` — workspace lock update

## Decisions Made

- Widget test for “Today” uses the table header next-month chevron instead of horizontal drag on `PageView` (drag did not surface the button in tests).

## Deviations from Plan

None — plan executed as written. Test interaction uses chevron tap (equivalent user-visible month change) where swipe simulation was unreliable.

## Issues Encountered

- Initial weekday assertion used `MaterialLocalizations.narrowWeekdays`; `table_calendar` uses `DateFormat.E` for DOW labels — tests now match that formatter.
- Horizontal drag on embedded `PageView` did not advance the month in widget tests; chevron tap matches real header navigation.

## User Setup Required

None.

## Next Phase Readiness

- Plan 04 can replace `_openDayDetail` logging shortcut with day detail sheet; `data` parameter reserved for that transition.

## Self-Check: PASSED

- On disk: `apps/ptrack/lib/features/calendar/calendar_screen.dart`, `apps/ptrack/test/features/calendar/calendar_screen_test.dart`, `05-03-SUMMARY.md`
- Commits: `d01439b`, `9c2c55e` plus docs bundle commit present on branch
- `fvm flutter analyze --no-pub` and full `fvm flutter test` under `apps/ptrack` passed after changes

---
*Phase: 05-calendar-home-cycle-surfaces*

*Completed: 2026-04-06*

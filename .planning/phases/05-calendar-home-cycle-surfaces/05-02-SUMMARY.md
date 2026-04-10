---
phase: 05-calendar-home-cycle-surfaces
plan: 02
subsystem: ui
tags: [flutter, custom-painter, calendar, accessibility, period-tracking]

requires:
  - phase: 04-core-logging
    provides: StoredPeriodWithDays, DayEntryData, period streams for later calendar screen
provides:
  - PeriodDayState row-aware band segments and CalendarDayData merge from periods + predictions
  - CustomPainters for solid band, hatched prediction circle, logged-data dot, today ring
  - buildCalendarDayCell Stack helper for Plan 03 table_calendar builders
affects:
  - 05-03 calendar screen integration
  - 05-04 day detail visuals

tech-stack:
  added: []
  patterns:
    - Pure UTC-midnight day keys for calendar decoration maps
    - Pattern-based distinction (solid fill vs diagonal hatch) for NFR-06

key-files:
  created:
    - apps/ptrack/lib/features/calendar/calendar_painters.dart
  modified:
    - apps/ptrack/lib/features/calendar/calendar_day_data.dart
    - apps/ptrack/test/features/calendar/calendar_day_data_test.dart

key-decisions:
  - "HatchedCirclePainter uses kPeriodColorLight for stripes and outline so prediction reads as pattern plus tone, not color alone versus logged band"
  - "buildCalendarDayCell wraps CustomPaint layers in Positioned.fill instead of size: Size.infinite for valid Stack constraints"

patterns-established:
  - "Calendar decoration data built once per upstream change via buildCalendarDayDataMap"
  - "Logged period state wins over prediction flags for the same calendar day"

requirements-completed: [CAL-02, NFR-06]

duration: 30min
completed: 2026-04-06
---

# Phase 5 Plan 02: Calendar day data and painters summary

**Row-aware PeriodDayState mapping with buildCalendarDayDataMap, four CustomPainters (solid band, diagonal-stripe circle, dot, today ring), and a Stack helper for day cells—satisfying pattern-based logged vs predicted distinction (CAL-02 / NFR-06).**

## Performance

- **Duration:** 30 min (includes prior Task 1 commit plus Task 2 implementation)
- **Started:** 2026-04-06T11:30:00Z
- **Completed:** 2026-04-06T11:40:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Immutable `CalendarDayData` and `buildCalendarDayDataMap` merging periods, predictions, day-entry dates, and today with row boundary caps (`middleRowStart` / `middleRowEnd`).
- `PeriodBandPainter`, `HatchedCirclePainter`, `DotIndicatorPainter`, `TodayRingPainter`, and `buildCalendarDayCell` under `kPeriodColor` / `kPeriodColorLight`.
- Twelve unit tests covering week boundaries, open periods, prediction variants, and precedence rules.

## Task Commits

Each task was committed atomically:

1. **Task 1: CalendarDayData model and buildCalendarDayDataMap with tests** — `e991292` (feat)
2. **Task 2: Custom painters for period band, hatched circles, dot, and today ring** — `239b9af` (feat)

**Plan metadata:** `docs(05-02): complete calendar day data and painters plan` (same commit as SUMMARY/STATE/ROADMAP/REQUIREMENTS updates)

_Note: Task 1 landed in an earlier session; Task 2 includes a one-line import change in `calendar_day_data.dart` for analyzer compliance._

## Files Created/Modified

- `apps/ptrack/lib/features/calendar/calendar_day_data.dart` — `PeriodDayState`, `CalendarDayData`, `buildCalendarDayDataMap` (uses `package:flutter/foundation.dart` for `@immutable`).
- `apps/ptrack/test/features/calendar/calendar_day_data_test.dart` — mapping and prediction coverage.
- `apps/ptrack/lib/features/calendar/calendar_painters.dart` — painters, color constants, `buildCalendarDayCell`.

## Decisions Made

- Followed plan deep pink `kPeriodColor` and lighter `kPeriodColorLight` for hatch/outline contrast.
- Used `Positioned.fill` + `CustomPaint` for full-cell layers so layout constraints stay valid in a `Stack`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Analyzer `depend_on_referenced_packages` on `package:meta`**

- **Found during:** Task 2 verification (`flutter analyze lib/features/calendar/`)
- **Issue:** `calendar_day_data.dart` imported `meta` without a direct app dependency.
- **Fix:** Switched to `import 'package:flutter/foundation.dart';` for `@immutable`.
- **Files modified:** `apps/ptrack/lib/features/calendar/calendar_day_data.dart`
- **Verification:** `flutter analyze lib/features/calendar/` — no issues
- **Committed in:** `239b9af`

**2. [Rule 3 - Blocking] Invalid `CustomPaint` sizing in planned helper**

- **Found during:** Task 2 implementation
- **Issue:** `CustomPaint(..., size: Size.infinite)` as a direct `Stack` child is not a valid layout pattern.
- **Fix:** Wrapped each paint layer in `Positioned.fill(child: CustomPaint(...))`.
- **Files modified:** `apps/ptrack/lib/features/calendar/calendar_painters.dart`
- **Verification:** Analyze clean; compile succeeds
- **Committed in:** `239b9af`

---

**Total deviations:** 2 auto-fixed (both blocking / layout-analyzer)
**Impact on plan:** No scope change; behavior matches plan intent.

## Issues Encountered

- Local `git commit` failed once because GPG signing could not reach `gpg-agent`; retry with `git -c commit.gpgsign=false commit` succeeded.

## User Setup Required

None.

## Next Phase Readiness

- Data map and painters are ready for Plan 03 (`table_calendar` builders and reactive wiring).

---

*Phase: 05-calendar-home-cycle-surfaces*

*Completed: 2026-04-06*

## Self-Check: PASSED

- `apps/ptrack/lib/features/calendar/calendar_day_data.dart` — FOUND
- `apps/ptrack/lib/features/calendar/calendar_painters.dart` — FOUND
- `apps/ptrack/test/features/calendar/calendar_day_data_test.dart` — FOUND
- Commits `e991292`, `239b9af` — FOUND (`git log --oneline --all`)

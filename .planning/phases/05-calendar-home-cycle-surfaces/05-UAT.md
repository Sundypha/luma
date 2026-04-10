---
status: testing
phase: 05-calendar-home-cycle-surfaces
source:
  - 05-01-SUMMARY.md
  - 05-02-SUMMARY.md
  - 05-03-SUMMARY.md
  - 05-04-SUMMARY.md
started: 2026-04-06T12:00:00.000Z
updated: 2026-04-06T15:00:00.000Z
---

## Current Test

number: 2
name: Home — cycle summary and today card
expected: |
  With logged periods, you see period/cycle day style copy (e.g. period day N or cycle day N). Next-period copy is a date range, not a single date. If today has a log, a small card summarizes flow/pain/mood/notes. If not, you see an empty-today message with a path to log (e.g. Log now) that opens logging. No cycle health scores or percentages.
awaiting: user response

<!-- Note: user reported calendar styling (Test 3) while Test 2 still open; Test 3 recorded as issue below. -->

## Tests

### 1. Tab shell — tabs, drawer, FAB
expected: Bottom tabs Home/Calendar; drawer with Settings and About; FAB (+) on both tabs opens logging; About navigates and returns.
result: pass

### 2. Home — cycle summary and today card
expected: With logged periods, you see period/cycle day style copy (e.g. period day N or cycle day N). Next-period copy is a date range, not a single date. If today has a log, a small card summarizes flow/pain/mood/notes. If not, you see an empty-today message with a path to log (e.g. Log now) that opens logging. No cycle health scores or percentages.
result: [pending]

### 3. Calendar — month grid and decorations
expected: Month grid with weekday headers. Swiping left/right changes months smoothly. Logged period days show solid connected bands in the period color. Predicted future days show hatched/striped circles, clearly different from solid bands. Days with logged entries show a small dot. Today shows a ring or outline. If you navigate away from the current month, a Today control appears; tapping it returns to the current month.
result: issue
reported: "Empty period day opens log screen (OK). Visibility and styling of period spans and whether something is logged is horrible."
severity: major

### 4. Calendar — empty day tap (not predicted)
expected: Tapping a day that has no logged day entry and is not a predicted period day opens the logging sheet directly for that calendar date (not an empty detail sheet).
result: [pending]

### 5. Logged day — detail, edit, delete
expected: Tapping a day with logged data opens a read-only detail with flow/pain/mood/notes (and related chips/lines as built). Edit opens the logging sheet with data prefilled. Delete asks for confirmation, then removes the entry.
result: [pending]

### 6. Predicted day — messaging and log start
expected: Tapping a predicted future period day shows estimate-style copy (e.g. period expected around this day) with appropriate disclaimer tone, and a clear way to log period start (or equivalent).
result: [pending]

### 7. Day detail — adjacent-day swipe
expected: In the day detail sheet, swiping left/right moves between adjacent days; content updates for each day.
result: [pending]

### 8. Reactivity — after logging
expected: From the FAB, log a new period (or otherwise change data). Without restarting the app, the Calendar tab shows updated bands/decorations, and the Home tab updates cycle position and the today card as applicable.
result: [pending]

## Summary

total: 8
passed: 1
issues: 1
pending: 6
skipped: 0

## Gaps

- truth: "Logged period days read as one continuous band; logged-entry indicator is clearly visible"
  status: failed
  reason: "User reported: empty period day → log screen is fine; period span visibility/styling and logged-data indicators are horrible."
  severity: major
  test: 3
  root_cause: "Each calendar cell paints its own band via PeriodBandPainter (calendar_painters.dart); table_calendar cell layout leaves gutters so bands do not meet. PeriodDayState per cell produces mixed corner radii (segment vs pill vs circle) that read as disconnected blocks. DotIndicatorPainter uses a 2.5px radius dot, easy to miss."
  artifacts:
    - path: "apps/ptrack/lib/features/calendar/calendar_painters.dart"
      issue: "Per-cell band; bandHeight 0.52; DotIndicatorPainter radius 2.5"
    - path: "apps/ptrack/lib/features/calendar/calendar_day_data.dart"
      issue: "PeriodDayState row boundaries drive corner shapes"
    - path: "apps/ptrack/lib/features/calendar/calendar_screen.dart"
      issue: "prioritizedBuilder delegates to buildCalendarDayCell per day"
  missing:
    - "Visual design pass: continuous span (e.g. horizontal overlap/negative inset, or row-level band behind cells)"
    - "Stronger logged-data marker (larger dot, badge, or dual affordance) and consistent period fill readability"
  debug_session: ""

---
phase: 05-calendar-home-cycle-surfaces
plan: 04
subsystem: ui
tags: [flutter, calendar, bottom-sheet, pageview, prediction]

requires:
  - phase: 05-calendar-home-cycle-surfaces
    provides: CalendarScreen, buildCalendarDayDataMap, showLoggingBottomSheet
provides:
  - Day detail bottom sheet (read-only logged days, predicted-day UX, swipe)
  - Calendar tap routing: empty → logging; logged/predicted → detail sheet
  - Edit bridge and delete-with-confirmation for day entries
affects:
  - Future calendar/home polish; CAL-03 human sign-off

tech-stack:
  added: []
  patterns:
    - Three-page PageView with jumpToPage(1) for infinite adjacent-day swipe
    - anchorContext for post-pop navigation (sheet State disposes on pop)

key-files:
  created:
    - apps/ptrack/lib/features/calendar/day_detail_sheet.dart
  modified:
    - apps/ptrack/lib/features/calendar/calendar_screen.dart

key-decisions:
  - "Tap routing uses !hasLoggedData && !isPredictedPeriod so period-band days without a day entry open logging directly (plan’s triple-AND missed that case)"
  - "Predicted-day copy includes PRED-04-style estimate disclaimer (not medical advice)"

patterns-established:
  - "Day detail uses parent BuildContext as anchorContext after Navigator.pop so logging sheet still has a valid context"

requirements-completed: []

duration: —
completed: 2026-04-06
---

# Phase 5 Plan 04: Day detail sheet summary

**Day-detail modal with read-only flow/pain/mood/notes, adjacent-day PageView swipe, Edit → `showLoggingBottomSheet`, delete with dialog, predicted-day card with “Log period start”, and calendar routing that sends empty non-predicted taps straight to logging.**

## Performance

- **Duration:** —
- **Started:** 2026-04-06
- **Completed:** Task 1 automated work 2026-04-06; Task 2 not yet signed off
- **Tasks:** 1 / 2 (automated tasks); Task 2 = human verification checkpoint
- **Files modified:** 2

## Accomplishments

- `showDayDetailSheet` + `DayDetailSheet` with 3-page window, center reset, and empty-adjacent swipe → close + `showLoggingBottomSheet`.
- Logged days: header date, optional period-day index, chips, mood line, notes, Edit, Delete (with confirmation → `deleteDayEntry`).
- Predicted days: info card with `Icons.auto_awesome` and estimate-only copy.
- `CalendarScreen._openDayDetail` uses `_cachedPrediction` and routes empty days before opening the detail sheet.

## Task Commits

1. **Task 1: DayDetailSheet with read-only view, swipe navigation, and edit bridge** — `f6658f1` (feat)

**Plan metadata:** Docs commit bundles `05-04-SUMMARY.md`, `STATE.md`, `ROADMAP.md` (Task 2 still open); see `git log` for hash.

_Note: Task 2 is a blocking human-verify checkpoint — no code commit until the user types **pass** or follow-up fixes._

## Task 2 — Human verification (checkpoint: blocking)

**Status:** Awaiting human sign-off. Do not mark plan or CAL-03 complete until the user runs the app and confirms (type `pass` or list issues).

**Prerequisites:** Run the app via `cd apps/ptrack` then `fvm flutter run`. Prefer at least 2–3 logged periods so prediction UI is meaningful.

**Step 1 — Tab shell**

1. Bottom tab bar shows **Home** and **Calendar**.
2. Tap each tab — content switches; both tabs stay alive (e.g. scroll position preserved).
3. Hamburger menu → drawer with Settings and About.
4. Tap About → AboutScreen loads; navigate back.
5. FAB (+) visible on both tabs.

**Step 2 — Home tab**

1. With logged periods: **Period day N** or **Cycle day N** displays as designed.
2. Next-period prediction shows as a **date range** (e.g. “Apr 20 – Apr 24”), not a single date.
3. If today has logged data: mini card shows flow/pain/mood/notes summary.
4. If nothing logged today: “Nothing logged today” (or equivalent) with **Log now** → logging sheet.
5. No “cycle health” scores or percentages anywhere.

**Step 3 — Calendar tab**

1. Month grid with weekday headers.
2. Swipe left/right → months change smoothly.
3. Logged period days: solid pink/magenta connected bands.
4. Predicted future days: hatched/striped circles, visually distinct from solid.
5. Days with logged entries: small dot indicator.
6. Today: ring/outline.
7. Navigate away from current month → **Today** appears; tap → returns to current month.

**Step 4 — Day detail**

1. Tap a day **with logged data** → read-only detail (flow/pain/mood/notes).
2. Tap **Edit** → logging sheet with pre-filled data.
3. Tap an **empty** day (no logged day entry, not predicted) → logging sheet opens **directly** for that date.
4. Tap a **predicted** future day → “Period expected around this day” and **Log period start** (or equivalent).
5. In the detail sheet, swipe left/right → **adjacent days** update.

**Step 5 — Reactivity**

1. Log a new period via FAB.
2. Calendar tab → new period band appears without restart.
3. Home tab → cycle position and today card update.

**Done when:** You confirm the above (reply `pass`) or describe issues to fix.

## Files Created/Modified

- `apps/ptrack/lib/features/calendar/day_detail_sheet.dart` — modal API, PageView, logged/predicted/empty-adjacent behavior, delete dialog.
- `apps/ptrack/lib/features/calendar/calendar_screen.dart` — `_openDayDetail` routing, `_cachedPrediction` use (already populated in `StreamBuilder`).

## Decisions Made

- Routing empty taps with `!hasLoggedData && !isPredictedPeriod` fixes period-band days that have no `StoredDayEntry` yet; the plan’s `loggedPeriodState == PeriodDayState.none` would incorrectly open the detail sheet on those days.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Empty tap routing for period-band days without day entries**

- **Found during:** Task 1 (`_openDayDetail`)
- **Issue:** Only days with `loggedPeriodState == none` were sent straight to logging; a day inside a logged period band but without a day entry opened an empty detail sheet.
- **Fix:** Route to logging when `!hasLoggedData && !isPredictedPeriod`.
- **Files modified:** `calendar_screen.dart`
- **Committed in:** `f6658f1`

## Issues Encountered

None blocking automated verification.

## User Setup Required

None for code; Task 2 requires a local `fvm flutter run` on device/emulator.

## Next Phase Readiness

- After Task 2 **pass**: mark CAL-03 / plan 05-04 complete in ROADMAP and REQUIREMENTS; optional widget tests for day-detail flows.
- Until then: treat Phase 5 as still in progress for UX sign-off.

## Self-Check

- **Automated:** `fvm flutter analyze --no-pub` and `fvm flutter test` under `apps/ptrack` — **PASSED** after Task 1.
- **On disk:** `day_detail_sheet.dart`, updated `calendar_screen.dart`, this `05-04-SUMMARY.md` — **PRESENT** (after docs commit).
- **Commit:** `f6658f1` (Task 1 feat) — **VERIFIED**.
- **Human verification (Task 2):** **PENDING** — follow “Task 2 — Human verification” above; reply `pass` when satisfied.

---
*Phase: 05-calendar-home-cycle-surfaces*

*Task 1 completed: 2026-04-06 — Task 2 awaiting human sign-off*

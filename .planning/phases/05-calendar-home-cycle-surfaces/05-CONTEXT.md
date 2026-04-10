# Phase 5: Calendar, home & cycle surfaces - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Users navigate time via a month-based calendar, distinguish logged from predicted days accessibly, drill into any day to view or log entries, and see an honest home summary with cycle position and a quick path back to logging. No new data types or prediction changes — this phase surfaces what exists from Phases 2–4.

</domain>

<decisions>
## Implementation Decisions

### Calendar day marking
- Follow Apple Cycle Tracking visual language: solid fill for logged period days, hatched/striped fill for predicted period days — same color family, distinguished by fill pattern (meets NFR-06: not color-only)
- Color family: deep pink/magenta
- Logged period ranges: connected band/pill spanning the days (circles merge into a continuous strip)
- Predicted period ranges: individual hatched circles per day (predictions feel tentative, not locked in)
- Small dot indicator on days with any logged data (symptoms, notes, mood) — separate from period marking
- Today's date: ring/outline, distinct from period fill, always visible
- Flow intensity not shown on calendar grid — details only on day tap (keep grid clean)
- When insufficient history for predictions: subtle inline message on the first empty future month ("predictions appear after more data")

### Home summary content
- During active period: lead with "Period day N" (focus on how many days in)
- Today's log at a glance: mini card showing today's entries in a structured layout
- When nothing logged today: prompt with "Nothing logged today" and a button to start logging
- Prediction wording: range-based, not single-date — e.g. "Jan 13–17" to avoid overconfident precision (HOME-04)
- No "cycle health" scores, no overconfident metrics — honest language only

### Screen structure & navigation
- Bottom tab bar with two tabs: Home and Calendar
- Sidebar (drawer) for settings and secondary items, opened via hamburger menu icon in the app bar
- Floating action button (FAB) for quick logging — always visible, one tap to open logging sheet (HOME-03)
- Calendar month navigation: horizontal swipe gesture
- "Today" button: appears contextually when the user has navigated away from the current month

### Day detail interaction
- Tapping a calendar day opens a bottom sheet (consistent with Phase 4's logging sheet pattern)
- Empty day (no data): opens logging directly for that date
- Day with logged data: opens in read-only view first, with an Edit button to switch to edit mode
- Predicted (future) period day: shows prediction info ("Period expected around this day") with option to log if it arrives
- Swipe left/right within the open bottom sheet to navigate adjacent days

### Claude's Discretion
- Cycle position display format on home screen (day count, countdown, or combination)
- Insufficient-data home state (encouraging progress message vs. simplified view)
- Bottom sheet reuse strategy (modes on existing sheet vs. separate read-only sheet)
- Exact spacing, typography, and animation details
- Loading skeleton design for calendar data
- Error state handling on calendar and home

</decisions>

<specifics>
## Specific Ideas

- "Follow Apple's Cycle Tracking visual approach" — reference for the solid vs hatched circle pattern and overall polish level
- Deep pink/magenta color family (not red) for period marking — softer, still stands out
- Connected band for logged ranges mirrors how Apple shows multi-day periods, but hatched individual circles for predictions differentiate confidence level
- Sidebar for settings rather than a third tab — keeps the tab bar focused on the two primary surfaces

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-calendar-home-cycle-surfaces*
*Context gathered: 2026-04-06*

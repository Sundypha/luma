# Phase 4: Core Logging - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can record and edit period and symptom data with validation that prevents impossible ranges and preserves adjacent cycle integrity. Covers: period start/end marking, flow intensity, pain score, mood, free-text notes, editing past entries, and retroactive logging. Does NOT include calendar view (Phase 5), home summary (Phase 5), export/import (Phase 6), or app lock (Phase 7).

</domain>

<decisions>
## Implementation Decisions

### Logging entry point & interaction
- Primary action: floating action button (FAB) on the home screen, always visible
- FAB opens a bottom sheet (lightweight, doesn't lose home context)
- Date-first flow: user picks a date, then marks period start or end for that date
- Optional detail fields (flow, symptoms, notes) are visible but collapsed/optional below the date action in the same bottom sheet — user adds what they want without a separate step

### Flow intensity
- 3 discrete levels: Light, Medium, Heavy
- Input control: segmented buttons (row of 3 tappable chips)
- Per-day granularity (each day within a period can have its own flow level)

### Pain score
- 1–5 scale: None / Mild / Moderate / Severe / Very Severe
- Familiar clinical-style labeling

### Mood
- Default: emoji row (5 faces from negative to positive), tap to select
- User preference (in settings): switch to word chip labels for accessibility (e.g. "Sad", "Low", "Neutral", "Good", "Great")
- Single-select per day

### Notes
- Short multiline text field: 2–3 visible lines, expandable, no hard character limit
- Free-text, one per day

### Navigating past entries
- Reverse-chronological list grouped by period (each period is a card/section, e.g. "Mar 1–5, 2026")
- Expand a period to see individual days with their logged details
- Calendar navigation deferred to Phase 5; list is the Phase 4 navigation surface

### Editing past entries
- Tap a day within the period list to open the same logging bottom sheet, pre-filled with existing data for that day
- Consistent UX: same bottom sheet for new entries and edits
- Reuse reduces surface area to build and test

### Deleting entries
- Users can delete an entire period or individual day entries
- Both require a confirmation dialog before deletion

### Validation timing
- Hybrid approach: obvious impossibilities (end before start) shown live/inline as soon as the user changes dates; overlap and duplicate-start checks run on save
- Inline red helper text below the offending field (standard Material pattern)

### Overlap handling
- Block save with clear explanation: "This overlaps with your [date range] period. Please adjust dates."
- No merge option in Phase 4

### Future dates
- Blocked: only today and past dates allowed for logging (period data is retrospective)

### Claude's Discretion
- Exact bottom sheet layout, spacing, and typography
- Segmented button styling and color treatment
- Emoji set selection for mood (5 faces, specific emoji choice)
- Animation and transition details for bottom sheet open/close
- Loading and saving state indicators
- How the period list groups and renders day detail summaries
- Schema migration approach for new columns (flow, pain, mood, notes)

</decisions>

<specifics>
## Specific Ideas

- Bottom sheet reuse: the same bottom sheet component serves both new-entry and edit flows, pre-filled with existing data when editing
- Mood preference toggle: emoji row as default, word chips as an accessibility alternative in settings — ensures users unfamiliar with emoji can still use the feature
- Period history list as the primary Phase 4 navigation surface (replaced by calendar tap-to-day in Phase 5)

</specifics>

<deferred>
## Deferred Ideas

- Calendar view for navigating to past days — Phase 5
- Toggle between calendar view and list view — Phase 5 (list view from Phase 4 can be retained as an option)

</deferred>

---

*Phase: 04-core-logging*
*Context gathered: 2026-04-05*

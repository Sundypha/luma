# Phase 5: Calendar, Home & Cycle Surfaces - Research

**Researched:** 2026-04-06
**Domain:** Flutter UI surfaces — calendar grid, home summary, tab shell, cycle position
**Confidence:** HIGH

## Summary

Phase 5 surfaces existing data (periods, day entries, predictions from Phases 2–4) through two primary screens — a month-based calendar and a home summary — connected by a bottom tab bar. The calendar requires custom day-cell rendering to achieve the Apple Cycle Tracking–inspired visual language (solid-fill connected bands for logged periods, hatched individual circles for predicted days). The home screen derives cycle position from the latest period and prediction engine, presents today's log at a glance, and offers a FAB for quick logging.

The main technical challenges are: (1) rendering visually connected period bands across independent day cells, (2) merging period and prediction data into a per-day calendar decoration model, and (3) restructuring the app shell from a single-screen Scaffold into a tabbed shell with drawer navigation — all without breaking the existing logging flow.

**Primary recommendation:** Use `table_calendar` (^3.2.0) for month navigation and day-cell layout with custom `CalendarBuilders` for all day decoration. Build a thin `CalendarDayData` model that merges periods + predictions into per-day render instructions. Use `NavigationBar` (Material 3) + `IndexedStack` for tab shell. Reuse the existing `LoggingBottomSheet` for day-detail interactions from the calendar.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Follow Apple Cycle Tracking visual language: solid fill for logged period days, hatched/striped fill for predicted period days — same color family, distinguished by fill pattern (meets NFR-06: not color-only)
- Color family: deep pink/magenta
- Logged period ranges: connected band/pill spanning the days (circles merge into a continuous strip)
- Predicted period ranges: individual hatched circles per day (predictions feel tentative, not locked in)
- Small dot indicator on days with any logged data (symptoms, notes, mood) — separate from period marking
- Today's date: ring/outline, distinct from period fill, always visible
- Flow intensity not shown on calendar grid — details only on day tap (keep grid clean)
- When insufficient history for predictions: subtle inline message on the first empty future month ("predictions appear after more data")
- During active period: lead with "Period day N" (focus on how many days in)
- Today's log at a glance: mini card showing today's entries in a structured layout
- When nothing logged today: prompt with "Nothing logged today" and a button to start logging
- Prediction wording: range-based, not single-date — e.g. "Jan 13–17" to avoid overconfident precision (HOME-04)
- No "cycle health" scores, no overconfident metrics — honest language only
- Bottom tab bar with two tabs: Home and Calendar
- Sidebar (drawer) for settings and secondary items, opened via hamburger menu icon in the app bar
- Floating action button (FAB) for quick logging — always visible, one tap to open logging sheet (HOME-03)
- Calendar month navigation: horizontal swipe gesture
- "Today" button: appears contextually when the user has navigated away from the current month
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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CAL-01 | User can view month-based calendar and navigate past/future months smoothly | table_calendar with horizontal swipe, `focusedDay` state, PageView-based month navigation |
| CAL-02 | Logged period days and predicted future days are visually distinguishable (not color-only) | CalendarBuilders with CustomPainter: solid fill vs hatched pattern via patterns_canvas or manual diagonal lines; fill pattern + shape difference meets NFR-06 |
| CAL-03 | User can tap a day to view or edit entries for that day | table_calendar `onDaySelected` callback → open day-detail bottom sheet |
| CAL-04 | Calendar remains performant with multi-year local history | table_calendar only renders visible month; `eventLoader` callback computes per-visible-day marks from pre-indexed Map; no full-history widget tree |
| CAL-05 | Prediction display on calendar updates after edits to underlying data | Reactive `watchPeriodsWithDays()` stream drives both period marks and re-computed predictions; StreamBuilder rebuilds calendar decorations on data change |
| HOME-01 | User sees cycle position and next expected period status (or insufficient-data state) | `PredictionCoordinator.predictNext()` computes result; home widget maps `PredictionResult` sealed class to cycle-position text and next-period range |
| HOME-02 | User sees what they logged today at a glance | Filter today's `DayEntryData` from `watchPeriodsWithDays()` stream; render mini-card with flow/pain/mood/notes |
| HOME-03 | User has a visible quick action to log or edit without deep navigation | FAB on Scaffold; opens existing `showLoggingBottomSheet()` |
| HOME-04 | Home does not present unsupported "cycle health" scores or overconfident precision | Range-based wording ("Jan 13–17"), no scores; prediction copy helpers already enforce PRED-04 guardrails |
| NFR-06 | Predicted vs actual periods distinguishable without relying on color alone | Solid fill (logged) vs hatched/striped pattern (predicted) — shape/texture difference, not just color |

</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| table_calendar | ^3.2.0 | Month grid, swipe navigation, day-cell builders | Most maintained Flutter calendar widget; CalendarBuilders API gives full control over each cell; built-in PageView month swipe; locale-aware weekday headers |
| (Flutter built-in) NavigationBar | Flutter SDK | Bottom tab bar (Material 3) | Replaces deprecated BottomNavigationBar; ships with M3 theming; no extra dependency |
| (Flutter built-in) NavigationDrawer | Flutter SDK | Sidebar for settings | Material 3 drawer component; Scaffold.drawer integrates automatically with app bar hamburger icon |
| (Flutter built-in) IndexedStack | Flutter SDK | Tab state preservation | Keeps both Home and Calendar alive across tab switches; preserves scroll positions and stream subscriptions |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (already in project) ptrack_domain | workspace | PredictionEngine, PredictionResult, PeriodSpan, DayEntryData | Home cycle-position computation, calendar day-data merging |
| (already in project) ptrack_data | workspace | PeriodRepository, PredictionCoordinator, watchPeriodsWithDays | Reactive data source for both calendar and home |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| table_calendar | Custom GridView + PageView calendar | Full rendering control (easier connected bands) but must rebuild month layout, weekday headers, locale support, swipe physics — significant effort for marginal gain since per-cell band segments achieve the same visual |
| table_calendar | flutter_calendar_carousel | Less actively maintained, fewer builder hooks; table_calendar has 7× more pub likes and active issues |
| patterns_canvas (hatched fills) | Manual CustomPainter diagonal lines | patterns_canvas adds a dependency for ~20 lines of canvas code; manual approach is simpler, avoids a dependency, and gives exact control. **Recommend manual.** |

**Installation:**
```bash
flutter pub add table_calendar
```
(No other new dependencies needed — NavigationBar, NavigationDrawer, IndexedStack are Flutter SDK built-ins.)

## Architecture Patterns

### Recommended Project Structure
```
apps/ptrack/lib/
├── main.dart                      # Updated: TabShell replaces direct HomeScreen
├── features/
│   ├── shell/
│   │   └── tab_shell.dart         # Scaffold + NavigationBar + IndexedStack + Drawer + FAB
│   ├── calendar/
│   │   ├── calendar_screen.dart   # TableCalendar + StreamBuilder
│   │   ├── calendar_day_data.dart # Per-day decoration model (period state, prediction state, has log)
│   │   ├── calendar_painters.dart # CustomPainter for solid fill, hatched fill, dot indicator, today ring
│   │   └── day_detail_sheet.dart  # Read-only day view + edit bridge to LoggingBottomSheet
│   ├── home/
│   │   ├── home_screen.dart       # Refactored: cycle summary + today card + quick actions
│   │   ├── cycle_position.dart    # Pure function: periods + prediction → cycle position model
│   │   └── today_card.dart        # Mini card: today's DayEntryData summary
│   ├── logging/
│   │   └── logging_bottom_sheet.dart  # Existing — reused from Phase 4
│   ├── onboarding/                # Existing — unchanged
│   └── settings/
│       └── ...                    # Existing — moved into drawer destinations
```

### Pattern 1: CalendarDayData — Per-Day Decoration Model

**What:** A pure data class that describes what a single calendar day cell should render, computed from the merged period + prediction data.

**When to use:** Computed once per visible month from the reactive stream, passed to CalendarBuilders.

**Example:**
```dart
enum PeriodDayState { none, start, middle, end, single }

class CalendarDayData {
  const CalendarDayData({
    this.loggedPeriodState = PeriodDayState.none,
    this.isPredictedPeriod = false,
    this.hasLoggedData = false,
    this.isToday = false,
  });

  final PeriodDayState loggedPeriodState;
  final bool isPredictedPeriod;
  final bool hasLoggedData;
  final bool isToday;
}

/// Build a Map<DateTime, CalendarDayData> from periods + prediction result.
/// DateTime keys are UTC-midnight-normalized (matching table_calendar's day keys).
Map<DateTime, CalendarDayData> buildCalendarDayDataMap({
  required List<StoredPeriodWithDays> periodsWithDays,
  required PredictionResult prediction,
  required DateTime today,
}) {
  // 1. Walk each period's start..end range → mark PeriodDayState
  // 2. Walk prediction range days → mark isPredictedPeriod (skip logged days)
  // 3. Walk dayEntries → mark hasLoggedData
  // 4. Mark today
  // ...
}
```

### Pattern 2: Tab Shell with FAB

**What:** A top-level Scaffold that owns the NavigationBar, IndexedStack (Home + Calendar), Drawer, and FAB. Replaces the current `HomeScreen` as the root widget after onboarding/first-log.

**When to use:** After initial routing resolves to `AppScreen.home`, the tab shell becomes the app's main surface.

**Example:**
```dart
class TabShell extends StatefulWidget {
  const TabShell({
    super.key,
    required this.repository,
    required this.database,
    required this.calendar,
  });
  // ...
}

class _TabShellState extends State<TabShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ptrack'),
        // Drawer icon auto-added by Scaffold when drawer is set
      ),
      drawer: NavigationDrawer(
        children: [
          // Settings, About, etc.
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeScreen(repository: widget.repository, ...),
          CalendarScreen(repository: widget.repository, ...),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showLoggingBottomSheet(context, ...),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Pattern 3: Connected Band via Per-Cell Segments

**What:** Each day cell in the calendar renders its own segment of the period band based on `PeriodDayState`. Start cells get left-rounded + right-flat fill; middle cells get full-width flat fill; end cells get left-flat + right-rounded fill. Visually, adjacent cells form a connected strip.

**When to use:** In `CalendarBuilders.prioritizedBuilder` when `loggedPeriodState != PeriodDayState.none`.

**Example:**
```dart
class PeriodBandPainter extends CustomPainter {
  PeriodBandPainter({required this.state, required this.color});

  final PeriodDayState state;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final bandHeight = size.height * 0.55;
    final top = (size.height - bandHeight) / 2;
    final rect = Rect.fromLTWH(0, top, size.width, bandHeight);

    final radius = Radius.circular(bandHeight / 2);
    final rrect = switch (state) {
      PeriodDayState.start => RRect.fromRectAndCorners(rect, topLeft: radius, bottomLeft: radius),
      PeriodDayState.end => RRect.fromRectAndCorners(rect, topRight: radius, bottomRight: radius),
      PeriodDayState.single => RRect.fromRectAndRadius(rect, radius),
      PeriodDayState.middle => RRect.fromRectAndRadius(rect, Radius.zero),
      PeriodDayState.none => RRect.zero,
    };
    if (state != PeriodDayState.none) {
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(PeriodBandPainter old) => old.state != state || old.color != color;
}
```

### Pattern 4: Hatched Circle for Predicted Days

**What:** A CustomPainter that draws a circle with diagonal stripe fill for predicted period days — visually tentative, meets NFR-06 (not color-only).

**When to use:** In CalendarBuilders when `isPredictedPeriod == true` and `loggedPeriodState == PeriodDayState.none`.

**Example:**
```dart
class HatchedCirclePainter extends CustomPainter {
  HatchedCirclePainter({required this.color, this.stripeSpacing = 4.0});

  final Color color;
  final double stripeSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    // Clip to circle, then draw diagonal stripes
    canvas.save();
    canvas.clipPath(circlePath);

    final stripePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Diagonal lines from bottom-left to top-right
    for (double offset = -size.height; offset < size.width + size.height; offset += stripeSpacing) {
      canvas.drawLine(
        Offset(offset, size.height),
        Offset(offset + size.height, 0),
        stripePaint,
      );
    }
    canvas.restore();

    // Circle outline
    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, outlinePaint);
  }

  @override
  bool shouldRepaint(HatchedCirclePainter old) => old.color != color;
}
```

### Pattern 5: Cycle Position Computation

**What:** A pure function that takes the latest period list and prediction result, returns a structured cycle-position model for the home screen.

**When to use:** Home screen rebuilds this on every `watchPeriodsWithDays` emission.

**Example:**
```dart
class CyclePosition {
  const CyclePosition({
    required this.dayInCycle,
    required this.isOnPeriod,
    required this.periodDayNumber,
    this.nextPeriodRange,
    this.insufficientData = false,
  });

  final int dayInCycle;
  final bool isOnPeriod;
  final int? periodDayNumber;
  final (DateTime, DateTime)? nextPeriodRange;
  final bool insufficientData;
}

CyclePosition computeCyclePosition({
  required List<StoredPeriodWithDays> periods,
  required PredictionResult prediction,
  required DateTime today,
}) {
  // Find the most recent period (last start ≤ today)
  // If that period spans today → isOnPeriod, periodDayNumber = today - start + 1
  // dayInCycle = today - lastPeriodStart + 1
  // Map prediction to nextPeriodRange
  // ...
}
```

### Anti-Patterns to Avoid

- **Rebuilding the full calendar on every stream emission:** Only recompute the `CalendarDayData` map and let `table_calendar` diff its own cells. Don't call `setState` on the entire screen — scope the `StreamBuilder` tightly.
- **Storing calendar decoration state in the database:** The `CalendarDayData` map is a derived view, not persisted state. Compute it on-the-fly from periods + predictions.
- **Passing raw `StoredPeriodWithDays` lists into calendar builders:** Transform to `Map<DateTime, CalendarDayData>` once per rebuild; accessing it in `eventLoader` / builders is O(1) per day.
- **Embedding prediction logic in UI widgets:** Keep prediction computation in `PredictionCoordinator` (data layer); the UI just reads the sealed `PredictionResult`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Month grid with weekday headers and swipe navigation | Custom GridView + PageView + locale-aware weekday names | `table_calendar` ^3.2.0 | Handles page caching, locale, first-day-of-week, disabled days, header formats — ~800 lines of well-tested layout code |
| Material 3 bottom tab bar | Custom BottomAppBar with InkWells | `NavigationBar` (Flutter SDK) | Consistent M3 theming, indicator animation, accessibility labels, adaptive sizing |
| Material 3 navigation drawer | Custom AnimatedContainer sidebar | `NavigationDrawer` (Flutter SDK) | Scaffold integration, swipe-to-open, M3 styling, auto hamburger icon |
| Tab state preservation across switches | Manual widget caching with GlobalKeys | `IndexedStack` | Trivial to use, zero external state, keeps both tabs alive |

**Key insight:** The calendar's visual complexity is in the *per-cell painting*, not the grid layout. Using table_calendar for structure and CustomPainter for decoration is the optimal split.

## Common Pitfalls

### Pitfall 1: DateTime Normalization Mismatch with table_calendar
**What goes wrong:** table_calendar normalizes day keys to UTC midnight. If period dates or prediction dates use local time or non-midnight UTC, lookups in `eventLoader` or the day-data map return null, and marks don't appear.
**Why it happens:** The project stores `startUtc` / `endUtc` as UTC instants (Drift DateTimeColumn); these may have non-zero time components.
**How to avoid:** Always normalize to `DateTime.utc(d.year, d.month, d.day)` before using as map keys. Create a shared `utcDateOnly()` helper (already exists in prediction_engine.dart — extract to shared location or duplicate).
**Warning signs:** Day marks appear on wrong days or not at all; `eventLoader` returns empty for days that should have data.

### Pitfall 2: Connected Band Breaks at Week/Month Row Boundaries
**What goes wrong:** A period spanning the end of one week row into the next renders the band end-cap on Saturday and start-cap on Sunday, creating a visual gap even though the days are consecutive.
**Why it happens:** `PeriodDayState` is computed from calendar-day adjacency, not visual-row adjacency — the last day of a row and first day of the next row are still "middle" in the period but sit in different grid rows.
**How to avoid:** This is actually correct behavior for per-cell rendering — the band *should* end and restart at row boundaries (Apple Cycle Tracking does this too). The start/end caps at row edges make the visual readable. Ensure `PeriodDayState` accounts for row position: if a middle day is the last day of a week row, render it as `middleRowEnd`; if first day of a week row, render as `middleRowStart`.
**Warning signs:** Band rendering looks broken at week boundaries; user perceives discontinuity.

### Pitfall 3: Prediction Re-computation Performance
**What goes wrong:** Running `PredictionEngine.predict()` on every calendar rebuild (which happens on swipe, selection, etc.) causes frame drops.
**Why it happens:** While the engine itself is fast, `PredictionCoordinator.predictNextFromRepository()` awaits a database query + computation on each call.
**How to avoid:** Cache the prediction result and only recompute when `watchPeriodsWithDays` emits a new snapshot. The prediction result doesn't change on swipe or day selection — only on data edits.
**Warning signs:** Jank during month swipe; `PredictionCoordinator` called more than once per data change.

### Pitfall 4: FAB Overlapping NavigationBar or Bottom Sheet
**What goes wrong:** The FAB position conflicts with NavigationBar or gets hidden behind the bottom sheet when it opens.
**Why it happens:** Material 3 `Scaffold` places FAB relative to `body`, but `NavigationBar` shifts the body's bottom padding.
**How to avoid:** Use `Scaffold.floatingActionButton` (standard placement) — Scaffold automatically positions above NavigationBar. For bottom sheet overlap, the logging sheet is modal (`showModalBottomSheet`) so it covers the FAB, which is fine — the FAB is not needed while the sheet is open.
**Warning signs:** FAB visually overlaps tab labels; FAB is inaccessible while bottom sheet is half-open.

### Pitfall 5: Stale Calendar After Logging
**What goes wrong:** User logs a period via FAB or day-tap sheet, closes the sheet, but the calendar still shows old marks.
**Why it happens:** The calendar's `CalendarDayData` map is not rebuilt because the `StreamBuilder` wraps the wrong scope or the stream deduplication suppresses the update.
**How to avoid:** The `StreamBuilder` on `watchPeriodsWithDays()` should wrap the entire calendar widget (or at minimum the `CalendarBuilders`). The existing `watchPeriodsWithDays()` already handles table-change notifications and deduplicates identical snapshots, so genuine data changes will propagate.
**Warning signs:** Day marks don't update until the user swipes away and back; logging changes visible on home tab but not calendar tab.

## Code Examples

### table_calendar Integration with Custom Builders

```dart
// Verified pattern from table_calendar ^3.2.0 API
TableCalendar<void>(
  firstDay: DateTime.utc(2020, 1, 1),
  lastDay: DateTime.utc(2030, 12, 31),
  focusedDay: _focusedDay,
  onDaySelected: (selectedDay, focusedDay) {
    _openDayDetail(selectedDay);
    setState(() => _focusedDay = focusedDay);
  },
  onPageChanged: (focusedDay) {
    setState(() => _focusedDay = focusedDay);
  },
  calendarBuilders: CalendarBuilders(
    prioritizedBuilder: (context, day, focusedDay) {
      final key = DateTime.utc(day.year, day.month, day.day);
      final data = _dayDataMap[key] ?? const CalendarDayData();
      return _buildDayCell(day, data);
    },
  ),
  headerStyle: const HeaderStyle(
    formatButtonVisible: false, // Month-only format
  ),
  availableGestures: AvailableGestures.horizontalSwipe,
)
```

### Reactive Calendar Data Pipeline

```dart
StreamBuilder<List<StoredPeriodWithDays>>(
  stream: repository.watchPeriodsWithDays(),
  builder: (context, snapshot) {
    final data = snapshot.data ?? [];

    // Recompute prediction only when data changes
    final prediction = PredictionCoordinator()
        .predictNext(storedPeriods: _extractPeriods(data), calendar: calendar);

    // Build per-day decoration map
    final dayDataMap = buildCalendarDayDataMap(
      periodsWithDays: data,
      prediction: prediction.result,
      today: DateTime.now(),
    );

    return TableCalendar<void>(
      // ... pass dayDataMap into builders
    );
  },
)
```

### Home Cycle Position Display

```dart
Widget _buildCycleStatus(CyclePosition pos) {
  if (pos.insufficientData) {
    return const Text('Log a few more periods to see cycle insights');
  }

  final lines = <Widget>[];
  if (pos.isOnPeriod) {
    lines.add(Text(
      'Period day ${pos.periodDayNumber}',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ));
  } else {
    lines.add(Text('Cycle day ${pos.dayInCycle}'));
  }

  if (pos.nextPeriodRange case (final start, final end)) {
    final fmt = MaterialLocalizations.of(context);
    lines.add(Text(
      'Next period expected ${_formatDateRange(start, end)}',
    ));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: lines,
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `BottomNavigationBar` (Material 2) | `NavigationBar` (Material 3) | Flutter 3.7+ (2023) | M3 indicator animation, adaptive layout, better theming |
| `Drawer` with `ListView` + `ListTile` | `NavigationDrawer` with `NavigationDrawerDestination` | Flutter 3.16+ (2023) | M3 styling, rounded corners, semantic destinations |
| table_calendar 2.x (legacy API) | table_calendar 3.x (CalendarBuilders, typed builders) | 2022 | Breaking API change; all builder signatures updated |

**Deprecated/outdated:**
- `BottomNavigationBar`: Still works but `NavigationBar` is the M3 replacement — use the new one for consistency with the project's `useMaterial3: true` theme.

## Open Questions

1. **Day-detail bottom sheet: read-only mode reuse vs. new widget**
   - What we know: The locked decision says "day with logged data opens read-only view first, with Edit button." The existing `LoggingBottomSheet` is edit-only.
   - What's unclear: Whether to add a read-only mode to the existing sheet or build a separate `DayDetailSheet` that delegates to `LoggingBottomSheet` on edit.
   - Recommendation: Build a lightweight `DayDetailSheet` that shows read-only data and has an "Edit" button that opens the existing `LoggingBottomSheet`. This avoids complicating the logging sheet's already complex state machine. **MEDIUM confidence** — planner should decide based on code complexity.

2. **Adjacent-day swipe within bottom sheet**
   - What we know: Locked decision: "Swipe left/right within the open bottom sheet to navigate adjacent days."
   - What's unclear: Whether to use a `PageView` inside the sheet (smooth swipe) or detect horizontal drag gestures manually.
   - Recommendation: Use a `PageView` with three pages (previous / current / next day) inside the sheet. On page change, update the current day and rebuild. This gives native swipe physics. **HIGH confidence** in pattern, **MEDIUM confidence** in UX polish needed.

3. **Row-aware period band rendering**
   - What we know: Connected bands must render per-cell segments. At week-row boundaries, the band should show end/start caps.
   - What's unclear: Whether `table_calendar` exposes row position per cell, or if we need to compute day-of-week to determine row edges.
   - Recommendation: Compute from `day.weekday` and the table_calendar's `startingDayOfWeek` setting. If the day is the last day of the week row, render as `middleRowEnd`; if first, `middleRowStart`. This is straightforward date arithmetic. **HIGH confidence.**

4. **"Today" button visibility logic**
   - What we know: "Appears contextually when the user has navigated away from the current month."
   - What's unclear: Exact threshold — same month check, or visual viewport check?
   - Recommendation: Compare `_focusedDay.month`/`_focusedDay.year` to `DateTime.now()`. Show a small FAB-like button (or AppBar action) when they differ. On tap, animate to today's month. **HIGH confidence.**

## Sources

### Primary (HIGH confidence)
- table_calendar 3.2.0 pub.dev — CalendarBuilders API, configuration, builder signatures
- Flutter SDK — NavigationBar, NavigationDrawer, IndexedStack, Scaffold.drawer API
- Existing codebase (apps/ptrack, packages/ptrack_data, packages/ptrack_domain) — period repository, prediction engine, logging sheet

### Secondary (MEDIUM confidence)
- pub.dev patterns_canvas 0.6.0 — hatched pattern rendering on circles (evaluated but recommending manual approach)
- WebSearch: Flutter IndexedStack tab preservation patterns — confirmed as standard approach
- WebSearch: table_calendar multi-day span rendering via Positioned in markerBuilder — evaluated but recommending per-cell segment approach instead

### Tertiary (LOW confidence)
- WebSearch: table_calendar performance with multi-year data — anecdotal reports, no benchmarks. Likely fine since only visible month is rendered and eventLoader is called per-day.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — table_calendar is the dominant Flutter calendar widget; NavigationBar/NavigationDrawer are Flutter SDK M3 components; pattern is well-established
- Architecture: HIGH — per-cell decoration model, reactive stream pipeline, and tab shell are standard Flutter patterns; codebase already has the reactive foundation (watchPeriodsWithDays)
- Pitfalls: HIGH — datetime normalization and connected-band rendering are known Flutter calendar challenges with documented solutions

**Research date:** 2026-04-06
**Valid until:** 2026-05-06 (30 days — stable ecosystem, no breaking changes expected)

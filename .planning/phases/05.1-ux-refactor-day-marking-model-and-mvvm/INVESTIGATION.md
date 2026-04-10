# UX & Architecture Investigation

**Date:** 2026-04-06
**Scope:** Period logging UX, calendar day interactions, MVVM refactor

---

## 1. Current State: How It Works Today

### 1.1 Data Model

Two tables drive everything:

- **`periods`**: `id`, `startUtc` (required), `endUtc` (nullable).
  When `endUtc` is null, the period is "open" (ongoing) and the calendar band
  extends implicitly through today.
- **`day_entries`**: `id`, `periodId` (FK → periods), `dateUtc`,
  optional `flowIntensity`, `painScore`, `mood`, `notes`.

A "period" is an explicit span the user creates by choosing "Start new period"
and optionally later choosing "End period." Day entries are children of a
period and are optional — a period can exist as a bare start/end span with zero
day entries.

### 1.2 Calendar Visualization

| Visual | Meaning |
|--------|---------|
| Solid pink pill band | Logged period (shape varies: start/middle/end/single/row-wrap) |
| Hatched circle | Predicted period day (only on days not covered by a logged band) |
| Pink ring | Today (when not on a period band) |
| White outline on band | Today (when on a period band) |
| Small pink dot below number | Day has a `day_entry` with logged symptoms |

### 1.3 Day Tap Behavior (Current)

The calendar routes taps through two different entry points depending on
content:

```
Tap day
├── Blank day (no band, no prediction, no log)
│   └── Opens LoggingBottomSheet directly (skips detail sheet)
│
└── Any other day (has band, prediction, or log)
    └── Opens DayDetailSheet
        ├── Has day_entry → Logged page (view data, Edit, Delete log, Delete period)
        ├── Predicted day → Prediction card + "Log period start"
        ├── Band without entry → "Log this day", "Adjust period dates", "Delete period"
        └── Empty non-predicted → Placeholder "Opening log…" (swipe redirects)
```

### 1.4 Logging Bottom Sheet (Current)

The logging sheet serves five distinct purposes through mode flags:

| Mode | Trigger | What it does |
|------|---------|-------------|
| Create — start new | FAB or blank-day tap (no ongoing period) | Creates period with `startUtc`, `endUtc=null` |
| Create — log day | FAB (ongoing period detected) | Upserts `day_entry` on the open period |
| Create — end period | FAB (ongoing period, user picks "End" segment) | Sets `endUtc` on the open period |
| Edit period dates | "Adjust period dates" button | Changes `startUtc`/`endUtc` with orphan handling |
| Edit day entry | "Edit" on logged page | Updates existing `day_entry` fields |

When an ongoing period exists, the sheet shows a **3-way segmented control**:
"Start new" / "Log day" / "End [date]".

### 1.5 Architecture (Current)

```
main.dart
  └── constructs PtrackDatabase, PeriodRepository, PeriodCalendarContext
      └── passes them as constructor args through widget tree

Widget tree:
  PtrackApp → TabShell → HomeScreen / CalendarScreen
                │
                └── FAB → LoggingBottomSheet
                          CalendarScreen → DayDetailSheet → LoggingBottomSheet
```

**No ViewModels.** All state management lives in `StatefulWidget.State`:

- `CalendarScreen` holds a `StreamBuilder` on `watchPeriodsWithDays()` and
  computes prediction + day data map inside `build()`.
- `LoggingBottomSheet` manages its own `StreamSubscription` to detect ongoing
  periods, holds form state, handles save logic, orphan resolution dialogs,
  and navigation — all in one 1143-line State class.
- `HomeScreen` is a `StatelessWidget` with a `StreamBuilder` that computes
  prediction and cycle position on every rebuild.
- `DayDetailSheet` receives a snapshot of `allData` as a constructor arg
  (stale the moment data changes).

**Problems this causes:**
- Business logic (ongoing period detection, prediction, validation) is
  duplicated or scattered across widgets.
- Widgets are untestable without rendering the full UI.
- The `DayDetailSheet` works on a stale snapshot and cannot react to changes.
- Adding features means adding more mode flags and branches to already complex
  widget State classes.

---

## 2. Problems Identified

### 2.1 UX Problems

1. **"Start" and "End" period are artificial actions.** Users don't think
   "I'm starting a period" and "I'm ending a period." They think "I had my
   period on this day." The system should derive spans from marked days.

2. **Blank days bypass the detail sheet.** Tapping a blank day skips the
   day detail and goes straight to the logging sheet. Every other state opens
   the detail sheet first. This inconsistency confuses users.

3. **The logging sheet is overloaded.** It handles five conceptually different
   flows through mode flags and a 3-way segmented control. Cognitive load is
   high.

4. **No "end period" from the calendar.** The only way to end an ongoing
   period is through the FAB or logging sheet. There's no affordance on the
   actual period days to say "it ended here."

5. **Future days are not gated.** Tapping a future empty day opens the
   logging sheet, which then blocks future dates only in the date picker.
   The user lands on a form they can't use without changing the date.

6. **Predicted future days offer an action button.** A predicted day in the
   future shows "Log period start" — but you can't log future data.

7. **Open periods are confusing.** An open period extends through today
   implicitly. The user must remember to "end" it. If they forget, the band
   keeps growing indefinitely.

### 2.2 Architecture Problems

1. **No separation between UI logic and business logic.** Period detection,
   prediction computation, and validation all run inside widget `build()`
   or State methods.

2. **Duplicated logic.** `_ongoingUnclosedAsOfToday` is defined in the
   logging sheet. Calendar and home each independently compute prediction.

3. **Stale data in sheets.** `DayDetailSheet` receives `allData` once at
   construction time and never updates.

4. **Giant State classes.** `LoggingBottomSheet` is 1143 lines with 5 modes,
   form state, stream subscriptions, save logic, orphan dialogs, and
   navigation all interleaved.

5. **Constructor-prop drilling.** `repository`, `database`, and `calendar`
   are passed through 4 levels of widgets.

---

## 3. New Mental Model: Day-Marking

### 3.1 Core Principle

The user's only period-related action is a **toggle**: mark a calendar day as
a period day, or unmark it. The system derives contiguous period spans
automatically.

This matches how people actually think about it: "I had my period on Tuesday."
Not "I'm starting a period entity on Tuesday with a null end date."

### 3.2 How Spans Are Derived

When the user marks or unmarks a day, the system maintains the `periods` table:

| User action | System behavior |
|-------------|----------------|
| Mark a day **adjacent** to an existing period | **Extend** that period to include the new day |
| Mark a day that **bridges** two periods (fills a 1-day gap) | **Merge** the two periods into one |
| Mark an **isolated** day (no adjacent period) | **Create** a new single-day period (`start=end=day`) |
| Unmark a day at the **edge** of a period | **Shrink** the period by 1 day |
| Unmark a day in the **middle** of a period | **Split** into two separate periods |
| Unmark the **only** day of a single-day period | **Delete** the period entirely |

"Adjacent" means the previous or next calendar day. No gap tolerance — every
day on the band is explicitly claimed by the user.

### 3.3 No More Open Periods

With day-marking, there are no "open" periods. Every period has both `startUtc`
and `endUtc` set (they can be equal for single-day periods). The band shows
exactly the days the user marked. If today is day 3, the band shows days 1–3
because the user marked all three. Tomorrow, if they mark day 4, the system
extends the span to day 4.

This eliminates:
- The concept of `endUtc = null` (ongoing period)
- The implicit "band extends through today" rendering logic
- The need for "End period" as a user action
- The `_ongoingUnclosedAsOfToday` detection logic

### 3.4 Day Actions (New)

Every tap opens the day detail sheet. Actions depend on the day's state:

#### Empty day (today or past)

| Action | Outcome |
|--------|---------|
| **"I had my period"** | Day marked. System creates or extends a period span. |

Single button. Optionally opens the symptom form afterward.

#### Empty day (future)

No actions. Text: "Future dates — check back when this day arrives."

#### Predicted day (today or past)

| Action | Outcome |
|--------|---------|
| **"I had my period"** | Same as marking an empty day. Prediction replaced by actual data. |

Shows prediction info card for context above the button.

#### Predicted day (future)

No actions. Shows prediction info card. Text: "You can log this once the day arrives."

#### Period day — no symptoms logged (today or past)

| Action | Outcome |
|--------|---------|
| **"Add symptoms"** | Opens symptom form (flow/pain/mood/notes) for this day. |
| **"Remove this day"** | Unmarks the day. System shrinks/splits/deletes the period. |
| **"Delete entire period"** | Removes full contiguous span + all day entries. Confirmation required. |

#### Period day — with symptoms (today or past)

| Action | Outcome |
|--------|---------|
| **"Edit"** | Opens symptom form pre-filled with current values. |
| **"Clear symptoms"** | Removes symptom data. Day stays marked as period day. |
| **"Remove this day"** | Unmarks day + deletes symptoms. Warning shown. System adjusts span. |
| **"Delete entire period"** | Removes full span + all day entries. Confirmation required. |

### 3.5 Symptom Form

A focused, single-purpose bottom sheet:
- Flow intensity (segmented: Light / Medium / Heavy)
- Pain score (segmented: None / Mild / Moderate / Severe / Very Severe)
- Mood (choice chips)
- Notes (text field)
- Save / Cancel

No date picker. No period lifecycle controls. The date is fixed to the day
the user tapped.

### 3.6 FAB Behavior (New)

The FAB on the home screen becomes **"Mark today"**:
- If today is not yet marked → marks today as a period day (extends or creates
  span), then optionally opens symptom form.
- If today is already marked → opens symptom form for today (add or edit).

One tap, one outcome. No segmented control, no mode detection.

### 3.7 Home Screen Quick Actions

- **"I had my period today"** (if today not marked) → same as FAB.
- **"Add symptoms for today"** (if today marked, no entry) → opens symptom form.
- **"Edit today's log"** (if today marked + entry exists) → opens symptom form pre-filled.

### 3.8 Migration from Open Periods

Existing open periods (`endUtc = null`) are migrated by setting `endUtc` to
the latest of:
- The last `day_entry` date for that period, or
- Today's date (if no day entries exist).

This is a one-time data migration.

---

## 4. MVVM Architecture Refactor

### 4.1 Why MVVM

Flutter's [architecture guide](https://docs.flutter.dev/app-architecture)
recommends the MVVM pattern:
- **Model**: data layer (repositories, database, domain entities)
- **View**: widgets that render UI and delegate events to the ViewModel
- **ViewModel**: holds UI state, exposes commands, talks to the Model layer

Benefits for ptrack:
- Business logic moves out of widget State into testable ViewModels.
- ViewModels are unit-testable without rendering widgets.
- Widgets become thin: they read state and call commands.
- Shared state (e.g., current periods, prediction) lives in one place.

### 4.2 Proposed Layer Structure

```
apps/ptrack/lib/
├── main.dart                          # Bootstrap, DI setup
├── di/
│   └── service_locator.dart           # Lightweight DI (get_it or manual)
├── features/
│   ├── calendar/
│   │   ├── calendar_screen.dart       # View (widget)
│   │   ├── calendar_view_model.dart   # ViewModel (ChangeNotifier)
│   │   ├── calendar_day_data.dart     # UI model (unchanged)
│   │   ├── calendar_painters.dart     # Painters (unchanged)
│   │   └── day_detail_sheet.dart      # View (widget)
│   ├── home/
│   │   ├── home_screen.dart           # View
│   │   ├── home_view_model.dart       # ViewModel
│   │   ├── today_card.dart            # View component
│   │   └── cycle_position.dart        # Pure computation (unchanged)
│   ├── logging/
│   │   ├── symptom_form_sheet.dart    # View (simplified from logging_bottom_sheet)
│   │   └── symptom_form_view_model.dart
│   ├── shell/
│   │   └── tab_shell.dart             # View
│   ├── onboarding/                    # Unchanged
│   └── settings/                      # Unchanged
│
packages/ptrack_domain/lib/
├── src/
│   ├── period/
│   │   ├── period_models.dart         # PeriodSpan (endUtc now always non-null)
│   │   ├── day_marking.dart           # NEW: span derivation logic
│   │   ├── logging_types.dart
│   │   ├── period_validation.dart
│   │   └── cycle_length.dart
│   └── prediction/                    # Unchanged
│
packages/ptrack_data/lib/
├── src/
│   ├── repositories/
│   │   └── period_repository.dart     # + toggleDay, markDay, unmarkDay
│   ├── db/                            # + migration v2→v3 (close open periods)
│   └── prediction/                    # Unchanged
```

### 4.3 ViewModel Design

Each ViewModel is a `ChangeNotifier` that:
- Subscribes to repository streams on creation.
- Exposes read-only state properties.
- Exposes command methods that call the repository and update state.

#### CalendarViewModel

```dart
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel(this._repository, this._calendar);

  // State
  List<StoredPeriodWithDays> periods = [];
  Map<DateTime, CalendarDayData> dayDataMap = {};
  PredictionResult prediction = const PredictionInsufficientHistory(...);
  DateTime focusedMonth = DateTime.now();

  // Commands
  Future<void> togglePeriodDay(DateTime day) async { ... }
  void changeMonth(DateTime month) { ... }
}
```

#### HomeViewModel

```dart
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository, this._calendar);

  // State
  CyclePosition? cyclePosition;
  DayEntryData? todayEntry;
  bool isTodayMarked = false;

  // Commands
  Future<void> markToday() async { ... }
}
```

#### SymptomFormViewModel

```dart
class SymptomFormViewModel extends ChangeNotifier {
  SymptomFormViewModel(this._repository, {required this.day, this.existing});

  // State
  FlowIntensity? flowIntensity;
  PainScore? painScore;
  Mood? mood;
  String notes = '';
  bool isSaving = false;
  String? errorText;

  // Commands
  Future<bool> save() async { ... }
}
```

### 4.4 View Wiring

Widgets use `ListenableBuilder` (built into Flutter, no extra packages):

```dart
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key, required this.viewModel});
  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        // Pure rendering from viewModel.dayDataMap, viewModel.prediction, etc.
      },
    );
  }
}
```

### 4.5 Dependency Injection

Replace constructor-prop drilling with a lightweight service locator or
`InheritedWidget`:

```dart
// In main.dart — create once, provide to tree
final repository = PeriodRepository(database: db, calendar: calendar);
final calendarVm = CalendarViewModel(repository, calendar);
final homeVm = HomeViewModel(repository, calendar);

runApp(
  PtrackProviders(
    calendarViewModel: calendarVm,
    homeViewModel: homeVm,
    repository: repository,
    child: PtrackApp(...),
  ),
);
```

No heavy framework needed. `InheritedWidget` or a simple `get_it` setup
suffices for this app's scale.

### 4.6 Domain: Day-Marking Logic

New pure functions in `ptrack_domain` that compute span operations:

```dart
/// Given existing periods and a day to mark, returns the repository
/// operations needed (create, extend, merge).
DayMarkResult computeMarkDay(List<PeriodSpan> existing, DateTime day);

/// Given existing periods and a day to unmark, returns the repository
/// operations needed (shrink, split, delete).
DayUnmarkResult computeUnmarkDay(List<PeriodSpan> existing, DateTime day);
```

These are pure, deterministic, and fully unit-testable without any database.
The repository calls them and executes the resulting operations in a
transaction.

---

## 5. Migration Path

### 5.1 Database Migration (v2 → v3)

- Close all open periods: set `endUtc` = max(`day_entries.dateUtc`) or today.
- Add NOT NULL constraint to `endUtc` (or keep nullable but enforce in code
  for backward compat).
- No structural schema change to `day_entries` — they remain children of
  periods.

### 5.2 Incremental Refactor Order

The refactor can be done incrementally without rewriting everything at once:

1. **Domain first**: add `day_marking.dart` with pure span-derivation
   functions + tests. No UI changes yet.
2. **Repository**: add `markDay(DateTime)` and `unmarkDay(DateTime)` that
   use the domain functions internally. Keep existing methods for backward
   compat.
3. **ViewModels**: introduce `CalendarViewModel`, `HomeViewModel`,
   `SymptomFormViewModel`. Initially they wrap the existing repository
   streams.
4. **Views**: refactor widgets to use ViewModels via `ListenableBuilder`.
   Remove `StreamBuilder` and inline logic from widgets.
5. **Day detail sheet**: rewrite to use the new action model (toggle +
   symptoms). Remove the old logging bottom sheet modes.
6. **Close open periods migration**: schema v3 migration + close open periods.
7. **Remove dead code**: old `_SheetCreateIntent`, segmented control,
   `_ongoingUnclosedAsOfToday`, stale `allData` snapshot passing.

---

## 6. Summary

| Dimension | Current | Proposed |
|-----------|---------|----------|
| User action | "Start period" / "End period" / "Log day" | "I had my period" (toggle) |
| Period span | Explicit start + optional end, managed by user | Derived from marked days by the system |
| Open periods | Yes (`endUtc = null`, extends through today) | No — every period has explicit start and end |
| Calendar day tap | Inconsistent (blank → logging, others → detail) | Always opens day detail sheet |
| Future days | Reachable, then blocked in date picker | View-only, no action buttons |
| Logging sheet | 5 modes, 1143 lines, 3-way segmented control | Symptom form only (flow/pain/mood/notes) |
| Architecture | Logic in widget State, StreamBuilder, prop drilling | MVVM with ChangeNotifier ViewModels |
| Testability | Widget tests required for business logic | Unit tests on ViewModels and domain functions |

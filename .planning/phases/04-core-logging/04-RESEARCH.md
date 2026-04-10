# Phase 4: Core Logging - Research

**Researched:** 2026-04-05
**Domain:** Flutter UI (bottom sheets, forms, segmented buttons), Drift schema migration, per-day data modeling
**Confidence:** HIGH

## Summary

Phase 4 transforms the placeholder home screen into a usable daily-logging surface. The primary interaction is a FAB that opens a modal bottom sheet where users pick a date, mark period start/end, and optionally add per-day detail (flow intensity, pain score, mood, notes). A reverse-chronological period history list provides navigation to past entries for editing or deletion.

The key architectural extension is a new `DayEntries` Drift table for per-day symptom data (flow, pain, mood, notes) linked to the existing `Periods` table via a foreign key. This requires a v1→v2 schema migration that creates the new table and enables `PRAGMA foreign_keys`. The UI layer uses standard Material 3 widgets already available in Flutter's SDK: `showModalBottomSheet` with `showDragHandle`, `SegmentedButton<T>` for discrete selections, `TextFormField` for notes, and inline error text for validation.

**Primary recommendation:** Add a `DayEntries` table (FK→periods, date + nullable symptom columns), bump schema to v2 with `m.createTable()`, and build a single reusable bottom sheet widget for both new-entry and edit flows.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Primary action: floating action button (FAB) on the home screen, always visible
- FAB opens a bottom sheet (lightweight, doesn't lose home context)
- Date-first flow: user picks a date, then marks period start or end for that date
- Optional detail fields (flow, symptoms, notes) are visible but collapsed/optional below the date action in the same bottom sheet — user adds what they want without a separate step
- Flow intensity: 3 discrete levels (Light, Medium, Heavy) via segmented buttons, per-day granularity
- Pain score: 1–5 scale (None / Mild / Moderate / Severe / Very Severe)
- Mood: emoji row (5 faces), single-select per day; word chip option in settings for accessibility
- Notes: short multiline text field (2–3 visible lines, expandable, no hard character limit), one per day
- Navigating past entries: reverse-chronological list grouped by period (each period is a card/section); calendar deferred to Phase 5
- Editing: tap a day within period list → same bottom sheet pre-filled with existing data
- Deleting: users can delete an entire period or individual day entries; both require confirmation dialog
- Validation timing: hybrid — live/inline for end-before-start; overlap and duplicate-start checks run on save
- Overlap handling: block save with clear explanation; no merge option in Phase 4
- Future dates: blocked — only today and past dates allowed

### Claude's Discretion
- Exact bottom sheet layout, spacing, and typography
- Segmented button styling and color treatment
- Emoji set selection for mood (5 faces, specific emoji choice)
- Animation and transition details for bottom sheet open/close
- Loading and saving state indicators
- How the period list groups and renders day detail summaries
- Schema migration approach for new columns (flow, pain, mood, notes)

### Deferred Ideas (OUT OF SCOPE)
- Calendar view for navigating to past days — Phase 5
- Toggle between calendar view and list view — Phase 5
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LOG-01 | User can mark period start date (today or past) and add or edit end date later | Date-first bottom sheet flow; `PeriodRepository.insertPeriod` / `updatePeriod` already exist; future-date blocking via `showDatePicker` `lastDate: DateTime.now()` |
| LOG-02 | User can log flow intensity for days or span without making symptoms mandatory | `DayEntries` table with all symptom columns nullable; `SegmentedButton<FlowIntensity>` for the 3-level selector |
| LOG-03 | User can add or edit notes, pain score, and mood on relevant days | `DayEntries` table columns: `pain_score`, `mood`, `notes`; same bottom sheet for create and edit |
| LOG-04 | User can edit previously entered periods without corrupting adjacent cycle data | Existing `PeriodValidation.validateForSave` excludes the edited period's own row from the existing list; transaction-wrapped writes in `PeriodRepository.updatePeriod` |
| LOG-05 | App prevents impossible date ranges or flags them clearly | Hybrid validation: live inline `EndBeforeStart` via form state; on-save `OverlappingPeriod` / `DuplicateStartCalendarDay` via existing domain validation |
| LOG-06 | Entries save reliably and display in correct day context (retroactive entry supported) | Drift transaction-wrapped inserts; dates stored as UTC midnight for calendar-date fidelity; `DayEntries.dateUtc` keyed to the intended calendar day |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK | 3.41.2 (FVM) | UI framework | Project constraint; already pinned |
| Drift | ^2.28.1 | SQLite ORM + reactive streams | Already in `ptrack_data`; provides typed schema, transactions, migrations, `watch()` streams |
| Material 3 widgets | (SDK) | `SegmentedButton`, `showModalBottomSheet`, `FloatingActionButton`, `TextFormField` | No extra packages needed; standard M3 set |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| timezone | ^0.10.1 | IANA timezone lookup for `PeriodCalendarContext` | Already used for UTC→local date conversion in validation |
| mocktail | ^1.0.4 | Test mocking | Already used for `MockPeriodRepository` in widget tests |
| drift_dev | ^2.28.0 | Code generation for Drift tables | Dev dependency; run `dart run build_runner build` after table changes |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `SegmentedButton` | `ToggleButtons` | `ToggleButtons` is Material 2; `SegmentedButton` is the M3 successor with better theming |
| Separate `DayEntries` table | Add columns to `Periods` table | Periods table is period-level; per-day granularity for flow/mood requires a child table |
| `showModalBottomSheet` | Full-screen dialog / page push | Bottom sheet preserves home context (locked decision) and is lighter-weight |
| Manual `customStatement` migration | Drift `stepByStep` generator | Project doesn't use `build.yaml` databases config; manual `m.createTable()` inside `onUpgrade` is consistent with existing migration pattern and simpler for a single table addition |

**Installation:**
No new packages required. All widgets are in Flutter SDK; Drift is already a dependency.

## Architecture Patterns

### Existing Project Structure
```
apps/ptrack/lib/
├── features/
│   ├── onboarding/      # Screens + state (Phase 3)
│   └── settings/        # About screen
└── main.dart            # App shell, routing, DI

packages/ptrack_domain/lib/src/
├── period/              # PeriodSpan, PeriodValidation, CalendarDate, CycleLength
└── prediction/          # PredictionEngine, PredictionResult, ExplanationStep

packages/ptrack_data/lib/src/
├── db/                  # PtrackDatabase, tables, migrations
├── mappers/             # period_mapper.dart
├── repositories/        # PeriodRepository
└── prediction/          # PredictionCoordinator
```

### Pattern 1: New `DayEntries` Table (Data Layer)

**What:** A child table storing per-day symptom data linked to a period via foreign key.

**Schema:**
```dart
class DayEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get periodId => integer().references(Periods, #id)();
  DateTimeColumn get dateUtc => dateTime()();
  IntColumn get flowIntensity => integer().nullable()();
  IntColumn get painScore => integer().nullable()();
  IntColumn get mood => integer().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{periodId, dateUtc}];
}
```

**Why this design:**
- `periodId` FK links each day entry to its parent period — enables cascade delete and efficient queries
- `dateUtc` stores the calendar date as UTC midnight (`DateTime.utc(y, m, d)`) — consistent with existing `firstLogScreen` pattern
- Unique constraint on `(periodId, dateUtc)` prevents duplicate entries for the same day within a period
- All symptom columns are nullable — LOG-02 requires symptoms not be mandatory
- `flowIntensity` as `int` (1=Light, 2=Medium, 3=Heavy) maps to the enum, compact storage
- `painScore` as `int` (1–5) maps to the labeled scale
- `mood` as `int` (1–5) maps to the emoji/word index

**When to use:** Every time a user saves flow, pain, mood, or notes for a day within a period.

### Pattern 2: Domain Enums for Discrete Fields

**What:** Type-safe enums in `ptrack_domain` for flow, pain, mood values.

```dart
enum FlowIntensity { light, medium, heavy }

enum PainScore { none, mild, moderate, severe, verySevere }

enum Mood { veryBad, bad, neutral, good, veryGood }
```

**Why:** Enums provide compile-time safety, make `SegmentedButton<FlowIntensity>` type-safe, and centralize display label mapping. Store as `int` (index + 1) in the database; convert via `FlowIntensity.values[dbValue - 1]`.

### Pattern 3: Reusable Logging Bottom Sheet

**What:** A single `LoggingBottomSheet` widget used for both new entries and edits.

```dart
Future<void> showLoggingBottomSheet(
  BuildContext context, {
  required PeriodRepository repository,
  StoredPeriod? existingPeriod,
  DayEntry? existingDayEntry,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => LoggingBottomSheet(
      repository: repository,
      existingPeriod: existingPeriod,
      existingDayEntry: existingDayEntry,
      initialDate: initialDate,
    ),
  );
}
```

**Key parameters:**
- `isScrollControlled: true` — allows the sheet to expand for content
- `showDragHandle: true` — Material 3 drag indicator
- `useSafeArea: true` — avoids notch/system bar overlap
- Pre-filled `existingPeriod` / `existingDayEntry` → edit mode; null → create mode

### Pattern 4: Reactive Period List with Drift `watch()`

**What:** Use Drift's `watch()` to auto-update the period history list when data changes.

```dart
Stream<List<StoredPeriod>> watchPeriodsDescending() {
  final query = _db.select(_db.periods)
    ..orderBy([(t) => OrderingTerm.desc(t.startUtc)]);
  return query.watch().map((rows) => [
    for (final r in rows) StoredPeriod(id: r.id, span: periodRowToDomain(r)),
  ]);
}
```

**Why:** After saving/editing/deleting in the bottom sheet, the period list updates automatically without manual refresh. `StreamBuilder` in the widget tree consumes this stream.

### Pattern 5: Delete with Confirmation

**What:** `showDialog` with `AlertDialog` for delete confirmation, then Drift delete inside a transaction.

```dart
Future<bool> deletePeriod(int id) {
  return _db.transaction(() async {
    await (_db.delete(_db.dayEntries)..where((t) => t.periodId.equals(id))).go();
    final count = await (_db.delete(_db.periods)..where((t) => t.id.equals(id))).go();
    return count > 0;
  });
}
```

**Why:** Deleting a period must also remove its child day entries. Wrapping in a transaction ensures atomicity. The confirmation dialog is a UI concern handled before calling the repository method.

### Anti-Patterns to Avoid
- **Storing symptom data in the `Periods` table:** This only supports period-level granularity, not per-day. The CONTEXT explicitly requires per-day flow intensity.
- **Using `Navigator.push` for the logging form:** The user decision is a bottom sheet to preserve home context. Don't route to a new page.
- **Allowing future dates in the date picker:** The CONTEXT blocks future dates. Always set `lastDate: DateTime.now()` on `showDatePicker`.
- **Running overlap validation on every keystroke:** The CONTEXT specifies hybrid timing — only `EndBeforeStart` is live/inline; overlap checks run on save.
- **Enabling `multiSelectionEnabled` on mood `SegmentedButton`:** Mood is single-select per day.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date picker | Custom date input widget | `showDatePicker()` | Handles localization, accessibility, past/future bounds; already used in Phase 3 `FirstLogScreen` |
| Schema migration | Raw SQL `ALTER TABLE` | Drift `Migrator.createTable()` + `addColumn()` | Drift handles SQLite's 12-step alter procedure, generates typed companions, and ensures consistency |
| Reactive data updates | Manual `setState` + reload after save | Drift `watch()` streams + `StreamBuilder` | Drift auto-invalidates streams on write; no manual refresh logic needed |
| Segmented toggle | Custom row of `InkWell` chips | `SegmentedButton<T>` | M3-themed, accessible, handles selection state, supports icons + labels |
| Bottom sheet boilerplate | Custom overlay/animation | `showModalBottomSheet()` | Built-in barrier dismiss, drag-to-close, safe area, M3 shape/elevation |
| Confirmation dialog | Custom overlay | `showDialog` + `AlertDialog` | Standard M3 pattern, handles barrier, accessibility |

**Key insight:** Every UI component in this phase has a direct Material 3 SDK equivalent. No third-party UI packages are needed. The complexity lives in the data model and validation flow, not the widgets.

## Common Pitfalls

### Pitfall 1: Drift Code Generation Not Re-Run After Table Changes
**What goes wrong:** Adding `DayEntries` to `tables.dart` and `@DriftDatabase(tables: [Periods, DayEntries])` but forgetting `dart run build_runner build` → compile errors on `$DayEntriesTable`, companions, etc.
**Why it happens:** Drift relies on code generation; the `.g.dart` file must be regenerated.
**How to avoid:** Always run `dart run build_runner build --delete-conflicting-outputs` in `packages/ptrack_data` after any table or column change.
**Warning signs:** `Undefined class` or `The getter 'dayEntries' isn't defined` errors.

### Pitfall 2: Foreign Key Not Enforced at Runtime
**What goes wrong:** SQLite foreign keys are OFF by default. Inserting a `DayEntry` with a non-existent `periodId` silently succeeds.
**Why it happens:** SQLite requires `PRAGMA foreign_keys = ON` per connection.
**How to avoid:** Add `beforeOpen` callback to `MigrationStrategy`:
```dart
beforeOpen: (details) async {
  await customStatement('PRAGMA foreign_keys = ON');
},
```
**Warning signs:** Orphaned day entries after period deletion; no FK constraint errors in tests.

### Pitfall 3: Bottom Sheet State Loss on Keyboard Dismiss
**What goes wrong:** `showModalBottomSheet` rebuilds when keyboard appears/disappears, losing form state.
**Why it happens:** The sheet's content is a `StatefulWidget` but the `isScrollControlled` parameter and `Padding` with `MediaQuery.of(context).viewInsets.bottom` are needed to handle keyboard resize.
**How to avoid:** Use `isScrollControlled: true` and wrap content in `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))`. Keep form state in the `State` object, not derived from build context.
**Warning signs:** Notes field clears when tapping another field; date resets.

### Pitfall 4: Overlapping Period Check Fails for Open Periods During Edit
**What goes wrong:** User marks period start (open), then later adds end date via edit. The update validation must exclude the period being edited from the "existing" list.
**Why it happens:** If the edited period's own row is included in `existing`, it will overlap with itself.
**How to avoid:** The existing `PeriodRepository.updatePeriod` already excludes the edited row (`if (r.id != id)`). Ensure all edit paths go through `updatePeriod`, not `insertPeriod`.
**Warning signs:** "This overlaps with your period" error when trying to add an end date to an existing period.

### Pitfall 5: Date Stored as Local DateTime Instead of UTC Midnight
**What goes wrong:** `DateTime.now()` returns local time. If stored directly, the same calendar date can map to different UTC values across timezones, causing duplicate or missing entries.
**Why it happens:** Easy to forget the local→UTC conversion.
**How to avoid:** Always convert picker output to UTC midnight: `DateTime.utc(picked.year, picked.month, picked.day)`. The existing `FirstLogScreen._save()` already does this — follow the same pattern.
**Warning signs:** Day entries appearing on the wrong calendar date; duplicate key violations on `(periodId, dateUtc)`.

### Pitfall 6: Schema Migration Not Tested With v1 Fixture
**What goes wrong:** Migration code works for fresh databases but fails when upgrading from v1 (existing users).
**Why it happens:** `onCreate` creates all tables at current schema; `onUpgrade` only runs for existing databases.
**How to avoid:** Write a migration test that opens the existing `test/fixtures/ptrack_v1.sqlite`, upgrades to v2, and verifies the new table exists and old data is intact. The project already has this pattern in `migration_test.dart`.
**Warning signs:** App crashes on upgrade for users who installed before Phase 4.

## Code Examples

### Example 1: DayEntries Table Definition
```dart
// packages/ptrack_data/lib/src/db/tables.dart
import 'package:drift/drift.dart';

class Periods extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startUtc => dateTime()();
  DateTimeColumn get endUtc => dateTime().nullable()();
}

class DayEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get periodId => integer().references(Periods, #id)();
  DateTimeColumn get dateUtc => dateTime()();
  IntColumn get flowIntensity => integer().nullable()();
  IntColumn get painScore => integer().nullable()();
  IntColumn get mood => integer().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{periodId, dateUtc}];
}
```

### Example 2: Schema v1→v2 Migration
```dart
// packages/ptrack_data/lib/src/db/ptrack_database.dart
const int ptrackSupportedSchemaVersion = 2;

@DriftDatabase(tables: [Periods, DayEntries])
class PtrackDatabase extends _$PtrackDatabase {
  PtrackDatabase(super.e);

  @override
  int get schemaVersion => ptrackSupportedSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          assertSupportedSchemaUpgrade(
            fromVersion: from,
            toVersion: to,
            supported: ptrackSupportedSchemaVersion,
          );
          await customStatement('PRAGMA foreign_keys = OFF');
          await m.database.transaction(() async {
            if (from < 2) {
              await m.createTable(dayEntries);
            }
          });
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
```

### Example 3: SegmentedButton for Flow Intensity
```dart
// Source: Flutter SDK SegmentedButton API
SegmentedButton<FlowIntensity>(
  segments: const [
    ButtonSegment(
      value: FlowIntensity.light,
      label: Text('Light'),
    ),
    ButtonSegment(
      value: FlowIntensity.medium,
      label: Text('Medium'),
    ),
    ButtonSegment(
      value: FlowIntensity.heavy,
      label: Text('Heavy'),
    ),
  ],
  selected: _selectedFlow != null ? {_selectedFlow!} : {},
  onSelectionChanged: (Set<FlowIntensity> selection) {
    setState(() => _selectedFlow = selection.firstOrNull);
  },
  emptySelectionAllowed: true,
  showSelectedIcon: false,
)
```

### Example 4: Modal Bottom Sheet with Keyboard Handling
```dart
// Source: Flutter API showModalBottomSheet
showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: const LoggingBottomSheet(),
  ),
);
```

### Example 5: Drift Watch Stream in Repository
```dart
Stream<List<StoredPeriodWithDays>> watchPeriodsWithDays() {
  final periodsQuery = _db.select(_db.periods)
    ..orderBy([(t) => OrderingTerm.desc(t.startUtc)]);
  return periodsQuery.watch().asyncMap((periodRows) async {
    final result = <StoredPeriodWithDays>[];
    for (final row in periodRows) {
      final dayQuery = _db.select(_db.dayEntries)
        ..where((d) => d.periodId.equals(row.id))
        ..orderBy([(d) => OrderingTerm.asc(d.dateUtc)]);
      final days = await dayQuery.get();
      result.add(StoredPeriodWithDays(
        period: StoredPeriod(id: row.id, span: periodRowToDomain(row)),
        dayEntries: days,
      ));
    }
    return result;
  });
}
```

### Example 6: Delete with Confirmation Dialog
```dart
Future<void> _confirmDeletePeriod(BuildContext context, int periodId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete period?'),
      content: const Text(
        'This will permanently delete this period and all its daily entries.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await repository.deletePeriod(periodId);
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ToggleButtons` (M2) | `SegmentedButton<T>` (M3) | Flutter 3.7+ | Type-safe, themed, replaces M2 toggle row |
| Persistent bottom sheet | `showModalBottomSheet` with `showDragHandle` | Flutter 3.7+ | M3 spec; drag handle is standard |
| Manual SQL migrations | Drift `Migrator` + generated `stepByStep` | Drift 2.x | Typed, testable; project uses manual `onUpgrade` which is also supported |
| `setState` + manual reload | Drift `watch()` streams | Drift 1.x+ | Reactive; auto-invalidates after writes |

**Deprecated/outdated:**
- `ToggleButtons`: Still functional but not M3-themed. Use `SegmentedButton` instead.
- `showBottomSheet` (non-modal): Does not dim background or handle barrier tap. Use `showModalBottomSheet` for the logging flow.

## Open Questions

1. **Emoji set for mood**
   - What we know: 5 faces from negative to positive; word-chip alternative in settings
   - What's unclear: Exact Unicode emoji characters (e.g. 😢😟😐🙂😄 vs 😞😕😶🙂😊)
   - Recommendation: Claude's discretion per CONTEXT. Pick a standard 5-face set; easy to change later since it's a display concern, not stored data.

2. **DayEntry for non-period days**
   - What we know: LOG-03 says "relevant days"; CONTEXT ties logging to the period bottom sheet
   - What's unclear: Whether users might want to log mood/pain on days outside a period
   - Recommendation: For Phase 4, day entries are always linked to a period (non-nullable FK). If non-period day logging is needed later, the FK can be made nullable in a future migration.

3. **Period list performance with many entries**
   - What we know: List is reverse-chronological, expand to see days
   - What's unclear: Whether lazy loading is needed for 5+ years of history
   - Recommendation: For Phase 4, load all periods eagerly. `ListView.builder` with lazy item building is sufficient. Optimize in Phase 8 (NFR-01) if needed.

## Sources

### Primary (HIGH confidence)
- **Drift docs** — migration API: https://drift.simonbinder.eu/migrations/api/ — createTable, addColumn, foreign key patterns
- **Drift docs** — stream queries: https://drift.simonbinder.eu/dart_api/streams — watch(), watchSingle()
- **Drift docs** — writes: https://drift.simonbinder.eu/dart_api/writes/ — delete, deleteWhere
- **Flutter API** — `SegmentedButton<T>`: https://docs.flutter.dev/flutter/material/SegmentedButton-class.html — segments, selected, emptySelectionAllowed
- **Flutter API** — `showModalBottomSheet`: https://docs.flutter.dev/flutter/material/showModalBottomSheet.html — isScrollControlled, showDragHandle, useSafeArea
- **Flutter cookbook** — form validation: https://flutter.dev/cookbook/forms/validation — TextFormField validator pattern

### Secondary (MEDIUM confidence)
- **Existing codebase** (`ptrack_data`, `ptrack_domain`) — verified patterns for PeriodRepository, PeriodValidation, migration tests, mapper layer

### Tertiary (LOW confidence)
- None; all findings verified against official sources or existing codebase.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in project; no new dependencies
- Architecture: HIGH — data model extends existing Drift/repository pattern; UI uses standard M3 widgets
- Pitfalls: HIGH — verified against Drift docs (FK pragma, migration testing) and Flutter API (bottom sheet keyboard handling)
- Migration: HIGH — Drift migration API docs confirm `m.createTable()` for new tables in `onUpgrade`

**Research date:** 2026-04-05
**Valid until:** 2026-05-05 (stable stack; no fast-moving APIs)

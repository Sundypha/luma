---
phase: 18-diary-table-migration
plan: 05
subsystem: ui
tags: [flutter, diary, calendar, home, l10n, streams]

requires:
  - phase: 18-diary-table-migration
    provides: "DiaryRepository.watchAllEntries, StoredDiaryEntry, showDiaryFormSheet from 18-02/18-04"
provides:
  - "CalendarDayData.hasDiaryEntry merged from diary date set; primary dot + symptom dot side-by-side in strip"
  - "Calendar legend always shows diary swatch (EN/DE); prediction/fertility swatches unchanged when applicable"
  - "HomeViewModel.todayDiaryEntry + diaryRepository; Today card ListTile opens DiaryFormSheet for today"
  - "DiaryRepository composed in main.dart and passed TabShell → CalendarViewModel + HomeViewModel"
affects:
  - "18-06 day detail hub"
  - "18-07 diary tab"

tech-stack:
  added: []
  patterns:
    - "Diary presence on calendar: same bottom strip as symptom log marker; diary uses colorScheme.primary"
    - "Reactive diary: separate StreamSubscription on watchAllEntries in both VMs; UTC calendar-day keys"

key-files:
  created: []
  modified:
    - "apps/ptrack/lib/features/calendar/calendar_day_data.dart"
    - "apps/ptrack/lib/features/calendar/calendar_view_model.dart"
    - "apps/ptrack/lib/features/calendar/calendar_painters.dart"
    - "apps/ptrack/lib/features/calendar/calendar_screen.dart"
    - "apps/ptrack/lib/features/home/home_view_model.dart"
    - "apps/ptrack/lib/features/home/today_card.dart"
    - "apps/ptrack/lib/features/home/home_screen.dart"
    - "apps/ptrack/lib/features/shell/tab_shell.dart"
    - "apps/ptrack/lib/main.dart"
    - "apps/ptrack/lib/l10n/app_en.arb"
    - "apps/ptrack/lib/l10n/app_de.arb"
    - "apps/ptrack/lib/l10n/app_localizations*.dart"

key-decisions:
  - "Calendar confidence legend strip is always shown so the diary swatch is discoverable even when prediction and fertility legends are off"
  - "Home Today diary row is always visible under a Divider on every day state (unmarked, marked without log, with log)"

patterns-established:
  - "TabShell is composition root for DiaryRepository alongside PeriodRepository for tab VMs"

requirements-completed: [DIARY-04, DIARY-05]

duration: 35min
completed: 2026-04-14
---

# Phase 18 Plan 05: Calendar diary dot + Home Today shortcut Summary

**Calendar cells show a primary-color diary dot (alongside the symptom log chip when both apply), the legend always includes a diary entry line, and the Home Today card exposes a write/edit diary row that opens `DiaryFormSheet` for the current UTC calendar day.**

## Performance

- **Duration:** 35 min (approx.)
- **Started:** 2026-04-14T16:00:00Z (approx.)
- **Completed:** 2026-04-14T16:35:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 20+ (including generated l10n)

## Accomplishments

- Merged diary dates into `buildCalendarDayDataMap` via `diaryDates` set and `hasDiaryEntry` on each `CalendarDayData`.
- `CalendarViewModel` and `HomeViewModel` subscribe to `watchAllEntries`, normalize UTC calendar days, and cancel subscriptions in `dispose`.
- Calendar UI: diary dot in bottom strip; legend includes `calendarLegendDiaryEntry` (EN/DE).
- `main.dart` constructs `DiaryRepository`; `TabShell` requires and forwards it to both VMs.
- `TodayCard` diary shortcut with ARB `homeDiaryNewEntry` / `homeDiaryEditEntry`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Calendar diary dot — data, painter, legend** — `45ba856` (feat)
2. **Task 2: Home Today card diary shortcut row** — `c8012c6` (feat)

## Files Created/Modified

- `apps/ptrack/lib/features/calendar/calendar_day_data.dart` — `hasDiaryEntry`, `diaryDates` merge in day map builder.
- `apps/ptrack/lib/features/calendar/calendar_view_model.dart` — diary stream subscription and `_recompute` integration.
- `apps/ptrack/lib/features/calendar/calendar_painters.dart` — `_diaryDotChip`, bottom strip layout, legend diary row; `buildCalendarDayCell` takes `BuildContext`.
- `apps/ptrack/lib/features/calendar/calendar_screen.dart` — always-on legend padding; passes context into day cell builder.
- `apps/ptrack/lib/features/home/home_view_model.dart` — diary repository, `todayDiaryEntry`, stream handler.
- `apps/ptrack/lib/features/home/today_card.dart` — diary `ListTile` + `showDiaryFormSheet`.
- `apps/ptrack/lib/features/home/home_screen.dart` — wires `TodayCard` diary props.
- `apps/ptrack/lib/features/shell/tab_shell.dart` — `diaryRepository` constructor + VM wiring.
- `apps/ptrack/lib/main.dart` — `DiaryRepository` creation, `LumaApp` field, `TabShell` argument.
- `apps/ptrack/lib/l10n/*` — new ARB keys + generated Dart.
- Tests under `apps/ptrack/test/` — `MockDiaryRepository` / `TabShell` / `CalendarViewModel` / `DayDetailTestViewModel` updates; `logging_test` uses mock diary and `pumpAndSettle` after mark-day tap.

## Decisions Made

- Legend always rendered below the grid so users without predictions still see the diary meaning of the dot.
- Diary shortcut uses UTC calendar day from `DateTime.now().toUtc()` for consistency with diary storage keys.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Tests and shell required `DiaryRepository` on every `TabShell` / VM construction**

- **Found during:** Task 1 (test updates)
- **Issue:** New required constructor parameters broke widget and calendar tests.
- **Fix:** Added `MockDiaryRepository` with `watchAllEntries` → `Stream.value([])`; `DayDetailTestViewModel` forwards diary repo; `logging_test` uses mock (avoids Drift timer noise from a real repo in shell tests).
- **Files modified:** Multiple test files under `apps/ptrack/test/`
- **Verification:** `fvm flutter analyze` clean
- **Committed in:** `45ba856` (Task 1)

**2. [Rule 1 - Bug] `logging_test` pending timer after calendar mark-day tap**

- **Found during:** Full test run
- **Issue:** Test ended on `pump()` while async work from view models was still scheduling frames/timers.
- **Fix:** Use `pumpAndSettle()` after tapping **I had my period**.
- **Files modified:** `apps/ptrack/test/logging_test.dart`
- **Committed in:** `45ba856` (Task 1)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** No product behavior change beyond stabilizing tests.

## Issues Encountered

- Repeated `flutter test` on Windows occasionally hit `PathExistsException` copying `sqlite3.dll` into `build/native_assets` (tooling race). Clearing `build/` or a single test run after idle may be required locally.

## User Setup Required

None.

## Next Phase Readiness

- Calendar and Home surfaces expose diary presence and entry point; ready for **18-06** day-detail routing and **18-07** diary tab.

---

*Phase: 18-diary-table-migration*
*Completed: 2026-04-14*

## Self-Check: PASSED

- `18-05-SUMMARY.md` exists at `.planning/phases/18-diary-table-migration/18-05-SUMMARY.md`.
- Commits `45ba856`, `c8012c6`, `7da1a5c` present on branch `feat/18-01-diary-schema-migration`.

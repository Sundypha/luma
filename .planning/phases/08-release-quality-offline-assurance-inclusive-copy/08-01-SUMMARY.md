---
phase: 08-release-quality-offline-assurance-inclusive-copy
plan: 01
subsystem: ui
tags: [flutter, copy, accessibility, a11y, prediction, nfr]

requires:
  - phase: 07-app-protection-lock
    provides: Lock, export/import, calendar surfaces for consistent copy patterns
provides:
  - Impersonal prediction explanation strings without UTC jargon in user-visible text
  - Plain-language error surfaces for mark/save/export/import/symptom flows
  - IconButton tooltips on export wizard back and clear-password controls
affects:
  - 08-02-PLAN.md (performance; unrelated but same phase)
  - 08-03-PLAN.md (offline assurance)

tech-stack:
  added: []
  patterns:
    - "Prediction copy tested for forbidden phrases plus no first-person plural (we )"
    - "Unexpected errors map to short retry-oriented user messages"

key-files:
  created: []
  modified:
    - packages/ptrack_domain/lib/src/prediction/prediction_copy.dart
    - packages/ptrack_domain/test/prediction_copy_test.dart
    - apps/ptrack/lib/features/onboarding/first_log_screen.dart
    - apps/ptrack/lib/features/home/home_screen.dart
    - apps/ptrack/lib/features/calendar/day_detail_sheet.dart
    - apps/ptrack/lib/features/backup/import_view_model.dart
    - apps/ptrack/lib/features/backup/export_view_model.dart
    - apps/ptrack/lib/features/backup/export_wizard_screen.dart
    - apps/ptrack/lib/features/logging/symptom_form_view_model.dart
    - apps/ptrack/test/features/backup/export_view_model_test.dart
    - apps/ptrack/test/features/logging/symptom_form_view_model_test.dart

key-decisions:
  - "DayMarkFailure and generic catch paths show fixed user messages instead of raw reason or Exception.toString()"
  - "Domain tests use fvm flutter test for ptrack_domain (flutter_test), not dart test"

patterns-established:
  - "Icon-only controls: IconButton.tooltip for semantic label (export wizard gaps closed)"

requirements-completed: [NFR-05, NFR-07]

duration: 18min
completed: 2026-04-07
---

# Phase 8 Plan 1: Inclusive copy & accessibility labels Summary

**Prediction explanations and app errors use impersonal, jargon-free copy; export IconButtons gain tooltips; tests assert no “we ” in prediction text.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-04-07T00:00:00Z (approximate)
- **Completed:** 2026-04-07T00:18:00Z (approximate)
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Reworded `formatPredictionExplanation` step lines (cycles considered, insufficient history, high variability) to remove first-person plural and “UTC calendar days” from user-visible strings.
- Standardized first-log subtitle to “last period day”; replaced raw failure surfaces with short retry messages across home, first log, day detail, import/export run paths, and symptom form.
- Added `tooltip` to export wizard AppBar back and password-field clear `IconButton`s; verified all `IconButton` usages in `apps/ptrack/lib` include tooltips.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix identified copy issues and full string audit** — `7ac8e87` (feat)
2. **Task 2: Accessibility label audit on icon-only buttons** — `fb8c9f5` (feat)

**Plan metadata:** docs commit on branch (message: `docs(08-01): Complete inclusive copy and accessibility plan`)

## Files Created/Modified

- `packages/ptrack_domain/lib/src/prediction/prediction_copy.dart` — User-facing prediction step copy
- `packages/ptrack_domain/test/prediction_copy_test.dart` — Anti–first-person-plural assertion
- `apps/ptrack/lib/features/onboarding/first_log_screen.dart` — First-log copy and save error snackbar
- `apps/ptrack/lib/features/home/home_screen.dart` — Mark-today error snackbar
- `apps/ptrack/lib/features/calendar/day_detail_sheet.dart` — Mark/unmark failure snackbars
- `apps/ptrack/lib/features/backup/import_view_model.dart` — Generic import failure message
- `apps/ptrack/lib/features/backup/export_view_model.dart` — Generic export failure message
- `apps/ptrack/lib/features/backup/export_wizard_screen.dart` — IconButton tooltips
- `apps/ptrack/lib/features/logging/symptom_form_view_model.dart` — Save/clear error messages
- `apps/ptrack/test/features/backup/export_view_model_test.dart` — Expect new export error copy
- `apps/ptrack/test/features/logging/symptom_form_view_model_test.dart` — Expect new save error copy

## Decisions Made

- **Fixed error strings vs. raw reasons:** `DayMarkFailure.reason` and `catch (e) => e.toString()` were replaced with short, non-technical messages so users never see stack-style text (aligns with NFR-05/NFR-07).
- **Tests:** `ptrack_domain` uses `flutter_test`; verification uses `fvm flutter test test/prediction_copy_test.dart`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Tests expected previous exception-based error strings**

- **Found during:** Task 1 verification (`ExportViewModel`, `SymptomFormViewModel` tests)
- **Issue:** Unit tests asserted substring of `StateError` / `toString()` output after copy change
- **Fix:** Updated expectations to match new user-facing messages
- **Files modified:** `apps/ptrack/test/features/backup/export_view_model_test.dart`, `apps/ptrack/test/features/logging/symptom_form_view_model_test.dart`
- **Verification:** `fvm flutter test --no-pub` in `apps/ptrack`
- **Committed in:** `7ac8e87`

**2. [Rule 3 - Blocking] `fvm dart test` unavailable for ptrack_domain**

- **Found during:** Task 1 verification
- **Issue:** Package has `flutter_test` only; `dart test` fails without `package:test`
- **Fix:** Ran `fvm flutter test test/prediction_copy_test.dart --no-pub` in `packages/ptrack_domain`
- **Verification:** All prediction_copy tests pass
- **Committed in:** N/A (verification method only; documented here)

---

**Total deviations:** 2 auto-fixed (both blocking / test alignment)
**Impact on plan:** No scope change; keeps NFR-aligned copy and green CI.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 8 plan `08-02` (performance feel) and `08-03` (offline assurance) remain; this plan completes copy/a11y baseline for NFR-05/NFR-07.

---
*Phase: 08-release-quality-offline-assurance-inclusive-copy*
*Completed: 2026-04-07*

## Self-Check: PASSED

- `08-01-SUMMARY.md` present at `.planning/phases/08-release-quality-offline-assurance-inclusive-copy/08-01-SUMMARY.md`
- Task commits `7ac8e87`, `fb8c9f5` and docs closure present on branch (`git log --grep=08-01`)

---
phase: 13-pdf-export-of-period-statistics-and-details-user-selectable-if-all-or-none-goal-is-to-have-a-pdf-ready-for-a-physician-or-gynecologist
plan: 01
subsystem: pdf-export
tags: [flutter, pdf, printing, shared_preferences, tdd, period-tracking]

requires:
  - phase: 12-fertility-window
    provides: "Stable period/day domain models and app locale patterns for downstream PDF plans"

provides:
  - "PdfSectionConfig with three presets, per-section toggles, and SharedPreferences persistence (sections + range)"
  - "PdfReportData models for cycle stats, symptom distributions, day rows, notes, and cycle-length series"
  - "PdfDataCollector building report DTOs from StoredPeriodWithDays using domain cycle-length rules"

affects:
  - "13-02 PDF document builder"
  - "13-03 export UI and preview"

tech-stack:
  added: [pdf ^3.11.1, printing ^5.13.4]
  patterns:
    - "Immutable report DTOs in lib/features/pdf_export/"
    - "Collector as pure logic over in-memory period snapshots (no repository mock)"

key-files:
  created:
    - apps/ptrack/lib/features/pdf_export/pdf_section_config.dart
    - apps/ptrack/lib/features/pdf_export/pdf_report_data.dart
    - apps/ptrack/lib/features/pdf_export/pdf_data_collector.dart
    - apps/ptrack/test/features/pdf_export/pdf_data_collector_test.dart
    - apps/ptrack/test/features/pdf_export/pdf_section_config_test.dart
  modified:
    - apps/ptrack/pubspec.yaml
    - pubspec.lock
    - apps/ptrack/linux/flutter/generated_plugin_registrant.cc
    - apps/ptrack/linux/flutter/generated_plugins.cmake
    - apps/ptrack/macos/Flutter/GeneratedPluginRegistrant.swift

key-decisions:
  - "Period inclusion for stats uses period **start** calendar day within the configured inclusive UTC range (matches plan test spec; differs from overlap wording in the GREEN implementation notes)."
  - "Completed-cycle stats use consecutive **filtered** period starts with completedCycleBetweenStarts; average bleeding length uses inclusive **local** calendar days per PeriodCalendarContext."
  - "First-time loadSaved() returns full preset with default 12‑month window when no prefs exist; range is persisted alongside section names."

requirements-completed: [PDF-01, PDF-02, PDF-04, PDF-05]

patterns-established:
  - "Export prefs: keys pdf_export_sections, pdf_export_range_start_ms, pdf_export_range_end_ms"
  - "Top-level sectionsForPreset() for preset → section set mapping"

duration: 35min
completed: 2026-04-08
---

# Phase 13 Plan 01: PDF data pipeline summary

**PDF export foundation: section config with presets and persistence, typed report DTOs, and a tested PdfDataCollector that turns stored periods into cycle stats and symptom distributions for a date range.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-08T12:00:00Z (approx.)
- **Completed:** 2026-04-08T12:35:00Z (approx.)
- **Tasks:** 2 (+ docs commit)
- **Files modified:** 10 (7 in task 1 commit, 3 new in task 2 commit)

## Accomplishments

- Added `pdf` / `printing` dependencies and Linux/macOS plugin registration for `printing`.
- Implemented `PdfSectionConfig` (five sections, three presets, `loadSaved` / `save`, default full preset + 12‑month window).
- Defined `PdfReportData` and related immutable models for stats, distributions, day summaries, notes, and cycle-length entries.
- Implemented `PdfDataCollector.collect` with eleven automated tests covering filtering, stats, distributions, sorting, notes, and single-period edge cases.

## Task Commits

1. **Task 1: Add deps and create section config + report data models** — `6b7efbc` (feat)
2. **Task 2: TDD — PDF data collector with stats computation** — `81a61a4` (feat; tests and implementation together)
3. **Planning docs** — `docs(13-01): Complete PDF data pipeline plan` (SUMMARY, STATE, ROADMAP)

_TDD note: tests were written against the collector contract before the final implementation; RED and GREEN are combined in the task 2 commit for a single reviewable unit._

## Files Created/Modified

- `apps/ptrack/pubspec.yaml` — `pdf`, `printing` dependencies.
- `apps/ptrack/lib/features/pdf_export/pdf_section_config.dart` — sections, presets, prefs, range helpers.
- `apps/ptrack/lib/features/pdf_export/pdf_report_data.dart` — report DTOs.
- `apps/ptrack/lib/features/pdf_export/pdf_data_collector.dart` — aggregation and statistics.
- `apps/ptrack/test/features/pdf_export/pdf_data_collector_test.dart` — collector behavior tests.
- `apps/ptrack/test/features/pdf_export/pdf_section_config_test.dart` — preset / `fromPreset` tests.
- `pubspec.lock` — workspace lockfile after `flutter pub get`.
- `apps/ptrack/linux/flutter/generated_plugin_registrant.cc`, `generated_plugins.cmake`, `apps/ptrack/macos/Flutter/GeneratedPluginRegistrant.swift` — register `printing` plugin.

## Decisions Made

- Filter periods by **start date** within the export range (inclusive UTC calendar days), as specified in the plan’s test list, rather than span overlap (mentioned only in the implementation bullet).
- Compute bleeding duration with the same local-calendar inclusive semantics as the domain cycle helper, using [PeriodCalendarContext].
- Merge multiple non-empty notes on the same calendar day into one `NoteEntry` with newline-separated text.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as specified aside from intentional interpretation of date filtering (see Decisions).

### Process / scope notes

- **TDD commit split:** The plan’s RED-then-GREEN commits are folded into one **task 2** commit because the collector and tests land together as one reviewable change.
- **Extra tests:** `pdf_section_config_test.dart` added to satisfy the verification bullet on preset section sets (not listed as a separate artifact in the plan).

---

**Total deviations:** 2 process/documentation (no Rule 1–3 auto-fixes)
**Impact on plan:** No behavioral drift beyond clarifying start-date vs overlap filtering; deliverables match success criteria.

## Issues Encountered

- System `flutter` not on PATH; verification used `d:\CODE\ptrack\.fvm\flutter_sdk\bin\flutter.bat` — workspace FVM SDK 3.41.2.

## User Setup Required

None.

## Next Phase Readiness

- **13-02** can consume `PdfReportData`, `PdfSectionConfig`, and `PdfDataCollector` for PDF layout and localized strings.
- **13-03** can wire UI to persisted config and call the collector before building the document.

---

*Phase: 13-pdf-export*
*Completed: 2026-04-08*

## Self-Check: PASSED

- `FOUND: apps/ptrack/lib/features/pdf_export/pdf_data_collector.dart`
- `FOUND: apps/ptrack/test/features/pdf_export/pdf_data_collector_test.dart`
- `FOUND: .planning/phases/13-pdf-export-of-period-statistics-and-details-user-selectable-if-all-or-none-goal-is-to-have-a-pdf-ready-for-a-physician-or-gynecologist/13-01-SUMMARY.md`
- `FOUND: 6b7efbc`, `81a61a4` via `git merge-base --is-ancestor <hash> HEAD`; docs commit present when `git log -1 --oneline` shows `docs(13-01): Complete PDF data pipeline plan`

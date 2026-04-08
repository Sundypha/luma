---
phase: 13-pdf-export
plan: 02
subsystem: ui
tags: [flutter, pdf, intl, l10n, arb]

# Dependency graph
requires:
  - phase: 13-01
    provides: PdfReportData, PdfSectionConfig, PdfDataCollector
provides:
  - PdfDocumentBuilder producing multi-page clinician-oriented PDF bytes
  - PdfContentStrings + AppLocalizations.toPdfContentStrings() bridge
  - EN/DE ARB keys for all PDF-visible strings (pdf* prefix)
affects:
  - 13-03-export-ui-preview-share

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "PDF layout via package:pdf MultiPage + TableHelper + Chart/BarDataSet"
    - "Copy-free PDF strings via PdfContentStrings populated from AppLocalizations"

key-files:
  created:
    - apps/ptrack/lib/features/pdf_export/pdf_document_builder.dart
  modified:
    - apps/ptrack/lib/l10n/app_en.arb
    - apps/ptrack/lib/l10n/app_de.arb
    - apps/ptrack/lib/l10n/app_localizations.dart
    - apps/ptrack/lib/l10n/app_localizations_en.dart
    - apps/ptrack/lib/l10n/app_localizations_de.dart

key-decisions:
  - "Footer combines brand line, generation date (UTC calendar), and page x/y via MultiPage footer context."
  - "Cycle chart uses pw.BarDataSet on CartesianGrid; skipped when fewer than two cycle length points."
  - "l10n Dart files updated in-repo to match ARB (Flutter gen-l10n not available in executor PATH; output matches standard codegen)."

requirements-completed: [PDF-03, PDF-04, PDF-05, PDF-08]

# Metrics
duration: ~25min
completed: 2026-04-08
---

# Phase 13 Plan 02: PDF document builder Summary

**Multi-page A4 PDF renderer (`PdfDocumentBuilder`) with conditional sections, disclaimer, bar chart, tables, and full EN/DE `pdf*` ARB strings wired through `PdfContentStrings` and `toPdfContentStrings()`.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-04-08 (executor session)
- **Completed:** 2026-04-08
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Implemented `PdfDocumentBuilder.build` using `pdf` widgets: header, italic bordered disclaimer, overview (stats + distributions), cycle history table, optional bar chart, day summary table, notes log, and `pw.Footer` with page numbers.
- Added 40+ matching `pdf*` keys in `app_en.arb` / `app_de.arb` with ICU metadata for placeholders and plurals.
- Exposed `AppLocalizationsPdfExport.toPdfContentStrings()` for Plan 03 UI to build PDFs without hard-coded English in the layout layer.

## Task Commits

Each task was committed atomically:

1. **Task 1: PDF document builder with all content sections** — `e73aefa` (feat)
2. **Task 2: Add all PDF content ARB strings (EN + DE)** — `18e94c0` (feat)

**Plan metadata:** Same commit as `.planning/STATE.md` + `.planning/ROADMAP.md` update (`docs(13-02): Complete PDF document builder plan`).

## Files Created/Modified

- `apps/ptrack/lib/features/pdf_export/pdf_document_builder.dart` — `PdfContentStrings`, `PdfDocumentBuilder`, l10n extension, chart/tables/layout.
- `apps/ptrack/lib/l10n/app_en.arb` / `app_de.arb` — PDF copy and `@` metadata.
- `apps/ptrack/lib/l10n/app_localizations*.dart` — getters and plural methods aligned with ARB.

## Decisions Made

- Used `TableHelper.fromTextArray` (non-deprecated) for cycle history and day summary tables with alternating row shading.
- Used Unicode en dash `–` for empty day cells (not a language-specific word string).
- Manual sync of `app_localizations*.dart` to ARB where `flutter gen-l10n` could not be run in this environment; `dart analyze` on `lib/l10n` and `pdf_document_builder.dart` is clean.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as specified aside from environment notes below.

### Environment / verification notes

- `dart run tool/arb_de_key_parity.dart` failed locally because the workspace SDK constraint (Dart 3.11) exceeds the executor’s `dart` 3.9.0; **ARB parity was verified** with an equivalent Node key-diff (344 EN / 344 DE message keys).
- **`flutter gen-l10n`** was not invoked (Flutter not on PATH). Localization Dart files were updated to match the ARB additions in the same shape `gen-l10n` would emit.

**Impact on plan:** Deliverables match the plan; CI or a machine with Flutter 3.11+ should run `flutter gen-l10n` and `dart run tool/arb_de_key_parity.dart` to confirm in the canonical toolchain.

## Issues Encountered

None blocking.

## User Setup Required

None.

## Next Phase Readiness

- Plan **13-03** can call `PdfDocumentBuilder` with `PdfReportData`, `PdfSectionConfig`, and `AppLocalizations.of(context).toPdfContentStrings()`.

## Self-Check: PASSED

- `Test-Path apps/ptrack/lib/features/pdf_export/pdf_document_builder.dart` — FOUND
- `git log --oneline -5` includes `e73aefa`, `18e94c0`, and the `docs(13-02)` commit — FOUND
- ARB parity (Node) — PASSED (344/344 keys)

---
*Phase: 13-pdf-export · Plan: 02 · Completed: 2026-04-08*

---
phase: 14-remove-deprecated-fab
plan: 01
subsystem: ui
tags: [flutter, shell, l10n, widget-test]

requires:
  - phase: 13-pdf-export
    provides: stable shell; not structurally required for FAB removal
provides:
  - TabShell without global FAB
  - logging tests covering calendar sheet + Home without FloatingActionButton
affects: []

tech-stack:
  added: []
  patterns:
    - "Widget tests locate today's calendar cell via bold day Text in TableCalendar"

key-files:
  created: []
  modified:
    - apps/ptrack/lib/features/shell/tab_shell.dart
    - apps/ptrack/lib/l10n/app_en.arb
    - apps/ptrack/lib/l10n/app_de.arb
    - apps/ptrack/lib/l10n/app_localizations.dart
    - apps/ptrack/lib/l10n/app_localizations_en.dart
    - apps/ptrack/lib/l10n/app_localizations_de.dart
    - apps/ptrack/test/logging_test.dart

key-decisions:
  - "Mark-only coverage uses calendar day sheet ('I had my period') because Home Today CTA runs mark + optional symptom sheet in one async action (unlike the old FAB's mark-only first tap)."

patterns-established:
  - "findTodayCalendarDayCell: descendant of TableCalendar with Text.data == today's day and FontWeight.bold (disambiguates duplicate day numbers in grid)."

requirements-completed: []

duration: —
completed: 2026-04-08
---

# Phase 14 — Plan 01 summary

**Global FAB removed; logging tests and ARBs updated — Task 4 (human-verify) in `14-01-PLAN.md` still required before closing UXFAB-01/02.**

## Performance

- **Tasks automated:** 3 (shell, l10n, tests)
- **Checkpoint:** Task 4 human-verify pending

## Accomplishments

- `TabShell` no longer sets `floatingActionButton`; doc comment documents Home Today card + calendar day detail as logging entry points.
- Removed `fabTooltipMarkToday` / `fabTooltipAddSymptoms`; `flutter gen-l10n`; ARB parity script passes.
- `logging_test.dart` uses Today card CTAs, calendar + `I had my period`, bold today-cell finder, and asserts no `FloatingActionButton`.

## Self-Check

- [x] `cd apps/ptrack && fvm flutter test test/logging_test.dart` — pass
- [x] `fvm dart run tool/arb_de_key_parity.dart` (repo root) — pass
- [x] `fvm flutter analyze lib/features/shell/tab_shell.dart` — pass
- [ ] Plan Task 4 manual checklist — pending owner

## Follow-ups

- Type **approved** on Task 4 after device check, or file issues for gap closure.
- Then mark requirements **UXFAB-01** / **UXFAB-02** complete in `REQUIREMENTS.md`, check ROADMAP plan checkbox, and run phase verifier / `phase complete` as per GSD.

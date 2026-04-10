---
phase: 12-optional-fertility-window-estimator
plan: 02
subsystem: ui
tags: [flutter, shared_preferences, i18n, arb, bottom-sheet]

requires:
  - phase: 10-i18n-foundation
    provides: ARB + AppLocalizations pipeline
provides:
  - FertilitySettings SharedPreferences API and FertilitySettingsTile
  - Disclaimer and setup bottom sheets; full fertility ARB (en/de)
affects:
  - 12-03-PLAN (calendar/home visuals consume strings)
  - 12-04-PLAN (home suggestion; onFertilityToggled wiring)

tech-stack:
  added: []
  patterns:
    - "Opt-in: switch stays off until disclaimer + input complete"
    - "Cycle length from predictionCycleInputsFromStored; null override = follow history average when eligible"

key-files:
  created:
    - apps/ptrack/lib/features/settings/fertility_settings.dart
  modified:
    - apps/ptrack/lib/features/shell/tab_shell.dart
    - apps/ptrack/lib/l10n/app_en.arb
    - apps/ptrack/lib/l10n/app_de.arb
    - apps/ptrack/lib/l10n/app_localizations.dart
    - apps/ptrack/lib/l10n/app_localizations_en.dart
    - apps/ptrack/lib/l10n/app_localizations_de.dart

key-decisions:
  - "Manual localization Dart edits: flutter CLI not on PATH in executor environment; ARB is source of truth; run flutter gen-l10n locally to reconcile generated files if diffs appear."
  - "When ≥2 completed intervals and saved cycle length equals rounded average, persist null override so estimates can track history; otherwise persist explicit override."

patterns-established:
  - "FertilitySettingsTile mirrors MoodSettingsTile self-load; enable path is async gate without optimistic switch-on."

requirements-completed: [FERT-01, FERT-02, FERT-04]

duration: 45 min
completed: 2026-04-08
---

# Phase 12 Plan 02: Fertility settings and i18n strings Summary

**Opt-in fertile-window settings with SharedPreferences, disclaimer + setup bottom sheets, and full English/German ARB so later plans avoid merge conflicts on l10n.**

## Performance

- **Duration:** 45 min (estimated)
- **Started:** 2026-04-08T10:30:00Z
- **Completed:** 2026-04-08T11:30:00Z
- **Tasks:** 2
- **Files touched:** 7

## Accomplishments

- `FertilitySettings` with granular load/save for enabled, disclaimer, cycle override, luteal phase (5–20), suggestion dismissal.
- All fertility UI strings in `app_en.arb` / `app_de.arb` (informal German “du”), including placeholders for counts, dates, and day labels.
- `FertilitySettingsTile` + disclaimer sheet + input sheet; settings list placement after predictions with dividers; `onFertilityToggled` passed through for Plan 04.

## Task Commits

1. **Task 1: FertilitySettings model + persistence + ALL fertility ARB strings** — `0ad700d` (feat)
2. **Task 2: Settings tile + disclaimer sheet + input form + integrate into Settings screen** — `940a4a7` (feat)

**Plan metadata:** `docs(12-02): Complete fertility settings plan` (final commit on branch)

## Files Created/Modified

- `apps/ptrack/lib/features/settings/fertility_settings.dart` — persistence, history helper, sheets, tile
- `apps/ptrack/lib/features/shell/tab_shell.dart` — `_SettingsScreen` passes `repository`, `calendar`, fertility tile
- `apps/ptrack/lib/l10n/app_en.arb` / `app_de.arb` — fertility\* keys
- `apps/ptrack/lib/l10n/app_localizations*.dart` — generated API mirrored manually

## Decisions Made

- Regenerated localization Dart by hand when `flutter gen-l10n` was unavailable; developers should run `flutter gen-l10n` in `apps/ptrack` after pulling to ensure tooling output matches ARB.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Executor shell could not run `flutter gen-l10n`**
- **Found during:** Task 1 verification
- **Issue:** `flutter` not on PATH; `dart run` ARB parity tool failed (workspace SDK vs installed Dart)
- **Fix:** Updated `app_localizations*.dart` in lockstep with ARB placeholders
- **Files modified:** `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`
- **Verification:** `dart analyze` clean on changed Dart files
- **Committed in:** `0ad700d`

---

**Total deviations:** 1 auto-fixed (blocking environment)
**Impact on plan:** No product behavior change; CI/local Flutter should still run `flutter gen-l10n` and `tool/arb_de_key_parity.dart` when available.

## Issues Encountered

- Workspace vs terminal path sync initially hid new files from `git add`; writes targeted `D:/CODE/ptrack` explicitly so commits succeeded.

## User Setup Required

None.

## Next Phase Readiness

- Plan 03/04 can consume ARB keys without editing `app_en.arb` / `app_de.arb` for fertility copy.
- Wire `onFertilityToggled` in `tab_shell` when home/calendar VMs need refresh (Plan 04).

## Self-Check: PASSED

- `12-02-SUMMARY.md` present at `.planning/phases/12-optional-fertility-window-estimator/12-02-SUMMARY.md`
- Commits `0ad700d`, `940a4a7`, and docs commit above present in `git log --grep=12-02`

---
*Phase: 12-optional-fertility-window-estimator*
*Completed: 2026-04-08*

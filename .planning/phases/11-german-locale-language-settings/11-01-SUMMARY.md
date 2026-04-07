---
phase: 11-german-locale-language-settings
plan: 01
subsystem: i18n
tags: [flutter, gen-l10n, arb, de, intl]

requires:
  - phase: 10-internationalization-foundation
    provides: English ARB template, MaterialApp delegates, migrated strings in app_en.arb
provides:
  - Full German ARB (`app_de.arb`) with key and ICU placeholder parity to `app_en.arb`
  - Generated `AppLocalizations` for `de` and `en` plus smoke tests under `Locale('de')`
affects:
  - 11-02-PLAN (language settings wiring)
  - 11-03-PLAN (locale formatting and CI parity checks)

tech-stack:
  added: []
  patterns:
    - "Informal du in German UI; legal-weight disclaimers aligned with English intent (11-CONTEXT)"

key-files:
  created:
    - apps/ptrack/lib/l10n/app_de.arb
    - apps/ptrack/lib/l10n/app_localizations_de.dart
    - apps/ptrack/test/german_locale_smoke_test.dart
  modified:
    - apps/ptrack/lib/l10n/app_localizations.dart
    - apps/ptrack/lib/l10n/app_en.arb
    - apps/ptrack/l10n.yaml

key-decisions:
  - "Committed full `lib/l10n/` bundle (EN template, DE catalog, prediction_localizations bridge, l10n.yaml) in task 1 because the directory was previously uncommitted in this branch."

patterns-established:
  - "Widget tests that pin `Locale('de')` use the same delegate order as `main.dart` (AppLocalizations + Material + Widgets + Cupertino)."

requirements-completed: [I18N-03]

duration: 30min
completed: 2026-04-07
---

# Phase 11 Plan 01: German ARB catalog summary

**Complete German (`de`) ARB keyed to the English template, regenerated `AppLocalizations` with `de`/`en` support, and widget smoke tests that pump `TabShell` under `Locale('de')` without delegate failures.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-04-07 (execution session)
- **Completed:** 2026-04-07
- **Tasks:** 2
- **Files modified:** 8 (7 in task 1, 1 test file in task 2)

## Accomplishments

- Added `app_de.arb` with informal **du** tone, conversational cycle/symptom-adjacent copy where applicable, and careful handling of prediction/disclaimer strings.
- `flutter gen-l10n` produces `AppLocalizationsDe`, `supportedLocales` includes `de` and `en`, delegate resolves `de*` via language code.
- Automated tests load `MaterialApp` with `locale: Locale('de')`, exercise home (localized empty state) and navigation to the settings screen from the drawer.

## Task Commits

1. **Task 1: Create app_de.arb with full key parity** — `006e4ab` (feat)
2. **Task 2: Tests — German locale smoke** — `d7d0386` (test)

**Plan metadata:** Bundled in the `docs(11-01)` commit with STATE, ROADMAP, and REQUIREMENTS.

## Files Created/Modified

- `apps/ptrack/lib/l10n/app_de.arb` — German message catalog
- `apps/ptrack/lib/l10n/app_en.arb` — English template (canonical keys)
- `apps/ptrack/lib/l10n/app_localizations.dart` / `app_localizations_de.dart` / `app_localizations_en.dart` — codegen output
- `apps/ptrack/lib/l10n/prediction_localizations.dart` — maps domain copy to `AppLocalizations`
- `apps/ptrack/l10n.yaml` — gen-l10n configuration
- `apps/ptrack/test/german_locale_smoke_test.dart` — `de` locale smoke tests

## Decisions Made

- Included the entire `lib/l10n/` tree and `l10n.yaml` in the task 1 commit so the German catalog and English template ship together with deterministic codegen inputs.

## Deviations from Plan

None — plan executed as written.

## Issues Encountered

- `flutter analyze` exits non-zero on deprecation infos in `prediction_settings.dart` (pre-existing); no analyzer errors in new l10n or test files.

## User Setup Required

None.

## Next Phase Readiness

- Plan 02 can wire user-selected language and `MaterialApp` locale using the existing `AppLocalizations.supportedLocales`.
- Plan 03 can add CI ARB parity and locale-aware formatting; **native-speaker review** of `app_de.arb` is still recommended before release (called out in plan verification).

## Self-Check: PASSED

- `apps/ptrack/lib/l10n/app_de.arb` — FOUND
- `apps/ptrack/test/german_locale_smoke_test.dart` — FOUND
- Task commits `006e4ab`, `d7d0386` — FOUND on branch; docs commit with this SUMMARY — FOUND on branch

---
*Phase: 11-german-locale-language-settings*  
*Completed: 2026-04-07*

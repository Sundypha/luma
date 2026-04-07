---
phase: 11-german-locale-language-settings
plan: 02
subsystem: ui
tags: [flutter, i18n, shared_preferences, materialapp, l10n]

requires:
  - phase: 11-german-locale-language-settings
    provides: German ARB parity and gen-l10n (`11-01`)

provides:
  - User-selectable app language (follow device, English, German) with SharedPreferences persistence
  - Settings UI section with ARB-backed labels and restart snackbar
  - MaterialApp locale + localeListResolutionCallback wired from cold-start preference

affects:
  - 11-03-PLAN (locale formatting builds on active locale)
  - Any future settings or onboarding copy

tech-stack:
  added: []
  patterns:
    - Optional SharedPreferences injection on load/save for tests
    - ListTile + checkmark for selection (avoids deprecated RadioListTile on current SDK)

key-files:
  created:
    - apps/ptrack/test/features/settings/app_language_settings_test.dart
    - apps/ptrack/test/features/settings/app_language_settings_section_test.dart
    - apps/ptrack/test/main_luma_app_locale_test.dart
  modified:
    - apps/ptrack/lib/features/settings/app_language_settings.dart
    - apps/ptrack/lib/features/shell/tab_shell.dart
    - apps/ptrack/lib/main.dart
    - apps/ptrack/lib/l10n/app_en.arb
    - apps/ptrack/lib/l10n/app_de.arb
    - apps/ptrack/lib/l10n/app_localizations.dart
    - apps/ptrack/lib/l10n/app_localizations_en.dart
    - apps/ptrack/lib/l10n/app_localizations_de.dart

key-decisions:
  - "Used ListTile with trailing check icon instead of RadioListTile after analyzer flagged RadioListTile groupValue/onChanged deprecation on this SDK."
  - "Skip snackbar when tapping the already-selected language option."

patterns-established:
  - "AppLanguageSettings.load/save accept optional SharedPreferences for deterministic tests."

requirements-completed: [I18N-02]

duration: 38min
completed: 2026-04-07
---

# Phase 11 Plan 02: Language settings summary

**User-selectable app language with SharedPreferences, Settings section (ARB-backed), and MaterialApp locale wiring including follow-device resolution with silent English fallback.**

## Performance

- **Duration:** 38 min
- **Started:** 2026-04-07T22:00:00Z (approx.)
- **Completed:** 2026-04-07T22:38:00Z (approx.)
- **Tasks:** 3
- **Files modified:** 10 (3 new tests, 7 touched app/l10n files)

## Accomplishments

- Persisted `AppLanguagePreference` (`followDevice` / `english` / `german`) with default follow-device for new installs.
- Dedicated Settings block at top of list: system default → English → German, restart snackbar on real change.
- `main.dart` loads preference once at startup; both `MaterialApp` branches (`homeOverride` and production) share the same locale resolution.

## Task Commits

Each task was committed atomically:

1. **Task 1: App language preference model + persistence** — `30f5b20` (feat)
2. **Task 2: Settings UI + restart prompt** — `b7d21c3` (feat)
3. **Task 3: MaterialApp locale wiring** — `81b610c` (feat)

**Plan metadata:** (see final `docs(11-02)` commit after SUMMARY/state/roadmap)

## Files Created/Modified

- `apps/ptrack/lib/features/settings/app_language_settings.dart` — Enum, persistence, device resolution, `AppLanguageSettingsSection` UI.
- `apps/ptrack/lib/features/shell/tab_shell.dart` — Inserts language section above mood settings.
- `apps/ptrack/lib/main.dart` — Loads preference; `LumaApp` + `_localeFromPreference()` for both MaterialApps.
- `apps/ptrack/lib/l10n/app_*.arb` + generated localizations — New strings for section title, options, restart hint.
- Tests under `test/features/settings/` and `test/main_luma_app_locale_test.dart`.

## Decisions Made

- ListTile + checkmark selection UI to avoid deprecated `RadioListTile` APIs reported by `dart analyze` on this Flutter SDK.
- No snackbar when the user re-taps the already active language.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] RadioListTile deprecation on analyzer**
- **Found during:** Task 2 (Settings UI)
- **Issue:** `dart analyze` reported deprecated `groupValue` / `onChanged` on `RadioListTile`.
- **Fix:** Replaced with three `ListTile`s and a primary-colored `Icons.check` trailing icon for the active choice.
- **Files modified:** `apps/ptrack/lib/features/settings/app_language_settings.dart`, `apps/ptrack/test/features/settings/app_language_settings_section_test.dart`
- **Verification:** `dart analyze` clean for changed files.
- **Committed in:** `b7d21c3`

---

**Total deviations:** 1 auto-fixed (blocking / SDK API)
**Impact on plan:** Behavior matches plan (radio-style selection and visible current choice); implementation detail only.

## Issues Encountered

- **Flutter CLI** was not available in the agent shell (`flutter` not on `PATH`), so full `flutter test` / `flutter analyze` were not executed here. `dart analyze` was run on the app and changed files successfully. **Recommended:** run `cd apps/ptrack && flutter test` and `flutter analyze` locally before merge.

## User Setup Required

None.

## Next Phase Readiness

- **11-03** can assume language preference and MaterialApp locale behavior are in place for locale-aware formatting and CI ARB work.

---

*Phase: 11-german-locale-language-settings*  
*Completed: 2026-04-07*

## Self-Check: PASSED

- `apps/ptrack/lib/features/settings/app_language_settings.dart` — FOUND
- `apps/ptrack/test/main_luma_app_locale_test.dart` — FOUND
- Commits `30f5b20`, `b7d21c3`, `81b610c` — FOUND (`git log --oneline`)

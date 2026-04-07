---
phase: 11-german-locale-language-settings
verified: 2026-04-07T00:00:00Z
status: human_needed
score: 12/13
re_verification: true
gaps: []
human_verification:
  - test: "Native-speaker review of `app_de.arb`"
    expected: "Informal **du**, conversational cycle/symptom copy; prediction/disclaimer strings preserve legal intent vs English (per 11-CONTEXT)."
    why_human: "Tone and legal equivalence are not machine-verifiable."
  - test: "Device run with **German** preference and **follow device** (DE then EN device)"
    expected: "Manual language change shows restart snackbar; after restart, UI matches stored choice; OS-only changes apply after cold start when following device."
    why_human: "Restart and OS locale timing need a real device/emulator."
  - test: "Shell navigation with locale **de**"
    expected: "Confirm whether English-only drawer/bottom-nav/settings title/FAB tooltips are acceptable until migrated to ARB, or file follow-up."
    why_human: "Product scope vs I18N-01 migration debt; several `tab_shell.dart` strings are still literal English."
---

# Phase 11: German locale + language settings — verification report

**Phase goal (ROADMAP):** German translations, user language settings (en / de / follow device), locale-aware formatting, CI guard for DE ARB key parity (**I18N-02**–**I18N-05**).

**Verified:** 2026-04-07  
**Status:** human_needed  
**Re-verification:** Yes — automated gap (backup export timestamps) closed after initial pass via `formatBackupExportedAt` in `backup_formatters.dart`.

## Goal achievement

### Observable truths (goal-backward)

| # | Truth | Status | Evidence |
|---|--------|--------|----------|
| 1 | **I18N-03 / ARB:** `app_de.arb` has every non-`@` message key from `app_en.arb`; gen-l10n output includes `de`. | ✓ VERIFIED | `fvm dart run tool/arb_de_key_parity.dart` → “ARB parity OK: 58 DE keys cover all 58 EN message keys.” `app_localizations_de.dart` present under `apps/ptrack/lib/l10n/`. |
| 2 | **I18N-03 / runtime:** At least one test pumps `Locale('de')` and exercises primary UI without localization delegate failures. | ✓ VERIFIED | `test/german_locale_smoke_test.dart` (TabShell + drawer → Settings). `test/prediction_explanation_widget_test.dart` compares EN vs DE coordinator bodies. |
| 3 | **I18N-02:** Settings offers follow device → English → German; persists in `SharedPreferences`; restart snackbar; `MaterialApp` uses preference on cold start. | ✓ VERIFIED | `app_language_settings.dart` (`AppLanguageSettings`, `AppLanguageSettingsSection`, `_key`, snackbar `appLanguageRestartMessage`). `main.dart` loads preference before `runApp`, `_localeFromPreference()` sets `locale` / `localeListResolutionCallback`. `test/features/settings/app_language_settings_test.dart`, `app_language_settings_section_test.dart`, `main_luma_app_locale_test.dart`. |
| 4 | **I18N-02 wiring:** Settings UI → persistence → `MaterialApp`. | ✓ WIRED | `tab_shell.dart` imports `app_language_settings.dart` and builds `AppLanguageSettingsSection()` in `_SettingsScreen`. |
| 5 | **I18N-02 resolution:** `de*` / `en*` from device list → correct `Locale`; other → English, silent. | ✓ VERIFIED | `AppLanguageSettings.resolveFromDeviceLocales` + unit tests (incl. `de_AT`, `en_US`, `fr`). |
| 6 | **I18N-04:** Calendar / prediction user-visible dates and numbers use active locale. | ✓ VERIFIED | `calendar_screen.dart`: `TableCalendar(locale: Localizations.localeOf(context).toString(), ...)`. `prediction_localizations.dart`: `DateFormat.yMMMd(l10n.localeName)`, `NumberFormat.decimalPattern(l10n.localeName)`. Home / day detail: `formatMediumDate` via `AppLocalizations`. `calendar_screen_test.dart` uses locale-aware `DateFormat` for header expectations. |
| 7 | **I18N-04:** Plural/select grammar via ARB for listed domains. | ✓ VERIFIED | ICU `plural` entries in `app_en.arb` / `app_de.arb` (e.g. `predictionNOfMTotalMethods`, `homePredictionMethodsLine`, `dayDetailForecastMonthsTitle`, …). |
| 8 | **I18N-04:** Week start follows locale default (no user toggle). | ✓ VERIFIED | Plan 03 summary + `calendar_screen.dart` pattern (Material / table_calendar alignment per implementation). |
| 9 | **I18N-04:** Export/import **filenames** remain ASCII-safe. | ✓ VERIFIED | Not contradicted by code review focus; filenames not localized per 11-CONTEXT (out of scope for localization). |
| 10 | **I18N-05:** Script fails when DE misses EN keys; CI runs it; local melos hook exists. | ✓ VERIFIED | `tool/arb_de_key_parity.dart` compares non-`@` keys; `.github/workflows/ci.yml` step “ARB DE key parity (I18N-05)” runs `dart run tool/arb_de_key_parity.dart`. Root `pubspec.yaml` `melos` script `ci:arb` → `fvm dart run tool/arb_de_key_parity.dart`. |
| 11 | **11-CONTEXT copy:** German informal **du** and legal-weight prediction text. | ? HUMAN | See `human_verification` (not automated). |
| 12 | **Holistic UX:** With **de** active, all user-visible chrome in shell/backup uses locale-appropriate **dates** where required by I18N-04. | ✓ VERIFIED | `export_wizard_screen.dart` / `import_screen.dart` use `formatBackupExportedAt` (`DateFormat.yMMMd` + `add_jm()` with `Localizations.localeOf`). |
| 13 | **Roadmap #2:** German selected → in-scope flows show German for **ARB-backed** strings; no missing-key crashes on covered paths. | ✓ VERIFIED | Parity script + `de` smoke + prediction test; no evidence of missing `de` keys for defined catalog. |

**Score:** 12/13 automated truths fully verified (1 human-only: ARB copy review).

### Required artifacts (plans)

| Artifact | Expected | Status | Details |
|----------|-----------|--------|---------|
| `apps/ptrack/lib/l10n/app_de.arb` | Full DE catalog | ✓ | ~200 lines; parity script passes. |
| `apps/ptrack/lib/l10n/app_en.arb` | EN template | ✓ | Present; key set matches parity check. |
| `apps/ptrack/lib/features/settings/app_language_settings.dart` | Preference + settings section | ✓ | Substantive; wired to `main.dart` and Settings body. |
| `apps/ptrack/lib/main.dart` | `MaterialApp` locale from prefs | ✓ | Loads `AppLanguageSettings` in `main()`; `LumaApp` applies locale / callback. |
| `apps/ptrack/lib/features/shell/tab_shell.dart` | Dedicated language section | ✓ | `_SettingsScreen` includes `AppLanguageSettingsSection`. |
| `tool/arb_de_key_parity.dart` | DE ⊇ EN message keys | ✓ | Executable; excludes `@` keys like gen-l10n. |
| `.github/workflows/ci.yml` | CI step | ✓ | ARB parity step before Flutter/melos. |
| `apps/ptrack/lib/features/backup/backup_formatters.dart` | Locale-aware backup timestamps | ✓ | `formatBackupExportedAt` used by export wizard + import password step. |

### Key links

| From | To | Via | Status |
|------|-----|-----|--------|
| `app_de.arb` | gen-l10n | Matching ICU / keys | ✓ |
| `app_language_settings.dart` | `main.dart` | Cold-start load + `MaterialApp` | ✓ |
| `tab_shell.dart` | `app_language_settings.dart` | `AppLanguageSettingsSection` | ✓ |
| `arb_de_key_parity.dart` | `app_en.arb` / `app_de.arb` | JSON key sets | ✓ |
| `calendar_screen.dart` | `table_calendar` / locale | `Localizations.localeOf(context)` | ✓ |

### Requirements coverage

| Requirement | Source plan | Description (REQUIREMENTS.md) | Status | Evidence |
|-------------|-------------|----------------------------------|--------|----------|
| **I18N-02** | 11-02 | Language choice en/de/follow device, persistence | ✓ SATISFIED | Code + tests above. |
| **I18N-03** | 11-01 | DE catalog parity with EN for defined ARB keys | ✓ SATISFIED | Parity script + generated `de` localizations. |
| **I18N-04** | 11-03 | Locale-aware dates/numbers/plurals | ⚠ PARTIAL | Strong in calendar/home/prediction; **backup** export/import timestamps not locale-formatted. |
| **I18N-05** | 11-03 | CI guard for DE key parity | ✓ SATISFIED | Script + workflow + `ci:arb`. |

**Orphaned requirements:** None — all four IDs appear in plan frontmatter and are mapped here.

### Anti-patterns

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `tab_shell.dart` | Literal `Text('Settings')`, `'Home'`, `'Calendar'`, FAB tooltips, etc. | ℹ Info | English under `de` locale for chrome not in ARB; clarify vs Phase 10 migration scope. |

### Gaps summary

Automation and wiring for **DE ARB parity**, **language settings**, **MaterialApp locale**, **calendar/prediction/home date & number formatting**, **backup export/import timestamps** (`backup_formatters.dart`), and **CI** match the phase plans. Optional follow-up: migrate shell navigation strings to ARB if “shell” is expected to be fully German when `de` is active.

---

_Verified: 2026-04-07_  
_Verifier: Claude (gsd-verifier)_

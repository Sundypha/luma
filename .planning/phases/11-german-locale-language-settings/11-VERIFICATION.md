---
phase: 11-german-locale-language-settings
verified: 2026-04-07T12:00:00Z
status: complete
score: 12/13
re_verification: false
gaps: []
human_verification:
  - test: "Native-speaker review of `app_de.arb`"
    expected: "Informal **du**, conversational cycle/symptom copy; prediction/disclaimer strings preserve legal intent vs English (per 11-CONTEXT)."
    why_human: "Tone and legal equivalence are not machine-verifiable."
  - test: "Device run with **German** preference and **follow device** (DE then EN device)"
    expected: "Manual language change shows restart snackbar; after restart, UI matches stored choice; OS-only changes apply after cold start when following device."
    why_human: "Restart and OS locale timing need a real device/emulator."
---

# Phase 11: German locale + language settings — verification report

**Phase goal (ROADMAP):** German translations, user language settings (en / de / follow device), locale-aware formatting, CI guard for DE ARB key parity (**I18N-02**–**I18N-05**).

**Verified:** 2026-04-07  
**Status:** **complete** (engineering closure — optional native-speaker polish remains as above)  
**Re-verification:** Not required unless ARB or locale resolution changes materially.

## Goal achievement

### Observable truths (goal-backward)

| # | Truth | Status | Evidence |
|---|--------|--------|----------|
| 1 | **I18N-03 / ARB:** `app_de.arb` has every non-`@` message key from `app_en.arb`; gen-l10n output includes `de`. | ✓ VERIFIED | `fvm dart run tool/arb_de_key_parity.dart` → ARB parity OK (276 EN message keys, DE covers all). `app_localizations_de.dart` generated under `apps/ptrack/lib/l10n/`. |
| 2 | **I18N-03 / runtime:** At least one test pumps `Locale('de')` and exercises primary UI without localization delegate failures. | ✓ VERIFIED | `test/german_locale_smoke_test.dart` (TabShell + drawer → Settings). `test/prediction_explanation_widget_test.dart` compares EN vs DE coordinator bodies. |
| 3 | **I18N-02:** Settings offers follow device → English → German; persists in `SharedPreferences`; restart snackbar; `MaterialApp` uses preference on cold start. | ✓ VERIFIED | `app_language_settings.dart`, `main.dart`, tests: `app_language_settings_test.dart`, `app_language_settings_section_test.dart`, `main_luma_app_locale_test.dart`. |
| 4 | **I18N-02 wiring:** Settings UI → persistence → `MaterialApp`. | ✓ WIRED | `tab_shell.dart` includes `AppLanguageSettingsSection()` in `_SettingsScreen`. |
| 5 | **I18N-02 resolution:** `de*` / `en*` from device list → correct `Locale`; other → English, silent. | ✓ VERIFIED | `AppLanguageSettings.resolveFromDeviceLocales` + unit tests (incl. `de_AT`, `en_US`, `fr`). |
| 6 | **I18N-04:** Calendar / prediction user-visible dates and numbers use active locale. | ✓ VERIFIED | `calendar_screen.dart`: `TableCalendar(locale: ...)`. `prediction_localizations.dart`: `DateFormat` / `NumberFormat` with `l10n.localeName`. Day detail / Material date strings via `MaterialLocalizations` + ARB. |
| 7 | **I18N-04:** Plural/select grammar via ARB for listed domains. | ✓ VERIFIED | ICU `plural` / placeholders in `app_en.arb` / `app_de.arb` (prediction, home, day detail, dialogs, …). |
| 8 | **I18N-04:** Week start follows locale default (no user toggle). | ✓ VERIFIED | `calendar_screen.dart` + `table_calendar` / Material alignment per 11-CONTEXT. |
| 9 | **I18N-04:** Export/import **filenames** remain ASCII-safe. | ✓ VERIFIED | Filenames not localized (11-CONTEXT). |
| 10 | **I18N-05:** Script fails when DE misses EN keys; CI runs it; local melos hook exists. | ✓ VERIFIED | `tool/arb_de_key_parity.dart`; `.github/workflows/ci.yml`; root `pubspec.yaml` `melos` script `ci:arb`. |
| 11 | **11-CONTEXT copy:** German informal **du** and legal-weight prediction text. | ? HUMAN | Optional polish — see `human_verification`. |
| 12 | **Holistic UX:** With **de** active, in-scope chrome uses locale-appropriate **dates** where I18N-04 requires. | ✓ VERIFIED | Backup export/import timestamps: `backup_formatters.dart` / `formatBackupExportedAt` with `Localizations.localeOf`. |
| 13 | **Roadmap:** German selected → primary flows use **ARB-backed** strings; flow/pain/mood **values** localized via `logging_localizations.dart` (not domain `.label`). | ✓ VERIFIED | Shell, lock, backup, onboarding, about, symptom form, day detail, first log, mood/prediction settings, today card; `fvm flutter test` green. |

**Score:** 12/13 automated truths verified; row 11 is optional human copy review.

### Primary surfaces (ARB + wiring)

| Area | Notes |
|------|--------|
| `tab_shell.dart` | Drawer, bottom nav, FAB tooltips, settings title — `AppLocalizations`. |
| Lock stack | Screens, PIN, biometrics copy, settings tile. |
| Backup / import / export | Wizards, errors via typed kinds + ARB. |
| Calendar | `day_detail_sheet.dart`, prediction card strings. |
| Logging | `symptom_form_sheet.dart`; enum display via `logging_localizations.dart`. |
| Home | `today_card.dart` (flow/pain/mood lines localized). |
| Onboarding | `onboarding_*`, `first_log_screen.dart`. |
| Settings | About, mood tile, prediction settings (algorithm names + hints). |

### Artifacts

| Artifact | Status |
|----------|--------|
| `apps/ptrack/lib/l10n/app_en.arb` / `app_de.arb` | ✓ Parity enforced |
| `apps/ptrack/lib/l10n/logging_localizations.dart` | ✓ Flow / pain / mood enum → `AppLocalizations` |
| `apps/ptrack/lib/l10n/app_localizations*.dart` | ✓ Generated (`fvm flutter gen-l10n`) |
| `apps/ptrack/l10n.yaml` | ✓ |
| `tool/arb_de_key_parity.dart` | ✓ |
| Language settings + `main.dart` | ✓ |

### Requirements coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **I18N-02** | ✓ SATISFIED | Preference, persistence, `MaterialApp`, tests. |
| **I18N-03** | ✓ SATISFIED | Full DE catalog + gen-l10n + parity CI. |
| **I18N-04** | ✓ SATISFIED | Dates, numbers, plurals, week start, backup timestamps locale-aware. |
| **I18N-05** | ✓ SATISFIED | Parity script + workflow + melos. |

---

_Phase closed (engineering): 2026-04-07_

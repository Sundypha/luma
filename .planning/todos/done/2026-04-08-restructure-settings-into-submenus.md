---
created: 2026-04-08T12:22:31.610Z
title: Restructure settings into submenus
area: ui
files:
  - apps/ptrack/lib/features/shell/tab_shell.dart
  - apps/ptrack/lib/features/settings/app_language_settings.dart
  - apps/ptrack/lib/features/settings/prediction_settings.dart
  - apps/ptrack/lib/features/settings/fertility_settings.dart
  - apps/ptrack/lib/features/settings/mood_settings.dart
  - apps/ptrack/lib/features/lock/lock_settings_tile.dart
  - apps/ptrack/lib/features/backup/data_settings_screen.dart
  - apps/ptrack/lib/l10n/app_en.arb
  - apps/ptrack/lib/l10n/app_de.arb
---

## Problem

The main settings surface should be reorganized into clear submenus instead of a flat list. Today, language choices and other items sit at the top level (see `_SettingsScreen` in `tab_shell.dart`). Product requirements:

1. **Main menu** should only expose four submenu entries: **Language**, **Period Prediction**, **Fertility Prediction**, and **Privacy & Security** (each navigates to a dedicated screen or nested list).

2. **Remove** the **“Use word labels for mood”** setting (`mood_settings.dart`, ARB keys `moodSettingsWordLabels*`). The UI now shows emoji and word label together, so the preference and any `SharedPreferences` / consumer logic tied to it should be removed or migrated so nothing depends on it.

3. **Fertility Prediction** submenu: add a **master toggle** to enable/disable the fertility feature. The **bottom sheet / drawer** that appears when enabling fertility today should be **replaced or complemented** by **persistent settings** inside this submenu so users can adjust fertility-related options **without** turning the feature off first.

4. **Language** submenu: **System default**, **English**, and **German** must appear **inside** the Language submenu, not as top-level tiles on the main settings screen.

## Solution

TBD. Likely: new routes or push screens under settings; group existing `AppLanguageSettingsSection` into a Language screen; keep `PredictionSettingsTile` flow under Period Prediction; consolidate fertility toggle + post-disclaimer form fields into `fertility_settings` (or new screen); group `LockSettingsTile`, backup/export (`DataSettingsScreen`), and related under Privacy & Security. Strip mood word-label preference end-to-end (prefs, UI, tests, ARB after `flutter gen-l10n`). Verify `tab_shell` / VMs still receive fertility-enabled updates as today.

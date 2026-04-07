import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-selected UI language, persisted across cold starts.
///
/// When [followDevice] is selected, the effective locale is derived from the
/// OS locale list on each process start only; mid-session OS language changes
/// are not applied until the next cold start.
enum AppLanguagePreference { followDevice, english, german }

/// Load/save [AppLanguagePreference] and map it to [MaterialApp] locale behavior.
class AppLanguageSettings {
  AppLanguageSettings._();

  static const _key = 'app_language_preference';

  static AppLanguagePreference _parseStored(String? raw) {
    if (raw == AppLanguagePreference.english.name) {
      return AppLanguagePreference.english;
    }
    if (raw == AppLanguagePreference.german.name) {
      return AppLanguagePreference.german;
    }
    return AppLanguagePreference.followDevice;
  }

  static Future<AppLanguagePreference> load({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return _parseStored(p.getString(_key));
  }

  static Future<void> save(
    AppLanguagePreference value, {
    SharedPreferences? prefs,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(_key, value.name);
  }

  /// Explicit locale for [MaterialApp.locale], or `null` to defer to the device
  /// (with [resolveFromDeviceLocales] via [MaterialApp.localeListResolutionCallback]).
  static Locale? materialAppLocale(AppLanguagePreference preference) {
    return switch (preference) {
      AppLanguagePreference.followDevice => null,
      AppLanguagePreference.english => const Locale('en'),
      AppLanguagePreference.german => const Locale('de'),
    };
  }

  /// Picks a supported app locale from the platform locale list (`de*` → German,
  /// `en*` → English, anything else → English) with no user-visible fallback message.
  static Locale resolveFromDeviceLocales(List<Locale>? locales) {
    if (locales == null || locales.isEmpty) {
      return const Locale('en');
    }
    for (final locale in locales) {
      final code = locale.languageCode.toLowerCase();
      if (code.startsWith('de')) return const Locale('de');
      if (code.startsWith('en')) return const Locale('en');
    }
    return const Locale('en');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/settings/app_language_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLanguageSettings', () {
    test('load defaults to followDevice when key missing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(await AppLanguageSettings.load(prefs: prefs),
          AppLanguagePreference.followDevice);
    });

    test('save and load round-trip', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await AppLanguageSettings.save(AppLanguagePreference.german, prefs: prefs);
      expect(await AppLanguageSettings.load(prefs: prefs),
          AppLanguagePreference.german);
      await AppLanguageSettings.save(AppLanguagePreference.english, prefs: prefs);
      expect(await AppLanguageSettings.load(prefs: prefs),
          AppLanguagePreference.english);
    });

    test('unknown stored value falls back to followDevice', () async {
      SharedPreferences.setMockInitialValues({
        'app_language_preference': 'nonsense',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(await AppLanguageSettings.load(prefs: prefs),
          AppLanguagePreference.followDevice);
    });

    test('materialAppLocale', () {
      expect(
        AppLanguageSettings.materialAppLocale(AppLanguagePreference.followDevice),
        isNull,
      );
      expect(
        AppLanguageSettings.materialAppLocale(AppLanguagePreference.english),
        const Locale('en'),
      );
      expect(
        AppLanguageSettings.materialAppLocale(AppLanguagePreference.german),
        const Locale('de'),
      );
    });

    test('resolveFromDeviceLocales maps de and en variants', () {
      expect(
        AppLanguageSettings.resolveFromDeviceLocales(
          const [Locale('de', 'AT')],
        ),
        const Locale('de'),
      );
      expect(
        AppLanguageSettings.resolveFromDeviceLocales(
          const [Locale('en', 'US')],
        ),
        const Locale('en'),
      );
      expect(
        AppLanguageSettings.resolveFromDeviceLocales(
          const [Locale('fr')],
        ),
        const Locale('en'),
      );
      expect(
        AppLanguageSettings.resolveFromDeviceLocales(null),
        const Locale('en'),
      );
      expect(
        AppLanguageSettings.resolveFromDeviceLocales([]),
        const Locale('en'),
      );
    });

    test('first supported locale in OS list wins', () {
      expect(
        AppLanguageSettings.resolveFromDeviceLocales(
          const [Locale('fr'), Locale('de')],
        ),
        const Locale('de'),
      );
      expect(
        AppLanguageSettings.resolveFromDeviceLocales(
          const [Locale('de'), Locale('en')],
        ),
        const Locale('de'),
      );
    });
  });
}

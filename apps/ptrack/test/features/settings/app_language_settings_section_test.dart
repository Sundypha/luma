import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/settings/app_language_settings.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('selecting German persists and shows restart snackbar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ListView(
            children: const [AppLanguageSettingsSection()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('German'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(
      await AppLanguageSettings.load(prefs: prefs),
      AppLanguagePreference.german,
    );
    expect(
      find.text('Restart the app to apply this change.'),
      findsOneWidget,
    );
  });

  testWidgets('stored English preference is selected in UI', (tester) async {
    SharedPreferences.setMockInitialValues({
      'app_language_preference': AppLanguagePreference.english.name,
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ListView(
            children: const [AppLanguageSettingsSection()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final englishRow = find.ancestor(
      of: find.text('English'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(
        of: englishRow,
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });
}

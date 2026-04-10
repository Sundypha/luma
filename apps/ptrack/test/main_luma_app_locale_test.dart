import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/settings/app_language_settings.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:luma/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LumaApp forces German locale when preference is german', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LumaApp(
        homeOverride: SizedBox(),
        appLanguagePreference: AppLanguagePreference.german,
      ),
    );
    await tester.pump();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('de'));
    expect(app.localeListResolutionCallback, isNull);
  });

  testWidgets('LumaApp followDevice uses callback for unsupported OS locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LumaApp(
        homeOverride: SizedBox(),
        appLanguagePreference: AppLanguagePreference.followDevice,
      ),
    );
    await tester.pump();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, isNull);
    expect(app.localeListResolutionCallback, isNotNull);
    final resolved = app.localeListResolutionCallback!(
      const [Locale('fr')],
      AppLocalizations.supportedLocales,
    );
    expect(resolved, const Locale('en'));
  });
}

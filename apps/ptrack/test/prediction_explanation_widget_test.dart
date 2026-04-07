import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:luma/l10n/prediction_localizations.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  testWidgets('renders coordinator explanation with approved estimate wording', (
    tester,
  ) async {
    final calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    final stored = [
      StoredPeriod(
        id: 1,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 5),
        ),
      ),
      StoredPeriod(
        id: 2,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 1, 29),
          endUtc: DateTime.utc(2026, 2, 2),
        ),
      ),
      StoredPeriod(
        id: 3,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 2, 26),
          endUtc: DateTime.utc(2026, 3, 2),
        ),
      ),
      StoredPeriod(
        id: 4,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 3, 26),
          endUtc: DateTime.utc(2026, 3, 30),
        ),
      ),
    ];

    final coordinator = PredictionCoordinator();
    final out = coordinator.predictNext(
      storedPeriods: stored,
      calendar: calendar,
    );

    late final String localizedBody;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            localizedBody = PredictionLocalizations.formatCoordinatorExplanation(
              l10n,
              result: out.result,
              steps: out.explanationSteps,
            );
            return Scaffold(
              body: SingleChildScrollView(
                child: Text(
                  localizedBody,
                  key: const Key('prediction_explanation'),
                ),
              ),
            );
          },
        ),
      ),
    );

    final text =
        tester.widget<Text>(find.byKey(const Key('prediction_explanation'))).data!;

    expect(text.trim(), isNotEmpty);
    expect(text.toLowerCase(), contains('estimate'));
    expect(text.toLowerCase(), isNot(contains('guarantee')));
    expect(out.result, isA<PredictionPointWithRange>());
    // Locale-aware yMMMd (en) — not raw ISO YYYY-MM-DD.
    expect(text, contains('2026'));
    expect(text, contains('23'));
    expect(text, contains('Apr'));
  });

  testWidgets('coordinator explanation differs for English vs German locale (dates/copy)',
      (tester) async {
    final calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    final stored = [
      StoredPeriod(
        id: 1,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 5),
        ),
      ),
      StoredPeriod(
        id: 2,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 1, 29),
          endUtc: DateTime.utc(2026, 2, 2),
        ),
      ),
      StoredPeriod(
        id: 3,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 2, 26),
          endUtc: DateTime.utc(2026, 3, 2),
        ),
      ),
      StoredPeriod(
        id: 4,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 3, 26),
          endUtc: DateTime.utc(2026, 3, 30),
        ),
      ),
    ];

    final coordinator = PredictionCoordinator();
    final out = coordinator.predictNext(
      storedPeriods: stored,
      calendar: calendar,
    );

    late final String englishBody;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            englishBody = PredictionLocalizations.formatCoordinatorExplanation(
              AppLocalizations.of(context),
              result: out.result,
              steps: out.explanationSteps,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    late final String germanBody;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            germanBody = PredictionLocalizations.formatCoordinatorExplanation(
              AppLocalizations.of(context),
              result: out.result,
              steps: out.explanationSteps,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(englishBody.trim(), isNotEmpty);
    expect(germanBody.trim(), isNotEmpty);
    expect(germanBody, isNot(equals(englishBody)));
  });
}

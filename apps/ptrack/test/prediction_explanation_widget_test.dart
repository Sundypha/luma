import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Text(
              out.explanationText,
              key: const Key('prediction_explanation'),
            ),
          ),
        ),
      ),
    );

    final text =
        tester.widget<Text>(find.byKey(const Key('prediction_explanation'))).data!;

    expect(text.trim(), isNotEmpty);
    expect(text.toLowerCase(), contains('estimate'));
    expect(text.toLowerCase(), isNot(contains('guarantee')));
    expect(out.result, isA<PredictionPointWithRange>());
    expect(text, contains('2026-03-26'));
  });
}

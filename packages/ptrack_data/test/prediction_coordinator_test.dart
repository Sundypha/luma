import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  late PeriodCalendarContext utcCtx;

  setUp(() {
    utcCtx = PeriodCalendarContext.fromTimeZoneName('UTC');
  });

  group('PredictionCoordinator', () {
    test('four closed periods (three cycle lengths) match engine point estimate', () {
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
      final direct = coordinator.predictNext(
        storedPeriods: stored,
        calendar: utcCtx,
      );

      final inputs = predictionCycleInputsFromStored(
        stored: stored,
        calendar: utcCtx,
      );
      final engineOnly = const PredictionEngine().predict(inputs);

      expect(direct.result, engineOnly.result);
      expect(
        direct.explanationSteps.map((e) => e.kind).toList(),
        engineOnly.explanation.map((e) => e.kind).toList(),
      );
      expect(direct.result, isA<PredictionPointWithRange>());
      final p = direct.result as PredictionPointWithRange;
      expect(p.pointStartUtc, DateTime.utc(2026, 3, 26));
      expect(
        direct.explanationSteps.map((e) => e.kind),
        containsAll([
          ExplanationFactKind.cyclesConsidered,
          ExplanationFactKind.medianCycleLength,
        ]),
      );
      expect(direct.explanationText.toLowerCase(), contains('estimate'));
      expect(direct.explanationText, contains('2026-03-26'));
    });

    test('skips same-local-day consecutive starts; uses next later local start', () {
      final la = PeriodCalendarContext.fromTimeZoneName('America/Los_Angeles');
      final stored = [
        StoredPeriod(
          id: 1,
          span: PeriodSpan(
            startUtc: DateTime.utc(2024, 6, 15, 8),
            endUtc: DateTime.utc(2024, 6, 17),
          ),
        ),
        StoredPeriod(
          id: 2,
          span: PeriodSpan(
            startUtc: DateTime.utc(2024, 6, 15, 20),
            endUtc: DateTime.utc(2024, 6, 18),
          ),
        ),
        StoredPeriod(
          id: 3,
          span: PeriodSpan(
            startUtc: DateTime.utc(2024, 7, 14, 12),
            endUtc: DateTime.utc(2024, 7, 16),
          ),
        ),
      ];

      final inputs = predictionCycleInputsFromStored(
        stored: stored,
        calendar: la,
      );

      expect(inputs, hasLength(1));
      expect(inputs.single.periodStartUtc, DateTime.utc(2024, 6, 15, 8));
      expect(inputs.single.lengthInDays, greaterThan(0));

      final coordinator = PredictionCoordinator();
      final out = coordinator.predictNext(storedPeriods: stored, calendar: la);
      // Only one usable cycle length after skipping the duplicate local-day start;
      // engine may still report insufficient history — must not throw.
      expect(out.result, isA<PredictionInsufficientHistory>());
    });

    test('open period at end excluded from cycle stats', () {
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
            endUtc: null,
          ),
        ),
      ];

      final coordinator = PredictionCoordinator();
      final out = coordinator.predictNext(
        storedPeriods: stored,
        calendar: utcCtx,
      );

      expect(out.result, isA<PredictionInsufficientHistory>());
      final inputs = predictionCycleInputsFromStored(
        stored: stored,
        calendar: utcCtx,
      );
      expect(inputs, hasLength(1));
    });
  });
}

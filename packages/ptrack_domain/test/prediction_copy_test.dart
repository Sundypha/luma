import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void _assertNoForbiddenPhrases(String text) {
  final lower = text.toLowerCase();
  for (final phrase in predictionCopyForbiddenPhrasesLowercase) {
    expect(lower, isNot(contains(phrase)), reason: 'forbidden: $phrase');
  }
}

void main() {
  final engine = PredictionEngine();

  group('prediction_copy PRED-04', () {
    test('forbidden phrases absent across representative narratives', () {
      final scenarios = <PredictionEngineResult>[
        engine.predict(const []),
        engine.predict([
          PredictionCycleInput(
            periodStartUtc: DateTime.utc(2026, 1, 1),
            lengthInDays: 28,
          ),
        ]),
        engine.predict([
          PredictionCycleInput(
            periodStartUtc: DateTime.utc(2026, 1, 1),
            lengthInDays: 28,
          ),
          PredictionCycleInput(
            periodStartUtc: DateTime.utc(2026, 1, 29),
            lengthInDays: 28,
          ),
          PredictionCycleInput(
            periodStartUtc: DateTime.utc(2026, 2, 26),
            lengthInDays: 28,
          ),
        ]),
      ];

      for (final s in scenarios) {
        final text = formatPredictionExplanation(
          result: s.result,
          steps: s.explanation,
        );
        _assertNoForbiddenPhrases(text);
        final lower = text.toLowerCase();
        expect(lower, isNot(contains('we ')),
            reason: 'no first-person plural in prediction copy');
        expect(lower, contains('estimate'));
      }
    });

    test('insufficient-history copy does not invent YYYY-MM-DD dates', () {
      final out = engine.predict([
        PredictionCycleInput(
          periodStartUtc: DateTime.utc(2026, 1, 1),
          lengthInDays: 28,
        ),
      ]);
      expect(out.result, isA<PredictionInsufficientHistory>());
      final text = formatPredictionExplanation(
        result: out.result,
        steps: out.explanation,
      );
      expect(
        RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(text),
        isFalse,
        reason: 'insufficient history should not surface calendar dates',
      );
    });
  });
}

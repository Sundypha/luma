import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void _assertNoForbiddenPhrases(String text) {
  final lower = text.toLowerCase();
  for (final phrase in predictionCopyForbiddenPhrasesLowercase) {
    expect(lower, isNot(contains(phrase)), reason: 'forbidden: $phrase');
  }
}

/// ISO-like YYYY-MM-DD anywhere in [s] without using a regex pattern.
bool _containsYyyyMmDdPattern(String s) {
  bool isDigit(int j) =>
      j >= 0 && j < s.length && s.codeUnitAt(j) >= 0x30 && s.codeUnitAt(j) <= 0x39;
  for (var i = 0; i <= s.length - 10; i++) {
    if (isDigit(i) &&
        isDigit(i + 1) &&
        isDigit(i + 2) &&
        isDigit(i + 3) &&
        s[i + 4] == '-' &&
        isDigit(i + 5) &&
        isDigit(i + 6) &&
        s[i + 7] == '-' &&
        isDigit(i + 8) &&
        isDigit(i + 9)) {
      return true;
    }
  }
  return false;
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

    test('fertility-related forbidden phrases are listed and detected', () {
      expect(
        predictionCopyForbiddenPhrasesLowercase,
        allOf(contains('safe days'), contains('birth control')),
      );
      expect(predictionCopyTextPassesGuard('These are safe days for you'), isFalse);
      expect(predictionCopyTextPassesGuard('Use this as birth control'), isFalse);
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
        _containsYyyyMmDdPattern(text),
        isFalse,
        reason: 'insufficient history should not surface calendar dates',
      );
    });
  });
}

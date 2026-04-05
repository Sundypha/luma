import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  group('FlowIntensity', () {
    test('has three values', () {
      expect(FlowIntensity.values, hasLength(3));
    });

    test('fromDbValue round-trips with dbValue', () {
      for (final e in FlowIntensity.values) {
        expect(FlowIntensity.fromDbValue(e.dbValue), e);
      }
    });

    test('fromDbValue(0) throws RangeError', () {
      expect(() => FlowIntensity.fromDbValue(0), throwsRangeError);
    });
  });

  group('PainScore', () {
    test('has five values', () {
      expect(PainScore.values, hasLength(5));
    });

    test('fromDbValue round-trips with dbValue', () {
      for (final e in PainScore.values) {
        expect(PainScore.fromDbValue(e.dbValue), e);
      }
    });

    test('fromDbValue(0) throws RangeError', () {
      expect(() => PainScore.fromDbValue(0), throwsRangeError);
    });

    test('compactLabel is short enough for tight UI', () {
      expect(PainScore.moderate.compactLabel, 'Mod.');
      expect(PainScore.verySevere.compactLabel, 'V. sev.');
    });
  });

  group('Mood', () {
    test('has five values', () {
      expect(Mood.values, hasLength(5));
    });

    test('fromDbValue round-trips with dbValue', () {
      for (final e in Mood.values) {
        expect(Mood.fromDbValue(e.dbValue), e);
      }
    });

    test('fromDbValue(0) throws RangeError', () {
      expect(() => Mood.fromDbValue(0), throwsRangeError);
    });
  });

  group('DayEntryData', () {
    final d = DateTime.utc(2024, 6, 15);

    test('equality when fields match', () {
      expect(
        DayEntryData(
          dateUtc: d,
          flowIntensity: FlowIntensity.medium,
          painScore: PainScore.mild,
          mood: Mood.good,
          notes: 'x',
        ),
        DayEntryData(
          dateUtc: d,
          flowIntensity: FlowIntensity.medium,
          painScore: PainScore.mild,
          mood: Mood.good,
          notes: 'x',
        ),
      );
    });

    test('inequality when any field differs', () {
      final base = DayEntryData(
        dateUtc: d,
        flowIntensity: FlowIntensity.light,
        painScore: PainScore.none,
        mood: Mood.neutral,
        notes: 'a',
      );
      expect(
        base,
        isNot(
          DayEntryData(
            dateUtc: DateTime.utc(2024, 6, 16),
            flowIntensity: FlowIntensity.light,
            painScore: PainScore.none,
            mood: Mood.neutral,
            notes: 'a',
          ),
        ),
      );
      expect(
        base,
        isNot(
          DayEntryData(
            dateUtc: d,
            flowIntensity: FlowIntensity.heavy,
            painScore: PainScore.none,
            mood: Mood.neutral,
            notes: 'a',
          ),
        ),
      );
      expect(
        base,
        isNot(
          DayEntryData(
            dateUtc: d,
            flowIntensity: FlowIntensity.light,
            painScore: PainScore.severe,
            mood: Mood.neutral,
            notes: 'a',
          ),
        ),
      );
      expect(
        base,
        isNot(
          DayEntryData(
            dateUtc: d,
            flowIntensity: FlowIntensity.light,
            painScore: PainScore.none,
            mood: Mood.veryGood,
            notes: 'a',
          ),
        ),
      );
      expect(
        base,
        isNot(
          DayEntryData(
            dateUtc: d,
            flowIntensity: FlowIntensity.light,
            painScore: PainScore.none,
            mood: Mood.neutral,
            notes: 'b',
          ),
        ),
      );
    });

    test('all-null optionals is valid and equal', () {
      final a = DayEntryData(dateUtc: d);
      final b = DayEntryData(dateUtc: d);
      expect(a, b);
    });
  });
}

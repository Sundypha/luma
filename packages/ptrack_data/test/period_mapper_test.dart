import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_data/src/db/ptrack_database.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  group('period mapper', () {
    test('row to domain preserves UTC instants', () {
      final start = DateTime.utc(2024, 2, 1, 12);
      final end = DateTime.utc(2024, 2, 6, 8);
      final row = Period(id: 1, startUtc: start, endUtc: end);
      final span = periodRowToDomain(row);
      expect(span.startUtc, start);
      expect(span.endUtc, end);
      expect(span.isCompleted, isTrue);
    });

    test('open period maps to domain with null end', () {
      final start = DateTime.utc(2024, 3, 10);
      final row = Period(id: 2, startUtc: start, endUtc: null);
      final span = periodRowToDomain(row);
      expect(span.startUtc, start);
      expect(span.endUtc, isNull);
      expect(span.isOpen, isTrue);
    });

    test('insert companion round-trip matches domain', () {
      final span = PeriodSpan(
        startUtc: DateTime.utc(2024, 4, 1),
        endUtc: DateTime.utc(2024, 4, 5),
      );
      final companion = periodSpanToInsertCompanion(span);
      expect(companion.startUtc.value, span.startUtc);
      expect(companion.endUtc.value, span.endUtc);

      final row = Period(
        id: 99,
        startUtc: companion.startUtc.value,
        endUtc: companion.endUtc.value,
      );
      expect(periodRowToDomain(row), span);
    });

    test('update companion carries span fields', () {
      final span = PeriodSpan(
        startUtc: DateTime.utc(2025, 1, 1),
        endUtc: null,
      );
      final companion = periodSpanToUpdateCompanion(span);
      expect(companion.startUtc.value, span.startUtc);
      expect(companion.endUtc.value, isNull);
    });
  });
}

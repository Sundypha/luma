import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  group('PeriodSpan.containsCalendarDayUtc', () {
    test('closed span is inclusive on start and end calendar days', () {
      final span = PeriodSpan(
        startUtc: DateTime.utc(2024, 3, 1),
        endUtc: DateTime.utc(2024, 3, 5),
      );
      expect(span.containsCalendarDayUtc(DateTime.utc(2024, 3, 1)), isTrue);
      expect(span.containsCalendarDayUtc(DateTime.utc(2024, 3, 5)), isTrue);
      expect(span.containsCalendarDayUtc(DateTime.utc(2024, 2, 28)), isFalse);
      expect(span.containsCalendarDayUtc(DateTime.utc(2024, 3, 6)), isFalse);
    });

    test('open span allows through todayLocal', () {
      final span = PeriodSpan(
        startUtc: DateTime.utc(2024, 1, 1),
        endUtc: null,
      );
      final today = DateTime(2024, 6, 15);
      expect(
        span.containsCalendarDayUtc(
          DateTime.utc(2024, 6, 15),
          todayLocal: today,
        ),
        isTrue,
      );
      expect(
        span.containsCalendarDayUtc(
          DateTime.utc(2024, 6, 16),
          todayLocal: today,
        ),
        isFalse,
      );
    });
  });
}

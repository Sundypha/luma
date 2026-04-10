import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  group('computeMarkDay', () {
    test('isolated day with no adjacent periods returns MarkCreate', () {
      final day = DateTime.utc(2024, 6, 15);
      final op = computeMarkDay([], day);
      expect(op, isA<MarkCreate>());
      expect((op as MarkCreate).day, DateTime.utc(2024, 6, 15));
    });

    test('MarkCreate uses UTC calendar date of input instant', () {
      final op = computeMarkDay([], DateTime.utc(2024, 6, 15, 22, 30));
      expect(op, isA<MarkCreate>());
      expect((op as MarkCreate).day, DateTime.utc(2024, 6, 15));
    });

    test('day inside existing period returns MarkNoOp', () {
      final periods = [
        SpanRecord(
          id: 1,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 20),
        ),
      ];
      final op = computeMarkDay(periods, DateTime.utc(2024, 6, 15));
      expect(op, isA<MarkNoOp>());
    });

    test('day on inclusive end of period returns MarkNoOp', () {
      final periods = [
        SpanRecord(
          id: 1,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 15),
        ),
      ];
      expect(computeMarkDay(periods, DateTime.utc(2024, 6, 15)), isA<MarkNoOp>());
    });

    test('day adjacent after period end returns MarkExtend', () {
      final periods = [
        SpanRecord(
          id: 7,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 14),
        ),
      ];
      final op = computeMarkDay(periods, DateTime.utc(2024, 6, 15));
      expect(op, isA<MarkExtend>());
      final e = op as MarkExtend;
      expect(e.periodId, 7);
      expect(e.newStart, DateTime.utc(2024, 6, 10));
      expect(e.newEnd, DateTime.utc(2024, 6, 15));
    });

    test('day adjacent before period start returns MarkExtend', () {
      final periods = [
        SpanRecord(
          id: 3,
          start: DateTime.utc(2024, 6, 16),
          end: DateTime.utc(2024, 6, 20),
        ),
      ];
      final op = computeMarkDay(periods, DateTime.utc(2024, 6, 15));
      expect(op, isA<MarkExtend>());
      final e = op as MarkExtend;
      expect(e.periodId, 3);
      expect(e.newStart, DateTime.utc(2024, 6, 15));
      expect(e.newEnd, DateTime.utc(2024, 6, 20));
    });

    test('single-day period with mark on next day extends (adjacent to end)', () {
      final periods = [
        SpanRecord(
          id: 1,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 10),
        ),
      ];
      final op = computeMarkDay(periods, DateTime.utc(2024, 6, 11));
      expect(op, isA<MarkExtend>());
      final e = op as MarkExtend;
      expect(e.newStart, DateTime.utc(2024, 6, 10));
      expect(e.newEnd, DateTime.utc(2024, 6, 11));
    });

    test('single-day period with mark on previous day extends (adjacent to start)', () {
      final periods = [
        SpanRecord(
          id: 2,
          start: DateTime.utc(2024, 6, 11),
          end: DateTime.utc(2024, 6, 11),
        ),
      ];
      final op = computeMarkDay(periods, DateTime.utc(2024, 6, 10));
      expect(op, isA<MarkExtend>());
      final e = op as MarkExtend;
      expect(e.newStart, DateTime.utc(2024, 6, 10));
      expect(e.newEnd, DateTime.utc(2024, 6, 11));
    });

    test('day bridges two periods with one-day gap returns MarkMerge', () {
      final periods = [
        SpanRecord(
          id: 10,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 11),
        ),
        SpanRecord(
          id: 20,
          start: DateTime.utc(2024, 6, 13),
          end: DateTime.utc(2024, 6, 14),
        ),
      ];
      final op = computeMarkDay(periods, DateTime.utc(2024, 6, 12));
      expect(op, isA<MarkMerge>());
      final m = op as MarkMerge;
      expect(m.newStart, DateTime.utc(2024, 6, 10));
      expect(m.newEnd, DateTime.utc(2024, 6, 14));
      expect({m.keepId, m.absorbId}, {10, 20});
    });

    test('month boundary: extend after Dec 31 into Jan 1', () {
      final periods = [
        SpanRecord(
          id: 1,
          start: DateTime.utc(2024, 12, 28),
          end: DateTime.utc(2024, 12, 31),
        ),
      ];
      final op = computeMarkDay(periods, DateTime.utc(2025, 1, 1));
      expect(op, isA<MarkExtend>());
      final e = op as MarkExtend;
      expect(e.newStart, DateTime.utc(2024, 12, 28));
      expect(e.newEnd, DateTime.utc(2025, 1, 1));
    });

    test('month boundary: merge across Dec 31 gap', () {
      final periods = [
        SpanRecord(
          id: 5,
          start: DateTime.utc(2024, 12, 30),
          end: DateTime.utc(2024, 12, 30),
        ),
        SpanRecord(
          id: 6,
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 1, 2),
        ),
      ];
      final op = computeMarkDay(periods, DateTime.utc(2024, 12, 31));
      expect(op, isA<MarkMerge>());
      final m = op as MarkMerge;
      expect(m.newStart, DateTime.utc(2024, 12, 30));
      expect(m.newEnd, DateTime.utc(2025, 1, 2));
    });
  });

  group('computeUnmarkDay', () {
    test('day not in any period returns UnmarkNoOp', () {
      final periods = [
        SpanRecord(
          id: 1,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 12),
        ),
      ];
      expect(computeUnmarkDay(periods, DateTime.utc(2024, 6, 20)), isA<UnmarkNoOp>());
    });

    test('single-day period returns UnmarkDelete', () {
      final periods = [
        SpanRecord(
          id: 9,
          start: DateTime.utc(2024, 6, 15),
          end: DateTime.utc(2024, 6, 15),
        ),
      ];
      final op = computeUnmarkDay(periods, DateTime.utc(2024, 6, 15));
      expect(op, isA<UnmarkDelete>());
      expect((op as UnmarkDelete).periodId, 9);
    });

    test('day at start of multi-day period returns UnmarkShrink', () {
      final periods = [
        SpanRecord(
          id: 1,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 14),
        ),
      ];
      final op = computeUnmarkDay(periods, DateTime.utc(2024, 6, 10));
      expect(op, isA<UnmarkShrink>());
      final s = op as UnmarkShrink;
      expect(s.periodId, 1);
      expect(s.newStart, DateTime.utc(2024, 6, 11));
      expect(s.newEnd, DateTime.utc(2024, 6, 14));
    });

    test('day at end of multi-day period returns UnmarkShrink', () {
      final periods = [
        SpanRecord(
          id: 2,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 14),
        ),
      ];
      final op = computeUnmarkDay(periods, DateTime.utc(2024, 6, 14));
      expect(op, isA<UnmarkShrink>());
      final s = op as UnmarkShrink;
      expect(s.newStart, DateTime.utc(2024, 6, 10));
      expect(s.newEnd, DateTime.utc(2024, 6, 13));
    });

    test('day in middle of 3-day period returns UnmarkSplit', () {
      final periods = [
        SpanRecord(
          id: 3,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 12),
        ),
      ];
      final op = computeUnmarkDay(periods, DateTime.utc(2024, 6, 11));
      expect(op, isA<UnmarkSplit>());
      final sp = op as UnmarkSplit;
      expect(sp.originalId, 3);
      expect(sp.leftStart, DateTime.utc(2024, 6, 10));
      expect(sp.leftEnd, DateTime.utc(2024, 6, 10));
      expect(sp.rightStart, DateTime.utc(2024, 6, 12));
      expect(sp.rightEnd, DateTime.utc(2024, 6, 12));
    });

    test('day in middle of longer period returns UnmarkSplit with correct edges', () {
      final periods = [
        SpanRecord(
          id: 4,
          start: DateTime.utc(2024, 6, 1),
          end: DateTime.utc(2024, 6, 10),
        ),
      ];
      final op = computeUnmarkDay(periods, DateTime.utc(2024, 6, 5));
      expect(op, isA<UnmarkSplit>());
      final sp = op as UnmarkSplit;
      expect(sp.leftStart, DateTime.utc(2024, 6, 1));
      expect(sp.leftEnd, DateTime.utc(2024, 6, 4));
      expect(sp.rightStart, DateTime.utc(2024, 6, 6));
      expect(sp.rightEnd, DateTime.utc(2024, 6, 10));
    });

    test('month boundary: shrink from Jan 1 edge after Dec span', () {
      final periods = [
        SpanRecord(
          id: 1,
          start: DateTime.utc(2024, 12, 31),
          end: DateTime.utc(2025, 1, 2),
        ),
      ];
      final op = computeUnmarkDay(periods, DateTime.utc(2024, 12, 31));
      expect(op, isA<UnmarkShrink>());
      final s = op as UnmarkShrink;
      expect(s.newStart, DateTime.utc(2025, 1, 1));
      expect(s.newEnd, DateTime.utc(2025, 1, 2));
    });

    test('lookup day with time-of-day still maps to UTC calendar day', () {
      final periods = [
        SpanRecord(
          id: 1,
          start: DateTime.utc(2024, 6, 10),
          end: DateTime.utc(2024, 6, 14),
        ),
      ];
      final op = computeUnmarkDay(periods, DateTime.utc(2024, 6, 10, 23, 59));
      expect(op, isA<UnmarkShrink>());
      final s = op as UnmarkShrink;
      expect(s.newStart, DateTime.utc(2024, 6, 11));
    });
  });
}

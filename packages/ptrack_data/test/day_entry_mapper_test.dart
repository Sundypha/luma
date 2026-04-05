import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_data/src/db/ptrack_database.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('day_entry_mapper', () {
    test('dayEntryRowToDomain maps a row with all fields set', () {
      final row = DayEntry(
        id: 1,
        periodId: 10,
        dateUtc: DateTime.utc(2024, 5, 1),
        flowIntensity: FlowIntensity.heavy.dbValue,
        painScore: PainScore.severe.dbValue,
        mood: Mood.veryGood.dbValue,
        notes: 'note',
      );
      final d = dayEntryRowToDomain(row);
      expect(d.dateUtc, row.dateUtc);
      expect(d.flowIntensity, FlowIntensity.heavy);
      expect(d.painScore, PainScore.severe);
      expect(d.mood, Mood.veryGood);
      expect(d.notes, 'note');
    });

    test('dayEntryRowToDomain maps null optional columns', () {
      final row = DayEntry(
        id: 2,
        periodId: 10,
        dateUtc: DateTime.utc(2024, 5, 2),
        flowIntensity: null,
        painScore: null,
        mood: null,
        notes: null,
      );
      final d = dayEntryRowToDomain(row);
      expect(d.flowIntensity, isNull);
      expect(d.painScore, isNull);
      expect(d.mood, isNull);
      expect(d.notes, isNull);
    });

    test('insert companion encodes enums; nulls are explicit null Values', () {
      final date = DateTime.utc(2024, 7, 1);
      final data = DayEntryData(
        dateUtc: date,
        flowIntensity: FlowIntensity.light,
        painScore: null,
        mood: Mood.bad,
        notes: null,
      );
      final c = dayEntryDataToInsertCompanion(42, data);
      expect(c.periodId.value, 42);
      expect(c.dateUtc.value, date);
      expect(c.flowIntensity.present, isTrue);
      expect(c.flowIntensity.value, FlowIntensity.light.dbValue);
      expect(c.painScore.present, isTrue);
      expect(c.painScore.value, isNull);
      expect(c.mood.present, isTrue);
      expect(c.mood.value, Mood.bad.dbValue);
      expect(c.notes.present, isTrue);
      expect(c.notes.value, isNull);
    });

    test('round-trip domain to row via database', () async {
      final path = createTempSqlitePath();
      final db = openPtrackDatabase(databasePath: path);
      try {
        final periodId = await db.into(db.periods).insert(
              periodSpanToInsertCompanion(
                PeriodSpan(
                  startUtc: DateTime.utc(2024, 8, 1),
                  endUtc: DateTime.utc(2024, 8, 5),
                ),
              ),
            );
        final data = DayEntryData(
          dateUtc: DateTime.utc(2024, 8, 2),
          flowIntensity: FlowIntensity.medium,
          painScore: PainScore.moderate,
          mood: Mood.neutral,
          notes: 'x',
        );
        await db.into(db.dayEntries).insert(
              dayEntryDataToInsertCompanion(periodId, data),
            );
        final rows = await db.select(db.dayEntries).get();
        expect(rows, hasLength(1));
        expect(dayEntryRowToDomain(rows.single), data);
      } finally {
        await db.close();
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/src/export/export_schema.dart';

void main() {
  group('LumaExportMeta', () {
    test('round-trip toJson / fromJson', () {
      final original = LumaExportMeta(
        formatVersion: 1,
        schemaVersion: 3,
        appVersion: '1.0.0+1',
        exportedAt: DateTime.utc(2026, 4, 6, 12, 30),
        encrypted: false,
        contentTypes: ['periods', 'symptoms'],
      );
      final decoded = LumaExportMeta.fromJson(original.toJson());
      expect(decoded.formatVersion, original.formatVersion);
      expect(decoded.schemaVersion, original.schemaVersion);
      expect(decoded.appVersion, original.appVersion);
      expect(decoded.exportedAt, original.exportedAt);
      expect(decoded.encrypted, original.encrypted);
      expect(decoded.contentTypes, original.contentTypes);
    });

    test('fromJson throws FormatException on missing keys', () {
      expect(
        () => LumaExportMeta.fromJson({'format_version': 1}),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('schema_version'),
        )),
      );
    });
  });

  group('ExportedPeriod', () {
    test('round-trip with end_utc', () {
      const p = ExportedPeriod(
        refId: 2,
        startUtc: '2024-01-01T00:00:00.000Z',
        endUtc: '2024-01-05T00:00:00.000Z',
      );
      final json = p.toJson();
      expect(json.containsKey('end_utc'), isTrue);
      final back = ExportedPeriod.fromJson(json);
      expect(back.refId, p.refId);
      expect(back.startUtc, p.startUtc);
      expect(back.endUtc, p.endUtc);
    });

    test('omits end_utc when null', () {
      const p = ExportedPeriod(
        refId: 1,
        startUtc: '2024-01-01T00:00:00.000Z',
      );
      final json = p.toJson();
      expect(json.containsKey('end_utc'), isFalse);
      final back = ExportedPeriod.fromJson(json);
      expect(back.endUtc, isNull);
    });

    test('fromJson requires ref_id and start_utc', () {
      expect(
        () => ExportedPeriod.fromJson({'start_utc': 'x'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ExportedDayEntry', () {
    test('round-trip with all optional fields', () {
      const e = ExportedDayEntry(
        periodRefId: 1,
        dateUtc: '2024-01-02T00:00:00.000Z',
        flowIntensity: 2,
        painScore: 3,
        mood: 1,
        notes: 'hello',
        personalNotes: 'diary',
      );
      final json = e.toJson();
      expect(json.keys, contains('flow_intensity'));
      expect(json['personal_notes'], 'diary');
      final back = ExportedDayEntry.fromJson(json);
      expect(back.flowIntensity, 2);
      expect(back.painScore, 3);
      expect(back.mood, 1);
      expect(back.notes, 'hello');
      expect(back.personalNotes, 'diary');
    });

    test('omits null optional fields from JSON', () {
      const e = ExportedDayEntry(
        periodRefId: 1,
        dateUtc: '2024-01-02T00:00:00.000Z',
      );
      final json = e.toJson();
      expect(json.containsKey('flow_intensity'), isFalse);
      expect(json.containsKey('pain_score'), isFalse);
      expect(json.containsKey('mood'), isFalse);
      expect(json.containsKey('notes'), isFalse);
      expect(json.containsKey('personal_notes'), isFalse);
    });

    test('fromJson requires period_ref_id and date_utc', () {
      expect(
        () => ExportedDayEntry.fromJson({'date_utc': 'x'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('LumaExportData', () {
    test('round-trip full document', () {
      final meta = LumaExportMeta(
        formatVersion: lumaFormatVersion,
        schemaVersion: 3,
        appVersion: '1.0.0+1',
        exportedAt: DateTime.utc(2026, 1, 1),
        encrypted: false,
        contentTypes: ['periods', 'symptoms', 'notes', 'diary'],
      );
      final data = LumaExportData(
        meta: meta,
        periods: const [
          ExportedPeriod(refId: 1, startUtc: '2024-01-01T00:00:00.000Z'),
        ],
        dayEntries: const [
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: '2024-01-02T00:00:00.000Z',
            flowIntensity: 1,
          ),
        ],
        diaryEntries: const [
          ExportedDiaryEntry(
            dateUtc: '2024-01-02T00:00:00.000Z',
            notes: 'diary line',
            tags: ['t1'],
          ),
        ],
      );
      final map = data.toJson();
      final back = LumaExportData.fromJson(map);
      expect(back.periods!.length, 1);
      expect(back.dayEntries!.length, 1);
      expect(back.diaryEntries, hasLength(1));
      expect(back.diaryEntries!.single.notes, 'diary line');
      expect(back.diaryEntries!.single.tags, ['t1']);
      expect(back.meta.contentTypes, meta.contentTypes);
    });

    test('fromJsonData parses inner data only', () {
      final meta = LumaExportMeta(
        formatVersion: 1,
        schemaVersion: 3,
        appVersion: '1.0.0+1',
        exportedAt: DateTime.utc(2026, 1, 1),
        encrypted: false,
        contentTypes: ['periods'],
      );
      final inner = {
        'periods': [
          {'ref_id': 1, 'start_utc': '2024-01-01T00:00:00.000Z'},
        ],
      };
      final parsed = LumaExportData.fromJsonData(meta, inner);
      expect(parsed.periods!.single.refId, 1);
      expect(parsed.dayEntries, isNull);
    });
  });

  group('ExportOptions', () {
    test('everything sets all inclusion flags', () {
      final o = ExportOptions.everything();
      expect(o.includePeriods, isTrue);
      expect(o.includeSymptoms, isTrue);
      expect(o.includeNotes, isTrue);
      expect(o.includeDiary, isTrue);
    });

    test('periodsOnly leaves symptoms, notes, and diary off', () {
      final o = ExportOptions.periodsOnly();
      expect(o.includePeriods, isTrue);
      expect(o.includeSymptoms, isFalse);
      expect(o.includeNotes, isFalse);
      expect(o.includeDiary, isFalse);
    });
  });

  group('ExportedDiaryTag', () {
    test('round-trip', () {
      const t = ExportedDiaryTag(name: 'work');
      final back = ExportedDiaryTag.fromJson(t.toJson());
      expect(back.name, 'work');
    });
  });

  group('ExportedDiaryEntry', () {
    test('round-trip with tags', () {
      const e = ExportedDiaryEntry(
        dateUtc: '2024-01-02T00:00:00.000Z',
        mood: 2,
        notes: 'hello',
        tags: ['a', 'b'],
      );
      final back = ExportedDiaryEntry.fromJson(e.toJson());
      expect(back.dateUtc, e.dateUtc);
      expect(back.mood, 2);
      expect(back.notes, 'hello');
      expect(back.tags, ['a', 'b']);
    });

    test('fromJson omits tags when absent', () {
      final back = ExportedDiaryEntry.fromJson({
        'date_utc': '2024-01-02T00:00:00.000Z',
      });
      expect(back.tags, isEmpty);
    });
  });

  group('lumaFormatVersion', () {
    test('is 2 for v2 diary payload', () {
      expect(lumaFormatVersion, 2);
    });
  });
}

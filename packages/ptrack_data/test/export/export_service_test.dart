import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_data/src/db/ptrack_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PtrackDatabase db;

  setUp(() {
    db = PtrackDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTwoPeriodsWithDays() async {
    final p1 = await db.into(db.periods).insert(
          PeriodsCompanion.insert(
            startUtc: DateTime.utc(2024, 1, 1),
            endUtc: Value(DateTime.utc(2024, 1, 5)),
          ),
        );
    final p2 = await db.into(db.periods).insert(
          PeriodsCompanion.insert(
            startUtc: DateTime.utc(2024, 2, 1),
            endUtc: Value(DateTime.utc(2024, 2, 4)),
          ),
        );
    await db.into(db.dayEntries).insert(
          DayEntriesCompanion.insert(
            periodId: p1,
            dateUtc: DateTime.utc(2024, 1, 2),
            flowIntensity: const Value(2),
            painScore: const Value(1),
          ),
        );
    await db.into(db.dayEntries).insert(
          DayEntriesCompanion.insert(
            periodId: p1,
            dateUtc: DateTime.utc(2024, 1, 3),
            mood: const Value(1),
            notes: const Value('note-a'),
          ),
        );
    await db.into(db.dayEntries).insert(
          DayEntriesCompanion.insert(
            periodId: p2,
            dateUtc: DateTime.utc(2024, 2, 2),
            flowIntensity: const Value(1),
            personalNotes: const Value('private diary line'),
          ),
        );
  }

  test('everything options produces JSON with periods and day entries', () async {
    await seedTwoPeriodsWithDays();
    final service = ExportService(db);
    final result = await service.exportData(
      options: ExportOptions.everything(),
    );
    final map = jsonDecode(utf8.decode(result.bytes)) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    expect((data['periods'] as List).length, 2);
    expect((data['day_entries'] as List).length, 3);
    final meta = map['meta'] as Map<String, dynamic>;
    expect(meta['content_types'], [
      'periods',
      'symptoms',
      'notes',
      'personal_notes',
    ]);
    final entries = data['day_entries'] as List<dynamic>;
    final withPersonal = entries.cast<Map<String, dynamic>>().where(
          (e) => e.containsKey('personal_notes'),
        );
    expect(withPersonal, isNotEmpty);
    expect(
      withPersonal.first['personal_notes'],
      'private diary line',
    );
  });

  test('periods only produces periods without day_entries', () async {
    await seedTwoPeriodsWithDays();
    final service = ExportService(db);
    final result = await service.exportData(
      options: ExportOptions.periodsOnly(),
    );
    final map = jsonDecode(utf8.decode(result.bytes)) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    expect(data['periods'], isNotNull);
    expect(data.containsKey('day_entries'), isFalse);
  });

  test('password produces encrypted envelope with payload', () async {
    await seedTwoPeriodsWithDays();
    final service = ExportService(db);
    final result = await service.exportData(
      options: ExportOptions.everything(password: 'secret'),
    );
    expect(result.meta.encrypted, isTrue);
    final map = jsonDecode(utf8.decode(result.bytes)) as Map<String, dynamic>;
    expect(map.containsKey('payload'), isTrue);
    expect(map.containsKey('data'), isFalse);
    final meta = map['meta'] as Map<String, dynamic>;
    expect(meta['encrypted'], isTrue);
    final inner = utf8.decode(
      await LumaCrypto.decrypt(
        base64Decode(map['payload']! as String),
        'secret',
      ),
    );
    final plain = jsonDecode(inner) as Map<String, dynamic>;
    expect(plain['data'], isNotNull);
  });

  test('filename matches luma-backup-YYYY-MM-DD.luma', () async {
    await db.into(db.periods).insert(
          PeriodsCompanion.insert(
            startUtc: DateTime.utc(2024, 1, 1),
          ),
        );
    final service = ExportService(db);
    final result = await service.exportData(
      options: ExportOptions.periodsOnly(),
    );
    expect(
      result.filename,
      matches(RegExp(r'^luma-backup-\d{4}-\d{2}-\d{2}\.luma$')),
    );
  });

  test('progress callback reports current and total', () async {
    await seedTwoPeriodsWithDays();
    final service = ExportService(db);
    final calls = <List<int>>[];
    await service.exportData(
      options: ExportOptions.everything(),
      onProgress: (c, t) => calls.add([c, t]),
    );
    expect(calls.last, [5, 5]);
    expect(calls.length, 5);
    for (final c in calls) {
      expect(c[0], lessThanOrEqualTo(c[1]));
      expect(c[1], 5);
    }
  });

  test('contentTypes reflect options (symptoms without notes)', () async {
    await db.into(db.periods).insert(
          PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
        );
    final service = ExportService(db);
    final result = await service.exportData(
      options: const ExportOptions(
        includePeriods: true,
        includeSymptoms: true,
        includeNotes: false,
      ),
    );
    expect(result.meta.contentTypes, [
      'periods',
      'symptoms',
      'personal_notes',
    ]);
  });
}

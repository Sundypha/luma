import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_data/src/db/ptrack_database.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

Uint8List _utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

Map<String, dynamic> _validMetaJson({
  int formatVersion = lumaFormatVersion,
  int schemaVersion = ptrackSupportedSchemaVersion,
  bool encrypted = false,
}) {
  return {
    'format_version': formatVersion,
    'schema_version': schemaVersion,
    'app_version': '1.0.0+1',
    'exported_at': DateTime.utc(2024, 6, 1).toIso8601String(),
    'encrypted': encrypted,
    'content_types': ['periods'],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  late PeriodCalendarContext utcCalendar;

  setUp(() {
    utcCalendar = PeriodCalendarContext(tz.UTC);
  });

  group('ImportService.parseFileMeta', () {
    late ImportService service;
    late PtrackDatabase db;

    setUp(() {
      db = PtrackDatabase(NativeDatabase.memory());
      service = ImportService(db, calendar: utcCalendar);
    });

    tearDown(() async {
      await db.close();
    });

    test('valid .luma bytes returns correct meta', () {
      final map = {
        'meta': _validMetaJson(),
        'data': <String, dynamic>{},
      };
      final meta = service.parseFileMeta(_utf8Bytes(jsonEncode(map)));
      expect(meta.formatVersion, lumaFormatVersion);
      expect(meta.schemaVersion, ptrackSupportedSchemaVersion);
      expect(meta.encrypted, isFalse);
    });

    test('garbage bytes throws LumaInvalidFileException', () {
      expect(
        () => service.parseFileMeta(Uint8List.fromList([0xFF, 0xFE, 0xFD])),
        throwsA(isA<LumaInvalidFileException>()),
      );
    });

    test('valid JSON but no meta key throws LumaInvalidFileException', () {
      expect(
        () => service.parseFileMeta(_utf8Bytes('{"data":{}}')),
        throwsA(isA<LumaInvalidFileException>()),
      );
    });

    test('format_version=99 throws LumaVersionException with descriptive message',
        () {
      final map = {
        'meta': _validMetaJson(formatVersion: 99),
        'data': <String, dynamic>{},
      };
      expect(
        () => service.parseFileMeta(_utf8Bytes(jsonEncode(map))),
        throwsA(
          predicate<LumaVersionException>(
            (e) =>
                e.fileVersion == 99 &&
                e.supportedVersion == lumaFormatVersion &&
                e.message.contains('newer'),
          ),
        ),
      );
    });

    test('schema_version > current throws LumaVersionException', () {
      final map = {
        'meta': _validMetaJson(schemaVersion: ptrackSupportedSchemaVersion + 1),
        'data': <String, dynamic>{},
      };
      expect(
        () => service.parseFileMeta(_utf8Bytes(jsonEncode(map))),
        throwsA(
          predicate<LumaVersionException>(
            (e) =>
                e.fileVersion == ptrackSupportedSchemaVersion + 1 &&
                e.supportedVersion == ptrackSupportedSchemaVersion &&
                e.message.toLowerCase().contains('update'),
          ),
        ),
      );
    });
  });

  group('ImportService.parseFileData', () {
    late ImportService service;
    late PtrackDatabase db;

    setUp(() {
      db = PtrackDatabase(NativeDatabase.memory());
      service = ImportService(db, calendar: utcCalendar);
    });

    tearDown(() async {
      await db.close();
    });

    test('unencrypted valid file returns full LumaExportData', () async {
      final map = {
        'meta': _validMetaJson(),
        'data': {
          'periods': [
            {
              'ref_id': 1,
              'start_utc': DateTime.utc(2024, 1, 1).toIso8601String(),
            },
          ],
        },
      };
      final data = await service.parseFileData(_utf8Bytes(jsonEncode(map)));
      expect(data.periods?.length, 1);
      expect(data.periods!.single.refId, 1);
    });

    test('encrypted file without password throws LumaDecryptionException',
        () async {
      await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );
      final export = await ExportService(db).exportData(
        options: ExportOptions.everything(password: 'secret'),
      );
      await expectLater(
        service.parseFileData(export.bytes),
        throwsA(isA<LumaDecryptionException>()),
      );
    });

    test('encrypted file with wrong password throws LumaDecryptionException',
        () async {
      await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );
      final export = await ExportService(db).exportData(
        options: ExportOptions.everything(password: 'secret'),
      );
      await expectLater(
        service.parseFileData(export.bytes, password: 'wrong'),
        throwsA(
          predicate<LumaDecryptionException>(
            (e) => e.message.contains('Incorrect password'),
          ),
        ),
      );
    });

    test('encrypted file with correct password returns decrypted data',
        () async {
      await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );
      final export = await ExportService(db).exportData(
        options: ExportOptions.everything(password: 'secret'),
      );
      final data = await service.parseFileData(
        export.bytes,
        password: 'secret',
      );
      expect(data.periods, isNotNull);
      expect(data.periods!.length, greaterThanOrEqualTo(1));
    });
  });

  group('ImportPreview.analyze', () {
    late PtrackDatabase db;

    setUp(() {
      db = PtrackDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('3 imported entries, 1 matching existing date → new=2 dup=1',
        () async {
      final p = await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );
      await db.into(db.dayEntries).insert(
            DayEntriesCompanion.insert(
              periodId: p,
              dateUtc: DateTime.utc(2024, 1, 15),
              flowIntensity: const Value(1),
            ),
          );

      final data = LumaExportData(
        meta: LumaExportMeta(
          formatVersion: lumaFormatVersion,
          schemaVersion: ptrackSupportedSchemaVersion,
          appVersion: 't',
          exportedAt: DateTime.utc(2024, 6, 1),
          encrypted: false,
          contentTypes: const ['periods'],
        ),
        periods: const [
          ExportedPeriod(
            refId: 1,
            startUtc: '2024-03-01T00:00:00.000Z',
          ),
        ],
        dayEntries: [
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: DateTime.utc(2024, 1, 10).toIso8601String(),
          ),
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: DateTime.utc(2024, 1, 15).toIso8601String(),
          ),
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: DateTime.utc(2024, 1, 20).toIso8601String(),
          ),
        ],
      );

      final preview = await ImportPreview.analyze(data, db);
      expect(preview.newEntries, 2);
      expect(preview.duplicateEntries, 1);
    });
  });

  group('ImportService.applyImport validation and day keys', () {
    late Directory supportRoot;
    late PtrackDatabase db;
    late ImportService importService;

    setUp(() async {
      supportRoot = await Directory.systemTemp.createTemp('import_hardened_');
      db = PtrackDatabase(NativeDatabase.memory());
      importService = ImportService(
        db,
        calendar: utcCalendar,
        backupService: BackupService(
          db,
          applicationSupportDirectory: () async => supportRoot,
        ),
      );
    });

    tearDown(() async {
      await db.close();
      if (await supportRoot.exists()) {
        await supportRoot.delete(recursive: true);
      }
    });

    test('orphan periodRefId throws and rolls back new periods', () async {
      await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );
      final before = await db.select(db.periods).get();

      final data = LumaExportData(
        meta: LumaExportMeta(
          formatVersion: lumaFormatVersion,
          schemaVersion: ptrackSupportedSchemaVersion,
          appVersion: 't',
          exportedAt: DateTime.utc(2024, 6, 1),
          encrypted: false,
          contentTypes: const ['periods'],
        ),
        periods: [
          ExportedPeriod(
            refId: 1,
            startUtc: DateTime.utc(2024, 5, 1).toIso8601String(),
          ),
        ],
        dayEntries: [
          ExportedDayEntry(
            periodRefId: 999,
            dateUtc: DateTime.utc(2024, 5, 2).toIso8601String(),
          ),
        ],
      );

      await expectLater(
        importService.applyImport(
          data: data,
          strategy: DuplicateStrategy.skip,
        ),
        throwsA(isA<LumaInvalidPeriodRefException>()),
      );

      final after = await db.select(db.periods).get();
      expect(after.length, before.length);
    });

    test(
        'same calendar date on two imported periods: replace touches only '
        'matching periodId', () async {
      final d = DateTime.utc(2024, 6, 15);
      final data = LumaExportData(
        meta: LumaExportMeta(
          formatVersion: lumaFormatVersion,
          schemaVersion: ptrackSupportedSchemaVersion,
          appVersion: 't',
          exportedAt: DateTime.utc(2024, 6, 1),
          encrypted: false,
          contentTypes: const ['periods'],
        ),
        periods: [
          ExportedPeriod(
            refId: 1,
            startUtc: DateTime.utc(2024, 3, 1).toIso8601String(),
            endUtc: DateTime.utc(2024, 3, 5).toIso8601String(),
          ),
          ExportedPeriod(
            refId: 2,
            startUtc: DateTime.utc(2024, 4, 1).toIso8601String(),
            endUtc: DateTime.utc(2024, 4, 5).toIso8601String(),
          ),
        ],
        dayEntries: [
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: d.toIso8601String(),
            flowIntensity: 1,
          ),
          ExportedDayEntry(
            periodRefId: 2,
            dateUtc: d.toIso8601String(),
            flowIntensity: 2,
          ),
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: d.toIso8601String(),
            flowIntensity: 9,
            painScore: 4,
          ),
        ],
      );

      final r = await importService.applyImport(
        data: data,
        strategy: DuplicateStrategy.replace,
      );
      expect(r.periodsCreated, 2);
      expect(r.entriesCreated, 2);
      expect(r.entriesReplaced, 1);

      final rows = await db.select(db.dayEntries).get();
      expect(rows.length, 2);
      final byFlow = {for (final e in rows) e.flowIntensity!: e};
      expect(byFlow[2]!.painScore, isNull);
      expect(byFlow[9]!.painScore, 4);
    });

    test('skip increments when duplicate is same periodId and dateUtc',
        () async {
      final data = LumaExportData(
        meta: LumaExportMeta(
          formatVersion: lumaFormatVersion,
          schemaVersion: ptrackSupportedSchemaVersion,
          appVersion: 't',
          exportedAt: DateTime.utc(2024, 6, 1),
          encrypted: false,
          contentTypes: const ['periods'],
        ),
        periods: [
          ExportedPeriod(
            refId: 1,
            startUtc: DateTime.utc(2024, 1, 1).toIso8601String(),
            endUtc: DateTime.utc(2024, 1, 5).toIso8601String(),
          ),
        ],
        dayEntries: [
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: DateTime.utc(2024, 1, 2).toIso8601String(),
            flowIntensity: 1,
          ),
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: DateTime.utc(2024, 1, 2).toIso8601String(),
            flowIntensity: 9,
          ),
        ],
      );

      final r = await importService.applyImport(
        data: data,
        strategy: DuplicateStrategy.skip,
      );
      expect(r.entriesCreated, 1);
      expect(r.entriesSkipped, 1);
      final row = await (db.select(db.dayEntries)).getSingle();
      expect(row.flowIntensity, 1);
    });

    test('overlapping imported periods throws and leaves DB unchanged',
        () async {
      final data = LumaExportData(
        meta: LumaExportMeta(
          formatVersion: lumaFormatVersion,
          schemaVersion: ptrackSupportedSchemaVersion,
          appVersion: 't',
          exportedAt: DateTime.utc(2024, 6, 1),
          encrypted: false,
          contentTypes: const ['periods'],
        ),
        periods: [
          ExportedPeriod(
            refId: 1,
            startUtc: DateTime.utc(2024, 1, 1).toIso8601String(),
            endUtc: DateTime.utc(2024, 1, 10).toIso8601String(),
          ),
          ExportedPeriod(
            refId: 2,
            startUtc: DateTime.utc(2024, 1, 5).toIso8601String(),
            endUtc: DateTime.utc(2024, 1, 15).toIso8601String(),
          ),
        ],
      );

      await expectLater(
        importService.applyImport(
          data: data,
          strategy: DuplicateStrategy.skip,
        ),
        throwsA(isA<LumaImportValidationException>()),
      );

      expect(await db.select(db.periods).get(), isEmpty);
    });

    test('export then applyImport round-trip on empty target DB', () async {
      final source = PtrackDatabase(NativeDatabase.memory());
      final sourceSupport =
          await Directory.systemTemp.createTemp('import_roundtrip_src_');
      try {
        await source.into(source.periods).insert(
              PeriodsCompanion.insert(
                startUtc: DateTime.utc(2024, 2, 1),
                endUtc: Value(DateTime.utc(2024, 2, 5)),
              ),
            );
        final export = await ExportService(source).exportData(
          options: ExportOptions.everything(),
        );
        final parsed = await ImportService(
          source,
          calendar: utcCalendar,
          backupService: BackupService(
            source,
            applicationSupportDirectory: () async => sourceSupport,
          ),
        ).parseFileData(export.bytes);

        final r = await importService.applyImport(
          data: parsed,
          strategy: DuplicateStrategy.skip,
        );
        expect(r.periodsCreated, greaterThanOrEqualTo(1));
        expect(await db.select(db.periods).get(), isNotEmpty);
      } finally {
        await source.close();
        if (await sourceSupport.exists()) {
          await sourceSupport.delete(recursive: true);
        }
      }
    });
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_data/src/db/ptrack_database.dart';

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

  group('ImportService.parseFileMeta', () {
    late ImportService service;
    late PtrackDatabase db;

    setUp(() {
      db = PtrackDatabase(NativeDatabase.memory());
      service = ImportService(db);
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
      service = ImportService(db);
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
}

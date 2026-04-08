import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/backup/import_view_model.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_data/src/db/ptrack_database.dart';

Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));

Map<String, dynamic> _metaMap({bool encrypted = false}) => {
      'format_version': lumaFormatVersion,
      'schema_version': ptrackSupportedSchemaVersion,
      'app_version': '1.0.0+1',
      'exported_at': DateTime.utc(2024, 6, 1).toIso8601String(),
      'encrypted': encrypted,
      'content_types': ['periods', 'day_entries'],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImportViewModel', () {
    test('handlePickedFile unencrypted → previewing with counts', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      final dir = await Directory.systemTemp.createTemp('import_vm');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      final backup = BackupService(
        db,
        applicationSupportDirectory: () async => dir,
      );
      final map = {
        'meta': _metaMap(),
        'data': {
          'periods': [
            {
              'ref_id': 1,
              'start_utc': DateTime.utc(2024, 1, 1).toIso8601String(),
            },
          ],
          'day_entries': [
            {
              'period_ref_id': 1,
              'date_utc': DateTime.utc(2024, 1, 5).toIso8601String(),
            },
          ],
        },
      };
      final vm = ImportViewModel(
        importService: ImportService(db, backupService: backup),
        db: db,
      );
      await vm.handlePickedFile(
        bytes: _utf8(jsonEncode(map)),
        fileName: 'backup.luma',
      );
      expect(vm.step, ImportStep.previewing);
      expect(vm.preview, isNotNull);
      expect(vm.preview!.totalPeriods, 1);
      expect(vm.preview!.totalEntries, 1);
    });

    test('encrypted file → passwordPrompt', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      final dir = await Directory.systemTemp.createTemp('import_vm');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );
      final backup = BackupService(
        db,
        applicationSupportDirectory: () async => dir,
      );
      final export = await ExportService(db).exportData(
        options: ExportOptions.everything(password: 'secret'),
      );
      final vm = ImportViewModel(
        importService: ImportService(db, backupService: backup),
        db: db,
      );
      await vm.handlePickedFile(bytes: export.bytes, fileName: 'enc.luma');
      expect(vm.step, ImportStep.passwordPrompt);
      expect(vm.isEncrypted, isTrue);
    });

    test('submitPassword wrong password stays on passwordPrompt', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      final dir = await Directory.systemTemp.createTemp('import_vm');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );
      final backup = BackupService(
        db,
        applicationSupportDirectory: () async => dir,
      );
      final export = await ExportService(db).exportData(
        options: ExportOptions.everything(password: 'secret'),
      );
      final vm = ImportViewModel(
        importService: ImportService(db, backupService: backup),
        db: db,
      );
      await vm.handlePickedFile(bytes: export.bytes, fileName: 'enc.luma');
      await vm.submitPassword('wrong');
      expect(vm.step, ImportStep.passwordPrompt);
      expect(vm.importErrorKind, ImportErrorKind.wrongPassword);
    });

    test('submitPassword correct → previewing', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      final dir = await Directory.systemTemp.createTemp('import_vm');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );
      final backup = BackupService(
        db,
        applicationSupportDirectory: () async => dir,
      );
      final export = await ExportService(db).exportData(
        options: ExportOptions.everything(password: 'secret'),
      );
      final vm = ImportViewModel(
        importService: ImportService(db, backupService: backup),
        db: db,
      );
      await vm.handlePickedFile(bytes: export.bytes, fileName: 'enc.luma');
      await vm.submitPassword('secret');
      expect(vm.step, ImportStep.previewing);
      expect(vm.preview, isNotNull);
    });

    test('applyImport → done with ImportResult', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      final dir = await Directory.systemTemp.createTemp('import_vm');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      final backup = BackupService(
        db,
        applicationSupportDirectory: () async => dir,
      );
      final map = {
        'meta': _metaMap(),
        'data': {
          'periods': [
            {
              'ref_id': 1,
              'start_utc': DateTime.utc(2024, 1, 1).toIso8601String(),
            },
          ],
          'day_entries': [
            {
              'period_ref_id': 1,
              'date_utc': DateTime.utc(2024, 1, 5).toIso8601String(),
            },
          ],
        },
      };
      final vm = ImportViewModel(
        importService: ImportService(db, backupService: backup),
        db: db,
      );
      await vm.handlePickedFile(
        bytes: _utf8(jsonEncode(map)),
        fileName: 'backup.luma',
      );
      await vm.applyImport();
      expect(vm.step, ImportStep.done);
      expect(vm.result, isNotNull);
      expect(vm.result!.periodsCreated, greaterThanOrEqualTo(1));
    });

    test('applyImport invalid period ref → error', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      final dir = await Directory.systemTemp.createTemp('import_vm');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      final backup = BackupService(
        db,
        applicationSupportDirectory: () async => dir,
      );
      final map = {
        'meta': _metaMap(),
        'data': {
          'periods': [
            {
              'ref_id': 1,
              'start_utc': DateTime.utc(2024, 1, 1).toIso8601String(),
            },
          ],
          'day_entries': [
            {
              'period_ref_id': 99,
              'date_utc': DateTime.utc(2024, 1, 2).toIso8601String(),
            },
          ],
        },
      };
      final vm = ImportViewModel(
        importService: ImportService(db, backupService: backup),
        db: db,
      );
      await vm.handlePickedFile(
        bytes: _utf8(jsonEncode(map)),
        fileName: 'backup.luma',
      );
      await vm.applyImport();
      expect(vm.step, ImportStep.error);
      expect(vm.importErrorKind, isNotNull);
    });

    test('selectStrategy updates strategy', () {
      final db = PtrackDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      final vm = ImportViewModel(
        importService: ImportService(db),
        db: db,
      );
      expect(vm.strategy, DuplicateStrategy.skip);
      vm.selectStrategy(DuplicateStrategy.replace);
      expect(vm.strategy, DuplicateStrategy.replace);
    });

    test('reset returns to idle', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      final dir = await Directory.systemTemp.createTemp('import_vm');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      final backup = BackupService(
        db,
        applicationSupportDirectory: () async => dir,
      );
      final map = {
        'meta': _metaMap(),
        'data': {
          'periods': [
            {
              'ref_id': 1,
              'start_utc': DateTime.utc(2024, 1, 1).toIso8601String(),
            },
          ],
        },
      };
      final vm = ImportViewModel(
        importService: ImportService(db, backupService: backup),
        db: db,
      );
      await vm.handlePickedFile(
        bytes: _utf8(jsonEncode(map)),
        fileName: 'backup.luma',
      );
      expect(vm.step, ImportStep.previewing);
      vm.reset();
      expect(vm.step, ImportStep.idle);
      expect(vm.hasData, isFalse);
      expect(vm.preview, isNull);
    });

    test('non-.luma file name → error', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      addTearDown(() async => db.close());
      final vm = ImportViewModel(
        importService: ImportService(db),
        db: db,
      );
      await vm.handlePickedFile(bytes: _utf8('{}'), fileName: 'note.txt');
      expect(vm.step, ImportStep.error);
      expect(vm.importErrorKind, ImportErrorKind.wrongExtension);
    });

    test('proceedToImport moves to chooseStrategy when duplicates exist',
        () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      final dir = await Directory.systemTemp.createTemp('import_vm');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      final pid = await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );
      await db.into(db.dayEntries).insert(
            DayEntriesCompanion.insert(
              periodId: pid,
              dateUtc: DateTime.utc(2024, 1, 15),
              flowIntensity: const Value(1),
            ),
          );
      final backup = BackupService(
        db,
        applicationSupportDirectory: () async => dir,
      );
      final map = {
        'meta': _metaMap(),
        'data': {
          'periods': [
            {
              'ref_id': 1,
              'start_utc': DateTime.utc(2024, 3, 1).toIso8601String(),
            },
          ],
          'day_entries': [
            {
              'period_ref_id': 1,
              'date_utc': DateTime.utc(2024, 1, 15).toIso8601String(),
            },
          ],
        },
      };
      final vm = ImportViewModel(
        importService: ImportService(db, backupService: backup),
        db: db,
      );
      await vm.handlePickedFile(
        bytes: _utf8(jsonEncode(map)),
        fileName: 'backup.luma',
      );
      expect(vm.preview!.duplicateEntries, greaterThan(0));
      vm.proceedToImport();
      expect(vm.step, ImportStep.chooseStrategy);
    });
  });
}

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_data/src/db/ptrack_database.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

LumaExportMeta _testMeta() => LumaExportMeta(
      formatVersion: lumaFormatVersion,
      schemaVersion: ptrackSupportedSchemaVersion,
      appVersion: 't',
      exportedAt: DateTime.utc(2024, 1, 1),
      encrypted: false,
      contentTypes: const ['periods', 'symptoms'],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('ImportService.applyImport', () {
    late Directory supportRoot;
    late PtrackDatabase db;
    late ImportService importService;

    setUp(() async {
      supportRoot = await Directory.systemTemp.createTemp('luma_import_test_');
      db = PtrackDatabase(NativeDatabase.memory());
      importService = ImportService(
        db,
        calendar: PeriodCalendarContext(tz.UTC),
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

    test('empty DB + 2 periods + 3 entries counts', () async {
      final data = LumaExportData(
        meta: _testMeta(),
        periods: [
          ExportedPeriod(
            refId: 1,
            startUtc: DateTime.utc(2024, 1, 1).toIso8601String(),
            endUtc: DateTime.utc(2024, 1, 5).toIso8601String(),
          ),
          ExportedPeriod(
            refId: 2,
            startUtc: DateTime.utc(2024, 2, 1).toIso8601String(),
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
            dateUtc: DateTime.utc(2024, 1, 3).toIso8601String(),
            painScore: 2,
          ),
          ExportedDayEntry(
            periodRefId: 2,
            dateUtc: DateTime.utc(2024, 2, 2).toIso8601String(),
            mood: 1,
          ),
        ],
      );

      final r = await importService.applyImport(
        data: data,
        strategy: DuplicateStrategy.skip,
      );

      expect(r.periodsCreated, 2);
      expect(r.entriesCreated, 3);
      expect(r.entriesSkipped, 0);
      expect(r.entriesReplaced, 0);

      final periods = await db.select(db.periods).get();
      final entries = await db.select(db.dayEntries).get();
      expect(periods.length, 2);
      expect(entries.length, 3);
    });

    test(
        'skip does not treat same calendar date on another period as duplicate',
        () async {
      final p1 = await db.into(db.periods).insert(
            PeriodsCompanion.insert(
              startUtc: DateTime.utc(2024, 1, 1),
              endUtc: Value(DateTime.utc(2024, 1, 5)),
            ),
          );
      await db.into(db.dayEntries).insert(
            DayEntriesCompanion.insert(
              periodId: p1,
              dateUtc: DateTime.utc(2024, 1, 10),
              flowIntensity: const Value(1),
            ),
          );

      final data = LumaExportData(
        meta: _testMeta(),
        periods: [
          ExportedPeriod(
            refId: 1,
            startUtc: DateTime.utc(2024, 3, 1).toIso8601String(),
          ),
        ],
        dayEntries: [
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: DateTime.utc(2024, 1, 10).toIso8601String(),
            flowIntensity: 9,
          ),
        ],
      );

      final r = await importService.applyImport(
        data: data,
        strategy: DuplicateStrategy.skip,
      );

      expect(r.periodsCreated, 1);
      expect(r.entriesSkipped, 0);
      expect(r.entriesCreated, 1);

      final rows = await db.select(db.dayEntries).get();
      expect(rows.length, 2);
      expect(
        rows.where((e) => e.flowIntensity == 9).length,
        1,
      );
    });

    test('replace updates same-period row when date repeats in one import',
        () async {
      final data = LumaExportData(
        meta: _testMeta(),
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
            painScore: 3,
          ),
        ],
      );

      final r = await importService.applyImport(
        data: data,
        strategy: DuplicateStrategy.replace,
      );

      expect(r.periodsCreated, 1);
      expect(r.entriesReplaced, 1);
      expect(r.entriesCreated, 1);

      final rows = await db.select(db.dayEntries).get();
      expect(rows.length, 1);
      expect(rows.single.flowIntensity, 9);
      expect(rows.single.painScore, 3);
    });

    test('invalid periodRefId rolls back entire import', () async {
      final before = await db.select(db.periods).get();
      expect(before, isEmpty);

      final data = LumaExportData(
        meta: _testMeta(),
        periods: [
          ExportedPeriod(
            refId: 1,
            startUtc: DateTime.utc(2024, 5, 1).toIso8601String(),
            endUtc: DateTime.utc(2024, 5, 5).toIso8601String(),
          ),
          ExportedPeriod(
            refId: 2,
            startUtc: DateTime.utc(2024, 6, 1).toIso8601String(),
            endUtc: DateTime.utc(2024, 6, 10).toIso8601String(),
          ),
        ],
        dayEntries: [
          ExportedDayEntry(
            periodRefId: 99,
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
      for (var i = 0; i < before.length; i++) {
        expect(after[i].id, before[i].id);
        expect(after[i].startUtc, before[i].startUtc);
      }
    });

    test('onProgress reports index and total', () async {
      final data = LumaExportData(
        meta: _testMeta(),
        periods: [
          ExportedPeriod(
            refId: 1,
            startUtc: DateTime.utc(2024, 1, 1).toIso8601String(),
          ),
        ],
        dayEntries: [
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: DateTime.utc(2024, 1, 2).toIso8601String(),
          ),
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: DateTime.utc(2024, 1, 3).toIso8601String(),
          ),
          ExportedDayEntry(
            periodRefId: 1,
            dateUtc: DateTime.utc(2024, 1, 4).toIso8601String(),
          ),
        ],
      );

      final calls = <List<int>>[];
      await importService.applyImport(
        data: data,
        strategy: DuplicateStrategy.skip,
        onProgress: (c, t) => calls.add([c, t]),
      );

      expect(calls, [
        [1, 3],
        [2, 3],
        [3, 3],
      ]);
    });
  });

  group('BackupService', () {
    late Directory supportRoot;
    late PtrackDatabase db;
    late BackupService backup;

    setUp(() async {
      supportRoot = await Directory.systemTemp.createTemp('luma_backup_svc_');
      db = PtrackDatabase(NativeDatabase.memory());
      backup = BackupService(
        db,
        applicationSupportDirectory: () async => supportRoot,
      );
    });

    tearDown(() async {
      await db.close();
      if (await supportRoot.exists()) {
        await supportRoot.delete(recursive: true);
      }
    });

    test('createBackup writes under luma_backups with expected prefix',
        () async {
      await db.into(db.periods).insert(
            PeriodsCompanion.insert(startUtc: DateTime.utc(2024, 1, 1)),
          );

      final file = await backup.createBackup();
      expect(await file.exists(), isTrue);
      expect(p.basename(file.path), startsWith('auto-backup-'));
      expect(file.path, contains('luma_backups'));
      expect(file.path, endsWith('.luma'));
      expect(await file.length(), greaterThan(0));
    });

    test('pruneBackups keeps only 3 newest auto-backups', () async {
      final dir = Directory(p.join(supportRoot.path, 'luma_backups'));
      await dir.create(recursive: true);
      final base = DateTime.utc(2024, 1, 1);
      for (var i = 0; i < 5; i++) {
        final f = File(
          p.join(dir.path, 'auto-backup-2024-01-0${i + 1}-120000.luma'),
        );
        await f.writeAsString('x');
        f.setLastModifiedSync(base.add(Duration(seconds: i)));
      }

      await backup.pruneBackups(keepCount: 3);

      final listed = await backup.listBackups();
      expect(listed.length, 3);
    });
  });
}

import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/ptrack_database.dart';
import 'export_schema.dart';
import 'luma_crypto.dart';

typedef ProgressCallback = void Function(int current, int total);

/// Result of [ExportService.exportData].
final class ExportResult {
  const ExportResult({
    required this.bytes,
    required this.filename,
    required this.meta,
  });

  final Uint8List bytes;
  final String filename;
  final LumaExportMeta meta;
}

/// Builds `.luma` export bytes from the local Drift database.
final class ExportService {
  ExportService(this._db);

  final PtrackDatabase _db;

  /// Exports selected content; optional [options.password] encrypts the JSON payload.
  Future<ExportResult> exportData({
    required ExportOptions options,
    ProgressCallback? onProgress,
  }) async {
    final exportedAt = DateTime.now().toUtc();
    final contentTypes = _contentTypes(options);
    final encrypted = options.password != null;

    if (!options.includePeriods) {
      final meta = LumaExportMeta(
        formatVersion: lumaFormatVersion,
        schemaVersion: ptrackSupportedSchemaVersion,
        appVersion: '1.0.0+1',
        exportedAt: exportedAt,
        encrypted: encrypted,
        contentTypes: contentTypes,
      );
      final data = LumaExportData(meta: meta);
      return _finish(
        exportData: data,
        exportedAt: exportedAt,
        password: options.password,
      );
    }

    final periodRows = await (_db.select(_db.periods)
          ..orderBy([(t) => OrderingTerm.asc(t.startUtc)]))
        .get();

    final includeDayData =
        options.includeSymptoms || options.includeNotes;

    final List<DayEntry> dayRows;
    if (includeDayData) {
      dayRows = await (_db.select(_db.dayEntries)
            ..orderBy([(t) => OrderingTerm.asc(t.dateUtc)]))
          .get();
    } else {
      dayRows = [];
    }

    final diaryRowsForExport = options.includeDiary
        ? await (_db.select(_db.diaryEntries)
              ..orderBy([(t) => OrderingTerm.asc(t.dateUtc)]))
            .get()
        : <DiaryEntryRow>[];

    final totalUnits = periodRows.length +
        (includeDayData ? dayRows.length : 0) +
        diaryRowsForExport.length;
    var progressCount = 0;
    void bump() {
      progressCount++;
      if (totalUnits > 0) {
        onProgress?.call(progressCount, totalUnits);
      }
    }

    final idToRef = <int, int>{};
    final exportedPeriods = <ExportedPeriod>[];
    var ref = 1;
    for (final row in periodRows) {
      idToRef[row.id] = ref;
      exportedPeriods.add(
        ExportedPeriod(
          refId: ref,
          startUtc: row.startUtc.toUtc().toIso8601String(),
          endUtc: row.endUtc?.toUtc().toIso8601String(),
        ),
      );
      ref++;
      bump();
    }

    List<ExportedDayEntry>? exportedDays;
    if (includeDayData) {
      exportedDays = [];
      for (final row in dayRows) {
        bump();
        final periodRef = idToRef[row.periodId];
        if (periodRef == null) {
          continue;
        }
        final flow =
            options.includeSymptoms ? row.flowIntensity : null;
        final pain = options.includeSymptoms ? row.painScore : null;
        final mood = options.includeSymptoms ? row.mood : null;
        final notes = options.includeNotes ? row.notes : null;

        if (flow == null &&
            pain == null &&
            mood == null &&
            (notes == null || notes.isEmpty)) {
          continue;
        }

        exportedDays.add(
          ExportedDayEntry(
            periodRefId: periodRef,
            dateUtc: row.dateUtc.toUtc().toIso8601String(),
            flowIntensity: flow,
            painScore: pain,
            mood: mood,
            notes: notes,
          ),
        );
      }
      if (exportedDays.isEmpty) {
        exportedDays = null;
      }
    }

    List<ExportedDiaryEntry>? exportedDiary;
    if (diaryRowsForExport.isNotEmpty) {
      exportedDiary = [];
      for (final row in diaryRowsForExport) {
        bump();
        final joinRows = await (_db.select(_db.diaryEntryTagJoin)
              ..where((t) => t.diaryEntryId.equals(row.id)))
            .get();
        final tagNames = <String>[];
        if (joinRows.isNotEmpty) {
          final tagIds = joinRows.map((j) => j.tagId).toList();
          final tagRows = await (_db.select(_db.diaryTags)
                ..where((t) => t.id.isIn(tagIds)))
              .get();
          tagNames.addAll(tagRows.map((t) => t.name));
        }
        exportedDiary.add(
          ExportedDiaryEntry(
            dateUtc: row.dateUtc.toUtc().toIso8601String(),
            mood: row.mood,
            notes: row.notes,
            tags: tagNames,
          ),
        );
      }
    }

    final meta = LumaExportMeta(
      formatVersion: lumaFormatVersion,
      schemaVersion: ptrackSupportedSchemaVersion,
      appVersion: '1.0.0+1',
      exportedAt: exportedAt,
      encrypted: encrypted,
      contentTypes: contentTypes,
    );

    final data = LumaExportData(
      meta: meta,
      periods: exportedPeriods,
      dayEntries: exportedDays,
      diaryEntries: exportedDiary,
    );

    return _finish(
      exportData: data,
      exportedAt: exportedAt,
      password: options.password,
    );
  }

  static List<String> _contentTypes(ExportOptions o) {
    final t = <String>[];
    if (o.includePeriods) {
      t.add('periods');
    }
    if (o.includeSymptoms) {
      t.add('symptoms');
    }
    if (o.includeNotes) {
      t.add('notes');
    }
    if (o.includeDiary) {
      t.add('diary');
    }
    return t;
  }

  Future<ExportResult> _finish({
    required LumaExportData exportData,
    required DateTime exportedAt,
    String? password,
  }) async {
    final plainJson = jsonEncode(exportData.toJson());
    var bytes = Uint8List.fromList(utf8.encode(plainJson));

    if (password != null) {
      final enc = await LumaCrypto.encrypt(bytes, password);
      final outer = <String, dynamic>{
        'meta': exportData.meta.toJson(),
        'payload': base64Encode(enc),
      };
      bytes = Uint8List.fromList(utf8.encode(jsonEncode(outer)));
    }

    return ExportResult(
      bytes: bytes,
      filename: _filenameFor(exportedAt),
      meta: exportData.meta,
    );
  }

  static String _filenameFor(DateTime exportedAt) {
    final u = exportedAt.toUtc();
    final y = u.year.toString().padLeft(4, '0');
    final m = u.month.toString().padLeft(2, '0');
    final d = u.day.toString().padLeft(2, '0');
    return 'luma-backup-$y-$m-$d.luma';
  }
}

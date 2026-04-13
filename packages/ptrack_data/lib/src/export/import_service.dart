import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../db/ptrack_database.dart';
import '../mappers/period_mapper.dart';
import 'backup_service.dart';
import 'export_schema.dart';
import 'export_service.dart' show ProgressCallback;
import 'luma_crypto.dart';

DateTime _utcCalendarDate(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day);

/// Base class for import failures with a user-facing [message].
sealed class LumaImportException implements Exception {
  const LumaImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class LumaInvalidFileException extends LumaImportException {
  const LumaInvalidFileException(super.message);
}

final class LumaVersionException extends LumaImportException {
  const LumaVersionException({
    required String message,
    required this.fileVersion,
    required this.supportedVersion,
  }) : super(message);

  final int fileVersion;
  final int supportedVersion;
}

final class LumaDecryptionException extends LumaImportException {
  const LumaDecryptionException(super.message);
}

/// Period rows in the backup failed [PeriodValidation] (overlap, end before start,
/// duplicate start day, etc.).
final class LumaImportValidationException extends LumaImportException {
  const LumaImportValidationException(super.message);
}

/// A day entry references a [periodRefId] that has no matching imported period.
final class LumaInvalidPeriodRefException extends LumaImportException {
  LumaInvalidPeriodRefException({
    required this.periodRefId,
    required this.entryIndex,
  }) : super(
          'Day entry at index $entryIndex references unknown period ref_id '
          '$periodRefId.',
        );

  final int periodRefId;
  final int entryIndex;
}

enum DuplicateStrategy { skip, replace }

/// True when [data.dayEntries] carries non-empty [ExportedDayEntry.personalNotes].
///
/// Some backups declare [LumaExportMeta.formatVersion] 2 but still embed legacy
/// `personal_notes` on day entries (older writers / round-trips). Import must
/// still promote those fields into [diary_entries].
bool _dayEntriesHaveNonEmptyPersonalNotes(LumaExportData data) {
  for (final ie in data.dayEntries ?? const <ExportedDayEntry>[]) {
    final raw = ie.personalNotes?.trim();
    if (raw != null && raw.isNotEmpty) {
      return true;
    }
  }
  return false;
}

/// Same UTC overlap rule as [PeriodValidation] (open-ended ranges unbounded).
bool _importUtcRangesOverlap(
  DateTime aStart,
  DateTime? aEnd,
  DateTime bStart,
  DateTime? bEnd,
) {
  final as = aStart.toUtc();
  final bs = bStart.toUtc();
  final ae = aEnd?.toUtc();
  final be = bEnd?.toUtc();
  if (ae != null && ae.isBefore(bs)) return false;
  if (be != null && be.isBefore(as)) return false;
  return true;
}

/// Counts written during [ImportService.applyImport].
final class ImportResult {
  const ImportResult({
    required this.periodsCreated,
    required this.entriesCreated,
    required this.entriesSkipped,
    required this.entriesReplaced,
  });

  final int periodsCreated;
  final int entriesCreated;
  final int entriesSkipped;
  final int entriesReplaced;
}

/// Parses and applies `.luma` backups.
final class ImportService {
  ImportService(
    this._db, {
    required PeriodCalendarContext calendar,
    BackupService? backupService,
  })  : _calendar = calendar,
        _backup = backupService ?? BackupService(_db);

  final PtrackDatabase _db;
  final PeriodCalendarContext _calendar;
  final BackupService _backup;

  Future<List<({int id, PeriodSpan span})>> _loadExistingPeriods() async {
    final rows = await (_db.select(_db.periods)
          ..orderBy([(t) => OrderingTerm.asc(t.startUtc)]))
        .get();
    return [
      for (final row in rows) (id: row.id, span: periodRowToDomain(row)),
    ];
  }

  Future<void> _syncDiaryFromImportedDayEntry({
    required DateTime dateUtc,
    required ExportedDayEntry ie,
    required bool legacyPersonalNotes,
  }) async {
    if (!legacyPersonalNotes) {
      return;
    }
    if (!ie.personalNotesIncludedInExport) return;
    final date = _utcCalendarDate(dateUtc);
    final raw = ie.personalNotes?.trim();
    if (raw == null || raw.isEmpty) {
      await (_db.delete(_db.diaryEntries)..where((t) => t.dateUtc.equals(date)))
          .go();
      return;
    }
    await (_db.delete(_db.diaryEntries)..where((t) => t.dateUtc.equals(date)))
        .go();
    await _db.into(_db.diaryEntries).insert(
          DiaryEntriesCompanion.insert(
            dateUtc: date,
            mood: Value(ie.mood),
            notes: Value(raw),
          ),
        );
  }

  String _messageForValidationIssues(List<PeriodValidationIssue> issues) {
    if (issues.isEmpty) {
      return 'This backup contains invalid period data.';
    }
    return switch (issues.first) {
      EndBeforeStart() =>
        'This backup contains a period where the end is before the start.',
      OverlappingPeriod() =>
        'This backup contains a period that overlaps existing data.',
      DuplicateStartCalendarDay(:final calendarDate) =>
        'This backup contains two periods starting on the same calendar day '
        '($calendarDate).',
    };
  }

  LumaExportMeta parseFileMeta(Uint8List bytes) {
    late final Map<String, dynamic> root;
    try {
      final text = utf8.decode(bytes);
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const LumaInvalidFileException(
          'File is not a valid Luma backup',
        );
      }
      root = Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw const LumaInvalidFileException(
        'File is not a valid Luma backup',
      );
    }

    if (!root.containsKey('meta') || root['meta'] is! Map) {
      throw const LumaInvalidFileException(
        'File is not a valid Luma backup',
      );
    }

    late final LumaExportMeta meta;
    try {
      meta = LumaExportMeta.fromJson(
        Map<String, dynamic>.from(root['meta']! as Map),
      );
    } on FormatException {
      throw const LumaInvalidFileException(
        'File is not a valid Luma backup',
      );
    }

    if (meta.formatVersion > lumaFormatVersion) {
      throw LumaVersionException(
        message:
            'This backup was created by a newer version of the app and cannot be imported here.',
        fileVersion: meta.formatVersion,
        supportedVersion: lumaFormatVersion,
      );
    }

    if (meta.formatVersion < 1) {
      throw LumaVersionException(
        message: 'This backup uses an export format that is no longer supported.',
        fileVersion: meta.formatVersion,
        supportedVersion: lumaFormatVersion,
      );
    }

    if (meta.schemaVersion > ptrackSupportedSchemaVersion) {
      throw LumaVersionException(
        message:
            'This backup requires a newer version of the app. Please update the app and try again.',
        fileVersion: meta.schemaVersion,
        supportedVersion: ptrackSupportedSchemaVersion,
      );
    }

    return meta;
  }

  Future<LumaExportData> parseFileData(
    Uint8List bytes, {
    String? password,
  }) async {
    final meta = parseFileMeta(bytes);

    late final Map<String, dynamic> root;
    try {
      final text = utf8.decode(bytes);
      root = Map<String, dynamic>.from(jsonDecode(text) as Map);
    } on FormatException {
      throw const LumaInvalidFileException(
        'File is not a valid Luma backup',
      );
    }

    if (meta.encrypted) {
      if (password == null) {
        throw const LumaDecryptionException(
          'This file is password-protected',
        );
      }
      final payloadRaw = root['payload'];
      if (payloadRaw is! String) {
        throw const LumaInvalidFileException(
          'File is not a valid Luma backup',
        );
      }
      late final Uint8List decrypted;
      try {
        final encryptedBytes = base64Decode(payloadRaw);
        decrypted = await LumaCrypto.decrypt(encryptedBytes, password);
      } on SecretBoxAuthenticationError {
        throw const LumaDecryptionException(
          'Incorrect password or corrupted file',
        );
      } on FormatException {
        throw const LumaDecryptionException(
          'Incorrect password or corrupted file',
        );
      }
      try {
        final innerText = utf8.decode(decrypted);
        final inner = jsonDecode(innerText);
        if (inner is! Map) {
          throw const LumaInvalidFileException(
            'File is not a valid Luma backup',
          );
        }
        return LumaExportData.fromJson(Map<String, dynamic>.from(inner));
      } on FormatException {
        throw const LumaInvalidFileException(
          'File is not a valid Luma backup',
        );
      }
    }

    try {
      return LumaExportData.fromJson(root);
    } on FormatException {
      throw const LumaInvalidFileException(
        'File is not a valid Luma backup',
      );
    }
  }

  /// Creates an auto-backup, then imports [data] in a single transaction.
  Future<ImportResult> applyImport({
    required LumaExportData data,
    required DuplicateStrategy strategy,
    ProgressCallback? onProgress,
  }) async {
    await _backup.createBackup();

    return _db.transaction(() async {
      final refMap = <int, int>{};
      var periodsCreated = 0;
      var entriesCreated = 0;
      var entriesSkipped = 0;
      var entriesReplaced = 0;

      var periodWorking = await _loadExistingPeriods();
      final periods = data.periods ?? [];
      for (final ip in periods) {
        final startUtc = DateTime.parse(ip.startUtc).toUtc();
        final endUtc =
            ip.endUtc != null ? DateTime.parse(ip.endUtc!).toUtc() : null;
        final candidate = PeriodSpan(startUtc: startUtc, endUtc: endUtc);

        final overlapIdx = <int>[];
        for (var i = 0; i < periodWorking.length; i++) {
          final w = periodWorking[i];
          if (_importUtcRangesOverlap(
                candidate.startUtc,
                candidate.endUtc,
                w.span.startUtc,
                w.span.endUtc,
              )) {
            overlapIdx.add(i);
          }
        }

        if (strategy == DuplicateStrategy.replace && overlapIdx.isNotEmpty) {
          final overlappedIds = {
            for (final j in overlapIdx) periodWorking[j].id,
          };
          if (overlappedIds.length > 1) {
            throw const LumaImportValidationException(
              'This backup overlaps more than one existing period. '
              'Resolve overlaps in the app or use a different backup.',
            );
          }
          final j = overlapIdx.first;
          final others = <PeriodSpan>[
            for (var k = 0; k < periodWorking.length; k++)
              if (k != j) periodWorking[k].span,
          ];
          final validation = PeriodValidation.validateForSave(
            candidate: candidate,
            existing: others,
            calendar: _calendar,
          );
          if (!validation.isValid) {
            throw LumaImportValidationException(
              _messageForValidationIssues(validation.issues),
            );
          }
          final reusedId = periodWorking[j].id;
          await (_db.update(_db.periods)..where((t) => t.id.equals(reusedId)))
              .write(periodSpanToUpdateCompanion(candidate));
          refMap[ip.refId] = reusedId;
          periodWorking[j] = (id: reusedId, span: candidate);
          continue;
        }

        final validation = PeriodValidation.validateForSave(
          candidate: candidate,
          existing: periodWorking.map((e) => e.span).toList(),
          calendar: _calendar,
        );
        if (!validation.isValid) {
          throw LumaImportValidationException(
            _messageForValidationIssues(validation.issues),
          );
        }
        final id = await _db.into(_db.periods).insert(
              PeriodsCompanion.insert(
                startUtc: startUtc,
                endUtc: endUtc != null
                    ? Value(endUtc)
                    : const Value.absent(),
              ),
            );
        refMap[ip.refId] = id;
        periodWorking = [...periodWorking, (id: id, span: candidate)];
        periodsCreated++;
      }

      final migratePersonalNotesToDiary = data.meta.formatVersion < 2 ||
          _dayEntriesHaveNonEmptyPersonalNotes(data);
      final entries = data.dayEntries ?? [];
      final totalEntries = entries.length;
      for (var i = 0; i < entries.length; i++) {
        final ie = entries[i];
        onProgress?.call(i + 1, totalEntries);
        final periodId = refMap[ie.periodRefId];
        if (periodId == null) {
          throw LumaInvalidPeriodRefException(
            periodRefId: ie.periodRefId,
            entryIndex: i,
          );
        }
        final dateUtc = _utcCalendarDate(DateTime.parse(ie.dateUtc).toUtc());

        final existing = await (_db.select(_db.dayEntries)
              ..where(
                (t) =>
                    t.periodId.equals(periodId) & t.dateUtc.equals(dateUtc),
              ))
            .getSingleOrNull();

        if (existing != null) {
          if (strategy == DuplicateStrategy.skip) {
            entriesSkipped++;
            continue;
          }
          await (_db.update(_db.dayEntries)
                ..where((t) => t.id.equals(existing.id)))
              .write(
            DayEntriesCompanion(
              periodId: Value(periodId),
              flowIntensity: Value(ie.flowIntensity),
              painScore: Value(ie.painScore),
              mood: Value(ie.mood),
              notes: Value(ie.notes),
            ),
          );
          await _syncDiaryFromImportedDayEntry(
            dateUtc: dateUtc,
            ie: ie,
            legacyPersonalNotes: migratePersonalNotesToDiary,
          );
          entriesReplaced++;
        } else {
          await _db.into(_db.dayEntries).insert(
                DayEntriesCompanion.insert(
                  periodId: periodId,
                  dateUtc: dateUtc,
                  flowIntensity: Value(ie.flowIntensity),
                  painScore: Value(ie.painScore),
                  mood: Value(ie.mood),
                  notes: Value(ie.notes),
                ),
              );
          await _syncDiaryFromImportedDayEntry(
            dateUtc: dateUtc,
            ie: ie,
            legacyPersonalNotes: migratePersonalNotesToDiary,
          );
          entriesCreated++;
        }
      }

      final diaryEntries = data.diaryEntries ?? [];
      for (final ie in diaryEntries) {
        final dateUtc = _utcCalendarDate(DateTime.parse(ie.dateUtc).toUtc());
        final existing = await (_db.select(_db.diaryEntries)
              ..where((t) => t.dateUtc.equals(dateUtc)))
            .getSingleOrNull();
        if (existing != null && strategy == DuplicateStrategy.skip) {
          continue;
        }
        final int entryId;
        if (existing != null) {
          await (_db.update(_db.diaryEntries)
                ..where((t) => t.id.equals(existing.id)))
              .write(
            DiaryEntriesCompanion(
              mood: Value(ie.mood),
              notes: Value(ie.notes),
            ),
          );
          entryId = existing.id;
        } else {
          entryId = await _db.into(_db.diaryEntries).insert(
                DiaryEntriesCompanion.insert(
                  dateUtc: dateUtc,
                  mood: Value(ie.mood),
                  notes: Value(ie.notes),
                ),
              );
        }
        await (_db.delete(_db.diaryEntryTagJoin)
              ..where((t) => t.diaryEntryId.equals(entryId)))
            .go();
        for (final tagName in ie.tags) {
          final trimmed = tagName.trim();
          if (trimmed.isEmpty) {
            continue;
          }
          final existingTag = await (_db.select(_db.diaryTags)
                ..where((t) => t.name.equals(trimmed)))
              .getSingleOrNull();
          final tagId = existingTag?.id ??
              await _db.into(_db.diaryTags).insert(
                    DiaryTagsCompanion.insert(name: trimmed),
                  );
          await _db.into(_db.diaryEntryTagJoin).insert(
                DiaryEntryTagJoinCompanion.insert(
                  diaryEntryId: entryId,
                  tagId: tagId,
                ),
              );
        }
      }

      if (migratePersonalNotesToDiary) {
        for (final ie in data.dayEntries ?? []) {
          final raw = ie.personalNotes?.trim();
          if (raw == null || raw.isEmpty) {
            continue;
          }
          final dateUtc = _utcCalendarDate(DateTime.parse(ie.dateUtc).toUtc());
          final exists = await (_db.select(_db.diaryEntries)
                ..where((t) => t.dateUtc.equals(dateUtc)))
              .getSingleOrNull();
          if (exists != null) {
            continue;
          }
          await _db.into(_db.diaryEntries).insert(
                DiaryEntriesCompanion.insert(
                  dateUtc: dateUtc,
                  mood: Value(ie.mood),
                  notes: Value(raw),
                ),
              );
        }
      }

      return ImportResult(
        periodsCreated: periodsCreated,
        entriesCreated: entriesCreated,
        entriesSkipped: entriesSkipped,
        entriesReplaced: entriesReplaced,
      );
    });
  }
}

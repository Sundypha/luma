import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../db/ptrack_database.dart';
import 'backup_service.dart';
import 'export_schema.dart';
import 'export_service.dart';
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

enum DuplicateStrategy { skip, replace }

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
    BackupService? backupService,
  }) : _backup = backupService ?? BackupService(_db);

  final PtrackDatabase _db;
  final BackupService _backup;

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

    if (meta.formatVersion != lumaFormatVersion) {
      throw LumaVersionException(
        message: meta.formatVersion > lumaFormatVersion
            ? 'This backup was created by a newer version of the app and cannot be imported here.'
            : 'This backup uses an export format that is no longer supported.',
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

      final periods = data.periods ?? [];
      for (final ip in periods) {
        final startUtc = DateTime.parse(ip.startUtc).toUtc();
        final endUtc =
            ip.endUtc != null ? DateTime.parse(ip.endUtc!).toUtc() : null;
        final id = await _db.into(_db.periods).insert(
              PeriodsCompanion.insert(
                startUtc: startUtc,
                endUtc: endUtc != null
                    ? Value(endUtc)
                    : const Value.absent(),
              ),
            );
        refMap[ip.refId] = id;
        periodsCreated++;
      }

      final entries = data.dayEntries ?? [];
      final totalEntries = entries.length;
      for (var i = 0; i < entries.length; i++) {
        final ie = entries[i];
        onProgress?.call(i + 1, totalEntries);
        final periodId = refMap[ie.periodRefId]!;
        final dateUtc = _utcCalendarDate(DateTime.parse(ie.dateUtc).toUtc());

        final existing = await (_db.select(_db.dayEntries)
              ..where((t) => t.dateUtc.equals(dateUtc)))
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
          entriesCreated++;
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

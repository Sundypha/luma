import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../db/ptrack_database.dart';
import 'export_schema.dart';
import 'luma_crypto.dart';

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
  ImportService(this._db);

  final PtrackDatabase _db;

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
}

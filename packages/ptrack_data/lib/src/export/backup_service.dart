import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/ptrack_database.dart';
import 'export_schema.dart';
import 'export_service.dart';

/// Resolves the directory used for `luma_backups/` (injectable in tests).
typedef ApplicationSupportDirectory = Future<Directory> Function();

/// Metadata for one auto-backup file on disk.
final class BackupInfo {
  const BackupInfo({
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String path;
  final DateTime createdAt;
  final int sizeBytes;
}

/// Creates and retains local `.luma` auto-backups under app support.
final class BackupService {
  BackupService(
    this._db, {
    ApplicationSupportDirectory? applicationSupportDirectory,
  }) : _supportDir = applicationSupportDirectory ?? getApplicationSupportDirectory;

  final PtrackDatabase _db;
  final ApplicationSupportDirectory _supportDir;

  /// Writes `luma_backups/auto-backup-YYYY-MM-DD-HHmmss.luma` and prunes old files.
  Future<File> createBackup() async {
    final root = await _supportDir();
    final backupsDir = Directory(p.join(root.path, 'luma_backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    final export = await ExportService(_db).exportData(
      options: ExportOptions.everything(),
    );
    final stamp = _timestampForFile(DateTime.now().toUtc());
    final file = File(p.join(backupsDir.path, 'auto-backup-$stamp.luma'));
    await file.writeAsBytes(export.bytes, flush: true);
    await pruneBackups(keepCount: 3);
    return file;
  }

  /// Lists `auto-backup-*.luma` files newest-first.
  Future<List<BackupInfo>> listBackups() async {
    final root = await _supportDir();
    final dir = Directory(p.join(root.path, 'luma_backups'));
    if (!await dir.exists()) {
      return [];
    }
    final files = <File>[];
    await for (final ent in dir.list(followLinks: false)) {
      if (ent is! File) {
        continue;
      }
      final name = p.basename(ent.path);
      if (name.startsWith('auto-backup-') && name.endsWith('.luma')) {
        files.add(ent);
      }
    }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return [
      for (final f in files)
        BackupInfo(
          path: f.path,
          createdAt: f.lastModifiedSync().toUtc(),
          sizeBytes: f.lengthSync(),
        ),
    ];
  }

  /// Deletes auto-backups beyond the newest [keepCount].
  Future<void> pruneBackups({int keepCount = 3}) async {
    final infos = await listBackups();
    if (infos.length <= keepCount) {
      return;
    }
    for (final info in infos.skip(keepCount)) {
      try {
        await File(info.path).delete();
      } catch (_) {
        // Best-effort cleanup.
      }
    }
  }

  static String _timestampForFile(DateTime u) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${u.year.toString().padLeft(4, '0')}-'
        '${two(u.month)}-${two(u.day)}-'
        '${two(u.hour)}${two(u.minute)}${two(u.second)}';
  }
}

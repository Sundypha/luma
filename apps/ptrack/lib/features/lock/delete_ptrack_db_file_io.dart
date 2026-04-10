import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'ptrack_db_delete_result.dart';

/// Removes the default on-disk SQLite file used by [openPtrackDatabase], if present.
Future<PtrackDbDeleteResult> deletePtrackDatabaseFileIfExists() async {
  try {
    late final String resolvedPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      resolvedPath = '${dir.path}/ptrack.sqlite';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      resolvedPath = '${dir.path}/ptrack.sqlite';
    }
    final file = File(resolvedPath);
    if (!await file.exists()) {
      return const PtrackDbNotFound();
    }
    await file.delete();
    return const PtrackDbDeleted();
  } on Object catch (e) {
    return PtrackDbDeleteFailed(e);
  }
}

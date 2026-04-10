import 'package:flutter/foundation.dart';

import 'ptrack_db_delete_result.dart';

/// Closes the database then removes the on-disk SQLite file, logging delete failures.
///
/// [deleteDatabaseFile] should match [deletePtrackDatabaseFileIfExists] or a test override.
Future<PtrackDbDeleteResult> closeAndDeletePtrackDatabaseFile({
  required Future<void> Function() closeDatabase,
  required Future<PtrackDbDeleteResult> Function() deleteDatabaseFile,
  void Function(PtrackDbDeleteResult result)? onAfterDelete,
}) async {
  await closeDatabase();
  final result = await deleteDatabaseFile();
  switch (result) {
    case PtrackDbDeleteFailed(:final cause):
      debugPrint('Ptrack database file delete failed: $cause');
    case PtrackDbDeleted():
    case PtrackDbNotFound():
      break;
  }
  onAfterDelete?.call(result);
  return result;
}

import 'ptrack_db_delete_result.dart';

/// Stub: no filesystem database (e.g. web); nothing to remove.
Future<PtrackDbDeleteResult> deletePtrackDatabaseFileIfExists() async {
  return const PtrackDbNotFound();
}

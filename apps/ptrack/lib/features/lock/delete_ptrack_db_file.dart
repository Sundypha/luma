import 'delete_ptrack_db_file_stub.dart'
    if (dart.library.io) 'delete_ptrack_db_file_io.dart' as ptrack_db_io;

/// Removes the default on-disk SQLite file used by [openPtrackDatabase], if present.
Future<void> deletePtrackDatabaseFileIfExists() =>
    ptrack_db_io.deletePtrackDatabaseFileIfExists();

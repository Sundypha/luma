export 'ptrack_db_delete_result.dart';

import 'delete_ptrack_db_file_stub.dart'
    if (dart.library.io) 'delete_ptrack_db_file_io.dart' as ptrack_db_io;

import 'ptrack_db_delete_result.dart';

/// Removes the default on-disk SQLite file used by [openPtrackDatabase], if present.
Future<PtrackDbDeleteResult> deletePtrackDatabaseFileIfExists() =>
    ptrack_db_io.deletePtrackDatabaseFileIfExists();

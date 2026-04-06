import 'package:drift/drift.dart';

import 'ptrack_database.dart';

/// Web and other non-IO platforms: local SQLite is not supported.
QueryExecutor openPtrackQueryExecutor({String? databasePath}) {
  throw UnsupportedError(
    'Ptrack local database is not available on this platform. '
    'Use Android, iOS, desktop, or a test executor.',
  );
}

/// Web and other non-IO platforms: local SQLite is not supported.
PtrackDatabase openPtrackDatabase({String? databasePath}) {
  throw UnsupportedError(
    'Ptrack local database is not available on this platform. '
    'Use Android, iOS, desktop, or a test executor.',
  );
}

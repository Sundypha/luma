import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ptrack_database.dart';

/// Web and other non-IO platforms: local SQLite is not supported.
QueryExecutor openPtrackQueryExecutor({
  String? databasePath,
  FlutterSecureStorage? encryptionKeyStorage,
}) {
  throw UnsupportedError(
    'Ptrack local database is not available on this platform. '
    'Use Android, iOS, desktop, or a test executor.',
  );
}

/// Web and other non-IO platforms: local SQLite is not supported.
PtrackDatabase openPtrackDatabase({
  String? databasePath,
  FlutterSecureStorage? encryptionKeyStorage,
}) {
  throw UnsupportedError(
    'Ptrack local database is not available on this platform. '
    'Use Android, iOS, desktop, or a test executor.',
  );
}

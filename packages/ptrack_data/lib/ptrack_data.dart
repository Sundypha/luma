/// Data layer for ptrack: Drift-backed local persistence.
library;

export 'src/db/ptrack_database.dart'
    show
        PtrackDatabase,
        openPtrackDatabase,
        openPtrackQueryExecutor,
        ptrackSupportedSchemaVersion;

/// Identifies the data package; used to verify monorepo wiring.
class PtrackData {
  const PtrackData._();

  /// Package name constant for tests and app imports.
  static const String packageName = 'ptrack_data';
}

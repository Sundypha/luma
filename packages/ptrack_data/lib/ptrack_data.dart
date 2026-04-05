/// Data layer for ptrack: Drift-backed local persistence.
library;

export 'src/db/migrations.dart'
    show PtrackUnsupportedDatabaseSchemaException;
export 'src/db/ptrack_database.dart'
    show
        PtrackDatabase,
        openPtrackDatabase,
        openPtrackQueryExecutor,
        ptrackSupportedSchemaVersion;
export 'src/mappers/day_entry_mapper.dart'
    show
        dayEntryDataToInsertCompanion,
        dayEntryDataToUpdateCompanion,
        dayEntryRowToDomain;
export 'src/mappers/period_mapper.dart'
    show
        periodRowToDomain,
        periodSpanToInsertCompanion,
        periodSpanToUpdateCompanion;
export 'src/repositories/period_repository.dart'
    show
        PeriodRepository,
        PeriodWriteNotFound,
        PeriodWriteOutcome,
        PeriodWriteRejected,
        PeriodWriteSuccess,
        StoredPeriod;
export 'src/prediction/prediction_coordinator.dart'
    show
        PredictionCoordinator,
        PredictionCoordinatorResult,
        predictionCycleInputsFromStored;

/// Identifies the data package; used to verify monorepo wiring.
class PtrackData {
  const PtrackData._();

  /// Package name constant for tests and app imports.
  static const String packageName = 'ptrack_data';
}

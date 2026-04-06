/// Data layer for ptrack: Drift-backed local persistence.
library;

export 'src/db/migrations.dart'
    show PtrackUnsupportedDatabaseSchemaException;
export 'src/export/export_schema.dart'
    show
        ExportOptions,
        ExportedDayEntry,
        ExportedPeriod,
        LumaExportData,
        LumaExportMeta,
        lumaFormatVersion;
export 'src/export/export_service.dart'
    show ExportResult, ExportService, ProgressCallback;
export 'src/export/luma_crypto.dart' show LumaCrypto;
export 'src/db/ptrack_database.dart'
    show
        PtrackDatabase,
        openPtrackDatabase,
        openPtrackQueryExecutor,
        ptrackSupportedSchemaVersion;
export 'package:ptrack_domain/ptrack_domain.dart' show DayEntryData;
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
        DayMarkFailure,
        DayMarkOutcome,
        DayMarkSuccess,
        PeriodRepository,
        PeriodWriteBlockedByOrphanDayEntries,
        PeriodWriteNotFound,
        PeriodWriteOutcome,
        PeriodWriteRejected,
        PeriodWriteSuccess,
        StoredDayEntry,
        StoredPeriod,
        StoredPeriodWithDays;
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

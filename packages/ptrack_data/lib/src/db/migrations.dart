import 'package:drift/drift.dart';

/// Thrown when the on-disk `user_version` is greater than this app build supports.
///
/// Opening must fail closed so the app does not silently misread a newer schema.
class PtrackUnsupportedDatabaseSchemaException implements Exception {
  const PtrackUnsupportedDatabaseSchemaException({
    required this.onDiskVersion,
    required this.supportedVersion,
  });

  final int onDiskVersion;
  final int supportedVersion;

  @override
  String toString() =>
      'PtrackUnsupportedDatabaseSchemaException: database schema version '
      '$onDiskVersion is newer than supported $supportedVersion. '
      'Upgrade the app or restore a backup.';
}

/// Ensures we never run [Migrator.onUpgrade] when the file is newer than [supported].
///
/// Call at the start of [MigrationStrategy.onUpgrade].
void assertSupportedSchemaUpgrade({
  required int fromVersion,
  required int toVersion,
  required int supported,
}) {
  if (fromVersion > supported) {
    throw PtrackUnsupportedDatabaseSchemaException(
      onDiskVersion: fromVersion,
      supportedVersion: supported,
    );
  }
  if (fromVersion < toVersion && toVersion > supported) {
    throw StateError(
      'Migration targets schema $toVersion but supported cap is $supported',
    );
  }
}

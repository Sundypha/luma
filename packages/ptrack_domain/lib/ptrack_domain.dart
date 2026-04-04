/// Domain layer for ptrack: period semantics, validation, cycle length, prediction types.
library;

export 'src/period/period_models.dart';
export 'src/period/period_validation.dart';

/// Identifies the domain package; used to verify monorepo wiring.
class PtrackDomain {
  const PtrackDomain._();

  /// Package name constant for tests and app imports.
  static const String packageName = 'ptrack_domain';
}

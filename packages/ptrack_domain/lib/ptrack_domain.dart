/// Domain layer for ptrack: period semantics, validation, cycle length, prediction types.
library;

export 'src/period/cycle_length.dart';
export 'src/period/period_models.dart';
export 'src/period/period_validation.dart';
export 'src/prediction/explanation_step.dart';
export 'src/prediction/prediction_copy.dart';
export 'src/prediction/prediction_engine.dart';
export 'src/prediction/prediction_result.dart';

/// Identifies the domain package; used to verify monorepo wiring.
class PtrackDomain {
  const PtrackDomain._();

  /// Package name constant for tests and app imports.
  static const String packageName = 'ptrack_domain';
}

import 'package:meta/meta.dart';

/// User-visible milestone when more prediction algorithms become active.
/// Copy is resolved in the app layer via [AppLocalizations].
@immutable
class EnsembleMilestone {
  const EnsembleMilestone({
    required this.kind,
    this.cycleCount = 0,
    this.activeAlgorithmCount = 0,
  });

  final EnsembleMilestoneKind kind;

  /// Used when [kind] is [EnsembleMilestoneKind.expandedMethodCount].
  final int cycleCount;

  /// Used when [kind] is [EnsembleMilestoneKind.expandedMethodCount].
  final int activeAlgorithmCount;
}

enum EnsembleMilestoneKind {
  /// Four algorithms contribute (trend line active).
  trendDetectionActive,

  /// Three algorithms contribute (all core methods).
  allCoreMethodsActive,

  /// Two algorithms contribute; show cycle and method counts.
  expandedMethodCount,
}

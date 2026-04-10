# Phase 9: Prediction of Next Period - Research

**Researched:** 2026-04-07
**Domain:** Multi-algorithm ensemble prediction with confidence-tiered calendar visualization (Dart/Flutter)
**Confidence:** HIGH

## Summary

Phase 9 replaces the single `PredictionEngine` (median-based) with a multi-algorithm ensemble that aggregates 3–4 independent prediction algorithms, all running on-device in pure Dart. Each algorithm predicts cycle length (and derived period days); per-day confidence tiers reflect how many algorithms agree on each predicted day. The calendar visualization evolves from a single `HatchedCirclePainter` to a confidence-tiered painter using opacity + hatch density (two independent visual channels for NFR-06 accessibility).

The existing codebase provides a clean separation point: `PredictionEngine` (domain layer) produces `PredictionEngineResult`, `PredictionCoordinator` (data layer) bridges repository → engine → copy, and `CalendarViewModel` / `HomeViewModel` consume `PredictionResult` to build `CalendarDayData`. The ensemble refactor introduces an abstract `PredictionAlgorithm` interface, wraps the existing median engine as Algorithm 1, adds EWMA / Bayesian / Linear Trend as sibling implementations, and replaces the single `PredictionResult` with per-day confidence maps. No external math libraries are needed — all algorithms are closed-form formulas implementable in ~30–80 lines of Dart each.

**Primary recommendation:** Implement all algorithms in pure Dart inside `ptrack_domain`, introduce an `EnsemblePredictionCoordinator` in `ptrack_data` that runs algorithms and aggregates per-day agreement counts, and evolve `CalendarDayData` + painters to render three confidence tiers. Add a `PredictionDisplayMode` setting via `SharedPreferences` for user-selectable display presets.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Confidence calendar visualization:** Opacity tiers for predicted days: same hatch pattern but fading opacity — faint (1 algorithm agrees), medium (2 agree), strong (3+ agree). Hatch density also varies for accessibility (NFR-06): sparse hatch (1 algo), medium hatch (2), dense hatch (3+). Two independent visual channels (opacity + pattern density) ensure distinction without relying on color alone. Logged days stay solid — only future predicted days show confidence tiers. Both legend + tap detail: subtle inline legend below calendar showing the 3 opacity/density levels with labels. Tapping a predicted day shows "X of 3 methods agree" in the day detail sheet.
- **Algorithm output & disagreement handling:** Each algorithm primarily predicts cycle length (next start date). Default display: consensus-only — only show days where 2+ algorithms agree. Hide lone-algorithm predictions. User-selectable presets in Settings: users can switch between display modes (e.g., consensus-only, show-all, show-all-with-note). Default is consensus-only. This lives in the Settings screen under a "Prediction display" option.
- **Prediction explanation UX:** Layered: summary + drill-down — default shows consensus summary ("X of 3 methods predict your period on this day" + one-line per algorithm). Tap "See details" to expand individual algorithm explanations. "Methods agree" framing for confidence language — say "All 3 methods agree on this day" rather than "High confidence". Two entry points: home screen prediction card has "How is this calculated?" link + day detail sheet shows per-day explanation.
- **Cold start & algorithm readiness:** Always show whatever's available — even 1 algorithm's output is useful. When only 1 algorithm is active, predicted days show as low-confidence (faintest tier). Milestone messages when new algorithms come online: "With 3 cycles logged, prediction now uses 2 methods" / "With 6 cycles, all methods active". Linear Trend (stretch) activation is part of milestone messages.

### Claude's Discretion
- Period duration prediction approach (shared estimate vs per-algorithm)
- Algorithm user-facing naming style
- Exact hatch pattern densities and opacity values
- EWMA decay factor (α) and Bayesian prior selection
- Linear Trend significance threshold
- Milestone message copy and presentation

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PRED-01 | Next-period estimate uses documented deterministic rules from user's period history | Extended: ensemble of 3+ documented algorithms (Median, EWMA, Bayesian, Linear Trend). All deterministic given inputs. Architecture pattern: Strategy + Ensemble. |
| PRED-02 | When history is insufficient or highly variable, app surfaces uncertainty instead of false precision | Extended: confidence tiers (1/2/3+ agreement) explicitly surface uncertainty. Cold-start shows faintest tier. Consensus-only default hides lone-algorithm predictions. |
| PRED-03 | User can read a plain-language explanation of how the current prediction was derived | Extended: layered explanation with per-algorithm summary + drill-down. "X of 3 methods agree" framing. ExplanationStep model extended for multi-algorithm output. |
| PRED-04 | Copy and UI never frame prediction as contraception or medically authoritative | Preserved: "methods agree" framing (not "confidence"), existing `predictionCopyForbiddenPhrasesLowercase` guardrails apply to all new copy. Non-medical positioning maintained throughout. |
| NFR-06 | Predicted vs actual periods distinguishable without relying on color alone | Extended: three tiers use dual channels (opacity + hatch density) for color-blind accessibility. Logged days remain solid. Pattern density is the primary distinguishing channel. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dart:math` | (SDK) | `sqrt`, `pow`, `log`, `exp` for algorithm formulas | Built-in, zero dependency, sufficient for all four algorithms |
| `meta` | ^1.16.0 | `@immutable` annotations for algorithm result types | Already in `ptrack_domain` |
| `timezone` | ^0.10.1 | Calendar-day normalization (existing pattern) | Already in `ptrack_domain` |
| `shared_preferences` | ^2.5.5 | Persist `PredictionDisplayMode` user setting | Already in app, same pattern as `MoodSettings` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_test` | (SDK) | Unit tests for algorithms and ensemble | All algorithm and coordinator tests |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pure Dart math | `statistics` package | Adds dependency for ~30 lines of math; `statistics` is 6K+ lines with Bayesian networks — massive overkill for 4 simple formulas |
| Pure Dart linear regression | `ml_linear_regression` | 0 likes, unverified publisher; simple `y = mx + b` via least squares is 15 lines |
| Pure Dart EWMA | `moving_average` package | Designed for time-series point lists, not cycle-length smoothing; adds abstraction overhead for a 5-line formula |
| `patterns_canvas` for hatching | Hand-rolled `CustomPainter` | Existing `HatchedCirclePainter` already implements diagonal stripes; extending with density parameter is simpler than adding a dependency |

**No new dependencies needed.** All algorithms are closed-form formulas in pure Dart. The existing `HatchedCirclePainter` already draws diagonal stripes and is the natural extension point for confidence tiers. `SharedPreferences` is already in the app for `MoodSettings`.

## Architecture Patterns

### Recommended Project Structure
```
packages/ptrack_domain/lib/src/prediction/
├── prediction_algorithm.dart      # Abstract interface + AlgorithmId enum
├── prediction_engine.dart         # Existing MedianBaseline (Algorithm 1) — preserved
├── ewma_algorithm.dart            # Algorithm 2: EWMA
├── bayesian_algorithm.dart        # Algorithm 3: Bayesian posterior
├── linear_trend_algorithm.dart    # Algorithm 4: Linear Trend (stretch)
├── ensemble_result.dart           # Per-day confidence map + per-algorithm outputs
├── prediction_result.dart         # Existing sealed result types — preserved
├── explanation_step.dart          # Extended with multi-algorithm kinds
└── prediction_copy.dart           # Extended with multi-algorithm explanation formatting

packages/ptrack_data/lib/src/prediction/
├── prediction_coordinator.dart    # Existing — refactored to use ensemble
└── ensemble_coordinator.dart      # Runs algorithms, aggregates, builds confidence map

apps/ptrack/lib/features/calendar/
├── calendar_day_data.dart         # Extended: isPredictedPeriod → confidenceTier (int 0–3)
├── calendar_painters.dart         # Extended: ConfidenceHatchedCirclePainter with tier parameter
└── calendar_screen.dart           # Updated to pass confidence tiers

apps/ptrack/lib/features/settings/
└── prediction_settings.dart       # PredictionDisplayMode enum + SharedPreferences tile

apps/ptrack/lib/features/home/
└── home_screen.dart               # "How is this calculated?" link + milestone messages
```

### Pattern 1: Strategy Pattern for Algorithms
**What:** Each algorithm implements a common interface returning predicted period days + algorithm-specific explanation. The ensemble orchestrator iterates all enabled algorithms and aggregates.
**When to use:** Whenever multiple interchangeable algorithms produce comparable outputs.

```dart
/// Abstract prediction algorithm — one prediction method.
abstract class PredictionAlgorithm {
  AlgorithmId get id;

  /// Human-readable name for explanation UX.
  String get displayName;

  /// Minimum completed cycles needed to produce output.
  int get minCycles;

  /// Predicts next period start date + optional period duration.
  /// Returns null if insufficient data.
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles);
}

/// Output of a single algorithm.
@immutable
class AlgorithmPrediction {
  const AlgorithmPrediction({
    required this.algorithmId,
    required this.predictedStartUtc,
    required this.predictedDurationDays,
    required this.explanationSteps,
  });

  final AlgorithmId algorithmId;
  final DateTime predictedStartUtc;
  final int predictedDurationDays;
  final List<ExplanationStep> explanationSteps;
}
```

### Pattern 2: Ensemble Aggregation with Per-Day Confidence
**What:** The ensemble coordinator runs all algorithms, maps each prediction to calendar days, and counts algorithm agreement per day. The result is a `Map<DateTime, int>` where value = number of agreeing algorithms (1, 2, or 3+).
**When to use:** In `EnsembleCoordinator.predictNext()` — replaces the single `PredictionResult` output with a richer `EnsemblePredictionResult`.

```dart
@immutable
class EnsemblePredictionResult {
  const EnsemblePredictionResult({
    required this.algorithmOutputs,
    required this.dayConfidenceMap,
    required this.activeAlgorithmCount,
    required this.totalAlgorithmCount,
    required this.milestoneMessage,
  });

  /// Individual algorithm outputs (for explanation drill-down).
  final List<AlgorithmPrediction> algorithmOutputs;

  /// Per-day confidence: key = UTC midnight, value = number of algorithms agreeing.
  final Map<DateTime, int> dayConfidenceMap;

  final int activeAlgorithmCount;
  final int totalAlgorithmCount;

  /// Non-null when a new algorithm just became active.
  final String? milestoneMessage;
}
```

### Pattern 3: CalendarDayData Confidence Tier
**What:** Replace `bool isPredictedPeriod` with `int predictionConfidenceTier` (0 = none, 1 = low, 2 = medium, 3 = high). The painter receives this tier and adjusts opacity + stripe spacing accordingly.
**When to use:** In `buildCalendarDayDataMap()` — maps `dayConfidenceMap` entries to tiers.

```dart
@immutable
class CalendarDayData {
  const CalendarDayData({
    this.loggedPeriodState = PeriodDayState.none,
    this.predictionConfidenceTier = 0,
    this.predictionAgreementCount = 0,
    this.hasLoggedData = false,
    this.isToday = false,
  });

  final PeriodDayState loggedPeriodState;
  /// 0 = no prediction, 1 = low (1 algo), 2 = medium (2 algos), 3 = high (3+ algos).
  final int predictionConfidenceTier;
  /// Raw count for tap detail ("X of 3 methods agree").
  final int predictionAgreementCount;
  final bool hasLoggedData;
  final bool isToday;

  bool get isPredictedPeriod => predictionConfidenceTier > 0;
}
```

### Pattern 4: SharedPreferences Settings (existing pattern)
**What:** `PredictionDisplayMode` enum persisted via `SharedPreferences`, following the exact same pattern as `MoodSettings`.
**When to use:** For the user-selectable display presets (consensus-only, show-all, show-all-with-note).

```dart
enum PredictionDisplayMode {
  consensusOnly,   // Default: only 2+ algorithms agree
  showAll,         // Show all predictions including lone-algorithm
  showAllWithNote, // Show all, but mark lone predictions with note
}

class PredictionSettings {
  static const _key = 'prediction_display_mode';

  static Future<PredictionDisplayMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return PredictionDisplayMode.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => PredictionDisplayMode.consensusOnly,
    );
  }

  static Future<void> save(PredictionDisplayMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
```

### Anti-Patterns to Avoid
- **God-class ensemble engine:** Don't put all algorithm logic in one class. Each algorithm is its own class implementing the interface.
- **Coupling UI tiers to algorithm count:** Don't hardcode `if (count == 3)` — use `min(count, 3)` for tier mapping so the system scales if a 5th algorithm is added later.
- **Modifying `PredictionEngine` internals:** The existing median engine is well-tested. Wrap it behind the `PredictionAlgorithm` interface without changing its internal logic.
- **Storing algorithm state in DB:** All algorithms are stateless computations from cycle history. No schema migration needed.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Calendar-day normalization | Custom UTC date math | Existing `_utcMidnight()` / `_utcDateOnly()` helpers | Already battle-tested throughout codebase; DST-safe via `timezone` |
| Cycle input extraction | New period-to-cycle conversion | Existing `predictionCycleInputsFromStored()` | Handles same-day duplicates, open-span skipping, ordering |
| Forbidden-copy checking | New copy guardrails | Existing `predictionCopyForbiddenPhrasesLowercase` | PRED-04 compliance already implemented |
| Preference persistence | Custom file/DB storage | `SharedPreferences` via existing `MoodSettings` pattern | Proven pattern, no schema migration, sync across app restarts |

**Key insight:** The existing prediction infrastructure (cycle input extraction, explanation steps, copy formatting, calendar day data mapping) is well-factored. Phase 9 extends these — it doesn't replace them. The median engine is preserved as Algorithm 1 with zero changes to its internal logic.

## Common Pitfalls

### Pitfall 1: EWMA Overreaction to Single Anomalous Cycle
**What goes wrong:** High α (e.g., 0.5+) makes EWMA swing wildly after one unusual cycle, producing predictions far from user's norm.
**Why it happens:** EWMA inherently amplifies recent data. With typical 6–12 cycles of history, one outlier dominates.
**How to avoid:** Use moderate α = 0.3 (balances recency with stability). The existing median engine's outlier exclusion doesn't apply to EWMA — EWMA's resilience comes from low α. Document the chosen α and rationale.
**Warning signs:** EWMA prediction differs from median by >5 days on stable-pattern users.

### Pitfall 2: Bayesian Prior Dominating Small Samples
**What goes wrong:** If the prior is too tight (low κ₀), the posterior barely moves from the prior mean even after 3–4 observed cycles. If too loose, the prior contributes nothing and Bayesian degenerates to sample statistics.
**Why it happens:** Normal-Inverse-Gamma conjugate requires careful prior selection. For menstrual cycles, a weakly informative prior (μ₀=28, κ₀=1, α₀=2, β₀=15) lets the first few observations dominate while still providing reasonable output with just 2 cycles.
**How to avoid:** Use weakly informative prior centered at 28 days. Document prior parameters and update equations. Test with 2, 3, 5, and 10 cycles to verify prior washes out.
**Warning signs:** Bayesian output barely changes between 2 and 6 cycles (too tight prior).

### Pitfall 3: Linear Trend Overfitting Short History
**What goes wrong:** Linear regression on 3–5 points produces a slope that projects unrealistic cycle lengths. E.g., cycles [28, 29, 30] yields slope=1, projecting cycle 10 as 37 days — reasonable. But [28, 30, 28] yields slope=0 with high noise, projecting exactly 28 — which is just the median again but less robust.
**Why it happens:** Linear regression is designed for trending data. Most menstrual cycles don't exhibit trends; they're better modeled as stationary with noise.
**How to avoid:** Require minimum 5 cycles. Gate activation on R² threshold: only activate when R² > 0.5 (explains more variance than a flat line). When below threshold, this algorithm returns null (doesn't participate in ensemble).
**Warning signs:** R² < 0.3 but algorithm still producing output; trend projects cycle length outside [18, 50] days.

### Pitfall 4: Calendar Day Overlap Between Algorithms
**What goes wrong:** Algorithms predict slightly different start dates. Algorithm A says period starts Day 25, Algorithm B says Day 26. Each predicts 5-day duration. Days 25 and 31 only have 1 algorithm agreement, Days 26–30 have 2. The "agreement" visualization becomes confusing because algorithms mostly agree but are offset by 1 day.
**Why it happens:** Different algorithms optimize different objectives (median vs recency-weighted vs posterior mean). Small disagreements in start date are normal and expected.
**How to avoid:** This is the correct behavior. The tier system naturally communicates this: the "core" predicted days (where algorithms overlap) show higher confidence, and the edges show lower. Document this as a feature, not a bug. The explanation UX clarifies: "Method A predicts Day 25, Method B predicts Day 26."
**Warning signs:** None — this is working as intended.

### Pitfall 5: Breaking Existing Calendar Rendering
**What goes wrong:** Replacing `bool isPredictedPeriod` with `int predictionConfidenceTier` breaks every consumer of `CalendarDayData`.
**Why it happens:** The `isPredictedPeriod` field is used in `buildCalendarDayCell()`, `buildCalendarDayDataMap()`, `CalendarScreen`, and tests.
**How to avoid:** Add `predictionConfidenceTier` field and derive `isPredictedPeriod` as a getter (`tier > 0`). This preserves backward compatibility while enabling the new tier rendering. Migrate callers incrementally.
**Warning signs:** Test failures in existing calendar tests after `CalendarDayData` changes.

### Pitfall 6: Display Mode Filtering at Wrong Layer
**What goes wrong:** Filtering consensus-only vs show-all in the domain or data layer makes the prediction engine aware of UI preferences.
**Why it happens:** Temptation to filter early for "efficiency."
**How to avoid:** The ensemble always computes the full `dayConfidenceMap` with all tiers. The `PredictionDisplayMode` filtering happens in `buildCalendarDayDataMap()` (the view-data boundary) — tier 1 entries are excluded when mode is `consensusOnly`. This keeps domain/data layers pure and testable.
**Warning signs:** Algorithm tests referencing `PredictionDisplayMode`.

## Code Examples

### EWMA Cycle Length Estimator
```dart
/// Exponentially Weighted Moving Average of cycle lengths.
/// Formula: x̃_{t} = α * x_{t} + (1 - α) * x̃_{t-1}
/// Source: Stanford EWMM paper (Boyd et al.), adapted for discrete cycle data.
class EwmaAlgorithm implements PredictionAlgorithm {
  const EwmaAlgorithm({this.alpha = 0.3});

  final double alpha;

  @override
  AlgorithmId get id => AlgorithmId.ewma;

  @override
  String get displayName => 'Recent-weighted';

  @override
  int get minCycles => 2;

  @override
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles) {
    if (cycles.length < minCycles) return null;
    double ewma = cycles.first.lengthInDays.toDouble();
    for (var i = 1; i < cycles.length; i++) {
      ewma = alpha * cycles[i].lengthInDays + (1 - alpha) * ewma;
    }
    final predictedLength = ewma.round();
    final anchor = cycles.last.periodStartUtc;
    final predictedStart = _addUtcCalendarDays(anchor, predictedLength);
    // ... build explanation steps, return AlgorithmPrediction
  }
}
```

### Bayesian Normal-Inverse-Gamma Posterior Update
```dart
/// Bayesian posterior estimation of cycle length using Normal-Inverse-Gamma
/// conjugate prior. Models cycle length as Normal(μ, σ²) with both unknown.
///
/// Prior: μ|σ² ~ N(μ₀, σ²/κ₀),  σ² ~ IG(α₀, β₀)
/// Posterior update (Murphy 2007, §3):
///   κₙ = κ₀ + n
///   μₙ = (κ₀·μ₀ + n·x̄) / κₙ
///   αₙ = α₀ + n/2
///   βₙ = β₀ + ½·Σ(xᵢ - x̄)² + (κ₀·n·(x̄ - μ₀)²) / (2·κₙ)
///
/// Point estimate: μₙ (posterior mean of cycle length)
/// Predictive variance: βₙ·(κₙ + 1) / (αₙ·κₙ) — Student-t spread
class BayesianAlgorithm implements PredictionAlgorithm {
  const BayesianAlgorithm({
    this.priorMu = 28.0,
    this.priorKappa = 1.0,
    this.priorAlpha = 2.0,
    this.priorBeta = 15.0,
  });

  final double priorMu;
  final double priorKappa;
  final double priorAlpha;
  final double priorBeta;

  @override
  AlgorithmId get id => AlgorithmId.bayesian;

  @override
  String get displayName => 'Pattern-learning';

  @override
  int get minCycles => 2;

  @override
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles) {
    if (cycles.length < minCycles) return null;
    final n = cycles.length.toDouble();
    final lengths = cycles.map((c) => c.lengthInDays.toDouble()).toList();
    final xBar = lengths.reduce((a, b) => a + b) / n;
    final ssq = lengths.fold<double>(0, (sum, x) => sum + (x - xBar) * (x - xBar));

    final kappaN = priorKappa + n;
    final muN = (priorKappa * priorMu + n * xBar) / kappaN;
    final alphaN = priorAlpha + n / 2;
    final betaN = priorBeta + 0.5 * ssq +
        (priorKappa * n * (xBar - priorMu) * (xBar - priorMu)) / (2 * kappaN);

    final predictedLength = muN.round();
    final anchor = cycles.last.periodStartUtc;
    final predictedStart = _addUtcCalendarDays(anchor, predictedLength);
    // ... build explanation with posterior parameters, return AlgorithmPrediction
  }
}
```

### Linear Trend Projection (Stretch)
```dart
/// Simple linear regression on cycle index → cycle length.
/// y = slope * x + intercept, where x = cycle index (0, 1, 2, ...).
/// Projects next cycle length = slope * n + intercept.
/// Gated on R² > 0.5 to avoid spurious trends.
class LinearTrendAlgorithm implements PredictionAlgorithm {
  const LinearTrendAlgorithm({
    this.rSquaredThreshold = 0.5,
  });

  final double rSquaredThreshold;

  @override
  AlgorithmId get id => AlgorithmId.linearTrend;

  @override
  String get displayName => 'Trend';

  @override
  int get minCycles => 5;

  @override
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles) {
    if (cycles.length < minCycles) return null;
    final n = cycles.length;
    // Least squares: y = mx + b
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = cycles[i].lengthInDays.toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // R² goodness-of-fit
    final yBar = sumY / n;
    double ssTot = 0, ssRes = 0;
    for (var i = 0; i < n; i++) {
      final y = cycles[i].lengthInDays.toDouble();
      final yHat = slope * i + intercept;
      ssTot += (y - yBar) * (y - yBar);
      ssRes += (y - yHat) * (y - yHat);
    }
    final rSquared = ssTot > 0 ? 1.0 - ssRes / ssTot : 0.0;
    if (rSquared < rSquaredThreshold) return null;

    final projectedLength = (slope * n + intercept).round().clamp(18, 50);
    // ... build explanation, return AlgorithmPrediction
  }
}
```

### Confidence-Tiered Hatched Circle Painter
```dart
/// Diagonal-stripe circle with variable opacity and density per confidence tier.
/// Tier 1 (low): sparse stripes, faint opacity
/// Tier 2 (medium): medium stripes, medium opacity
/// Tier 3 (high): dense stripes, strong opacity
class ConfidenceHatchedCirclePainter extends CustomPainter {
  ConfidenceHatchedCirclePainter({
    required this.tier,
    this.color = kPeriodColorLight,
  });

  final int tier; // 1, 2, or 3
  final Color color;

  static const _tierConfig = {
    1: (opacity: 0.30, spacing: 7.0, strokeWidth: 1.0),
    2: (opacity: 0.55, spacing: 4.5, strokeWidth: 1.3),
    3: (opacity: 0.85, spacing: 3.0, strokeWidth: 1.6),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final config = _tierConfig[tier.clamp(1, 3)]!;
    final tierColor = color.withValues(alpha: config.opacity);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.36;
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(circlePath);

    final stripePaint = Paint()
      ..color = tierColor
      ..strokeWidth = config.strokeWidth
      ..style = PaintingStyle.stroke;

    for (var offset = -size.height;
        offset < size.width + size.height;
        offset += config.spacing) {
      canvas.drawLine(
        Offset(offset, size.height),
        Offset(offset + size.height, 0),
        stripePaint,
      );
    }
    canvas.restore();

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = tierColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant ConfidenceHatchedCirclePainter oldDelegate) {
    return oldDelegate.tier != tier || oldDelegate.color != color;
  }
}
```

## Algorithm Design Decisions (Claude's Discretion)

### Period Duration: Shared Estimate
**Recommendation:** Use a **shared period duration** derived from the median of observed bleeding durations across all completed periods. Rationale: period duration is far less variable than cycle length across individuals. Different algorithms predicting different durations would create confusing "staggered" predictions on the calendar. A single shared duration keeps the calendar visualization clean and focuses algorithm disagreement on the more meaningful question: *when* the period starts.

### Algorithm Naming: Behavior-Descriptive Labels
**Recommendation:** Use plain-English behavior labels rather than technical names:
| Algorithm | Internal ID | User-Facing Name |
|-----------|------------|-----------------|
| Median Baseline | `median` | "Average spacing" |
| EWMA | `ewma` | "Recent-weighted" |
| Bayesian | `bayesian` | "Pattern-learning" |
| Linear Trend | `linearTrend` | "Trend" |

These names describe *what the algorithm does* from the user's perspective, not how it works internally. They fit naturally into the explanation: "The Recent-weighted method gives more importance to your latest cycles."

### EWMA Decay Factor: α = 0.3
**Recommendation:** α = 0.3 balances recency sensitivity with stability. With α = 0.3 and 6 cycles, the most recent cycle carries ~30% weight, the previous ~21%, and earlier cycles diminish smoothly. This is aggressive enough to detect genuine pattern shifts within 2–3 cycles but stable enough that one anomalous cycle doesn't dominate.

Half-life ≈ `log(0.5) / log(1 - 0.3)` ≈ 1.9 cycles — the influence of a cycle halves roughly every 2 cycles. This is appropriate for menstrual data where the last 2–3 cycles are most informative.

### Bayesian Prior: Weakly Informative N-IG
**Recommendation:** `μ₀ = 28.0, κ₀ = 1.0, α₀ = 2.0, β₀ = 15.0`
- `μ₀ = 28`: Population-mean cycle length. Sensible starting point; washes out after 3+ observations since κ₀ is low.
- `κ₀ = 1`: Prior contributes the equivalent of 1 observation. After 2 real cycles, the data already dominates 2:1.
- `α₀ = 2`: Minimum for a defined variance in the Inverse-Gamma. Mildly informative about spread.
- `β₀ = 15`: Implies a prior variance around β₀/α₀ = 7.5 days², i.e., prior std ≈ 2.7 days. Reasonable for typical cycle variability.

### Linear Trend: R² > 0.5, Min 5 Cycles
**Recommendation:** R² threshold of 0.5 means the linear model must explain at least half the variance in cycle lengths. This gates the algorithm so it only activates when there's a genuine trend (e.g., cycles gradually lengthening toward perimenopause). With less than 5 data points, regression is too noisy to be meaningful. Projected length clamped to [18, 50] days as a safety bound.

### Hatch Pattern Densities and Opacity Values
**Recommendation (exact values):**
| Tier | Agreement | Opacity | Stripe Spacing | Stroke Width | Visual Description |
|------|-----------|---------|---------------|-------------|-------------------|
| 1 | 1 algorithm | 0.30 | 7.0 px | 1.0 px | Very faint, sparse stripes |
| 2 | 2 algorithms | 0.55 | 4.5 px | 1.3 px | Medium visibility, medium density |
| 3 | 3+ algorithms | 0.85 | 3.0 px | 1.6 px | Strong, dense stripes (close to current single-tier) |

These values ensure each tier is visually distinct through both channels (opacity AND density), satisfying NFR-06. The current `HatchedCirclePainter` uses spacing=4.0, strokeWidth=1.5 — tier 3 is slightly denser, making the upgrade feel like a natural evolution rather than a regression.

### Milestone Message Copy
**Recommendation:**
| Cycles | Algorithms Active | Message |
|--------|------------------|---------|
| 2 | 1 (Median only) | — (no milestone, this is the starting state) |
| 3 | 2 (Median + EWMA) | "With 3 cycles logged, your prediction now uses 2 methods for better accuracy." |
| 3 | 3 (+ Bayesian) | "3 cycles logged — all core methods are now active." |
| 5 | 4 (+ Linear Trend, if R²>0.5) | "With 5 cycles, trend detection is now active." |

Messages shown as a subtle card below the prediction summary on the home screen, dismissible. Not shown again after first view (persisted flag in SharedPreferences).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single median-based prediction | Multi-algorithm ensemble with confidence tiers | Phase 9 | More nuanced uncertainty communication, adapts faster to pattern shifts |
| Single `PredictionResult` (point/range/insufficient) | `EnsemblePredictionResult` with per-day confidence map | Phase 9 | Calendar shows graduated confidence instead of binary predicted/not-predicted |
| Single `HatchedCirclePainter` (uniform) | `ConfidenceHatchedCirclePainter` with 3 tiers | Phase 9 | NFR-06 enhanced: dual-channel (opacity + density) accessibility |
| No user control over prediction display | `PredictionDisplayMode` in Settings | Phase 9 | User agency: consensus-only (default) vs show-all vs show-all-with-note |

**Preserved from current system:**
- `PredictionEngine` class and its tests (becomes Algorithm 1 adapter)
- `PredictionCycleInput` and `predictionCycleInputsFromStored()` (shared input pipeline)
- `predictionCopyForbiddenPhrasesLowercase` (PRED-04 guardrails)
- `PeriodBandPainter` (logged days unchanged)
- `TodayRingPainter` (today indicator unchanged)

## Open Questions

1. **Period duration estimation edge cases**
   - What we know: Shared duration estimate from observed bleeding durations is the recommended approach.
   - What's unclear: How to handle users who have highly variable period durations (e.g., 3–7 days). Should the ensemble use a "typical" duration (median) or the range?
   - Recommendation: Use median of observed durations. If no duration data is available (only start dates), default to 5 days (population median). Document this clearly in the explanation.

2. **Ensemble behavior with only 1 active algorithm (cold start)**
   - What we know: CONTEXT.md says "always show whatever's available" and single-algorithm predictions show as faintest tier.
   - What's unclear: The consensus-only display mode (default) hides tier-1 predictions. This means on cold start with <3 cycles, the default mode shows *nothing* while show-all mode would show faint predictions.
   - Recommendation: For cold start (only 1 algorithm active), override the display mode to show tier-1 predictions regardless of user setting. Once 2+ algorithms are active, respect the user's display mode choice. This avoids a regression from the current behavior where predictions appear after 2 cycles.

3. **Explanation text length**
   - What we know: Layered explanation with summary + drill-down. Each algorithm contributes 1–2 explanation lines.
   - What's unclear: With 3–4 algorithms, the drill-down could be 10+ lines. Is this too much?
   - Recommendation: Summary shows only consensus count ("3 of 3 methods agree on this day"). Drill-down shows one line per algorithm with its prediction. Full engine details (cycles considered, exclusions) available behind a second "More details" tap.

## Sources

### Primary (HIGH confidence)
- Existing codebase: `ptrack_domain/prediction_engine.dart`, `ptrack_data/prediction_coordinator.dart`, `calendar_painters.dart`, `calendar_day_data.dart` — verified via direct code reading
- Flutter `CustomPainter` API — `api.flutter.dev` — verified for opacity/paint patterns
- Normal-Inverse-Gamma conjugate prior update equations — Murphy (2007) "Conjugate Bayesian analysis of the Gaussian distribution" (UBC CS) — standard textbook result
- EWMA recursive formula — Stanford EWMM paper (Boyd et al.) — verified standard definition

### Secondary (MEDIUM confidence)
- SkipTrack Bayesian hierarchical model (arxiv.org/html/2508.05845v1, 2025) — confirms Bayesian approach to menstrual cycle modeling is well-established in literature
- Bellabeat advanced tracking algorithms (bellabeat.com, April 2025) — confirms industry practice of ML-based prediction, validates that simpler statistical methods (our Layer A approach) are the appropriate starting point per PRD Phase 4
- `data` package `stats` library (pub.dev) — confirms `NormalDistribution` and `InverseGammaDistribution` exist in Dart ecosystem if sampling needed later

### Tertiary (LOW confidence)
- `patterns_canvas` package (pub.dev) — evaluated but not recommended; existing hand-rolled painter is simpler for this use case
- `ml_linear_regression` package (pub.dev) — evaluated but not recommended; too thin, unverified publisher, trivial to implement inline
- `moving_average` package (pub.dev) — evaluated but not recommended; API designed for point-series, not cycle-length smoothing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all algorithms are textbook formulas implementable in pure Dart
- Architecture: HIGH — Strategy + Ensemble pattern is well-understood; existing codebase already separates domain/data/UI cleanly
- Pitfalls: HIGH — menstrual cycle prediction is well-studied; EWMA α sensitivity, Bayesian prior selection, and regression overfitting are documented concerns with known mitigations
- Calendar visualization: HIGH — extending existing `HatchedCirclePainter` with tier parameter follows the established `CustomPainter` pattern
- Algorithm math: HIGH — NIG conjugate update, EWMA, and least-squares regression are closed-form standard formulas

**Research date:** 2026-04-07
**Valid until:** 2026-05-07 (stable domain — statistical algorithms don't change; Flutter painting API is stable)

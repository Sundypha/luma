---
phase: 09-prediction-of-next-period
plan: 01
subsystem: domain
tags: [dart, prediction, ewma, bayesian, regression, ptrack_domain]

requires:
  - phase: 08-release-quality-offline-assurance-inclusive-copy
    provides: Stable v1 baseline and copy guardrails for building on

provides:
  - PredictionAlgorithm abstraction with AlgorithmId and AlgorithmPrediction
  - MedianBaselineAlgorithm adapter over unchanged PredictionEngine logic
  - EwmaAlgorithm (α=0.3), BayesianAlgorithm (NIG weak prior), LinearTrendAlgorithm (R²≥0.5, 5+ cycles)
  - EnsemblePredictionResult value type for Plan 02
  - Package-visible UTC calendar helpers addUtcCalendarDays / utcCalendarDateOnly
  - Extended ExplanationFactKind + prediction_copy lines for algorithm steps

affects:
  - 09-02 ensemble coordinator
  - 09-03 UI / painters / ViewModels

tech-stack:
  added: []
  patterns:
    - "Pure domain algorithms: same PredictionCycleInput in, AlgorithmPrediction? out"
    - "Median baseline wraps PredictionEngine without editing engine internals"

key-files:
  created:
    - packages/ptrack_domain/lib/src/prediction/prediction_algorithm.dart
    - packages/ptrack_domain/lib/src/prediction/ensemble_result.dart
    - packages/ptrack_domain/lib/src/prediction/ewma_algorithm.dart
    - packages/ptrack_domain/lib/src/prediction/bayesian_algorithm.dart
    - packages/ptrack_domain/lib/src/prediction/linear_trend_algorithm.dart
    - packages/ptrack_domain/test/prediction_algorithm_test.dart
  modified:
    - packages/ptrack_domain/lib/src/prediction/prediction_engine.dart
    - packages/ptrack_domain/lib/src/prediction/explanation_step.dart
    - packages/ptrack_domain/lib/src/prediction/prediction_copy.dart
    - packages/ptrack_domain/lib/ptrack_domain.dart
    - packages/ptrack_domain/test/prediction_copy_test.dart

key-decisions:
  - "Public UTC helpers live in prediction_engine.dart and are re-exported from prediction_algorithm.dart to avoid circular imports"
  - "Linear trend uses R² (not p-value) per plan spec; projection at cycle index n with length clamp [18, 50]"
  - "Median three-cycle test uses lengths (28, 29, 30) so median 29 matches engine math (plan example (28,30,28) has median 28)"

patterns-established:
  - "Algorithm explanations use ExplanationStep with algorithm-specific kinds and payloads"

requirements-completed: [PRED-01]

duration: 28min
completed: 2026-04-07
---

# Phase 9 Plan 01: Prediction algorithm foundation summary

**Multi-algorithm domain layer: median engine adapter, EWMA (α=0.3), Normal–Inverse-Gamma Bayesian mean, and R²-gated linear trend, with EnsemblePredictionResult and full unit coverage.**

## Performance

- **Duration:** ~28 min
- **Started:** 2026-04-07T00:00:00Z (approx.)
- **Completed:** 2026-04-07
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Introduced `PredictionAlgorithm` / `AlgorithmPrediction` / `AlgorithmId` and `EnsemblePredictionResult` for ensemble work in Plan 02.
- Wrapped existing `PredictionEngine` in `MedianBaselineAlgorithm` (range-only uses UTC midpoint calendar day).
- Implemented `EwmaAlgorithm`, `BayesianAlgorithm`, and `LinearTrendAlgorithm` with documented deterministic math and explanation steps.
- Added `prediction_algorithm_test.dart` (80 tests total in package; all pass).

## Task Commits

1. **Task 1: Algorithm interface, types, MedianBaselineAlgorithm adapter, and EwmaAlgorithm** — `ebb1c0c` (feat)
2. **Task 2: BayesianAlgorithm, LinearTrendAlgorithm, and comprehensive unit tests** — `73eaaad` (feat)

**Plan metadata:** Planning closure bundled with STATE.md and ROADMAP.md (`docs(09-01): Complete prediction algorithm foundation plan` in git history).

## Files Created/Modified

- `packages/ptrack_domain/lib/src/prediction/prediction_algorithm.dart` — Interface, types, median adapter, re-exports.
- `packages/ptrack_domain/lib/src/prediction/ensemble_result.dart` — Ensemble result DTO.
- `packages/ptrack_domain/lib/src/prediction/ewma_algorithm.dart` — EWMA cycle-length prediction.
- `packages/ptrack_domain/lib/src/prediction/bayesian_algorithm.dart` — NIG posterior mean prediction.
- `packages/ptrack_domain/lib/src/prediction/linear_trend_algorithm.dart` — OLS trend with R² gate and clamp.
- `packages/ptrack_domain/lib/src/prediction/prediction_engine.dart` — Public `addUtcCalendarDays` / `utcCalendarDateOnly`.
- `packages/ptrack_domain/lib/src/prediction/explanation_step.dart` — New algorithm explanation kinds.
- `packages/ptrack_domain/lib/src/prediction/prediction_copy.dart` — Copy lines for new kinds.
- `packages/ptrack_domain/lib/ptrack_domain.dart` — Barrel exports.
- `packages/ptrack_domain/test/prediction_algorithm_test.dart` — Algorithm tests.
- `packages/ptrack_domain/test/prediction_copy_test.dart` — YYYY-MM-DD probe without deprecated `RegExp` reference in doc comment.

## Decisions Made

- Re-exported `PredictionCycleInput` and engine helpers from `prediction_algorithm.dart` so algorithm implementations share one import surface.
- Adjusted the median “three regular cycles” test data to `[28, 29, 30]` so the expected median spacing is 29 days (consistent with `PredictionEngine` median, unlike `[28, 30, 28]` which medians to 28).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Analyzer fatal on deprecated RegExp reference in test doc comment**

- **Found during:** Task 1 verification (`dart analyze --fatal-infos`)
- **Issue:** Doc comment contained `[RegExp]`, triggering deprecated_member_use info treated as fatal.
- **Fix:** Rephrased comment; replaced calendar-date probe with a small digit-scan helper (no regex).
- **Files modified:** `packages/ptrack_domain/test/prediction_copy_test.dart`
- **Verification:** `fvm dart analyze packages/ptrack_domain --fatal-infos`
- **Committed in:** `ebb1c0c` (Task 1 commit)

**2. [Rule 1 - Bug] Wrong expected median in initial median baseline test**

- **Found during:** Task 2 test run
- **Issue:** Test expected 29-day spacing for lengths `(28, 30, 28)` but engine median is 28.
- **Fix:** Use `(28, 29, 30)` so median is 29 and expectation matches engine output.
- **Files modified:** `packages/ptrack_domain/test/prediction_algorithm_test.dart`
- **Verification:** `fvm flutter test` in `packages/ptrack_domain`
- **Committed in:** `73eaaad` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking analyzer, 1 test expectation)
**Impact on plan:** No scope change; behavior matches PRED-01 and existing engine semantics.

## Issues Encountered

- `gsd-tools.cjs state advance-plan` could not parse `STATE.md` (missing structured Current Plan fields); STATE/ROADMAP updated manually for this completion.

## User Setup Required

None.

## Next Phase Readiness

- Plan 02 can consume `PredictionAlgorithm` list outputs and `EnsemblePredictionResult`.
- `dayConfidenceMap` and consensus wiring remain to be implemented.

---

*Phase: 09-prediction-of-next-period*

*Completed: 2026-04-07*

## Self-Check: PASSED

- `09-01-SUMMARY.md` exists at `.planning/phases/09-prediction-of-next-period/09-01-SUMMARY.md`
- Task commits `ebb1c0c`, `73eaaad` present; planning closure commit present (see `git log --oneline -- .planning/phases/09-prediction-of-next-period/09-01-SUMMARY.md`)
- `packages/ptrack_domain` tests: 80/80 passed (`fvm flutter test`)

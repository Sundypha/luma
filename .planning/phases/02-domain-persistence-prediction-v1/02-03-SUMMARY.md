---
phase: 02-domain-persistence-prediction-v1
plan: 03
subsystem: domain
tags: [dart, flutter, tdd, prediction, median, explanation]

requires:
  - phase: 02-domain-persistence-prediction-v1
    provides: PredictionResult, ExplanationStep, completed-cycle semantics (Plan 01)
provides:
  - Pure PredictionEngine with configurable PredictionThresholds
  - Median-based next-start estimates with long-gap, long-bleed, and within-window outlier exclusions (last six cycles)
  - Uncertainty tiers: insufficient history, point+range, range-only high variability
  - Ordered ExplanationStep assembly (cyclesConsidered, cycleExcluded, medianCycleLength, tier-specific steps)
  - prediction_rules.md mirroring code thresholds and date policy
affects:
  - 02-04-PLAN (repository wiring, PRED-04 copy on top of engine output)

tech-stack:
  added: []
  patterns:
    - "UTC calendar-day anchor + Duration(days) for predicted instants (documented in prediction_rules.md)"
    - "Single-pass outlier drop after gap/bleed filtering when pool size ≥ 3"

key-files:
  created:
    - packages/ptrack_domain/lib/src/prediction/prediction_engine.dart
    - packages/ptrack_domain/lib/src/prediction/prediction_rules.md
    - packages/ptrack_domain/test/prediction_engine_test.dart
  modified:
    - packages/ptrack_domain/lib/ptrack_domain.dart
    - packages/ptrack_domain/lib/src/prediction/explanation_step.dart

key-decisions:
  - "Numeric thresholds: long gap >45d, long bleed >10d when bleedingDays set, outlier if |length−median|>7, high-variability tier when included spread ≥12d, window capped at six cycles."
  - "Even-count median uses mean of two middle lengths rounded to nearest integer (Dart .round())."
  - "Exclusion explanation lines use ExplanationFactKind.cycleExcluded with string codes long_gap, long_bleed, statistical_outlier."

patterns-established:
  - "PredictionEngine.predict takes oldest-first full history; engine slices the last six for statistics; anchor is always the latest period start in the full list."

requirements-completed: [PRED-01, PRED-02, PRED-03]

duration: 35 min
completed: 2026-04-04
---

# Phase 2 Plan 03: Deterministic prediction engine Summary

**Median-based next-start prediction over up to six completed cycles with documented exclusions, insufficient-history and high-variability tiers, and ordered ExplanationStep output for later UI.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-04-04T12:00:00Z (approximate)
- **Completed:** 2026-04-04T12:35:00Z (approximate)
- **Tasks:** 3 completed
- **Files modified:** 5

## Accomplishments

- TDD RED–GREEN–REFACTOR: failing vector tests, full `PredictionEngine` implementation, then docs/tests for empty input and six-cycle windowing.
- `prediction_rules.md` documents thresholds, median tie-breaking, UTC calendar-day policy, and explanation ordering aligned with `ExplanationFactKind`.
- `ExplanationFactKind.cycleExcluded` separates exclusion facts from the window summary step.

## Task Commits

1. **Task 1: RED — prediction engine tests** — `d6b64bf` (test)
2. **Task 2: GREEN — implement PredictionEngine** — `8926fa8` (feat)
3. **Task 3: REFACTOR — docs and edge cases** — `1c2f350` (ref)

**Plan metadata:** Single docs commit bundles this SUMMARY with `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md` updates.

## Files Created/Modified

- `packages/ptrack_domain/lib/src/prediction/prediction_engine.dart` — thresholds, inputs, `predict`, pure date helpers, explanation assembly.
- `packages/ptrack_domain/lib/src/prediction/prediction_rules.md` — human-readable rule spec mirrored by tests.
- `packages/ptrack_domain/test/prediction_engine_test.dart` — golden-style cases for median, outliers, long gap, variability, window, empty list.
- `packages/ptrack_domain/lib/ptrack_domain.dart` — exports `prediction_engine.dart`.
- `packages/ptrack_domain/lib/src/prediction/explanation_step.dart` — `cycleExcluded` kind; null-aware `reasonCode` in placeholder payload.

## Decisions Made

- Anchored next-start math on UTC date components of the latest `periodStartUtc`, then add whole days (`Duration`), matching documented local-first storage policy until a shared calendar helper is wired from persistence.
- High-variability test data uses lengths 22/28/34 so all cycles stay inside the outlier band while spread still hits the 12-day tier threshold.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] placeholderExplanationSteps analyzer hygiene**
- **Found during:** Task 1 (RED)
- **Issue:** `PredictionRangeOnly` payload needed a nullable `reasonCode`; analyzer required Dart null-aware collection syntax (`'reasonCode': ?reasonCode`) instead of a verbose conditional map entry.
- **Files modified:** `packages/ptrack_domain/lib/src/prediction/explanation_step.dart`
- **Verification:** `fvm flutter analyze` (ptrack_domain) clean
- **Committed in:** `d6b64bf` (Task 1 commit)

### Planned file list vs RED compile

**2. Stub `prediction_engine.dart` and barrel export in Task 1**
- **Found during:** Task 1
- **Issue:** Plan Task 1 listed only tests + `prediction_rules.md`, but tests need a compilable API surface; minimal stub + `ptrack_domain.dart` export were added with the RED commit.
- **Fix:** Included stub implementation returning `PredictionInsufficientHistory` so tests fail on assertions until GREEN.
- **Files modified:** `prediction_engine.dart`, `ptrack_domain.dart`
- **Committed in:** `d6b64bf`

---

**Total deviations:** 2 (1 analyzer-blocking syntax fix, 1 intentional RED scaffolding)
**Impact on plan:** No change to deliverables; engine and tests match CONTEXT median/window/uncertainty intent.

## Issues Encountered

- `melos exec` with a path like `packages/ptrack_domain/test/...` resolves incorrectly from the package working directory; full package tests run via `melos exec --scope=ptrack_domain -- fvm flutter test` (no extra path), matching plan verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 04 can call `PredictionEngine` from repository/coordinator code and replace or bypass `placeholderExplanationSteps` using engine-produced `ExplanationStep` lists.
- PRED-04 string review remains for user-facing copy; domain layer stays non-clinical in payloads.

## Self-Check: PASSED

- `02-03-SUMMARY.md` present at `.planning/phases/02-domain-persistence-prediction-v1/02-03-SUMMARY.md`
- Task commits `d6b64bf`, `8926fa8`, `1c2f350` plus docs commit updating planning files (see `git log --oneline -- .planning/phases/02-domain-persistence-prediction-v1/02-03-SUMMARY.md`)
- `packages/ptrack_domain/lib/src/prediction/prediction_engine.dart` exists

---
*Phase: 02-domain-persistence-prediction-v1*
*Completed: 2026-04-04*

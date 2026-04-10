---
phase: 09-prediction-of-next-period
verified: 2026-04-07T18:45:00Z
automated_rerun: 2026-04-07T19:30:00Z
status: passed
score: 14/14 plan must-haves (static) + automated tests green on FVM Flutter SDK ^3.11 (orchestrator)
human_verification: []
optional_follow_up:
  - On a device or emulator, spot-check three prediction tiers and legend (NFR-06 visual comfort).
  - Smoke day detail “See details”, home “How is this calculated?”, milestone dismiss, and prediction display mode switching.
---

# Phase 9: Prediction of next period — Verification Report

**Phase goal (ROADMAP):** Replace the single median-based prediction engine with a multi-algorithm ensemble (3+ methods) that runs locally, produces per-day scores from algorithm agreement, and renders those scores on the calendar with visually distinct tiers — honest forecast sense without implying medical authority.

**Verified:** 2026-04-07T18:45:00Z (static); **automated re-run:** 2026-04-07 (orchestrator, FVM)  
**Status:** passed  
**Re-verification:** No — initial verification (no prior `09-VERIFICATION.md`).

### Automated verification (orchestrator)

| Command | Result |
|---------|--------|
| `fvm flutter test` in `packages/ptrack_domain` | 80/80 passed |
| `fvm flutter test` in `packages/ptrack_data` | 84/84 passed |
| `fvm flutter test` in `apps/ptrack` | 121/121 passed |

_Note: Use `fvm flutter test` (not bare `dart test`) for workspace packages that declare `flutter_test` only._

## Goal achievement

### Observable truths (goal-backward)

| # | Truth | Status | Evidence |
|---|--------|--------|----------|
| G1 | Ensemble runs **3+** on-device methods and aggregates **per-day agreement** | VERIFIED | `EnsembleCoordinator._defaultAlgorithmsForDuration` registers four algorithms (`MedianBaselineAlgorithm`, `EwmaAlgorithm`, `BayesianAlgorithm`, `LinearTrendAlgorithm`); `dayConfidenceMap` increments per predicted day in `ensemble_coordinator.dart`. |
| G2 | **Locally** executed (no network in prediction path) | VERIFIED | Domain/data prediction code is synchronous pure Dart; coordinator uses `PeriodRepository` / in-memory lists only in reviewed paths. |
| G3 | **Calendar** shows **tiered** predicted days vs **solid** logged bands | VERIFIED | `buildCalendarDayCell`: `PeriodBandPainter` when `hasPeriod`; `ConfidenceHatchedCirclePainter(tier: data.predictionConfidenceTier)` when predicted and not on logged band (`calendar_painters.dart`). |
| G4 | Tiers use **non-color-only** cues (NFR-06) | VERIFIED | `ConfidenceHatchedCirclePainter` varies **opacity** and **hatch spacing/stroke** per tier (`_tierConfig`). Legend uses same painter (`buildConfidenceLegend`). |
| G5 | **Plain-language** multi-method explanation (PRED-03) | VERIFIED | `formatEnsembleExplanation` + disclaimer; home `TextButton` “How is this calculated?” → sheet with `ensembleExplanationText` (`home_screen.dart`); day detail `formatDayAgreementSummary` + expandable per-algorithm lines (`day_detail_sheet.dart`). |
| G6 | Copy avoids contraception / medical authority (PRED-04) | VERIFIED (with note) | `predictionCopyForbiddenPhrasesLowercase` + assert in `formatEnsembleExplanation`; “methods agree” framing in agreement summary. **Note:** milestone string includes “better accuracy” (`ensemble_coordinator.dart`) — not in forbidden list but slightly stronger than “methods agree” tone; see anti-patterns. |

**Score (goal-level):** 6/6 structurally satisfied in code; visual and test confirmation deferred to human/CI.

### Plan must-haves (09-01 / 09-02 / 09-03)

Consolidated from plan frontmatter; each checked against repository (existence + wiring, not SUMMARY claims).

| Plan | Truth / artifact | Status | Evidence |
|------|------------------|--------|----------|
| 01 | Algorithms + `MedianBaselineAlgorithm` wraps `PredictionEngine` | VERIFIED | `prediction_algorithm.dart`; `predict` delegates to `_engine.predict` without forking engine internals. |
| 01 | EWMA α=0.3; Bayesian NIG-style prior defaults μ₀=28, κ₀=1, α₀=2, β₀=15; Linear trend R² & min cycles | VERIFIED | `ewma_algorithm.dart`, `bayesian_algorithm.dart`, `linear_trend_algorithm.dart` (`rSquaredThreshold = 0.5`, `minCycles => 5`). |
| 01 | Tests file present | PRESENT | `packages/ptrack_domain/test/prediction_algorithm_test.dart` (not executed here). |
| 02 | Ensemble runs algorithms, builds `dayConfidenceMap` | VERIFIED | `ensemble_coordinator.dart` loop + map aggregation. |
| 02 | Consensus default suppresses tier-1 when **>1** active algorithm; cold-start keeps tier-1 | VERIFIED | `buildCalendarDayDataMap`: `if (mode == consensusOnly && tier < 2 && eff.activeAlgorithmCount > 1) continue` (`calendar_day_data.dart`). |
| 02 | Explanation / “methods agree” copy | VERIFIED | `formatDayAgreementSummary`, `formatEnsembleExplanation`, `prediction_copy.dart`. |
| 02 | Display mode applied at **view-data** boundary | VERIFIED | Filtering only in `buildCalendarDayDataMap`, not in `EnsembleCoordinator`. |
| 02 | Milestone when active algorithm count increases | VERIFIED | `_milestoneMessage` + `merged.add` milestone step; home `_MilestoneNotice` with prefs dismiss. |
| 03 | `ConfidenceHatchedCirclePainter` + legend | VERIFIED | `calendar_painters.dart`; `calendar_screen.dart` shows `buildConfidenceLegend` when `activeAlgorithmCount > 0`. |
| 03 | `CalendarViewModel` / `HomeViewModel` call `EnsembleCoordinator.predictNext` | VERIFIED | `_recompute` in both view models. |
| 03 | Day detail agreement + expandable breakdown | VERIFIED | `_PredictedDayInfoCard` + `formatDayAgreementSummary` / covering algorithms (`day_detail_sheet.dart`). |
| 03 | Settings: `PredictionSettingsTile` + callback to refresh calendar | VERIFIED | `tab_shell.dart` → `PredictionSettingsTile(onModeChanged: … updateDisplayMode)`. |
| 03 | `ptrack_data` exports `EnsembleCoordinator` | VERIFIED | `ptrack_data.dart` export line. |

**Static must-have score:** 14/14 satisfied in codebase.

### Required artifacts (existence + substance)

| Artifact | Status | Notes |
|----------|--------|--------|
| `packages/ptrack_domain/lib/src/prediction/prediction_algorithm.dart` | VERIFIED | Interface, `MedianBaselineAlgorithm`, exports used by ensemble. |
| `ensemble_result.dart`, `ewma_algorithm.dart`, `bayesian_algorithm.dart`, `linear_trend_algorithm.dart` | VERIFIED | Non-trivial implementations. |
| `packages/ptrack_data/lib/src/prediction/ensemble_coordinator.dart` | VERIFIED | Full orchestration + milestone + `PredictionCoordinator` consensus bridge. |
| `explanation_step.dart` (`algorithmContribution`, etc.) | VERIFIED | Extended kinds for ensemble. |
| `prediction_copy.dart` | VERIFIED | Ensemble + forbidden-phrase guard. |
| `calendar_day_data.dart` | VERIFIED | `buildCalendarDayDataMap` ensemble path + legacy adapter. |
| `prediction_settings.dart` | VERIFIED | Enum, persistence, tile widget. |
| `calendar_painters.dart`, `calendar_view_model.dart`, `home_view_model.dart`, `home_screen.dart`, `day_detail_sheet.dart`, `calendar_screen.dart` | VERIFIED | Wired as per key_links in plans. |

### Key links (wiring)

| From | To | Via | Status |
|------|-----|-----|--------|
| `calendar_view_model.dart` | `EnsembleCoordinator` | `_ensembleCoordinator.predictNext` in `_recompute` | WIRED |
| `home_view_model.dart` | `EnsembleCoordinator` | Same | WIRED |
| `calendar_painters.dart` | `CalendarDayData` | `predictionConfidenceTier` → `ConfidenceHatchedCirclePainter` | WIRED |
| `day_detail_sheet.dart` | `CalendarDayData` / ensemble | `predictionAgreementCount`, `formatDayAgreementSummary` | WIRED |
| `tab_shell.dart` | `CalendarViewModel` | `PredictionSettingsTile.onModeChanged` → `updateDisplayMode` | WIRED |

## Requirements coverage

| Requirement | Description (REQUIREMENTS.md) | Status | Evidence |
|-------------|--------------------------------|--------|----------|
| **PRED-01** | Documented deterministic rules from history | SATISFIED | Four explicit algorithm classes + engine wrap; math and thresholds in code/comments. |
| **PRED-02** | Surface uncertainty when insufficient/variable | SATISFIED | Agreement tiers, `consensusOnly` filtering, range/point handling preserved via consensus `PredictionResult`, explanation copy. |
| **PRED-03** | Plain-language derivation | SATISFIED | Home sheet + ensemble text + day detail + expandable method lines. |
| **PRED-04** | Not contraception / not medically authoritative | SATISFIED | Forbidden phrase list + disclaimers; see warning on “better accuracy” in milestone. |
| **NFR-06** | Predicted vs actual distinguishable without color alone | SATISFIED | Solid band vs hatched circle + dual-channel tier painter + legend; widget tests cover painter/legend. Optional device spot-check in frontmatter. |

**Traceability note:** `.planning/REQUIREMENTS.md` trace table still maps PRED-* / NFR-06 to earlier phases; Phase 9 **extends** those behaviors. No code conflict found; doc table is stale relative to Phase 9 depth, not an implementation orphan.

## Anti-patterns / risks

| Location | Pattern | Severity | Impact |
|----------|---------|----------|--------|
| `ensemble_coordinator.dart` — `_milestoneMessage` (2→ methods path) | Phrase “better accuracy” | Warning | Plan 09-03 asked to avoid “accurate”-style certainty; string is not in `predictionCopyForbiddenPhrasesLowercase` but may read slightly overconfident vs “methods agree” tone. |

No `TODO` / `PLACEHOLDER` / empty stub handlers found in reviewed prediction/calendar paths.

## Gaps summary

**No blocking gaps** identified in static review: ensemble, tiers, explanations, settings wiring, and exports match the phase goal and plan must-haves.

**Automated bar met** on FVM Flutter ^3.11. **Optional:** device smoke for visual tier comfort and modal flows (see frontmatter `optional_follow_up`).

---

_Verified: 2026-04-07T18:45:00Z_  
_Verifier: Claude (gsd-verifier)_

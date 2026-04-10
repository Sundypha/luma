# Prediction rules (Plan 02-03)

Deterministic, no-ML next-period estimation. Thresholds below match `prediction_engine.dart` and tests.

## Input

- Ordered completed cycles, **oldest first** (`periodStartUtc`, `lengthInDays`, optional `bleedingDays`).
- **Open / incomplete cycles** are not passed in; callers derive completed lengths first (Phase 2 boundary).
- Engine uses the **last six** cycles by time (tail of the list).
- Empty input → `PredictionInsufficientHistory` with `completedCyclesAvailable: 0`.

## Exclusions (machine-readable reasons)

| Rule | Condition | Reason code |
|------|-----------|-------------|
| Long gap | `lengthInDays` > **45** | `long_gap` |
| Long bleed | `bleedingDays` != null and > **10** | `long_bleed` |
| Within-window outlier | After gap/bleed filtering, if **≥3** cycles remain: provisional **median** length *m*; exclude any cycle with **\|length − m\| > 7** | `statistical_outlier` |

Outlier pass is **one shot** on the set after gap/bleed exclusions (no iterative re-median in v1).

## Central tendency

- **Median** of **included** cycle lengths (integer days). For an **even** count of lengths, median is the **arithmetic mean of the two middle values, rounded to the nearest integer** (`.round()` in Dart).
- Need **≥2** included cycles after all exclusions to emit a concrete next-start **interval** or point.
- With **<2** included cycles → `PredictionInsufficientHistory` (`minCompletedCyclesNeeded: 2`).

## Variability / tiers

- Let **min** / **max** be min/max **included** lengths.
- If **max − min ≥ 12** → `PredictionRangeOnly` (`reasonCode: high_variability`). Range: anchor + **min** days through anchor + **max** days (UTC calendar-day arithmetic).
- Else → `PredictionPointWithRange`: **point** = anchor + **median** days; **range** = anchor + **min** .. anchor + **max** (UTC calendar days).

## Anchor and date math

- **Anchor** = `periodStartUtc` of the **most recent** cycle in the input list (last element, oldest-first ordering).
- **UTC calendar-day policy:** normalize anchor to `DateTime.utc(y, m, d)` from its UTC components, then add **N** days via `Duration(days: N)`. Same as tests; DST is handled at persistence/UI layers in later plans.

## Explanation (PRED-03)

Ordered `ExplanationStep` list:

1. `cyclesConsidered` — window size, lengths, UTC starts.
2. `cycleExcluded` — one step per excluded row (`exclusionReason`: `long_gap` \| `long_bleed` \| `statistical_outlier`).
3. `medianCycleLength` — median, min/max included lengths, spread, anchor instant (when history suffices).
4. `insufficientHistory` — when included count \< 2 after exclusions.
5. `highVariabilityRange` — when tier is range-only (payload includes ISO range and `reasonCode: high_variability`).

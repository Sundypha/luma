# Prediction rules (Plan 02-03)

Deterministic, no-ML next-period estimation. Thresholds below match `prediction_engine.dart` and tests.

## Input

- Ordered completed cycles, **oldest first** (`periodStartUtc`, `lengthInDays`, optional `bleedingDays`).
- Engine uses the **last six** cycles by time (tail of the list).

## Exclusions (machine-readable reasons)

| Rule | Condition | Reason code |
|------|-----------|-------------|
| Long gap | `lengthInDays` > **45** | `long_gap` |
| Long bleed | `bleedingDays` != null and > **10** | `long_bleed` |
| Within-window outlier | After gap/bleed filtering, if **≥3** cycles remain: provisional **median** length *m*; exclude any cycle with **\|length − m\| > 7** | `statistical_outlier` |

Outlier pass is **one shot** on the set after gap/bleed exclusions (no iterative re-median in v1).

## Central tendency

- **Median** of **included** cycle lengths (integer days).
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

Ordered `ExplanationStep` list: cycles considered, exclusions with reasons, median, then either insufficient history, high-variability range, or point + spread interval.

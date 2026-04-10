# Phase 2: Domain, persistence & prediction v1 - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Local **data model**, **persistence with tested migrations**, and **deterministic, explainable** next-period **prediction** (no opaque ML), correct under TDD and safe across app upgrades **without silent data loss**—before onboarding, core logging UI, and calendar surfaces depend on them. This phase does not deliver full product UI; it delivers domain behavior, storage, and prediction outputs that later phases consume.

</domain>

<decisions>
## Implementation Decisions

### Period & cycle semantics

- **Storage model:** Persist timing in **UTC**; derive calendar-day labels using the **device’s current local timezone at view time** (travel may shift how historical days appear on screen).
- **Overlapping periods:** **Invalid** — reject on save/edit (no silent merge).
- **Open periods:** Periods without an end date **do not** contribute to **historical cycle-length** statistics until closed.
- **Long gaps between periods:** Cycles whose length exceeds a **configurable threshold** are **excluded from prediction averages** (still stored).
- **Very long bleeding spans:** Treatment of outliers is **implementation-defined** (thresholds), but any span **excluded** from prediction statistics must carry a **clear, user-visible marker or structured reason** in the domain layer so UI can explain that something is off—not a silent exclusion.
- **Single-day periods:** **Valid** (start and end on the same calendar day).
- **End before start:** **Invalid** — reject validation.
- **Duplicate same-day starts:** Starting a second period on the **same calendar day** as an existing period start is **rejected**.

### Cycle length definition (for statistics)

- **Claude's discretion:** Choose and **document** one canonical definition (recommended default: cycle length = days from one period **start** to the calendar day **before** the next period **start**, matching common clinical/calendar counting). Planner/researcher must lock this in code and tests.

### Deterministic prediction math

- **Input window:** Use up to the **last 6 completed cycles** (fewer if history is shorter).
- **Central tendency:** **Median** of included cycle lengths.
- **Within-window outliers:** **Claude's discretion** — define a deterministic rule (e.g. deviation from median) and document it; user did not fix numeric thresholds.
- **Minimum history for a point estimate:** Need **at least 2 completed cycles** before emitting a specific predicted next-start **date**; with fewer, follow uncertainty rules below.

### Uncertainty & explanation

- **Sufficient history:** Expose both a **point estimate** (median-based) and, when appropriate, a **range** reflecting spread across recent cycles; **widen the range** when variability is high, and if spread exceeds an implementation threshold, **downgrade** presentation tier (e.g. range-only / high-variability — exact tier names are implementation-defined).
- **Insufficient history:** **No predicted date**; emit a structured **`insufficient_history`** (or equivalent) outcome plus a short explanation template.
- **Plain-language explanation (PRED-03):** Machine-readable output should be an **ordered list of factual steps** (e.g. which cycles were used, median length, exclusions, outliers dropped) that UI can render as bullets or a single paragraph later.
- **Reference:** User asked how **Apple Cycle Tracking** handles uncertainty. Public materials emphasize **predictions on the timeline** and needing **enough logged data**; predictions may be absent when data is insufficient. Detailed irregular-cycle uncertainty UI is not fully documented. **ptrack** aligns on **honest absence / widening** at the domain layer; rich calendar visuals are **Phase 5**, not Phase 2.

### Persistence & migrations (NFR-02)

- **Migration failure:** **Transactional, fail closed** — do not leave a half-migrated database; prefer retaining a consistent prior state and surfacing a **clear error** over silent corruption or silent wipe.
- **Testing bar:** **Each schema version bump** must have an automated test that opens a **fixture DB** at version *N* and asserts successful migration to *N+1* with expected data preserved.
- **Forward compatibility with export:** Include an explicit **schema version** (integer) in persistence and **document** that a future export format (Phase 6) will reference it.
- **Downgrade:** If the on-disk schema is **newer** than the app supports, **detect and refuse** to open normally (or read-only) — **no** silent corruption.

### Claude's Discretion

- Exact **UTC + local-date** mapping utilities and edge-case tests (DST).
- Numeric thresholds: **long gap**, **long bleed**, **outlier deviation**, **high-variability spread** for range widening vs tier downgrade.
- Choice of **SQLite access layer** (e.g. Drift) and file location under app sandbox—must satisfy decisions above.
- Wording of user-facing strings for errors and explanation bullets, subject to **PRED-04** (no contraception/medical authority framing) — copy tone was not deep-dived in this session; keep conservative, non-medical language.

</decisions>

<specifics>
## Specific Ideas

- **Apple Health / Cycle Tracking:** Predictions appear in the context of logged history; insufficient data → predictions may not appear. Use as a **soft UX reference** only; implement **explicit** domain outcomes (`insufficient_history`, ranges, exclusions) rather than copying undocumented internals.
- **Excluded spans:** Whenever data is excluded from prediction statistics, the user should eventually be able to see **that** something is off (marker + reason), not wonder why the app “ignored” a period.

</specifics>

<deferred>
## Deferred Ideas

- **PRED-04 deep-dive:** Dedicated pass on **non-medical disclaimer** phrasing and string review — deferred; implementation must still satisfy PRED-04 from requirements.
- **Calendar / home visualization** of predictions (e.g. stripe-style cues): **Phase 5**.
- **Onboarding** copy tying predictions to history: **Phase 3**.

</deferred>

---

*Phase: 02-domain-persistence-prediction-v1*
*Context gathered: 2026-04-04*

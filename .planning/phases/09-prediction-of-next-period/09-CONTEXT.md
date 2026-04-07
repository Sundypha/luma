# Phase 9: Prediction of next period - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the single median-based prediction engine with a multi-algorithm ensemble (3+ methods) that runs locally, produces per-day confidence scores based on algorithm agreement, and renders those scores on the calendar with visually distinct tiers. All algorithms must be on-device, explainable, and non-medical.

Algorithms: (1) Median Baseline (existing), (2) EWMA (recency-weighted), (3) Bayesian Posterior Estimation, (4) Linear Trend Projection (stretch).

</domain>

<decisions>
## Implementation Decisions

### Confidence calendar visualization
- **Opacity tiers** for predicted days: same hatch pattern but fading opacity — faint (1 algorithm agrees), medium (2 agree), strong (3+ agree).
- **Hatch density also varies** for accessibility (NFR-06): sparse hatch (1 algo), medium hatch (2), dense hatch (3+). Two independent visual channels (opacity + pattern density) ensure distinction without relying on color alone.
- **Logged days stay solid** — only future predicted days show confidence tiers. Past logged days are facts, not predictions. Clean separation.
- **Both legend + tap detail**: subtle inline legend below calendar showing the 3 opacity/density levels with labels. Tapping a predicted day shows "X of 3 methods agree" in the day detail sheet.

### Algorithm output & disagreement handling
- Each algorithm primarily predicts **cycle length** (next start date). Period duration approach is Claude's discretion (shared vs per-algorithm).
- **Default display: consensus-only** — only show days where 2+ algorithms agree. Hide lone-algorithm predictions.
- **User-selectable presets** in Settings: users can switch between display modes (e.g., consensus-only, show-all, show-all-with-note). Default is consensus-only. This lives in the **Settings screen** under a "Prediction display" option.
- Research basis: algorithms predict cycle length as primary output (Li et al. 2022, Bellabeat 2025, SkipTrack 2025); Bayesian approach naturally produces per-day probability distributions.

### Prediction explanation UX
- **Layered: summary + drill-down** — default shows consensus summary ("X of 3 methods predict your period on this day" + one-line per algorithm). Tap "See details" to expand individual algorithm explanations.
- **Algorithm naming**: Claude's discretion — pick naming that fits the explanation layout best (plain-English or descriptive behavior labels).
- **"Methods agree" framing** for confidence language — say "All 3 methods agree on this day" rather than "High confidence". Avoids implying medical certainty, focuses on internal consistency. Consistent with PRED-04.
- **Two entry points**: home screen prediction card has "How is this calculated?" link + day detail sheet shows per-day explanation.

### Cold start & algorithm readiness
- **Always show whatever's available** — even 1 algorithm's output is useful. The tier system itself communicates confidence level. No additional waiting state beyond what exists.
- When only 1 algorithm is active, predicted days show as **low-confidence (faintest tier)** — consistent with the tier model.
- **Milestone messages** when new algorithms come online: "With 3 cycles logged, prediction now uses 2 methods" / "With 6 cycles, all methods active". Celebrate progress, encourage continued logging.
- Linear Trend (stretch) activation is **part of milestone messages**: "With 5 cycles, trend detection is now active".

### Claude's Discretion
- Period duration prediction approach (shared estimate vs per-algorithm)
- Algorithm user-facing naming style
- Exact hatch pattern densities and opacity values
- EWMA decay factor (α) and Bayesian prior selection
- Linear Trend significance threshold
- Milestone message copy and presentation

</decisions>

<specifics>
## Specific Ideas

- Research references: SkipTrack Bayesian hierarchical model (2025), Bellabeat deep-learning period tracking (2025), Urteaga et al. calibrated predictions (PMLR 2021), Li et al. predictive model with adherence (JAMIA 2022), Rego et al. time-series forecasting (2023).
- The existing `PredictionEngine` (median-based, 6-cycle window, outlier exclusion) is Algorithm 1 — preserve it and add the new algorithms alongside.
- The existing PRD (`period_tracker_prds/PRD_Phase_4_Advanced_Prediction.md`) provides product principles: Layer A (statistical) before Layer B (ML), explainability requirement, non-medical positioning, on-device only.
- Confidence visualization should feel like a natural evolution of the existing predicted-day hatch marks, not a completely new visual language.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 09-prediction-of-next-period*
*Context gathered: 2026-04-06*

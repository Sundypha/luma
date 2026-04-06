# Phase 8: Release quality, offline assurance & inclusive copy - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Polish pass over the entire Phase 1 feature set. Make it feel fast, read clearly, use respectful language, and work fully offline after install. No new features — this refines what Phases 1–7 shipped.

Requirements: NFR-01 (performance feel), NFR-05 (label clarity), NFR-07 (inclusive copy), NFR-08 (offline assurance).

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion

All four areas below are at Claude's discretion. The user approved these defaults — deviate only if a concrete technical reason emerges.

#### Copy voice & terminology
- Warm but not cutesy — direct, clear sentences. No emoji in functional copy.
- "Period" (not "menstruation" or "menses"). "Cycle" for the full cycle. "Flow" for intensity.
- Second person where natural ("Your period started") but avoid overusing "your" — context makes ownership obvious.

#### Inclusive language boundaries
- No gendered pronouns in app copy — use "you/your" (already second person).
- No "women" or "female" — the app tracks periods, no need to address who uses it.
- Medical disclaimers stay short and factual: "Predictions are estimates based on your history, not medical advice." No lecturing.

#### Action & label clarity
- Icon + text for primary actions. Icon-only acceptable for well-known patterns (back, close, delete) with accessibility labels.
- Labels are verbs for actions ("Log today", "Export data"), nouns for navigation ("Calendar", "Settings").
- No tooltips — if a label needs a tooltip, the label is wrong.

#### Performance feel & priorities
- Calendar month scrolling and day taps should feel instant (no visible loading state).
- Logging actions (mark day, save symptoms) should complete without spinners.
- Export/import can show progress — those are inherently slow operations.
- No gratuitous animations; transitions should be fast (200–300ms max).

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. The user trusts Claude's judgment on tone, clarity, and performance targets within the defaults above.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 08-release-quality-offline-assurance-inclusive-copy*
*Context gathered: 2026-04-06*

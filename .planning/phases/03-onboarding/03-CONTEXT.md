# Phase 3: Onboarding - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

First-run onboarding that satisfies ONBD-01–04: the user understands local-only storage and no account, understands predictions as non-medical estimates from their history, can complete a minimal path to first period logging in under about one minute, and can skip non-essential education while the full flow works offline. Scope is onboarding and the handoff into first log—not full logging/calendar features (later phases).

</domain>

<decisions>
## Implementation Decisions

### Flow shape & pacing
- Short wizard: several focused screens (one main idea per screen), not a single long-scroll page.
- Order of required disclosures: **privacy & local-first first**, then **estimates / not medical advice**.
- Show **subtle step progress** (e.g. dots or step indicator).
- Default path is **balanced**: enough context per screen for comprehension without adding new product capabilities; still optimized for low friction.

### Trust & disclosure
- **Warm, conversational** tone; plain, reassuring language.
- **Medium** copy length per screen: short paragraphs or bullets, still scannable.
- **Light illustration or hero graphic** per major idea (not icons-only).
- **Explicit heading or callout** for the not-medical-advice framing, plus short supporting explanation (must satisfy ONBD-02 clearly).

### Skip, defer, resume
- **Skip applies only to non-essential** steps; required disclosures must be acknowledged before continuing (ONBD-04).
- **Skip affordance per screen** on optional steps; required steps use Continue (no global “skip everything”).
- **Replay**: user can read onboarding-style privacy/estimates content again from **Settings → About (or equivalent)**.
- **Mid-onboarding app close**: **resume** where they left off on next launch (persist minimal progress).

### First logging moment
- After onboarding: go **straight into period-start logging** (minimal fields; today or change date).
- **One short inline hint** on first logging screen (e.g. logging current or most recent period start).
- **Default period start date: today** (user can change).
- After first save: **brief success acknowledgment**, then enter the **main app shell** as implemented by surrounding work (home/calendar when available).

### Claude's Discretion
- Exact number of wizard steps, precise strings, illustration style, and stepper visuals.
- Persistence keys and edge cases (e.g. data clear / reinstall) unless requirements add constraints later.
- Exact Settings entry label and layout for “About / privacy & estimates” replay.

</decisions>

<specifics>
## Specific Ideas

- Step order: trust (local device) before talking about how predictions work.
- Dots/stepper for orientation without a heavy “tutorial” feel.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-onboarding*
*Context gathered: 2026-04-04*

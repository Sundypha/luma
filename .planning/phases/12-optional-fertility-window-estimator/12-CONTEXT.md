# Phase 12: Optional Fertility Window Estimator - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Opt-in feature that estimates a fertile window on the calendar and home screen. Off by default; shows limitations copy when enabled; prompts for missing inputs; uses accessible (non-color-only) visualization; can be disabled cleanly without affecting period/export data. All math on-device, deterministic, documented, and tested. Strings go through i18n (ARB files, English + German).

</domain>

<decisions>
## Implementation Decisions

### Opt-in flow & disclaimer presentation
- **Both** settings toggle and one-time home suggestion card
- Home suggestion card is **always available from first use** — grayed out or explained if not enough data yet
- Settings screen has a dedicated fertility window toggle
- When enabling, a **bottom sheet** presents the limitations disclaimer with an "I understand" button — consistent with existing app patterns
- If user **dismisses** the home suggestion card without enabling, it **never comes back** — fertility window is then only discoverable via settings; respects the user's "no"

### Input collection
- **Auto-fill from history** — show computed average cycle length from logged periods, let user confirm or adjust
- Input presented as a **bottom sheet with a simple form** — consistent with existing patterns (symptom logging, etc.)
- Luteal phase: **show with explanation** — "Most people have ~14 days. Adjust if you know yours." with a slider. Most users won't know theirs, but the option is visible rather than hidden
- If user **disables and re-enables**, previous settings are **remembered** and pre-filled from last configuration
- Fertile window **auto-updates** whenever new period data is logged — no manual recalculation needed

### Calendar & home visual treatment
- Fertile days marked with a **small colored dot beneath the date** — subtle secondary indicator
- Color family: **soft teal/green** — natural contrast with period pink, clearly different color family
- NFR-06 accessibility: **different shape** as secondary visual channel (e.g. diamond or hollow circle vs solid period dot) — not relying on color alone
- **Legend entry added** to the existing calendar legend — consistent and discoverable alongside prediction confidence tiers
- Home screen: **dedicated card/section** — "Fertile window: Apr 12–17" style with a subtle explanation line, consistent with existing home layout
- Tapping a fertile day in the calendar shows a **simple label** — "Estimated fertile day" with a one-liner about the calculation basis

### Copy & tone
- **Educational & warm** tone — "Your estimated fertile window is Apr 12–17. This is a rough guide based on your cycle history." Consistent with existing app voice
- Disclaimer: **gentle but clear** — "This is an educational estimate, not medical or contraceptive advice. Talk to a healthcare provider for personal guidance."
- **Extend the existing forbidden-phrases list** with fertility-specific terms: "safe days", "guaranteed", "birth control", "contraception", "prevent pregnancy" — one unified guardrail
- Inclusive language: **allow some biological terms** where natural (e.g. "ovulation" is biological, not gendered) but generally use "your body", "your cycle" framing — consistent with NFR-07 spirit without over-sanitizing
- **Subtle footer on the home card** always visible — small text like "Estimate only" as a persistent-but-unobtrusive reminder; no recurring nag dialogs after initial opt-in

### i18n constraint
- All user-facing strings must be added to ARB files (English `app_en.arb` + German `app_de.arb`) — Phase 10 i18n foundation is a dependency

### Claude's Discretion
- Exact fertile window calculation formula (standard calendar method vs. more sophisticated approach), as long as it meets FERT-05 (deterministic, documented, tested)
- Exact dot shape choice (diamond, hollow circle, etc.) for the accessibility secondary channel
- Home card layout details and spacing
- Bottom sheet form field ordering and validation UX
- How "grayed out / not enough data" state looks on the home suggestion card
- Error handling when cycle data is insufficient for a meaningful estimate

</decisions>

<specifics>
## Specific Ideas

- Home suggestion card should feel like the existing milestone cards — not a new UI paradigm
- Bottom sheet for disclaimer and input should feel like the existing symptom form sheet — familiar interaction pattern
- The teal/green fertility dot should be visually subtle enough that the calendar doesn't feel cluttered when both predictions and fertility markers are showing
- Auto-update of the fertile window should be seamless — user logs a period, and next time they look at the calendar/home the window has quietly adjusted

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 12-optional-fertility-window-estimator*
*Context gathered: 2026-04-07*

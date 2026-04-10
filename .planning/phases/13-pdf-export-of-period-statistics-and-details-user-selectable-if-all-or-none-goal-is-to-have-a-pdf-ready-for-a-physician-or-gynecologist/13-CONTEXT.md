# Phase 13: PDF export of period statistics and details (user selectable if all or none). Goal is to have a PDF ready for a physician or gynecologist. - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

## Phase Boundary

Deliver **on-device PDF export** of existing tracked cycle data (statistics and optional detail), with **user control over included sections** so the document can range from **non-clinical metadata only** up to a **full** export suitable to share with a **physician or gynecologist**. Does **not** add new logging fields or prediction features; only **presentation and export** of data the app already holds.

## Implementation Decisions

### Section scope & toggles

- **Presets plus advanced:** Offer quick **presets** (e.g. summary / standard / full — exact names TBD) and an **Advanced** path with **per-section toggles**.
- **Minimum content:** When all data sections are off, the PDF contains **only non-clinical metadata** (e.g. app name, export generation date) — **no cycle lengths, symptoms, or other health metrics** unless the user enables the relevant sections.
- **Day-level data:** If included, expose as **two separate optional sections**: (1) **aggregated summary table** (scannable per-day marks), (2) **detailed notes log** (free-text / richer entries where logged). User can enable either or both.
- **First-time default:** **Full preset on first export** — all sections on; user strips down. Persist their choices for subsequent exports.

### Clinical presentation (PDF copy & metadata)

- **Language:** PDF **follows the active app locale** (strings, date/number formatting) — aligned with i18n work in phases 10–11.
- **Identity:** **No patient identity fields** on the PDF (no name, initials, or pseudonym line). Document is identified only by neutral export metadata (app + dates as above).
- **Disclaimer:** **Short, fixed disclaimer** on every export (informational export, not diagnostic; accuracy depends on user logging — exact wording TBD).
- **Time window:** **Default range = last 12 months** of data; user can **change** the range before generating.

### Export UX

- **Entry points:** **Settings** (primary home for the feature) **and** a clear action from **cycle / stats / history** surfaces (exact screens TBD in plan).
- **Preview:** **Required** — user must see an **in-app scrollable preview** before **Share** or save path completes.
- **Filename:** **Auto-generated dated name**; user may **edit the filename** where the **platform supports** it before sharing/saving.
- **Delivery:** Generate file → **system share sheet** as the **primary** handoff (email, Files, cloud, print, etc.).

### Layout & visuals

- **Charts:** **Optional toggled section(s)** with **simple** chart(s) (e.g. cycle length over time) — not required for a minimal export.
- **Branding:** **Minimal** — small/neutral header with app name; **not** a marketing-heavy layout; readable as a clinical handout.
- **Structure:** **Section headings only** — linear document; **no** table-of-contents page.
- **Page size:** **Follow locale/device default** (e.g. A4 vs Letter) where the PDF pipeline allows.

### Claude's Discretion

- Exact **preset names**, **section list**, and **ordering**
- **Chart** type(s), styling, and when to omit if data is sparse
- **Disclaimer** final copy (legally careful, concise)
- PDF **library/stack**, file lifecycle, and **error** UX when generation or share fails
- Precise **stats** blocks and table columns derived from existing domain models

## Specific Ideas

- User described the roadmap intent as **selectable sections** including **“all or none”** — implemented as **full preset** vs **metadata-only floor** when all data toggles are off.
- **Clinician-ready** means clear sections, sensible defaults for a visit (**full** first export), and **12-month** default window with user override.

## Deferred Ideas

None — discussion stayed within phase scope.

---

*Phase: 13-pdf-export-of-period-statistics-and-details-user-selectable-if-all-or-none-goal-is-to-have-a-pdf-ready-for-a-physician-or-gynecologist*
*Context gathered: 2026-04-07*

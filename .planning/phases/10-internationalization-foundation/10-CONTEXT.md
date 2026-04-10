# Phase 10: Internationalization foundation - Context

**Gathered:** 2026-04-07  
**Status:** Ready for planning  

<domain>
## Phase Boundary

Introduce Flutter **internationalization infrastructure** (`gen_l10n` / ARB workflow), wire **`MaterialApp`** (and any required localization delegates), and **migrate all user-visible strings** from hard-coded literals into the **English** template catalog for the **entire app**.  

**Out of this phase (Phase 11):** explicit **language** setting in Settings, **German (`de`)** ARB completion, locale-aware **formatting** polish beyond what Flutter provides by default where needed, and **CI guard** for missing `de` keys (**I18N-02**–**I18N-05**).

Discussion clarified **how** we implement Phase 10; it does not add new product capabilities beyond I18N-01.

</domain>

<decisions>
## Implementation Decisions

### String rollout scope

- **Phase 10 migrates every user-visible string in the app** to ARB (no “core only” subset).  
- Tests, internal asserts, and developer-only logs remain non-ARB unless they are user-visible (e.g. user-facing error strings must be ARB).

### Locale behavior before Phase 11

- Use **standard Flutter locale resolution**: respect the device locale; **unsupported locales fall back to the English ARB** catalog.  
- Phase 10 does **not** add a user-facing language picker (Phase 11).

### Branding / proper nouns

- **“Luma”** (and equivalent product branding) stays a **proper name** in the UI: **not** meaningfully “translated” per locale.  
- Implementation may still use a dedicated ARB key for consistency, but **source and `de` (later) should keep the same display string** unless a future milestone explicitly revisits marketing localization.

### Accessibility and semantics strings

- **Tooltips, `Semantics` labels, and other screen-reader-facing copy** are **in scope for Phase 10** and **must** be migrated into the same ARB pass as visible UI strings (**same quality bar**).

### Claude's Discretion

- Exact **`l10n.yaml` / `pubspec` layout**, whether generated Dart is committed vs CI-only, and **key naming conventions** (`camelCase` vs `snake_case` per Flutter defaults).  
- Ordering of file splits (single vs multiple ARB files) if the catalog grows large.  
- Any **third-party** widget strings that cannot be overridden (document exceptions in the phase plan).

</decisions>

<specifics>
## Specific Ideas

- User chose **full migration**, **locale fallback to English** until more locales exist, **fixed brand name**, and **a11y strings in the same pass** — no additional product references.

</specifics>

<deferred>
## Deferred Ideas

- **Language Settings** UI and persistence — Phase 11 (**I18N-02**).  
- **German** translations and **CI ARB parity checks** — Phase 11 (**I18N-03**, **I18N-05**).  
- **Date/number/plural** formatting audit across all surfaces — primarily Phase 11 (**I18N-04**), with Phase 10 only ensuring infrastructure does not block it.

</deferred>

---

*Phase: 10-internationalization-foundation*  
*Context gathered: 2026-04-07*

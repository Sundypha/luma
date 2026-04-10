# Phase 11: German locale + language settings - Context

**Gathered:** 2026-04-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **I18N-02**–**I18N-05**: user-selectable **language** in Settings (**en**, **de**, **follow device**) with **persistence**; **German** string catalog with **parity** to English for the agreed in-scope flows; **dates, numbers, and plurals** respecting the active locale where user-visible; **CI guard** so **de** cannot silently miss required keys. Clarifications below apply only within this scope—additional locales or unrelated features belong in other phases.

</domain>

<decisions>
## Implementation Decisions

### Language settings UX
- **Placement:** Dedicated Settings section (e.g. “Language” / “App language”) with clear grouping—not buried only inside another generic group.
- **New install default:** Always **follow device**; if the device locale does not map to a supported app language, use **English** for UI strings until the user chooses otherwise.
- **Applying a change:** After the user changes language in Settings, require **app restart** to apply (e.g. prompt or snackbar—exact copy flexible).
- **Choice order** in the language list: **System default (follow device)** first, then **English**, then **German**.

### “Follow device” and locale resolution
- **Unsupported device locales:** Use **English** with **no** extra user-facing explanation (silent fallback).
- **System language changes** while “follow device” is selected: pick up the new resolution on **next cold start / process restart** only (not mid-session hot switch).
- **German:** Any resolved **`de*`** locale uses the **German** ARB catalog.
- **English:** All **`en*`** regions share the **same** English catalog for Phase 11.

### German copy tone and ownership
- **Address form:** Informal **du** throughout user-facing German.
- **Register:** **Everyday / conversational** German for symptoms, cycle, and period-related labels (not clinical-first wording).
- **Prediction / disclaimer strings:** Preserve the **same legal weight and intent** as English; wording may be longer or restructured as needed for accurate German.
- **Sign-off:** A **native speaker on the team** approves final German strings; **no** paid professional translator required in this phase.

### Formatting (I18N-04) scope and rules
- **Audit priority:** Treat **all** in-scope user-visible surfaces **equally**—no mandated sequence such as “calendar before settings.”
- **Calendar week start:** Phase 11 uses **Flutter / active-locale defaults** only. A separate user toggle for “week starts on” is **out of scope** here (future phase if ever added).
- **Export / import filenames:** Keep **English or ASCII-safe** names so shares, backups, and tooling stay reliable.
- **Numbers:** Use **standard Flutter / Dart `intl` behavior** for the active locale—no custom number-format overrides unless a bug is found.

### Claude's Discretion
- Exact **restart** prompt copy, snackbar vs dialog, and visual styling.
- **I18N-05** mechanism details (which script, CI step shape, dev vs prod behavior) as long as the roadmap criterion is met: CI fails when **de** is missing required keys.
- Exact Settings section title strings and ordering next to unrelated tiles.
- Edge-case UX if restart flow is awkward on a specific platform.

</decisions>

<specifics>
## Specific Ideas

- **Silent** English fallback for unsupported locales keeps first-run simple and avoids nagging.
- **Cold start** for picking up OS locale changes pairs with explicit **restart** after manual language change.

</specifics>

<deferred>
## Deferred Ideas

- **Additional locales** beyond **en** / **de** — roadmap already defers post–v2.0.
- **User setting for “week starts on”** independent of locale — not in Phase 11; only locale defaults apply here.

</deferred>

---

*Phase: 11-german-locale-language-settings*
*Context gathered: 2026-04-07*

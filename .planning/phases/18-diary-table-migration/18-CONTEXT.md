# Phase 18: Diary Table Migration - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Extract the personal diary from the symptom/period model into a standalone table so users can add a diary entry on any day — not only during their period. Migrate existing `personalNotes` data from `DayEntries` to the new diary table. Add a new Diary tab with journal browsing, search, and tag filtering. Update calendar, home, export/import, and backup paths. Keep `.luma` backward-compatible.

</domain>

<decisions>
## Implementation Decisions

### Entry points — how users access the diary

- **Calendar day tap** opens a day detail sheet that acts as a **routing hub**:
  - No records → "I had my period" + "Add diary entry" buttons
  - Period exists, no diary → "Edit period record" + "Add diary entry"
  - Diary exists, no period → "I had my period" + "Edit diary entry"
  - Both exist → "Edit period record" + "Edit diary entry"
- **Home Today card** shows a diary shortcut **below** the period status (always reachable from Home on any day).
- Both entry points (calendar + Home) available consistently.

### Diary form — what the diary entry contains

- **Text field** (freeform personal notes — same content type as current `personalNotes`).
- **Mood selector** (same scale as symptom mood — lets users track mood on any day).
- **Tag chips** (flat tags, hybrid system: predefined starters + user-created custom tags).
- **One entry per day** (consistent with period logging model).

### Diary table schema

- Standalone table keyed by `dateUtc` (no `periodId` FK — that's the whole point).
- Columns: `id`, `dateUtc` (unique), `mood`, `notes` (text), plus a many-to-many join for tags.
- Separate `DiaryTags` table for tag definitions, and a join table for diary-entry-to-tag associations.

### Tag system

- **Flat tags only** (no nesting/hierarchy — defer to future phase if needed).
- **Hybrid**: predefined starter set + user can create custom tags.
- **Starter tags**: Exercise, Sleep, Stress, Diet, Hydration, Medication, Work, Social, Travel, Self-care, Family.
- **Create inline** on the diary form (type-ahead chip input, new tags created on the fly).
- **Full management** in Settings → "Diary Tags" section (create, rename, delete).
- **Delete behavior**: confirm dialog showing how many entries use the tag, then remove association (entries keep their text/mood).

### Mood architecture

- **Mood stays on DayEntries** for clinical/PDF use — symptom sheet continues to write `DayEntries.mood`.
- **Mood also on diary table** — diary form writes diary mood.
- **Precedence**: on period days, `DayEntries.mood` (symptom mood) takes precedence; diary mood is the authoritative mood only when no symptom entry exists for that day.
- **Display**: when both exist, show both labeled as "Symptom mood" / "Diary mood" in day detail.

### Symptom sheet changes

- **Fully separate** from diary: symptom sheet = flow intensity, pain score, mood, clinical notes only.
- **No diary shortcut** on the symptom sheet — diary is always accessed from the day detail routing hub.
- `personalNotes` field **removed** from the symptom sheet (migrated to diary table).

### Calendar visualization

- **Small blue dot** below the date number for days with a diary entry (but no period).
- **Blue = app's primary blue** (brand-consistent).
- When both a period marker and diary dot exist for the same day, show **both side by side**.
- **Legend updated** to include the diary dot alongside period, prediction, and fertility entries.

### Journal browsing — new Diary tab

- **New "Diary" tab** in bottom navigation — dedicated space for browsing entries.
- **Reverse-chronological list** — most recent entry first, scrollable feed of diary cards.
- **Lazy-loaded / paginated** — mandatory for performance with many entries.
- **Search bar at top** + tag filter chips below + date range filter via filter icon (progressive disclosure).
- **Card content**: date, mood emoji, text preview (~2 lines), tag chips — tap to expand/edit.

### Data migration

- **Full rollback** on failure — Drift's transactional migration; if any step fails, the whole schema upgrade rolls back.
- Migration steps: (1) create diary + tags tables, (2) copy `personalNotes` from `DayEntries` to diary table (keyed by same `dateUtc`), (3) copy mood to diary **only when `personalNotes` also exists**, (4) drop `personalNotes` column from `DayEntries`.
- **Mood column stays on DayEntries** — not dropped (still used by symptom sheet for clinical/PDF data).

### Export / import (.luma)

- **New top-level `diary_entries` array** in `.luma` exports (clean break, bump export version).
- **Old-format import** must still work: if `personal_notes` exists inline on `day_entries` in an old export, route those values to the diary table on import.
- **Manual export** gets a "Diary" toggle in export settings (alongside existing section toggles).

### Backup

- **Auto-backup always includes diary entries** (matches current behavior where `personalNotes` was included via `ExportOptions.everything()`).

### Claude's Discretion

- Exact diary table column types and Drift table definition details.
- Tag chip visual design and color scheme.
- Search/filter implementation details (SQLite FTS vs LIKE queries).
- Diary card expand/collapse animation.
- Exact placement of diary dot relative to period markers.
- Migration step ordering optimization.

</decisions>

<specifics>
## Specific Ideas

- Day detail sheet as a routing hub with dynamic buttons based on existing records — not a unified form.
- Tag filter chips on the Diary tab for quick filtering by tag.
- Lazy loading is mandatory for the diary list — could be many entries over time.
- Blue diary dot must coexist visually side-by-side with the red/pink period dot when both present.
- "Symptom mood" / "Diary mood" labeling when both moods exist for a day.

</specifics>

<deferred>
## Deferred Ideas

- **SQLite-based export/import**: Replace `.luma` JSON with raw SQLite dump/restore for simpler versioning — would be a fundamental architecture change, own phase.
- **Nested/hierarchical tags**: e.g. `Self-Care:Exercise` — deferred for simplicity, flat tags only for now.

</deferred>

---

*Phase: 18-diary-table-migration*
*Context gathered: 2026-04-13*

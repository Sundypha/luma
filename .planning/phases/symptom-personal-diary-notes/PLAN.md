<!-- /autoplan restore point: /home/sbalkau/.gstack/projects/Sundypha-luma/main-autoplan-restore-20260411-225342.md -->

# Feature plan: Personal diary notes on symptom sheet

## Objective (user request)

Add a **second text field** in the symptom bottom sheet (`SymptomFormSheet`) for **personal / diary notes** that are **not** included in the physician-oriented PDF export. Existing **symptom notes** (`notes` on `DayEntryData`) continue to feed the PDF notes log (`pdf_data_collector.dart` → `noteEntries`).

**Personal notes** must participate in:

- Manual backup / export (`.luma`)
- Import / restore
- **Auto-backup** (`BackupService.createBackup` uses `ExportOptions.everything()`)

---

## Phase 1 — CEO review (strategy & scope)

### 0A — Premise challenge

| Premise | Evaluation |
|---------|------------|
| Users want a private journal distinct from clinical notes | **Accepted** — matches PDF product boundary (Phase 13: notes log = data shared with clinicians). |
| Same day row as symptoms | **Accepted** — one calendar day, one period; avoids new tables and keeps backup shape simple. |
| Backup parity with clinical data | **Accepted** — auto-backup already exports full payload; extend row, not parallel format. |

### 0B — Existing code leverage

| Sub-problem | Existing code |
|-------------|----------------|
| Symptom UI + save | `symptom_form_sheet.dart`, `symptom_form_view_model.dart`, `PeriodRepository.updateDayEntry` / `upsertDayEntryForPeriod` |
| PDF exclusion | `pdf_data_collector.dart` (~lines 89–94): only `d.data.notes` → extend to **not** read new field |
| Export/import JSON | `export_schema.dart` `ExportedDayEntry`, `export_service.dart`, `import_service.dart` |
| DB migration | `ptrack_database.dart` `schemaVersion` 3, `tables.dart` `DayEntries` |
| Domain model | `DayEntryData` in `logging_types.dart`, `day_entry_mapper.dart` |

### 0C — Dream state diagram

```
CURRENT: one notes field → PDF + backup + UI (ambiguous “for doctor vs for me”)
    → THIS PLAN: clinical notes + personal diary column; PDF only clinical; backup both
12-MONTH IDEAL: optional encryption-at-rest for diary (out of scope unless requested)
```

### 0C-bis — Implementation alternatives

| Approach | Effort | Risk | Pros | Cons |
|----------|--------|------|------|------|
| **A: New nullable column** `personal_notes` on `day_entries` | ~0.5 day | Low | Matches mental model, one migration, clear PDF split | “Clear symptoms” behavior must be updated |
| B: Separate `diary_entries` table | ~1 day | Med | Clean separation | More joins, export/import surface area, worse fit for “same day” |
| C: Prefix convention in single `notes` field | ~2 h | High | No migration | Fragile, breaks PDF parsing, terrible UX |

**Decision:** **A** (completeness + explicit boundary).

### 0D — Mode: SELECTIVE EXPANSION

In blast radius: `ptrack_domain`, `ptrack_data`, `ptrack` app logging + PDF + tests. No new infra.

### 0E — Temporal

- **Hour 1:** Drift column + migration 4, domain + mapper + export/import.
- **Hour 6+:** UI strings (EN/DE), widget tests, edge cases (clear symptoms, import merge).

### 0F — Mode confirmation

SELECTIVE EXPANSION locked.

### 0.5 — Dual voices (CEO)

- **Codex:** Not available (`codex` not on PATH). Tagged `[single-reviewer]`.
- **Claude subagent:** Not invoked as separate process; primary analysis above substitutes structured review.

**CEO DUAL VOICES — CONSENSUS TABLE:**

```
═══════════════════════════════════════════════════════════════
  Dimension                           Claude  Codex  Consensus
  ──────────────────────────────────── ─────── ─────── ─────────
  1. Premises valid?                   Y       N/A    Y
  2. Right problem to solve?           Y       N/A    Y
  3. Scope calibration correct?      Y       N/A    Y
  4. Alternatives explored?          Y       N/A    A chosen
  5. Competitive/market risks?       low     N/A    low
  6. 6-month trajectory?             OK      N/A    OK
═══════════════════════════════════════════════════════════════
```

### Sections 1–10 (CEO) — condensed

- **User value:** Reduces fear of writing honest notes that should not appear on a PDF for a clinician.
- **Risk:** Users confuse two fields → mitigate with **clear labels + short helper text** (i18n).
- **Regulatory / trust:** PDF remains the controlled share surface; diary stays device + backup only.

### NOT in scope

- Encrypting diary separately, cloud sync, exporting diary to PDF (explicit non-goal).
- Changing PDF section toggles copy (unless needed for clarification).

### Error & Rescue Registry

| Failure | Detection | Rescue |
|---------|-----------|--------|
| Migration fails on old installs | `migration_test` + manual upgrade | Drift `IF NOT EXISTS` style add column |
| Old `.luma` without key | Import | `personal_notes` optional in `fromJson` → null |

### Failure modes

| Mode | Mitigation |
|------|------------|
| Clear symptoms wipes diary | **Product bug** — change `clearSymptoms` path (see Eng) |
| Export omits diary | Extend empty-row predicate + `ExportedDayEntry` |

### Dream state delta

Ship leaves users with explicit **shareable vs private** notes; 12-month ideal might add lock screen / encryption (defer).

### CEO completion summary

| Area | Status |
|------|--------|
| Problem fit | Strong |
| Scope | Column + UI + export/import + PDF exclusion + clear-symptoms fix |
| Deferred | Encryption, separate export toggle for diary only |

**PHASE 1 COMPLETE.** Codex: N/A. Subagent: N/A. Consensus: single-reviewer. Passing to Phase 2.

---

## Phase 2 — Design review (UI scope: **yes** — symptom sheet)

### Step 0 — Design scope

Symptom sheet already has one `TextField` for notes. Add a **second** field **below** clinical notes (or above, with visual grouping — **recommend:** clinical notes first, then diary, so “for my doctor” reads before “for me”).

### 0.5 — Design dual voices

Codex/subagent: unavailable → single-reviewer.

**Design litmus (condensed):**

| Dimension | Score | Note |
|-----------|-------|------|
| Hierarchy | 8/10 | Titles must distinguish “Notes for reports” vs “Personal notes” |
| States | 7/10 | Empty diary is fine; loading already tied to save |
| Accessibility | 8/10 | Two multiline fields need distinct `semanticsLabel` / hints |
| i18n | 9/10 | EN + DE ARB keys |

### Passes 1–7 — decisions

- **Labels:** Avoid “diary” if it sounds juvenile in DE — use “Personal notes (not in PDF)” style description in subtitle or helper.
- **Max length:** Match existing notes field behavior first; if unlimited, document same as `notes` column.

**PHASE 2 COMPLETE.** Passing to Phase 3.

---

## Phase 3 — Eng review

### Step 0 — Scope challenge (code-backed)

- **`DayEntries`:** add `TextColumn personalNotes => text().nullable()();` (`tables.dart`).
- **`ptrackSupportedSchemaVersion`:** bump to **4**; `onUpgrade` `from < 4`: `ALTER TABLE day_entries ADD COLUMN personal_notes TEXT;` (Drift `addColumn` if preferred).
- **`DayEntryData`:** add `String? personalNotes` with `==` / `hashCode` / `toString`.
- **`day_entry_mapper.dart`:** map both directions; companions include new field.
- **`ExportedDayEntry`:** add optional `personalNotes` JSON key **`personal_notes`** (snake_case consistent with `flow_intensity`).
- **`export_service.dart`:**  
  - When `includeSymptoms || includeNotes`, load and emit `personal_notes` if non-null/non-empty.  
  - Extend skip predicate: include row if personal notes alone exist.  
  - `_contentTypes`: add `'personal_notes'` when any exported day row carries personal notes **or** always when `includeDayData` ( **auto-decide:** add literal `'personal_notes'` to `content_types` whenever `includeSymptoms || includeNotes` for simpler meta — no sparse detection).
- **`import_service.dart`:** read `personal_notes`, write companion on insert/update.
- **`pdf_data_collector.dart`:** **only** aggregate `d.data.notes` for `noteByDay` / `NoteEntry` — **do not** read `personalNotes`.
- **`SymptomFormViewModel`:** second controller field `personalNotes`; `save()` includes it; load from `existing`.
- **`clearSymptoms`:** **Change behavior:** if only clearing “symptoms”, use `updateDayEntry` to set `flowIntensity`, `painScore`, `mood`, `notes` to null **and keep** `personalNotes`, **or** if all clinical fields already null, delete row only when **both** notes fields empty. Simplest robust approach: **`deleteDayEntry` only when** clinical + personal all empty after clear; otherwise **update** to null out clinical fields only. May require new repository method `clearClinicalSymptoms(int dayEntryId)` to avoid duplicating logic.

### Architecture (ASCII)

```
SymptomFormSheet
    → SymptomFormViewModel
        → PeriodRepository (upsert/update)
            → day_entries [notes, personal_notes, flow, pain, mood]
                    ↓
    ExportService / ImportService  ←→  ExportedDayEntry.personal_notes
                    ↓
    PdfDataCollector  reads only .notes (clinical)
```

### Section 3 — Test diagram

See artifact: `~/.gstack/projects/Sundypha-luma/main-test-plan-20260411-225400.md`

### Section 4 — Performance

Negligible: one extra nullable text column per row.

### Eng consensus table

Same degradation: single-reviewer; all six dimensions **OK** contingent on clear-symptoms fix.

### NOT in scope (Eng)

- File-level encryption of `.luma`.

### Failure modes (Eng)

| Issue | Severity |
|-------|----------|
| Clear wipes diary | **Critical** — must fix before ship |
| Import replaces row and drops personal notes | **High** — companions must set `Value(ie.personalNotes)` |

**PHASE 3 COMPLETE.** Passing to Phase 3.5.

---

## Phase 3.5 — DX review

**DX scope:** marginal (Flutter app, not a public API). **Skip deep DX** — log: “Phase 3.5 skipped — no primary developer-facing API change; `.luma` schema is internal.”

Optional: document new JSON field in internal export comments or `06-export-import` phase docs **only if** the repo already documents schema (check before editing).

---

## Cross-phase themes

1. **Boundary clarity** (CEO + Design + Eng): clinical vs private must be obvious in UI and enforced in PDF pipeline.
2. **Destructive actions** (Eng): symptom clear/delete paths need explicit audit.

---

## Decision Audit Trail

<!-- AUTONOMOUS DECISION LOG -->
## Decision Audit Trail

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|-------|----------|----------------|-----------|-----------|----------|
| 1 | CEO | New column on `day_entries` | Mechanical | P1 completeness | Single-row model, clear PDF split | Separate table |
| 2 | CEO | PDF excludes `personalNotes` | Mechanical | P1 | User requirement | N/A |
| 3 | Eng | JSON key `personal_notes` | Mechanical | P5 explicit | Matches existing snake_case | camelCase in JSON |
| 4 | Eng | content_types includes `personal_notes` when day data exported | Mechanical | P5 | Discoverability in meta | Sparse-only flag |
| 5 | Eng | Refactor clear symptoms to update-or-delete | Mechanical | P1 | Prevents data loss | Keep delete-only |
| 6 | Design | Clinical notes field first, personal below | Taste | P3 | Doctor-facing reads first | Reverse order |

---

## Pre-gate verification checklist

- [x] CEO outputs present
- [x] Design outputs present (UI scope)
- [x] Eng: architecture + test plan path + failure modes
- [x] DX: skipped with reason
- [x] Audit trail ≥1 row per decision
- [x] Cross-phase themes

---

## Premise gate (human confirmation required)

**Premises to confirm:**

1. Personal notes live on the **same** `day_entry` row as symptoms (one row per period+day).
2. **PDF** never includes personal notes; **`.luma`** always includes them when any day-level data is exported (symptoms and/or notes toggles), including **auto-backup**.
3. **Clear symptoms** clears flow/pain/mood/clinical notes but **preserves** personal notes when non-empty (or equivalent non-lossy rule you approve).

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | single-reviewer | Column approach; PDF split |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | CLI unavailable |
| Eng Review | `/plan-eng-review` | Architecture & tests | 1 | single-reviewer | Migration, import/export, clear-symptoms |
| Design Review | `/plan-design-review` | UI/UX | 1 | single-reviewer | Two-field hierarchy + i18n |
| DX Review | `/plan-devex-review` | Developer experience | 0 | skipped | No public API |

**VERDICT:** Plan ready for **premise confirmation** and **final approval gate**. Run individual reviews or implement after approval.

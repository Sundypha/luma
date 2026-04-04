# Architecture: Current vs Intended

**Analysis date:** 2026-04-04

## Current repository architecture

**Pattern:** Documentation-only repository with a **single utility script**.

| Concern | Location | Behavior |
|---------|----------|----------|
| Product specification | `period_tracker_prds/*.md` | Static Markdown PRDs; no executable product. |
| Doc generation (optional) | `file.py` | Creates PRD files on disk at a hardcoded base path using in-memory strings. |

There are **no** layers such as UI, domain services, persistence, or API—only prose requirements and the generator.

## Intended product architecture (from PRDs)

The PRDs describe a **client-only** mobile product for Phases 1–2, with **optional sync** in Phase 3. The following is a consolidated view suitable for future implementation planning; cite the PRD files for acceptance criteria and edge cases.

### Phase 1 — logical subsystems

Derived from `period_tracker_prds/PRD_Phase_1_MVP.md`:

1. **Onboarding / education** — Minimal first-run flow; sets privacy and limitation expectations without collecting identity.
2. **Logging domain** — Period spans (start/end, partial periods), per-day attributes (flow, pain, mood, notes), retroactive edits with validation (impossible ranges flagged).
3. **Presentation** — Month calendar (actual vs predicted styling), home/dashboard summary, day detail/edit surfaces.
4. **Prediction engine v1** — Deterministic, documented rules from history (e.g., cycle length / period duration aggregates, outlier handling, uncertainty); reproducible from same inputs.
5. **Portability** — Export to documented format; import with validation and explicit duplicate semantics.
6. **App protection** — Optional local lock (PIN/biometric), non-destructive failure modes.
7. **Persistence & migrations** — Local store with upgrade-safe schema; tests called out for migrations.

**Cross-cutting (Phase 1 NFRs):** offline-first operation, no network dependency for core paths, no third-party analytics, performance for long histories, accessibility (not color-only cues for states).

### Phase 2 — extensions

From `period_tracker_prds/PRD_Phase_2_Usability_and_Trust.md`:

- Expanded optional symptom model (curated + custom tags), quick-log affordances.
- **Prediction v2** — Range-based forecasts and confidence communication; still rules-based and explainable.
- **Local insights** — Descriptive summaries only (averages, variability, symptom timing); non-diagnostic copy.
- **Backup UX** — Reminders, user-chosen destinations, possible WebDAV-class options if kept understandable; still not “sync.”
- **Data model evolution** — Phase 1 exports must import into Phase 2; versioned fields.

### Phase 3 — sync layer

From `period_tracker_prds/PRD_Phase_3_Secure_Sync.md`:

- **Optional** sync; local database remains **authoritative** for device behavior when offline or when sync fails.
- **E2E encryption** of payloads before they leave the device; documented key creation/recovery and metadata exposure.
- **Provider abstraction** — At least one understandable backend model (user-managed storage, etc.).
- **Conflict handling** — Documented per record type; user-visible repair when automatic resolution is unsafe.
- **Device enrollment / revocation** — Honest UX about what revocation can and cannot do on a lost device.

### Phase 4 — prediction evolution

From `period_tracker_prds/PRD_Phase_4_Advanced_Prediction.md`:

- **Layer A:** Advanced transparent statistics (recency weighting, variability windows, insufficient-data / pattern-shift handling, explanation surface).
- **Layer B (gated):** On-device personalization only by default; optional mode; evaluation before release; no centralized training of user histories for ordinary use.

## Data and domain concepts (implementation-facing)

Terms recur across PRDs; an implementer should model these explicitly:

| Concept | Source | Notes |
|---------|--------|-------|
| **Period / cycle** | Phase 1 | Start/end dates, support incomplete periods; edits must not corrupt neighbors. |
| **Day-scoped entries** | Phase 1–2 | Symptoms, notes, flow, mood tied to calendar days; calendar is primary interpretation layer. |
| **Prediction (estimate)** | Phase 1–4 | Always non-medical; uncertainty and explainability are requirements, not optional polish. |
| **Export document** | Phase 1+ | Must round-trip; versioning and schema documentation required in repo per Phase 1. |
| **Sync blob / encrypted payload** | Phase 3 | Distinct from export semantics; must not replace export/import. |

## Entry points (future app)

Not applicable today. When implementation begins, expect:

- **Mobile app entry** — Platform-specific main activity / `App` root (location TBD by chosen framework).
- **Repository entry today** — `file.py` if regenerating docs; otherwise readers open `period_tracker_prds/PRD_Phase_1_MVP.md` for MVP scope.

## Error handling and trust (product-level)

PRDs emphasize **no silent data loss**, **clear import failures**, **predictable conflict behavior** (Phase 3), and **honest capability claims**. These translate into engineering requirements: migration tests, validation layers on import, user-visible error copy, and deterministic prediction tests.

---

*Architecture analysis for doc-only repo + PRD-defined future system.*

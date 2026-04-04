# Repository Overview

**Analysis date:** 2026-04-04

## Purpose

This repository holds **product requirements** for a **FOSS, privacy-first, local-first menstrual cycle tracker** (mobile application as specified in the PRDs). At the time of analysis there is **no application implementation**—only documentation and a small Python utility that can regenerate those documents.

## Complete file inventory

Paths are relative to the repository root `D:/CODE/ptrack`. `.git` is listed for completeness; it is not product source.

| Path | Role |
|------|------|
| `file.py` | Python script: writes the PRD markdown files to a configured directory (see Quality notes in sibling docs). |
| `period_tracker_prds/README.md` | Index of the PRD package and file list. |
| `period_tracker_prds/PRD_Phase_1_MVP.md` | Phase 1 MVP PRD (local-first core). |
| `period_tracker_prds/PRD_Phase_2_Usability_and_Trust.md` | Phase 2 PRD (depth, uncertainty, local insights, backup UX). |
| `period_tracker_prds/PRD_Phase_3_Secure_Sync.md` | Phase 3 PRD (optional encrypted multi-device sync). |
| `period_tracker_prds/PRD_Phase_4_Advanced_Prediction.md` | Phase 4 PRD (advanced statistics / bounded personalization). |
| `.planning/analysis/OVERVIEW.md` | This file (codebase map output). |
| `.planning/analysis/ARCHITECTURE.md` | Intended vs current architecture. |
| `.planning/analysis/QUALITY_AND_RISKS.md` | Quality, security/privacy hooks, risks. |
| `.git/` | Git metadata (hooks, config, etc.). |

**Not present:** `package.json`, `pubspec.yaml`, `build.gradle`, `Cargo.toml`, application `src/`, tests, CI configs, or other runtime project scaffolding.

## Simplified tree

```
ptrack/
├── file.py
├── period_tracker_prds/
│   ├── README.md
│   ├── PRD_Phase_1_MVP.md
│   ├── PRD_Phase_2_Usability_and_Trust.md
│   ├── PRD_Phase_3_Secure_Sync.md
│   └── PRD_Phase_4_Advanced_Prediction.md
└── .planning/
    └── analysis/
        ├── OVERVIEW.md
        ├── ARCHITECTURE.md
        └── QUALITY_AND_RISKS.md
```

## Product phases (from PRDs)

| Phase | Document | Goal (summary) |
|-------|----------|----------------|
| **1 — MVP** | `period_tracker_prds/PRD_Phase_1_MVP.md` | Usable offline tracker: onboarding, period/symptom logging, calendar, home summary, rules-based prediction v1, export/import, optional app lock; no accounts, no cloud, no analytics. |
| **2 — Usability & trust** | `period_tracker_prds/PRD_Phase_2_Usability_and_Trust.md` | Richer (optional) symptom model, quick logging, prediction v2 with uncertainty, local descriptive insights, better history/backup UX; still local-only computation. |
| **3 — Secure sync** | `period_tracker_prds/PRD_Phase_3_Secure_Sync.md` | Optional multi-device continuity: client-side encryption, provider abstraction, conflict handling, local DB remains authoritative. |
| **4 — Advanced prediction** | `period_tracker_prds/PRD_Phase_4_Advanced_Prediction.md` | Better forecasting via advanced statistics first; gated, on-device bounded personalization; non-medical framing. |

## MVP scope (Phase 1) — condensed

From `period_tracker_prds/PRD_Phase_1_MVP.md`:

- **Onboarding:** local storage explanation, no account, predictions as estimates, path to first log quickly.
- **Logging:** period start/end (including retroactive), flow, notes, pain, mood; edits must not corrupt adjacent cycle logic.
- **Calendar:** month view, distinct actual vs predicted days, day drill-down, smooth navigation over years.
- **Home:** cycle position, next expected period, today’s log state, quick log action.
- **Prediction v1:** documented deterministic rules; uncertainty when data is thin; never contraceptive/medical claims.
- **Export / import:** full round-trip, documented format in repo.
- **Protection:** optional PIN/biometric (not forced on first launch).
- **NFRs:** performance, reliable migrations, no analytics/ads/telemetry, accessibility and neutral copy.

**Explicitly out of scope for Phase 1:** cloud backup, sync, ML, diagnosis/treatment, social, wearables, advanced dashboards, fertility-treatment mode, etc.

## Technology stack

### Actual (repository)

- **Languages:** Python 3–style script only (`file.py` uses `pathlib`).
- **Dependencies:** Standard library only (`pathlib`); no `requirements.txt` or lockfile.
- **Runtime:** None for an end-user product; PRDs are static Markdown.

### Planned / implied (PRDs)

- **Product type:** FOSS **mobile application** (`period_tracker_prds/PRD_Phase_1_MVP.md` states “FOSS mobile application”).
- **Platform framework:** **Not specified** in the sampled PRD text (no Flutter vs native vs React Native mandate).
- **Data:** Local-first on-device storage; Phase 1 requires documented export schema; Phase 3 adds E2E-encrypted sync payloads and provider abstraction.
- **Backend:** None for Phases 1–2; Phase 3 introduces optional sync targets (user-managed or similar), not a prescribed vendor.

## Relationship between docs and code

- **`period_tracker_prds/*.md`** are the canonical product specs in the repo.
- **`file.py`** duplicates the same content as embedded strings and can write `README.md` plus the four PRDs to an output directory. The checked-in copies under `period_tracker_prds/` are the documents engineers should treat as source of truth unless the team standardizes on “generate from `file.py` only.”

## Implementation status vs PRDs

| PRD expectation | Repo reality |
|-----------------|--------------|
| Mobile app with UI, storage, prediction, export | **Not started** — no app tree or manifests. |
| Documented export format in repository | **Partial** — format is required by PRD but not yet defined as schema files in repo (only requirements text). |
| Local-first, no telemetry | **N/A for code** — no shipped binary; future dependency choices must be validated against PRD. |

---

*Overview generated for planning and implementation handoff.*

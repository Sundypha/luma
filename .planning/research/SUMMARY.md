# Project Research Summary

**Project:** Period Tracker (ptrack)  
**Domain:** Privacy-first local-first menstrual cycle tracking (mobile)  
**Researched:** 2026-04-04  
**Confidence:** HIGH for Phase 1 scope (grounded in packaged PRDs); MEDIUM for exact Flutter package choices

## Executive Summary

The product is defined primarily by **`period_tracker_prds/`**: Phase 1 is a **complete offline MVP** with logging, calendar, home, **explainable rules-based prediction**, **documented export/import**, and optional lock—**no accounts, no sync, no ML**. Engineering choices **Flutter with FVM** and **TDD** align with reproducible builds and the PRD’s emphasis on **determinism, migrations, and no silent data loss**. The main early technical risks are **schema/migration discipline**, **prediction clarity**, and **keeping dependencies telemetry-free**.

## Key Findings

### Recommended Stack

- **Flutter (pinned via FVM)** for iOS/Android with shared codebase  
- **Local SQL-flavored persistence** (e.g. drift) favored for migrations and relational timeline queries  
- **flutter_test / integration_test** for TDD and critical-path coverage  

### Expected Features

**Must have (Phase 1):** Accountless onboarding; period + symptom logging; calendar; home summary; prediction v1 with uncertainty; export + import; optional lock; privacy NFRs; accessibility basics  

**Defer:** Sync (Phase 3), advanced prediction (Phase 4), deep usability program (Phase 2 items beyond MVP bar—see Phase 2 PRD when planning that milestone)  

### Architecture Approach

Layer **UI → use cases → domain (rules) → repositories → local DB/file I/O**; keep prediction **pure** and **tested**; treat export schema as a **public contract** with version field.

### Pitfalls to Watch

Data loss on migration; ambiguous calendar semantics; telemetry creep via dependencies; import idempotency confusion.

## Roadmap Implications

- Early phases should establish **domain + DB + prediction tests** before heavy UI polish  
- **Export schema documentation** in repo should land with or before import/export features  
- **Dependency review** as an explicit task in Phase 1 setup  

---
*Synthesized from `.planning/research/{STACK,FEATURES,ARCHITECTURE,PITFALLS}.md` and `period_tracker_prds/`.*

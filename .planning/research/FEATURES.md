# Features Research

**Domain:** Period / cycle tracking apps  
**Researched:** 2026-04-04  
**Source:** `period_tracker_prds/PRD_Phase_1_MVP.md` and package README (Phases 2–4 for deferral context)

## Table Stakes (Phase 1 — must ship)

Users expect a tracker to:

- Log period start/end and edit retroactively
- See a **calendar** that shows history clearly
- Get a **simple next-period estimate** when enough data exists
- **Not require an account**
- Feel **fast** for habitual logging

This project adds non-negotiable **export/import** and **offline-only** core use as differentiators vs many commercial apps.

## Phase 1 Feature Set (v1 roadmap input)

Derived from PRD §6–7 and §10 acceptance summary:

| Area | Capability |
|------|------------|
| Onboarding | Local storage + no account + predictions are estimates; quick path to first log |
| Logging | Start/end dates, flow intensity, notes, pain, mood; invalid ranges flagged |
| Calendar | Month view; distinct actual vs predicted; tap day to view/edit; performance over years |
| Home | Cycle position, next estimate, today’s log state, quick log/edit |
| Prediction v1 | Documented deterministic rules; uncertainty when sparse/irregular; never contraception framing |
| Export | Full user data + metadata; documented schema in repo |
| Import | Validate; clear errors; deterministic duplicate policy |
| Lock | Optional PIN/biometric; not forced on first launch |
| NFR | No analytics/ads; accessible patterns (not color-only); inclusive copy |

## Differentiators (product positioning, not extra Phase 1 scope)

- **FOSS + documented export format** for community trust
- **Explainable** prediction vs black-box “AI”
- **Technical privacy** (no telemetry) vs policy-only claims

## Anti-features (do not build in Phase 1)

- Sync, cloud backup, ML prediction, social, wearables, medical/fertility treatment modes — per PRD §8

## Deferred (later PRD phases)

- **Phase 2:** Usability & trust depth (see `PRD_Phase_2_Usability_and_Trust.md`)
- **Phase 3:** Optional E2E-encrypted sync (`PRD_Phase_3_Secure_Sync.md`)
- **Phase 4:** Advanced on-device prediction with governance (`PRD_Phase_4_Advanced_Prediction.md`)

## Dependencies Between Features

- **Prediction** depends on **logging** data model and stable **date** handling
- **Export/import** depends on finalized **schema + versioning**
- **Calendar/home** depend on same domain model and prediction read model

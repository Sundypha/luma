# Requirements: Period Tracker (ptrack)

**Defined:** 2026-04-04  
**Core Value:** Trustworthy local-first cycle tracking without accounts or required network access, with verifiable data ownership via export/import.

## v1 Requirements

Phase 1 MVP — derived from `period_tracker_prds/PRD_Phase_1_MVP.md` (functional §6, NFR §7, acceptance §10).

### Onboarding

- [ ] **ONBD-01**: User sees that data is stored locally on the device and no account is required
- [ ] **ONBD-02**: User sees that predictions are estimates based on entered history (not medical advice)
- [ ] **ONBD-03**: User can reach the first logging action in under one minute (minimal friction path)
- [ ] **ONBD-04**: User can skip non-essential education and continue; onboarding works fully offline

### Core logging

- [ ] **LOG-01**: User can mark period start date (today or past) and add or edit end date later
- [ ] **LOG-02**: User can log flow intensity for days or span without making symptoms mandatory
- [ ] **LOG-03**: User can add or edit notes, pain score, and mood on relevant days
- [ ] **LOG-04**: User can edit previously entered periods without corrupting adjacent cycle data
- [ ] **LOG-05**: App prevents impossible date ranges or flags them clearly
- [ ] **LOG-06**: Entries save reliably and display in the correct day context (retroactive entry supported)

### Calendar and timeline

- [ ] **CAL-01**: User can view a month-based calendar and navigate past and future months smoothly
- [ ] **CAL-02**: Logged period days and predicted future days are visually distinguishable (not color-only)
- [ ] **CAL-03**: User can tap a day to view or edit entries for that day
- [ ] **CAL-04**: Calendar remains performant with multi-year local history
- [ ] **CAL-05**: Prediction display on the calendar updates after edits to underlying data

### Home summary

- [ ] **HOME-01**: User sees where they are in the cycle and status of the next expected period (or clear insufficient-data state)
- [ ] **HOME-02**: User sees what they logged today at a glance
- [ ] **HOME-03**: User has a visible quick action to log or edit without deep navigation
- [ ] **HOME-04**: Home does not present unsupported “cycle health” scores or overconfident precision

### Prediction v1

- [x] **PRED-01**: Next-period estimate uses documented deterministic rules from user’s period history (e.g. averages, basic outlier handling)
- [x] **PRED-02**: When history is insufficient or highly variable, app surfaces uncertainty instead of false precision
- [x] **PRED-03**: User can read a plain-language explanation of how the current prediction was derived
- [ ] **PRED-04**: Copy and UI never frame prediction as contraception or medically authoritative

### Data export

- [ ] **XPRT-01**: User can initiate full local export without an account
- [ ] **XPRT-02**: Export includes periods, symptoms, notes, and metadata needed for round-trip restoration
- [ ] **XPRT-03**: Export format is documented in the repository and includes schema/version markers

### Data import

- [ ] **IMPT-01**: User can import from a prior valid export file
- [ ] **IMPT-02**: Invalid or corrupted files fail with readable validation errors (no silent corruption)
- [ ] **IMPT-03**: Duplicate-handling behavior is deterministic and explained in product copy

### App protection

- [ ] **LOCK-01**: User can enable optional PIN or biometric lock from settings (not forced on first use)
- [ ] **LOCK-02**: Lock behavior is reliable across background/foreground transitions on supported devices
- [ ] **LOCK-03**: Lock is not described as full cryptographic protection; failure modes avoid stranding users without data recovery narrative

### Non-functional (Phase 1)

- [ ] **NFR-01**: Common screens and logging actions feel immediate on mainstream supported devices
- [ ] **NFR-02**: No silent data loss; core paths are stable; app upgrades preserve local data with tested migrations
- [x] **NFR-03**: No analytics collection, ad identifiers, or third-party ads/profiling SDKs; no hidden telemetry of reproductive events
- [x] **NFR-04**: Dependency and build choices are reviewable for the above privacy constraints
- [ ] **NFR-05**: Primary actions are understandable without dense tutorial text
- [ ] **NFR-06**: Predicted vs actual periods distinguishable without relying on color alone
- [ ] **NFR-07**: Copy avoids unnecessary gendered assumptions and unsupported medical claims
- [ ] **NFR-08**: Full Phase 1 feature set works in airplane mode after install (no login, no network-required errors on core flows)

## v2 Requirements

Deferred — see later PRDs (not in current v1 roadmap):

- **Phase 2** — `PRD_Phase_2_Usability_and_Trust.md`: deeper usability, trust, and polish initiatives beyond MVP acceptance
- **Phase 3** — `PRD_Phase_3_Secure_Sync.md`: optional E2E-encrypted sync and multi-device narratives
- **Phase 4** — `PRD_Phase_4_Advanced_Prediction.md`: advanced on-device prediction and governance

## Out of Scope

Explicit Phase 1 exclusions per PRD §8:

| Feature | Reason |
|---------|--------|
| Cloud backup / multi-device sync | Phase 3; would change trust model and architecture |
| Machine learning / opaque prediction | Phase 4; Phase 1 requires explainable rules |
| Diagnosis, treatment, or contraception guidance | Legal/ethical scope; not a medical device |
| Community, forums, chat, partner sharing | Out of product scope for Phase 1 |
| Wearables and device integrations | Complexity; deferred |
| Advanced analytics dashboards | Performance and scope; not Phase 1 core loop |
| Fertility treatment mode / clinician portal | Explicit non-goal for Phase 1 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ONBD-01 | Phase 3 | Pending |
| ONBD-02 | Phase 3 | Pending |
| ONBD-03 | Phase 3 | Pending |
| ONBD-04 | Phase 3 | Pending |
| LOG-01 | Phase 4 | Pending |
| LOG-02 | Phase 4 | Pending |
| LOG-03 | Phase 4 | Pending |
| LOG-04 | Phase 4 | Pending |
| LOG-05 | Phase 4 | Pending |
| LOG-06 | Phase 4 | Pending |
| CAL-01 | Phase 5 | Pending |
| CAL-02 | Phase 5 | Pending |
| CAL-03 | Phase 5 | Pending |
| CAL-04 | Phase 5 | Pending |
| CAL-05 | Phase 5 | Pending |
| HOME-01 | Phase 5 | Pending |
| HOME-02 | Phase 5 | Pending |
| HOME-03 | Phase 5 | Pending |
| HOME-04 | Phase 5 | Pending |
| PRED-01 | Phase 2 | Complete |
| PRED-02 | Phase 2 | Complete |
| PRED-03 | Phase 2 | Complete |
| PRED-04 | Phase 2 | Pending |
| XPRT-01 | Phase 6 | Pending |
| XPRT-02 | Phase 6 | Pending |
| XPRT-03 | Phase 6 | Pending |
| IMPT-01 | Phase 6 | Pending |
| IMPT-02 | Phase 6 | Pending |
| IMPT-03 | Phase 6 | Pending |
| LOCK-01 | Phase 7 | Pending |
| LOCK-02 | Phase 7 | Pending |
| LOCK-03 | Phase 7 | Pending |
| NFR-01 | Phase 8 | Pending |
| NFR-02 | Phase 2 | Pending |
| NFR-03 | Phase 1 | Complete |
| NFR-04 | Phase 1 | Complete |
| NFR-05 | Phase 8 | Pending |
| NFR-06 | Phase 5 | Pending |
| NFR-07 | Phase 8 | Pending |
| NFR-08 | Phase 8 | Pending |

**Coverage:**

- v1 requirements: 40 total
- Mapped to phases: 40
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-04*  
*Last updated: 2026-04-04 after initial definition from Phase 1 PRD*

# PRD — Phase 3: Secure Multi-Device Sync and Conflict-Safe State Coordination

**Document status:** Draft for planning  
**Phase goal:** Enable optional multi-device continuity without abandoning the product’s local-first and privacy-first architecture.  
**Dependencies:** Phase 1 and Phase 2 stable, including documented export format and mature local data model  
**Out of scope for this phase:** hosted central accounts as a requirement, plaintext server visibility, social collaboration, machine learning

---

## 1. Purpose of this phase

Phase 3 exists because local-first is necessary but not always sufficient. Many users eventually expect to continue using the same tracker across multiple devices, after device replacement, or after loss events. Manual import/export and backup solve part of this problem, but not the ongoing state coordination problem.

This phase must provide optional sync without collapsing into the architecture of a typical cloud-first health app. The design challenge is not merely technical synchronization. The challenge is preserving the product’s trust model while supporting multi-device continuity.

### Success definition

Phase 3 succeeds if a user can keep data consistent across multiple devices using a sync path that is:
- optional,
- understandable,
- privacy-preserving,
- resilient against common conflict scenarios,
- not dependent on trusting the server with plaintext reproductive health data.

### Failure definition

Phase 3 fails if:
- sync becomes effectively mandatory,
- the server can read user health data in plaintext,
- conflicts silently destroy or rewrite data,
- product messaging confuses backup, restore, and sync,
- the local-first architecture becomes secondary to server truth.

---

## 2. Problem statement

By this stage, the product should already be valuable on a single device. However, real-world usage patterns introduce new needs:
- users replace phones,
- some users track on phone and tablet,
- users want continuity after data loss events,
- users do not want to manually shuttle exports every time data changes.

Commercial apps solve this by making a central cloud account the canonical source of truth. This project must solve it differently: the local database remains primary, and synchronization is an optional coordination layer, not the defining identity of the app.

---

## 3. Product principles specific to sync

## 3.1 Sync must remain optional

**Why this is included**
A local-first product becomes a cloud product the moment sync is treated as the default requirement.

**Acceptance criteria**
- All existing non-sync functionality continues to work with sync disabled.
- Users can explicitly choose to never configure sync.
- Product copy does not pressure sync setup for ordinary use.

**Pitfalls**
- Sync prompts during onboarding.
- UI paths that assume a signed-in sync state exists.
- Treating unsynced users as second-class.

**What to avoid and why**
Avoid framing sync as “complete setup.” That language redefines the product around cloud participation.

## 3.2 End-to-end confidentiality of synced data

Sync transport or storage providers must not gain access to plaintext reproductive health data.

**Why this is included**
Without this requirement, sync would directly undermine the privacy premise of the app.

**Acceptance criteria**
- Synced payloads are encrypted client-side before leaving the device.
- Providers used for sync cannot read user content from stored payloads.
- Key handling and recovery model are documented clearly.

**Pitfalls**
- Metadata leakage being ignored.
- Using platform sync surfaces that appear private but are not actually end-to-end encrypted under the project’s control.
- Overpromising against every conceivable adversary.

**What to avoid and why**
Avoid claims of perfect secrecy without a concrete threat model. The product must specify what is protected and from whom.

## 3.3 Local database remains authoritative for device behavior

The app must not become unusable because sync is temporarily unavailable.

**Why this is included**
If server reachability controls user access to local data, the product is no longer meaningfully local-first.

**Acceptance criteria**
- Device remains fully usable while offline after sync is configured.
- Local changes queue or stage appropriately for later sync rather than blocking.
- Read access to prior data never depends on current sync availability.

**Pitfalls**
- Making sync state part of normal data retrieval paths.
- Locking the UI until remote reconciliation completes.

**What to avoid and why**
Avoid designs where the server becomes the primary store and local data is a cache. That architecture directly conflicts with the product’s identity.

## 3.4 Conflict behavior must be explicit and safe

**Why this is included**
When multiple devices edit overlapping data, silent resolution can erase user intent. This is unacceptable for personal health history.

**Acceptance criteria**
- Conflict rules are documented.
- Common simultaneous edit scenarios produce predictable outcomes.
- Where automatic resolution cannot preserve meaning safely, the user is informed and given a comprehensible recovery path.

**Pitfalls**
- “Last write wins” applied indiscriminately to complex records.
- Hidden merges that preserve structural validity but alter meaning.
- Overcomplicated conflict UIs that only expert users understand.

**What to avoid and why**
Avoid pretending conflicts never happen. They do, and unacknowledged conflict policy is itself a product decision.

---

## 4. User problems this phase must solve

### 4.1 “I changed phones and want my data intact”
### 4.2 “I use more than one device and do not want manual import/export every time”
### 4.3 “I want this convenience without trusting a company server with my reproductive health data”
### 4.4 “I want to know what happens if sync breaks or devices disagree”

**Why these are included**
These are the most likely real-world continuity concerns once a local-first tracker becomes a user’s long-term record.

---

## 5. Functional requirements

## 5.1 Sync setup and mental model

### Requirements
The app must provide a sync setup flow that explains:
- sync is optional,
- data remains locally available,
- sync provider choices available in this phase,
- the role of encryption,
- the implications of key loss or device loss.

The setup experience must not require identity with the project itself unless the project later offers an optional hosted service and such service still respects end-to-end encryption. Even then, project-hosted identity must remain optional if alternative user-controlled providers are supported.

**Why this is included**
Sync is too important and too sensitive to hide behind a wizard that users do not understand.

**Acceptance criteria**
- Users can complete setup without guessing what the provider can see.
- Users understand whether the project is storing plaintext data or not.
- Users can exit setup without damaging local data.

**Pitfalls**
- Overloading setup with cryptographic terminology.
- Providing convenience first and explanation second.

**What to avoid and why**
Avoid dark-pattern simplicity where the product is easy to enable but impossible to understand later. Comprehensibility is part of trust.

## 5.2 Provider abstraction and supported backends

### Requirements
The sync layer must support one or more provider models that preserve user control, such as:
- user-managed storage endpoint,
- user-selected file or object storage path,
- project-hosted encrypted blob transport only if optional and not identity-mandatory.

The PRD does not prescribe a specific technical provider implementation, but the user-facing requirement is clear: the storage destination and trust boundary must be understandable.

**Why this is included**
If sync is introduced but only via a project-controlled black box, user trust may not meaningfully improve over commercial alternatives.

**Acceptance criteria**
- At least one provider model is usable end to end.
- The product can describe the provider’s role accurately.
- Provider failure does not corrupt local data.

**Pitfalls**
- Designing for too many providers before one is robust.
- Hiding provider-specific constraints from the user.

**What to avoid and why**
Avoid broad provider support claims in Phase 3 if the user experience differs meaningfully between them and those differences are not yet polished.

## 5.3 Data encryption for sync payloads

### Requirements
Before synced records leave the device, the app must encrypt content using a key model documented in product and repository documentation. The PRD requires:
- no plaintext reproductive health data transmitted or stored by the sync provider,
- explicit key creation and recovery model,
- clear explanation of consequences if recovery material is lost.

**Why this is included**
The privacy posture of sync is only as credible as its data confidentiality model.

**Acceptance criteria**
- Representative sync traffic inspection does not reveal plaintext data.
- The provider cannot reconstruct periods, symptoms, or notes from stored payloads.
- Documentation explains what metadata may still be visible.

**Pitfalls**
- Ignoring filenames, object names, or timing metadata.
- Recovery flows that are so weak users lock themselves out permanently.
- Recovery flows that are so permissive the encryption becomes meaningless.

**What to avoid and why**
Avoid promising “zero knowledge” if the design has not formally evaluated what metadata remains exposed. Precise language is better than inflated language.

## 5.4 Offline edits and later synchronization

### Requirements
A synced user must still be able to:
- create new logs,
- edit existing logs,
- delete entries,
- export data,
while offline. Later synchronization must reconcile those changes according to documented rules.

**Why this is included**
The defining property of local-first cannot disappear once sync is enabled.

**Acceptance criteria**
- Sync-disabled and sync-enabled offline behavior are both functional.
- Local changes are durable before remote transmission.
- Network restoration does not cause data disappearance or duplicate storms.

**Pitfalls**
- Temporary IDs or local state markers leaking into user-visible inconsistencies.
- Retrying logic that creates duplicate entries.
- Deletion semantics that are not coordinated safely.

**What to avoid and why**
Avoid architectures that treat offline edit mode as an exceptional state. In this product, offline is the baseline, not the exception.

## 5.5 Conflict detection and resolution

### Requirements
The product must define what constitutes a conflict and how it is handled for at least the following cases:
- the same day edited differently on two devices,
- a period range changed on one device while symptom entries for overlapping days are added on another,
- deletion on one device and modification on another,
- note edits that diverge.

The conflict strategy may differ by record type, but it must be documented and understandable. Pure “last write wins” may be acceptable for some low-risk fields but not as a blanket policy if it destroys user meaning too easily.

**Why this is included**
Conflicts are not edge cases in sync. They are normal product behavior.

**Acceptance criteria**
- Common conflict scenarios are tested.
- The user is not silently left with corrupt or implausible state.
- Where user intervention is needed, the prompt is rare, comprehensible, and recoverable.

**Pitfalls**
- Assuming timestamps alone are enough for all cases.
- Burdening users with technical merge screens for common cases.
- Preserving structural validity but losing semantic history.

**What to avoid and why**
Avoid overly elegant resolution rules that only engineers understand. If a merge policy cannot be explained clearly, it is likely too brittle.

## 5.6 Device enrollment and revocation

### Requirements
Users must be able to understand which devices participate in sync and remove participation when needed, especially after device loss or replacement.

**Why this is included**
Multi-device use creates operational security questions. Users need confidence they can end a lost device’s participation.

**Acceptance criteria**
- Active device list or equivalent participation model is visible if applicable to the chosen design.
- Device removal or reset path is documented.
- Revocation does not erase healthy devices unexpectedly.

**Pitfalls**
- Weak mental model for what revocation actually means when data is already local.
- Treating device removal as though it can retroactively delete local copies on offline lost devices.

**What to avoid and why**
Avoid implying magical control over an already-lost offline device. The product must be honest about what revocation can and cannot do.

## 5.7 Recovery and repair flows

### Requirements
The sync system must have user-facing recovery paths for:
- interrupted initial sync,
- corrupted remote state,
- key mismatch or missing recovery material,
- duplicate import/sync confusion,
- migration from backup-only use to sync-enabled use.

**Why this is included**
Sync failure handling determines whether users see the feature as trustworthy or as dangerous.

**Acceptance criteria**
- Recovery paths do not require deleting local data as the first resort.
- Error messages explain what remains safe locally.
- Support and documentation can explain recovery without requiring hidden engineering knowledge.

**Pitfalls**
- Error messages that expose implementation jargon only.
- “Start over” as the dominant resolution path.
- Mixing backup restore and sync repair semantics.

**What to avoid and why**
Avoid destructive repair defaults. For a personal health history app, preservation is more important than convenience.

---

## 6. Non-functional requirements

## 6.1 Sync must not degrade baseline performance excessively

**Why this is included**
Users must not feel punished for enabling sync.

**Acceptance criteria**
- Ordinary local interactions remain responsive.
- Sync occurs without blocking ordinary use except where unavoidable and clearly communicated.
- Battery and storage impact remain proportionate.

**Pitfalls**
- Excessive polling.
- Whole-database uploads for minor changes.
- heavy background processing that reduces trust in the app.

**What to avoid and why**
Avoid wasteful sync semantics that imply the product is not mature enough for real-world use.

## 6.2 Security communication must be precise

**Why this is included**
This phase introduces terminology users may misread. Precision matters.

**Acceptance criteria**
- In-app language matches the actual threat model.
- Documentation distinguishes encrypted transport, encrypted storage, and end-to-end confidentiality.
- Recovery tradeoffs are stated clearly.

**Pitfalls**
- Marketing-style security phrases not backed by architecture.
- Burying tradeoffs like unrecoverable keys too deeply.

**What to avoid and why**
Avoid absolute claims unless they are defensible against clear threat models.

## 6.3 Data portability remains intact

Sync must not replace export/import or make exported data secondary.

**Why this is included**
A local-first FOSS app cannot let sync become a new lock-in path.

**Acceptance criteria**
- User can still export full data with sync enabled.
- Export remains understandable and complete.
- Disabling sync does not strand the data.

**Pitfalls**
- Storing sync-only metadata in ways that break portability.
- Treating cloud state as canonical and export as derivative.

**What to avoid and why**
Avoid any design where leaving sync means losing coherence of the local dataset.

---

## 7. Exclusions and non-goals for Phase 3

Not included:
- mandated project-hosted accounts,
- plaintext cloud analytics over synced data,
- shared family or partner views,
- collaborative editing as a product feature,
- machine learning personalization from remote training,
- “smart” conflict decisions that are opaque to users.

**Why this is included**
Sync invites many adjacent requests, but this phase is specifically about secure continuity, not collaboration or intelligence.

**Acceptance criteria**
- Scope remains focused on secure optional continuity.
- Architectural decisions do not quietly centralize control.

**Pitfalls**
- Collaboration requirements sneaking in under sync design.
- Hosted-account assumptions contaminating the data model.

**What to avoid and why**
Avoid turning personal sync into a shared-data platform. That is a different product and a different trust model.

---

## 8. Risks and mitigation

### 8.1 Risk: sync undermines privacy narrative
If users cannot understand what the provider sees, they may trust the app less than before.

**Mitigation**
- Clear setup explanations.
- Strong encryption defaults.
- Transparent documentation.

### 8.2 Risk: conflict handling harms data integrity
Poor merge behavior could rewrite history incorrectly.

**Mitigation**
- Conservative conflict policy.
- Extensive scenario testing.
- User-visible repair path when needed.

### 8.3 Risk: support burden increases sharply
Sync introduces far more failure modes than single-device use.

**Mitigation**
- Keep supported provider set narrow at first.
- Invest in diagnostics and user documentation.
- Treat sync as optional, not required.

### 8.4 Risk: sync architecture recentralizes the product
Engineering convenience may push the design toward server-truth assumptions.

**Mitigation**
- Reaffirm local database authority in product reviews.
- Test offline behavior continuously.

---

## 9. Acceptance test summary for Phase 3

Phase 3 is complete only if the following are all true:

1. Sync is optional and does not gate ordinary product use.
2. Synced data is encrypted client-side before provider storage or transport.
3. Local use remains fully functional while sync is unavailable.
4. Common conflict scenarios are handled predictably and safely.
5. Users can understand and recover from sync failures without immediate data loss.
6. Export/import still works independently of sync.
7. Product copy accurately describes the sync trust model.
8. The app does not become cloud-first in user experience or architecture.

---

## 10. Launch recommendation for end of Phase 3

At the end of Phase 3, the app may reasonably describe itself as:
“A local-first menstrual cycle tracker with optional encrypted multi-device sync.”

It should not imply:
- that the provider can never see any metadata unless that has been specifically addressed and documented,
- that all conflict scenarios are invisible or trivial,
- that sync replaces backups,
- that project-hosted infrastructure is required for trustworthy use.

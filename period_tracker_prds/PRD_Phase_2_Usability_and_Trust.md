# PRD — Phase 2: Usability, Depth, and Trust Reinforcement

**Document status:** Draft for planning  
**Phase goal:** Build on the stable Phase 1 core by making the app substantially more useful, more expressive, and more competitive with mainstream trackers in day-to-day experience, while preserving local-first and privacy-first principles.  
**Dependencies:** Phase 1 complete and stable  
**Out of scope for this phase:** multi-device sync, hosted accounts, machine learning, remote insights processing, social features

---

## 1. Purpose of this phase

Phase 2 exists to solve the most likely reason a privacy-first tracker loses users after initial adoption: lack of depth and lack of comfort in daily use.

Phase 1 proves that the app can work. Phase 2 must prove that the app can become the app users want to keep using. That means improving logging richness, presentation quality, confidence communication, manual backup options, and local-only insights that add practical value without introducing surveillance patterns.

This phase is not about adding complexity for its own sake. It is about increasing usefulness while preserving the product’s trust posture.

### Success definition

Phase 2 succeeds if users who already trust the app also find it significantly more informative, more comfortable to use, and more resilient for long-term retention than the MVP.

### Failure definition

Phase 2 fails if:
- feature richness increases logging friction materially,
- the app starts to resemble a data-entry burden,
- “insights” drift into pseudo-medical interpretation,
- backup options reintroduce centralization assumptions,
- the product loses the simplicity and credibility earned in Phase 1.

---

## 2. Product problem addressed in this phase

A basic tracker is useful, but many users eventually want more than a calendar plus a next-date estimate. They want to track patterns that matter to them, understand variability, and preserve their data more comfortably. Commercial apps often satisfy these needs by collecting more data than necessary and centralizing it. This phase aims to meet those same underlying user needs using local-only design.

---

## 3. Objectives for Phase 2

1. Make tracking more expressive without making it cumbersome.
2. Improve predictions by reflecting uncertainty honestly rather than only returning a single date.
3. Add local-only pattern visibility that users can understand and control.
4. Introduce user-controlled backup pathways that do not require trust in a hosted vendor.
5. Improve UX polish to reduce the gap between privacy-focused tools and mainstream tools.

**Why these objectives are included**
They represent the biggest functional deficits that privacy-first trackers typically have compared with commercial leaders.

**Acceptance criteria**
- Each objective is implemented without violating Phase 1 trust constraints.
- Added functionality remains optional where appropriate.
- Daily logging remains fast.

**Pitfalls**
- Treating “advanced” as synonymous with “better.”
- Turning the product into a generalized wellness tracker.
- Adding too many symptom categories before usage patterns justify them.

---

## 4. User needs addressed in this phase

### 4.1 “My cycle experience is not fully captured by basic fields”
Users may want to log symptoms with more nuance, especially when patterns matter from month to month.

### 4.2 “I want predictions that acknowledge irregularity”
Many users do not have highly regular cycles and distrust tools that imply false certainty.

### 4.3 “I want to see patterns in my own data”
Users often want practical local insights such as recurring symptoms or cycle variability, but without being told that the app is diagnosing them.

### 4.4 “I want a safer backup path than remembering to export manually”
Manual export is necessary, but some users need easier recurring backup methods that still keep control in their hands.

**Why these are included**
They are natural follow-on needs once the Phase 1 app becomes part of a user’s routine.

---

## 5. Functional requirements

## 5.1 Expanded symptom tracking

### Requirements
The app must support a broader but still controlled symptom model. This includes:
- symptom type selection from a curated list,
- symptom severity where appropriate,
- optional duration or repeat markers where useful,
- user-defined custom symptoms or custom tags,
- medication or intervention notes when entered as notes or structured tags if product design supports them cleanly.

Structured symptom capture must remain optional. The app must not pressure users into comprehensive journaling.

**Why this is included**
Many conditions or recurring experiences are not meaningfully represented by a simple pain score or mood label. However, forcing comprehensive health logging would damage retention.

**Acceptance criteria**
- User can add multiple symptoms to a day without excessive friction.
- Symptom entry is quicker than typing unstructured notes for common cases.
- Custom symptoms or tags can be created without breaking reporting consistency.
- Existing Phase 1 data remains compatible.

**Pitfalls**
- Too many categories making the app intimidating.
- Over-structuring what users may prefer to note informally.
- Introducing symptom semantics that sound diagnostic.

**What to avoid and why**
Avoid trying to encode the entire universe of menstrual and reproductive health in Phase 2. The goal is useful flexibility, not taxonomy maximalism.

## 5.2 Quick logging improvements

### Requirements
Introduce faster pathways for common repeated actions such as:
- quick add from the home surface,
- save recent symptom combinations where appropriate,
- lighter interaction cost for repeating common entries.

**Why this is included**
More data fields usually mean more friction. Quick logging is required to offset that.

**Acceptance criteria**
- A user who only wants to mark “period day + medium flow” can still do so rapidly.
- The expanded feature set does not make the simple path slower than in Phase 1.
- Common repeat actions are measurably easier.

**Pitfalls**
- Shortcut designs that are confusing because they try to be too clever.
- Presets that make logs less transparent or harder to edit later.

**What to avoid and why**
Avoid hiding stateful shortcuts behind vague UI labels. Fast paths must remain legible.

## 5.3 Prediction version 2: uncertainty-aware forecasting

### Requirements
Prediction output must move from a single nominal date toward a range-based representation where warranted, based on variability in the user’s history.

The product may display:
- likely next period range,
- indication of low, medium, or high confidence,
- reasons confidence is limited, such as sparse history or irregularity.

The app must still remain rules-based and explainable.

**Why this is included**
A single exact date often communicates more confidence than the data supports. Range-based display is often both more honest and more useful.

**Acceptance criteria**
- Users with variable cycles see appropriately widened prediction ranges.
- Users with sparse history are informed why precision is limited.
- The prediction explanation remains understandable without technical jargon.
- Prediction logic remains documented and testable.

**Pitfalls**
- Overcomplicated confidence systems that look scientific but are not understandable.
- Presenting confidence in a way users misread as medical reliability.
- Unclear transitions between exact and ranged outputs.

**What to avoid and why**
Avoid false statistical theater. The confidence model should help the user reason, not merely decorate the UI.

## 5.4 Local insights and pattern summaries

### Requirements
Provide a limited set of local-only pattern summaries derived entirely on-device. These may include:
- average cycle length over recent history,
- average period duration,
- cycle variability,
- recurring symptom timing relative to period start,
- recurring symptom frequency.

Insights must be descriptive, not diagnostic.

**Why this is included**
Users often want to understand their own patterns, especially when preparing for appointments or adjusting routines. Local descriptive insights provide real value without requiring cloud analysis.

**Acceptance criteria**
- Insight language describes observed patterns without implying clinical interpretation.
- Insights are derived only from data the user logged.
- Users can understand what underlying data drove each summary.
- Insights update when logs are edited.

**Pitfalls**
- Drifting into condition suggestions or health scoring.
- Summaries that are mathematically correct but not meaningful.
- Overwhelming the interface with analytics.

**What to avoid and why**
Avoid generic wellness insights that are only tangentially related to menstrual tracking. The feature must stay domain-relevant.

## 5.5 History and editing ergonomics

### Requirements
Improve access to past logs through:
- clearer day detail views,
- better editing flows,
- optional filtered history views by symptom or note,
- ability to correct long spans of data with low friction.

**Why this is included**
Richer data is only useful if the user can inspect and correct it without frustration.

**Acceptance criteria**
- Editing older data is straightforward.
- Filter or search behavior, if included, is understandable and performant.
- Long note histories remain navigable.

**Pitfalls**
- Building a full report builder rather than solving common history tasks.
- Making edits expensive because the UI tries to preserve too many abstractions.

**What to avoid and why**
Avoid interaction patterns that require users to remember where a past edit lives. History must feel reliable and recoverable.

## 5.6 Manual and user-controlled backup improvements

### Requirements
Phase 2 introduces easier backup options beyond one-off export while remaining user-controlled. Potential acceptable approaches include:
- scheduled reminders to export,
- backup to a user-chosen local file destination,
- integration with platform file providers where this can be done without reintroducing vendor lock-in,
- optional support for user-managed endpoints such as WebDAV or equivalent only if the interaction can be kept understandable and deterministic in this phase.

Any backup introduced in this phase must remain optional and must not create an account dependency.

**Why this is included**
Users who care about privacy also care about not losing years of data. Manual export alone is valuable but easy to neglect.

**Acceptance criteria**
- Backup remains understandable as user-controlled storage, not vendor-managed cloud storage.
- User can identify where backup data goes.
- Backup failure states are legible.
- Backup preserves the same completeness guarantees as export.

**Pitfalls**
- Quietly depending on platform cloud defaults without telling the user.
- Introducing merge or conflict behavior prematurely.
- Making backup settings too technical for the average user.

**What to avoid and why**
Avoid pretending backup and sync are the same. Backup is one-way preservation; sync is state coordination. Confusing them causes bad product expectations.

## 5.7 Improved education and expectation-setting

### Requirements
Provide clearer in-app explanations about:
- what predictions mean,
- what insights mean,
- what backup covers,
- what the app does not do medically.

This can be implemented through contextual help, concise tooltips, or settings documentation, but it must remain readable.

**Why this is included**
As the product becomes richer, the risk of misunderstanding increases. Trust requires explanation.

**Acceptance criteria**
- Users can find clear explanation without leaving the app.
- Explanations do not rely on legalistic language.
- Copy remains accurate to product behavior.

**Pitfalls**
- Hiding critical caveats deep in help text.
- Overexplaining to the point of intimidation.

**What to avoid and why**
Avoid medicalized copy unless it is necessary and supported. Plain language supports trust.

---

## 6. Non-functional requirements

## 6.1 Simplicity preservation

The app must remain approachable despite increased depth.

**Why this is included**
Phase 2 can easily become the point where a clean product turns into a dense logging system.

**Acceptance criteria**
- Users who only want Phase 1 behavior can still use the app comfortably.
- Expanded features are additive, not obstructive.
- The simple path remains fast.

**Pitfalls**
- Feature visibility overload.
- Every screen trying to surface every capability.

**What to avoid and why**
Avoid one-size-fits-all dashboards. Progressive disclosure is preferable.

## 6.2 Local computation only

Any insight or prediction enhancement in this phase must run on-device.

**Why this is included**
This phase is specifically about improving usefulness without sacrificing architectural trust.

**Acceptance criteria**
- No remote service is required for insights or prediction.
- Data processing occurs locally.
- Common tasks work without connectivity.

**Pitfalls**
- Pulling in libraries with optional online dependencies.
- Using remote text or model downloads “just for help copy.”

**What to avoid and why**
Avoid convenience architecture that chips away at the local-first contract. The contract is the product.

## 6.3 Data model stability

Phase 2 extends the data model but must preserve portability and migration safety.

**Why this is included**
Expanding symptom systems often introduces schema churn.

**Acceptance criteria**
- Phase 1 exports can be imported into a Phase 2 app.
- Migration path from Phase 1 local data is tested.
- New fields are versioned and documented.

**Pitfalls**
- Over-normalization that makes exports hard to understand.
- Breaking compatibility in the name of model purity.

**What to avoid and why**
Avoid schema changes that are technically elegant but user-hostile for long-term data longevity.

---

## 7. Exclusions and non-goals for Phase 2

Not included:
- cross-device state sync,
- hosted backup service controlled by the project,
- machine learning predictions,
- diagnosis or condition detection,
- clinician-facing advice system,
- messaging, forums, or social interaction,
- partner or provider portals.

**Why this is included**
These are natural next asks once the app becomes richer. They must still be deferred.

**Acceptance criteria**
- Product and engineering planning do not silently absorb these items.
- Documentation distinguishes backup from sync clearly.

**Pitfalls**
- Building backup with hidden assumptions that become a sync system accidentally.
- Letting “insights” become algorithmic health advice.

**What to avoid and why**
Avoid calling descriptive correlations “analysis” in a clinical sense. The product is summarizing user data, not diagnosing.

---

## 8. Risks and mitigation

### 8.1 Risk: richer symptom model lowers retention
More options can make users feel that they are “failing” if they do not log thoroughly.

**Mitigation**
- Keep structured logging optional.
- Preserve low-friction defaults.
- Use progressive disclosure.

### 8.2 Risk: confidence display confuses users
Users may not understand a confidence indicator intuitively.

**Mitigation**
- Use plain-language labels and short explanations.
- Prefer clear ranges over pseudo-statistical ornament.

### 8.3 Risk: backup options are mistaken for seamless sync
Users may assume that backups merge across devices.

**Mitigation**
- Explicitly label backup behavior.
- Avoid any language suggesting live multi-device consistency.

### 8.4 Risk: local insights are interpreted as health advice
Even descriptive patterns may feel authoritative if phrased poorly.

**Mitigation**
- Keep language observational.
- Avoid recommendations unless they are purely about app use, not health decisions.

---

## 9. Acceptance test summary for Phase 2

Phase 2 is considered complete only if the following are all true:

1. Users can log a richer set of symptoms without slowing the simplest logging path materially.
2. Custom symptoms or tags, if included, are usable and do not break portability.
3. Prediction output reflects uncertainty honestly and clearly.
4. Local-only insights produce meaningful descriptive summaries without diagnostic language.
5. History and editing flows are improved enough to manage richer data.
6. Backup options are more convenient than manual export while remaining user-controlled and understandable.
7. All new behavior still works offline.
8. Data migration from Phase 1 is safe and tested.
9. The app remains clearly non-medical in its claims.

---

## 10. Launch recommendation for end of Phase 2

At the end of Phase 2, the app may reasonably describe itself as:
“A local-first menstrual cycle tracker with flexible symptom tracking, explainable predictions, descriptive local insights, and user-controlled backup.”

It should still not claim:
- synchronized multi-device operation,
- medically validated prediction,
- diagnosis or condition detection,
- clinician-grade reporting beyond descriptive summaries unless such reporting is explicitly built and supported later.

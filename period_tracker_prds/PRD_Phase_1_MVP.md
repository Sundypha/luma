# PRD — Phase 1 MVP: Local-First Cycle Tracking Core

**Document status:** Draft for planning  
**Phase goal:** Deliver a genuinely usable, privacy-first menstrual cycle tracker that works fully offline and creates the product foundation for all later phases.  
**Product type:** FOSS mobile application  
**Audience:** Product, design, engineering, QA, maintainers, community contributors  
**Out of scope for this phase:** cloud sync, hosted accounts, machine learning, medical claims, fertility treatment workflows, community/social features

---

## 1. Purpose of this phase

Phase 1 exists to answer a very practical question: can this product become a trustworthy daily-use tracker before any advanced intelligence, sync, or ecosystem features are introduced?

The answer must be yes. If the app is not already useful in an offline-only state, every future phase compounds complexity without solving the primary user need. This phase therefore focuses on the smallest feature set that still qualifies as a real product rather than a demo.

This phase is intentionally narrow because local-first health software becomes fragile when too many subsystems are introduced early. Storage, editing semantics, prediction semantics, date handling, and export/import must be made stable first. These are foundational and costly to change later.

### Success definition

Phase 1 succeeds if a privacy-conscious user can:
- install the app,
- use it without creating an account,
- log periods and basic symptoms quickly,
- see a calendar with past and predicted periods,
- export and re-import their data without loss,
- trust that no internet access is required for core use.

### Failure definition

Phase 1 fails if any of the following happen:
- the app feels like a prototype rather than a daily-use tool,
- users lose data during edits or upgrades,
- prediction behavior appears random or unexplained,
- the app quietly depends on connectivity,
- the product scope is diluted by “nice to have” features that delay correctness.

---

## 2. Problem statement

Most popular trackers are usable but not trust-minimized. Most privacy-centric trackers are trust-minimized but often feel limited, rough, or incomplete compared with mainstream products. This creates a product gap: users who want strong privacy and local ownership still want a polished everyday experience.

Phase 1 addresses that gap by establishing a baseline product that is:
- private by design, not by policy text alone,
- functional without network access,
- clear enough to be trusted,
- stable enough to become the canonical home of user data.

---

## 3. Product principles for Phase 1

These are not abstract values. They are decision rules.

### 3.1 Local-first is mandatory

All core behavior must function with networking disabled. This is listed because “mostly offline” is not sufficient for health data. Users must not have to infer whether data is stored remotely, synced later, or blocked by sign-in requirements.

**Why this is included**
Local-first is the central promise of the product. If this is softened early, every later decision will drift toward convenience-first architecture and compromise the product identity.

**Acceptance criteria**
- The full Phase 1 feature set works in airplane mode after initial install.
- No login, account, or remote token is required to use the app.
- No background errors occur solely because network access is unavailable.
- If the platform asks for network permission for unrelated reasons, those requests are absent in the Phase 1 app.

**Pitfalls**
- Pulling in SDKs that make background requests.
- Implicit dependency on remote time, feature configuration, or crash pipelines.
- Future-proofing the codebase by pre-wiring remote assumptions that complicate offline flow.

**What to avoid and why**
Avoid any library or subsystem that phones home by default, because users cannot verify that behavior easily and maintainers inherit trust debt immediately.
Avoid pseudo-local designs that stage data locally but assume future cloud semantics, because this produces migration pain when true local-first invariants later collide with server expectations.

### 3.2 No account requirement

The product must be usable from first launch without user identity creation.

**Why this is included**
Accountless use lowers friction, preserves anonymity, and is necessary for vulnerable users who do not want reproductive health data tied to identity.

**Acceptance criteria**
- User can complete onboarding and start tracking without entering email, phone, username, or passkey.
- No feature in Phase 1 blocks usage because an account is absent.
- Export/import remains available without account state.

**Pitfalls**
- Product decisions that quietly prioritize future hosted-user models.
- Design copy that implies account creation is the “normal” path.

**What to avoid and why**
Avoid “skip for now” account prompts. Even optional account prompting changes the perceived trust model and distracts from the core proposition.

### 3.3 Deterministic and explainable predictions

Predictions must come from simple documented statistical rules, not opaque heuristics.

**Why this is included**
Prediction is one of the most visible product behaviors. If it feels magical but wrong, user trust collapses quickly. A modest but understandable prediction is preferable to a more complex prediction that users cannot audit.

**Acceptance criteria**
- Prediction output is reproducible from the same data set.
- The app can describe the basis of the current prediction in plain language.
- When data is insufficient or irregular, uncertainty is surfaced rather than hidden.

**Pitfalls**
- Showing an exact future date when confidence should be low.
- Using language that sounds diagnostic or medically authoritative.
- Adding heuristic tweaks that are hard to explain but not meaningfully better.

**What to avoid and why**
Avoid overclaiming precision. A health tracker that pretends certainty where none exists creates both ethical and product risk.

### 3.4 Data ownership and portability

The user must be able to take their data out in a complete, documented format and bring it back in.

**Why this is included**
For a FOSS local-first product, portability is part of trust. Without it, the app is merely a private silo.

**Acceptance criteria**
- Full export includes all user-generated data required to reconstruct app state.
- Import of a prior export restores equivalent state.
- Export format is documented in the repository.
- Import failures produce clear validation feedback.

**Pitfalls**
- Exporting only the visible subset of data and omitting internal metadata needed to round-trip.
- Silent data coercion during import.
- Breaking format compatibility casually between app versions.

**What to avoid and why**
Avoid proprietary or unstable exports. Even in a FOSS project, undocumented schema drift undermines confidence and blocks community tooling.

### 3.5 Conservative scope

Phase 1 must resist feature creep.

**Why this is included**
Health products often become complicated because every adjacent request sounds reasonable. This phase must remain small enough to be built correctly.

**Acceptance criteria**
- No sync features.
- No AI/ML features.
- No social or community features.
- No wearable integrations.
- No custom chart laboratory or insight engine beyond the core needs.

**Pitfalls**
- Adding “just one more field” until logging becomes cumbersome.
- Building infrastructure early for hypothetical future needs.
- Confusing extensibility with immediate necessity.

**What to avoid and why**
Avoid designing Phase 1 around future press-release features. Phase 1 must prove daily utility, not roadmap ambition.

---

## 4. Target users for this phase

Phase 1 is not trying to serve every possible reproductive health scenario. It serves a narrow but meaningful user base well.

### Primary user
A privacy-conscious person who wants a straightforward cycle tracker for daily use, values local storage, and does not want to entrust reproductive health data to a commercial cloud service.

### Secondary user
A technically inclined user who values exportability, open formats, and FOSS transparency.

### Explicitly not optimized for in Phase 1
- Users expecting fertility-awareness workflows with high medical rigor.
- Users expecting partner sharing, clinician portals, or social support features.
- Users needing comprehensive pregnancy, postpartum, or perimenopause programs.
- Users expecting cross-device sync at launch.

**Why this segmentation is included**
A good PRD names who the phase is not for. This prevents misframing the MVP as an all-purpose reproductive health platform.

**Acceptance criteria**
- Marketing and product copy do not imply unsupported use cases.
- Onboarding and help text set appropriate expectations.
- Engineering scope remains aligned to the primary user need.

**Pitfalls**
- Over-generalizing the product as “for everyone.”
- Accidentally implying contraception reliability or medical guidance.

**What to avoid and why**
Avoid broad messaging that suggests the app can safely replace medical advice. That creates ethical, reputational, and legal risk.

---

## 5. User problems Phase 1 must solve

### 5.1 “I want to log my period quickly”
The app must make the primary action feel faster than opening notes or a calendar and typing manually.

**Why**
If logging is slow, users churn before any advanced feature matters.

**Acceptance criteria**
- Starting a period can be logged in at most two primary interactions from the home surface.
- Stopping or editing a period is similarly direct.

**Pitfalls**
- Excessive onboarding before first log.
- Modal chains requiring multiple confirmations.

### 5.2 “I want to see when my next period is likely”
The app must provide value from entered history, even if the model is simple.

**Why**
Prediction is the most immediate reward loop for continued use.

**Acceptance criteria**
- Once enough data exists, a next expected period is shown.
- If not enough data exists, the app says so clearly.

**Pitfalls**
- Pretending confidence too early.
- Displaying a fertility window in a way that implies clinical reliability.

### 5.3 “I want confidence that my data is mine”
The product must let users verify that their data can be moved and backed up manually.

**Why**
Trust is not built by privacy claims alone. It is built by inspectable affordances.

**Acceptance criteria**
- User can export locally to a file.
- User can import that file later.
- App documentation explains the export.

**Pitfalls**
- Export files that are incomplete or too obscure to inspect.
- Import behavior that duplicates or corrupts entries.

---

## 6. Functional requirements

## 6.1 Onboarding

Phase 1 onboarding must be minimal. Its job is to establish expectations and get the user to first value quickly.

### Requirements
- Show a brief explanation that the app stores data locally on device.
- Explain that no account is required.
- Explain that predictions are estimates based on entered history.
- Offer the option to set a basic lock later, not force it during the first-use path.
- Reach first logging action quickly.

**Why this is included**
Onboarding sets the trust frame. It must communicate privacy and product limits without becoming a tutorial maze.

**Acceptance criteria**
- A new user can reach the first log action in under one minute.
- Onboarding text does not contain unsupported claims.
- User can skip non-essential education and continue.
- Onboarding is still understandable without internet access.

**Pitfalls**
- Overloading onboarding with health education.
- Introducing too many customization steps.
- Scaring users with heavy legalistic copy.

**What to avoid and why**
Avoid collecting demographic or sensitive profile fields during onboarding. They are not needed for Phase 1 utility and create unnecessary psychological weight.

## 6.2 Core period logging

### Requirements
The user must be able to:
- mark period start date,
- mark period end date,
- edit both later,
- log flow intensity for individual days or period span,
- add or edit notes,
- add pain score,
- add mood selection.

The logging model must support retroactive entry because many users begin tracking from memory rather than in real time.

**Why this is included**
This is the core data capture system. Without it, there is no product.

**Acceptance criteria**
- Start date can be logged for today or a past day.
- End date can be added later without forcing immediate completion.
- Editing a previously entered period does not corrupt adjacent cycle calculations.
- The app prevents impossible date ranges or flags them clearly.
- Basic symptom entries save reliably and display in the correct day context.

**Pitfalls**
- Designing the data model around “completed periods only,” which breaks partial entry flows.
- Treating flow, pain, or mood as required, causing friction.
- Overcomplicating editing semantics.

**What to avoid and why**
Avoid forcing users to think in medical or technical vocabulary when simple language is sufficient. Phase 1 should be understandable without specialist knowledge.

## 6.3 Calendar and timeline visibility

### Requirements
- Month-based calendar view.
- Distinct visual treatment for logged period days.
- Distinct visual treatment for predicted future period days.
- Tap a day to view or edit entries.
- User can navigate past and future months smoothly.

**Why this is included**
The calendar is the product’s primary interpretation layer. It translates logs into an understandable history.

**Acceptance criteria**
- Logged days and predicted days are visually distinguishable.
- Editing from the calendar is direct.
- Calendar navigation remains performant across multiple years of data.
- Prediction display updates after edits.

**Pitfalls**
- Visual ambiguity between actual and predicted data.
- Performance degradation with long history.
- Hiding detail behind too many nested views.

**What to avoid and why**
Avoid decorative visual complexity that obscures meaning. The calendar must privilege clarity over aesthetics.

## 6.4 Home summary surface

### Requirements
The app must include a primary surface that answers the most common questions at a glance:
- where am I in the cycle,
- when is the next expected period,
- what did I log today,
- quick action to log or edit.

**Why this is included**
A calendar alone is not enough for everyday use. Users need a current-state summary that makes the app feel active and useful.

**Acceptance criteria**
- Home view loads quickly.
- Home view presents prediction status and today’s log state clearly.
- Quick logging action is visible without digging through menus.

**Pitfalls**
- Turning the home screen into a dashboard overloaded with future analytics.
- Presenting exact certainty when only an estimate exists.

**What to avoid and why**
Avoid adding generalized wellness scores or synthetic “cycle health” numbers. These are not justified in Phase 1 and risk misleading users.

## 6.5 Prediction engine version 1

### Requirements
Prediction must use a documented rules-based approach built from the user’s entered period history. It may use:
- average cycle length,
- average period duration,
- basic outlier exclusion or warning behavior,
- uncertainty signaling when history is sparse or variable.

Prediction must never claim medical reliability and must never be framed as contraception.

**Why this is included**
Users expect some forecast value from a tracker, but Phase 1 must earn trust through modesty and transparency.

**Acceptance criteria**
- Prediction is available only when sufficient historical data exists according to documented rules.
- Prediction changes in a way that matches the documented rules after editing data.
- App explains why prediction is unavailable or low confidence.
- Prediction UI labels predicted data as estimate.

**Pitfalls**
- Hardcoding assumptions like a universal 28-day cycle.
- Showing fertility-related language that users could misread as medically actionable.
- Retrofitting complexity to imitate commercial apps without evidence.

**What to avoid and why**
Avoid “smart” language unless it can be explained concretely. Users should understand what the app is doing.

## 6.6 Data export

### Requirements
- Full local export to a documented file format.
- Export initiated by the user without account dependency.
- Export includes periods, symptoms, notes, and required metadata for round-trip restoration.

**Why this is included**
Export is a cornerstone trust feature and a non-negotiable requirement for a FOSS local-first product.

**Acceptance criteria**
- Export creates a file accessible to the user.
- Exported file validates against documented schema.
- A new install can restore from that export with equivalent state.

**Pitfalls**
- Leaving out internal identifiers or version markers needed for future compatibility.
- Tying export to platform-specific file assumptions only.

**What to avoid and why**
Avoid hidden backup formats that only the app understands internally. The user must not be trapped.

## 6.7 Data import

### Requirements
- Import from a prior export file.
- Input validation with readable error messages.
- Clear duplicate-handling behavior defined in product copy and implementation.

**Why this is included**
Export without import is not portability.

**Acceptance criteria**
- Valid prior export imports successfully.
- Invalid or corrupted files fail gracefully with explanation.
- Import does not silently merge in ways the user cannot understand.

**Pitfalls**
- Duplicate records after repeated import.
- Schema changes breaking old exports unexpectedly.

**What to avoid and why**
Avoid magical import reconciliation in Phase 1. Deterministic and predictable behavior matters more than cleverness.

## 6.8 Basic app protection

### Requirements
Provide optional local access protection such as PIN or biometric lock if supported by platform, but do not make it mandatory on first use.

**Why this is included**
Many users want protection from casual access by others sharing the device. This is distinct from storage privacy.

**Acceptance criteria**
- User can enable protection from settings.
- Lock behavior is reliable after app background/foreground transitions.
- Failure modes are recoverable without data loss.

**Pitfalls**
- Creating a lock flow that can permanently strand users.
- Confusing app lock with cryptographic storage guarantees.

**What to avoid and why**
Avoid describing app lock as a complete security solution. It is a convenience and privacy barrier, not absolute protection.

---

## 7. Non-functional requirements

## 7.1 Performance

The app must feel immediate because it supports quick habitual use.

**Requirements**
- Common screens render promptly.
- Logging actions feel instant.
- Calendar navigation remains smooth with years of local history.

**Why this is included**
Users compare utility apps against native platform performance expectations, not against enterprise software tolerance.

**Acceptance criteria**
- No perceptible lag on mainstream supported devices for common actions.
- Writes persist without blocking the UI in a way that feels broken.

**Pitfalls**
- Heavy state management for simple views.
- Expensive calendar recomputation on every interaction.

**What to avoid and why**
Avoid premature charting or analytics components in Phase 1. They consume performance budget without serving the core loop.

## 7.2 Reliability

**Requirements**
- No silent data loss.
- No crash-prone core paths.
- App upgrades preserve local data.

**Why this is included**
Health tracking is cumulative. Losing one month may be irritating; losing two years destroys trust entirely.

**Acceptance criteria**
- Autosave or explicit save behavior is consistent and testable.
- Upgrade migrations are covered by tests.
- App recovers cleanly from interrupted writes where feasible.

**Pitfalls**
- Weak migration discipline.
- Storing essential state only in transient UI memory.

**What to avoid and why**
Avoid schema experimentation without migration planning. In local-first software, migrations are product behavior, not just engineering detail.

## 7.3 Privacy by default

**Requirements**
- No analytics collection.
- No ad identifiers.
- No third-party advertising or profiling SDKs.
- No hidden telemetry of reproductive events.

**Why this is included**
This is the principal market differentiator and a foundational ethical choice.

**Acceptance criteria**
- Dependency review confirms absence of prohibited tracking components.
- Privacy documentation matches actual product behavior.
- Network inspection of Phase 1 common use shows no unneeded outbound traffic.

**Pitfalls**
- Pulling in convenience packages with opaque telemetry defaults.
- Relying on policy claims without technical verification.

**What to avoid and why**
Avoid saying “we respect your privacy” unless the architecture materially enforces it. Technical guarantees are stronger than slogans.

## 7.4 Accessibility and clarity

**Requirements**
- Core flows must be understandable without dense text.
- Colors and icons must not be the sole means of distinguishing state.
- The tone should be neutral and inclusive.

**Why this is included**
A privacy-first tool still fails if it is difficult to use or overly coded toward a narrow aesthetic.

**Acceptance criteria**
- Primary actions are identifiable without tutorial dependence.
- Predicted versus actual periods are distinguishable through more than color alone.
- Copy avoids unnecessary gendered assumptions where not required.

**Pitfalls**
- Pink-coded, stereotype-heavy design language.
- Reliance on subtle color differences only.
- Jargon that implies medical authority.

**What to avoid and why**
Avoid aesthetic choices that signal the product is only for one kind of user. Inclusiveness begins with neutral defaults.

---

## 8. Exclusions and non-goals for Phase 1

The PRD explicitly excludes the following:
- cloud backup,
- multi-device sync,
- machine learning,
- diagnosis or treatment guidance,
- community forums or chat,
- wearable/device integrations,
- advanced correlations and analytics dashboards,
- fertility treatment mode,
- clinician portal,
- partner sharing.

**Why this is included**
Exclusions keep Phase 1 buildable and reduce ambiguity during planning and review.

**Acceptance criteria**
- No work is added under these headings unless Phase 1 is formally re-scoped.
- Roadmap ideas do not leak into the MVP implementation plan.

**Pitfalls**
- Adding backend assumptions “for later.”
- Designing the data model around unsupported features prematurely.

**What to avoid and why**
Avoid building scaffolding that complicates current code in the name of future optionality. Good foundations are stable, not speculative.

---

## 9. Risk management

### 9.1 Risk: misleading predictions
If predictions look too authoritative, users may over-trust them.

**Mitigation**
- Use explicit estimate language.
- Surface uncertainty.
- Avoid contraception-like framing.

### 9.2 Risk: local data loss due to migrations or file handling
A local-first app bears full responsibility for safe upgrades.

**Mitigation**
- Migration test suite.
- Export/import validation.
- Conservative schema evolution.

### 9.3 Risk: MVP becomes feature-bloated
The domain invites endless additions.

**Mitigation**
- Freeze Phase 1 scope around daily utility.
- Route later ideas into subsequent phases formally.

### 9.4 Risk: privacy claims exceed actual guarantees
Users will judge the product harshly if messaging outruns architecture.

**Mitigation**
- Document what Phase 1 does and does not protect against.
- Keep claims specific and technical.

---

## 10. Acceptance test summary for Phase 1

Phase 1 is considered complete only if the following are all true:

1. A new user can install the app and begin tracking without creating any account.
2. The app remains usable in airplane mode for all Phase 1 features.
3. Period start and end logging are easy, editable, and reliable.
4. Basic symptoms and notes can be logged on relevant days.
5. Calendar distinguishes historical data from predicted data.
6. Prediction behavior follows a documented deterministic ruleset.
7. When data is insufficient, the app says so clearly rather than fabricating precision.
8. Full export works locally.
9. Import of a valid export restores equivalent data state.
10. No prohibited tracking or analytics behavior is present.

---

## 11. Launch recommendation for end of Phase 1

Phase 1 should launch only when it can honestly be described as:
“A local-first, accountless, private cycle tracker with simple explainable predictions and full export/import.”

It should not launch with language implying:
- medical-grade fertility guidance,
- sync availability,
- advanced AI,
- comprehensive reproductive health coverage beyond the documented scope.

This recommendation is included because honest framing at launch will protect the product more than aggressive ambition.

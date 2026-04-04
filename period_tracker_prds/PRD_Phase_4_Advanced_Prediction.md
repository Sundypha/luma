# PRD — Phase 4: Advanced Prediction Research, Statistical Improvement, and Carefully Bounded Personalization

**Document status:** Draft for planning  
**Phase goal:** Improve forecasting quality and usefulness beyond the earlier rules-based models while preserving transparency, safety, and the project’s non-medical positioning.  
**Dependencies:** Stable Phases 1 through 3, including mature data model, sufficient historical datasets on device, and strong product messaging discipline  
**Out of scope for this phase:** diagnosis, treatment recommendations, contraceptive claims, opaque server-trained black-box prediction as a default product behavior

---

## 1. Purpose of this phase

Phase 4 exists because forecasting is one of the most valued aspects of menstrual tracking, but also one of the most ethically sensitive. Earlier phases intentionally use conservative, explainable rules. Over time, users may reasonably expect better adaptation to irregularity, trend shifts, and individualized patterns. However, the project is not a medical company and should not pretend to be one.

This phase therefore introduces a structured research-and-product approach to advanced prediction. The emphasis is not “use ML because it is interesting.” The emphasis is: improve usefulness only where improvement can be justified, tested, explained, and bounded.

### Success definition

Phase 4 succeeds if prediction quality improves measurably for appropriate users without:
- eroding explainability,
- increasing medical ambiguity,
- requiring remote collection of personal reproductive data,
- turning the product into an opaque AI system.

### Failure definition

Phase 4 fails if:
- “advanced prediction” becomes a marketing slogan rather than a documented improvement,
- models become hard to explain,
- users are exposed to higher-confidence outputs than the data supports,
- the app begins to imply medical interpretation or contraceptive reliability,
- ML complexity is introduced where better statistics would suffice.

---

## 2. Why this phase is separate

Prediction improvement is separated from earlier phases intentionally because it has a different risk profile.

Unlike logging or backup, advanced prediction can mislead users without any visible software error. A clean interface can conceal unsound assumptions. This phase therefore requires a much more disciplined approach to:
- evaluation,
- uncertainty communication,
- model boundaries,
- and product messaging.

This phase is not required for the app to be valuable. That is why it comes later.

---

## 3. Product principles for advanced prediction

## 3.1 Improved prediction must remain subordinate to truthfulness

**Why this is included**
A slightly more accurate but much less understandable predictor can damage trust more than it helps.

**Acceptance criteria**
- Any advanced prediction output is accompanied by understandable explanation or rationale.
- The system can still communicate uncertainty honestly.
- Product language avoids presenting prediction as certainty.

**Pitfalls**
- Model sophistication outrunning product explainability.
- Teams optimizing aggregate metrics while ignoring user comprehension.

**What to avoid and why**
Avoid chasing performance metrics alone. In this domain, user understanding is part of product correctness.

## 3.2 Better statistics come before machine learning

**Why this is included**
Many prediction gains can be achieved through improved statistical handling of variability, trends, and recency without introducing ML complexity or opacity.

**Acceptance criteria**
- Phase 4 planning explicitly compares advanced non-ML approaches with ML approaches.
- ML is not adopted unless it clearly improves meaningful outcomes beyond transparent statistical methods.

**Pitfalls**
- Treating ML as a roadmap milestone because it sounds advanced.
- Skipping strong baselines and therefore overstating ML gains.

**What to avoid and why**
Avoid “AI for its own sake.” If a weighted statistical model solves the problem, it is the better product choice.

## 3.3 Personal health data should not be centralized for model training by default

**Why this is included**
Centralized collection for model improvement would compromise the project’s privacy posture and create new governance burdens.

**Acceptance criteria**
- Advanced prediction works without uploading user reproductive data to a central training service.
- If any future research mode is proposed, it is explicitly opt-in, separately governed, and not required for product operation.

**Pitfalls**
- Quietly redefining local-first in order to get more data for model work.
- Treating anonymous aggregation as obviously harmless when reproductive data remains highly sensitive.

**What to avoid and why**
Avoid building a data-hungry ML roadmap that conflicts with the project’s core product promise.

## 3.4 The product remains non-medical

**Why this is included**
More sophisticated prediction can increase the temptation to imply diagnostic or contraceptive relevance.

**Acceptance criteria**
- Product copy remains explicit that the app is not a medical device unless that status changes through a separate program far beyond this PRD.
- Advanced prediction output is framed as planning assistance, not medical guidance.
- Fertility-related displays remain carefully worded if present at all.

**Pitfalls**
- Users equating improved personalization with medical validation.
- Feature naming that implies professional-grade authority.

**What to avoid and why**
Avoid phrases that users may reasonably interpret as treatment advice or contraception assurance.

---

## 4. User problems addressed in this phase

### 4.1 “My cycle is variable and simple averages do not fit me well”
### 4.2 “I want the app to adapt when my pattern changes”
### 4.3 “I want better forecasts, but I do not want opaque or invasive AI”
### 4.4 “I need the app to acknowledge when it does not know”

**Why these are included**
They represent legitimate product needs once the app has enough personal history to support more nuanced modeling.

---

## 5. Phase structure within advanced prediction

This phase should itself be subdivided conceptually into two layers.

### Layer A: advanced statistical forecasting
This includes better non-ML approaches such as:
- recency weighting,
- variability-aware forecasting,
- change-point sensitivity,
- confidence intervals or ranges informed by historical dispersion,
- robust handling of sparse or irregular histories.

### Layer B: carefully bounded personalization research
Only after Layer A is mature should the project evaluate whether any ML-like or learned personalization method adds sufficient value to justify its cost and complexity.

**Why this is included**
It creates a governance checkpoint. The project should not jump from simple averages directly to opaque personalization.

**Acceptance criteria**
- Layer A can be shipped and evaluated independently.
- Layer B is blocked unless Layer A baselines and evaluation criteria are documented.

**Pitfalls**
- Bundling all advanced prediction into a single “smart mode.”
- Losing the ability to compare methods meaningfully.

**What to avoid and why**
Avoid roadmap compression that makes it impossible to tell which improvement actually helped.

---

## 6. Functional requirements for Layer A: advanced statistical forecasting

## 6.1 Recency-aware cycle estimation

### Requirements
The predictor may weight recent cycles more than distant cycles when estimating the next likely period, provided the behavior is documented and explainable.

**Why this is included**
Averages across very old data may lag behind genuine shifts in the user’s pattern.

**Acceptance criteria**
- The app can explain that recent cycles influence predictions more when applicable.
- Prediction changes caused by recent data are understandable.
- The method is testable and documented.

**Pitfalls**
- Overreacting to one anomalous cycle.
- Making recency weighting so aggressive that predictions become unstable.

**What to avoid and why**
Avoid hidden tuning constants without rationale. Even simple weighting choices shape user trust.

## 6.2 Variability-aware prediction windows

### Requirements
Prediction output should model variability more faithfully using history dispersion or similar understandable measures.

**Why this is included**
Users with irregular cycles are poorly served by exact dates.

**Acceptance criteria**
- Wide variability leads to wider prediction windows.
- Stable history can lead to narrower windows if justified.
- The UI does not imply that a narrower window means medical certainty.

**Pitfalls**
- Ranges that are so wide they stop being useful.
- Ranges that are narrow because the model underestimates uncertainty.

**What to avoid and why**
Avoid confidence displays that obscure rather than clarify the practical planning value.

## 6.3 Insufficient-data and pattern-shift handling

### Requirements
The predictor must detect conditions where normal forecasting quality is degraded, such as:
- too little history,
- long gaps in tracking,
- major recent deviations,
- postpartum-like or perimenopausal variability if the product has enough reason to suspect high instability based on data alone, without diagnosing.

The app must then reduce confidence or fall back to more conservative output.

**Why this is included**
A model that does not know when it is unreliable is more dangerous than a modest one.

**Acceptance criteria**
- The system identifies predefined low-confidence conditions.
- The UI communicates that estimation quality is reduced.
- Fallback behavior is documented.

**Pitfalls**
- Treating all irregularity as model failure rather than a normal user pattern.
- Surfacing internal technical reasons instead of user-relevant explanations.

**What to avoid and why**
Avoid pseudo-diagnostic labels. The product can say the pattern is variable without saying why medically.

## 6.4 Prediction explanation surface

### Requirements
The user must be able to understand, at a product level, why the prediction looks the way it does. This may include statements like:
- based on your recent logged cycles,
- confidence reduced because your recent cycle lengths vary more,
- prediction unavailable because there is too little recent data.

**Why this is included**
Advanced prediction without explanation invites suspicion and misuse.

**Acceptance criteria**
- Users can access explanation without reading developer docs.
- Explanation language is concise and non-technical.
- Explanation remains accurate to the actual model behavior.

**Pitfalls**
- Generic explanations that are always shown and therefore not informative.
- Explanations that oversimplify to the point of being false.

**What to avoid and why**
Avoid decorative explainability. It must map to real behavior, not generic reassurance.

---

## 7. Functional requirements for Layer B: bounded personalization research

Layer B should only proceed when Layer A is stable and insufficient for meaningful product improvement.

## 7.1 Personalization must be on-device by default

### Requirements
If a learned or adaptive model is introduced, it must run locally and derive its adaptation from the user’s own device-resident data unless an explicitly separate research program is approved later.

**Why this is included**
This preserves the privacy posture and keeps the system aligned with local-first architecture.

**Acceptance criteria**
- Personalization works without uploading personal history for centralized prediction service use.
- Model artifacts, if any, are stored locally or derived locally.
- Disabling advanced personalization does not impair ordinary use.

**Pitfalls**
- Introducing model download/update dependencies that reintroduce centralization pressure.
- Hidden cloud inference paths for convenience.

**What to avoid and why**
Avoid server-side scoring of reproductive health history as the default. That would represent a fundamental product shift.

## 7.2 User control over advanced prediction mode

### Requirements
If a more advanced mode is introduced, the user should be able to understand that it is an advanced forecasting mode and disable it if desired.

**Why this is included**
Users differ in their appetite for adaptive systems, and some may prefer simple transparent rules.

**Acceptance criteria**
- The setting or mode distinction is comprehensible.
- Disabling the mode reverts predictably to the simpler baseline.
- User data is not harmed by switching modes.

**Pitfalls**
- Presenting advanced mode as obviously better in all cases.
- Making mode toggles too technical.

**What to avoid and why**
Avoid “beta intelligence” gimmickry. This is a health-adjacent utility, not an AI demo.

## 7.3 Evaluation before release

### Requirements
No advanced learned approach should ship without predefined evaluation criteria, including:
- whether it materially improves prediction usefulness,
- whether it behaves sensibly for irregular histories,
- whether users understand and trust it,
- whether it causes overconfidence.

This evaluation must include qualitative review, not only quantitative metrics.

**Why this is included**
A model can optimize numerical error while worsening user experience or safety interpretation.

**Acceptance criteria**
- Baseline comparator is documented.
- Evaluation dataset and method are documented at least internally.
- Release decision includes product review of user comprehension and risk.

**Pitfalls**
- Cherry-picking favorable metrics.
- Ignoring failure cases because average performance improved.

**What to avoid and why**
Avoid shipping because the team is excited about the model. Excitement is not a release criterion.

---

## 8. UX and communication requirements

## 8.1 Uncertainty must become more visible, not less

**Why this is included**
More advanced models can create false confidence because users assume sophistication means certainty.

**Acceptance criteria**
- Prediction output still signals uncertainty where appropriate.
- Irregular or sparse cases remain clearly labeled as such.
- The app never presents advanced output as fact.

**Pitfalls**
- Cleaner UI leading users to infer stronger confidence than warranted.
- Hiding caveats in secondary screens only.

**What to avoid and why**
Avoid confidence theater. Precision must be earned by evidence.

## 8.2 Product language must remain non-medical

**Why this is included**
Advanced prediction sits close to domains where regulatory and ethical boundaries matter.

**Acceptance criteria**
- Copy avoids diagnosis, treatment, or contraception language unless separately supported by rigorous program changes.
- “Prediction” is framed as estimate or forecast.
- The app does not imply that missed periods or irregularity have been clinically interpreted.

**Pitfalls**
- Innocent-sounding copy that nevertheless implies medical knowledge.
- Users inferring too much from pattern summaries.

**What to avoid and why**
Avoid naming features in a way that borrows authority from medicine without the corresponding evidence and governance.

---

## 9. Non-functional requirements

## 9.1 Reproducibility and auditability

Any advanced predictor must remain auditable enough for maintainers and community reviewers to reason about it.

**Why this is included**
FOSS trust depends partly on inspectability. A model that technically exists in the repository but is practically inscrutable weakens that benefit.

**Acceptance criteria**
- Model behavior and configuration are documented.
- The build and release process for any model-related component is controlled.
- Regression tests cover representative prediction scenarios.

**Pitfalls**
- Model artifacts that cannot be reproduced easily.
- Tuning performed without documentation.

**What to avoid and why**
Avoid releasing model behavior that cannot be explained even by maintainers after a few months. That is operationally fragile.

## 9.2 Resource proportionality

Advanced prediction must not make the app feel heavy or battery-intensive.

**Why this is included**
A personal utility app should remain lightweight.

**Acceptance criteria**
- Prediction processing remains reasonable for supported devices.
- Any on-device training or adaptation, if ever introduced, does not noticeably degrade normal use.

**Pitfalls**
- Background processing spikes.
- Large model artifacts for marginal gains.

**What to avoid and why**
Avoid importing general-purpose ML infrastructure when a small targeted method would suffice.

---

## 10. Exclusions and non-goals for Phase 4

Not included:
- diagnosis of PCOS, PMDD, endometriosis, pregnancy, or other conditions,
- contraception or fertility treatment guidance,
- centralized population training on user reproductive histories by default,
- opaque black-box remote prediction service,
- pseudo-clinical health scores.

**Why this is included**
Advanced forecasting can slide into medicalized territory very quickly. These exclusions protect product boundaries.

**Acceptance criteria**
- Documentation and UI stay within these boundaries.
- Research curiosity does not silently expand product claims.

**Pitfalls**
- Users or contributors pushing “just one condition detector.”
- marketing language turning personalization into implied diagnosis.

**What to avoid and why**
Avoid health-condition labeling unless the project is prepared for the evidence, governance, and regulatory burden that would follow.

---

## 11. Risks and mitigation

### 11.1 Risk: advanced prediction reduces trust rather than improving it
Users may prefer a simple model they understand over a better model they cannot reason about.

**Mitigation**
- Preserve explanation surfaces.
- Consider keeping baseline mode available.
- Evaluate user comprehension explicitly.

### 11.2 Risk: ML is adopted prematurely
Team enthusiasm may outrun evidence.

**Mitigation**
- Require strong Layer A baselines.
- Make ML adoption a gated decision.
- Document why simpler methods are insufficient first.

### 11.3 Risk: stronger predictions are overinterpreted medically
Users may infer clinical meaning from improved forecasts.

**Mitigation**
- Conservative copy.
- uncertainty emphasis.
- no diagnostic or contraceptive framing.

### 11.4 Risk: advanced personalization creates maintenance burden
Complex prediction systems can be hard to debug and explain over time.

**Mitigation**
- Keep methods lightweight and documented.
- Prefer simpler models where gains are close.
- Invest in regression testing.

---

## 12. Acceptance test summary for Phase 4

Phase 4 is complete only if the following are all true:

1. Prediction quality is improved using documented methods beyond the earlier baseline.
2. Explanations remain available and accurate.
3. Uncertainty communication is at least as strong as in earlier phases.
4. Product copy remains clearly non-medical.
5. No centralized personal-data collection is required for ordinary advanced prediction use.
6. Better statistical methods are evaluated before any ML approach is adopted.
7. Any personalization mode is bounded, optional if appropriate, and reversible.
8. The app remains a trustworthy planner, not an implied diagnostic tool.

---

## 13. Launch recommendation for end of Phase 4

At the end of Phase 4, the app may reasonably describe itself as:
“A local-first menstrual cycle tracker with more adaptive, still explainable forecasting.”

It should still not claim:
- medical-grade prediction,
- diagnosis,
- contraceptive reliability,
- provider-grade clinical intelligence,
- AI superiority without careful documented evidence.

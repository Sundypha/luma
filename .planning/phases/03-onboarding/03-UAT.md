---
status: complete
phase: 03-onboarding
source:
  - 03-01-SUMMARY.md
  - 03-02-SUMMARY.md
started: 2026-04-05T12:00:00Z
updated: 2026-04-05T23:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Privacy screen (required first step)
expected: First screen shows local-only / on-device storage messaging; Continue only (no Skip); swipe does not advance.
result: pass

### 2. Estimates screen (required second step)
expected: After Continue, second screen explains predictions are estimates, not medical advice or a substitute for a professional; Continue only (no Skip); dot indicator reflects step 2 of 3.
result: pass

### 3. Quick-start screen (optional third step)
expected: Third screen mentions logging period start / predictions improving with history; both Skip and Continue (or Get Started) are visible; you can advance with either.
result: pass
notes: "Pass — behavior matched spec. User finds Skip redundant on the last page (only path is forward); logged under Gaps."

### 4. First period log and home
expected: After the wizard, you see first-log UI with a short hint about when the period started; selected date defaults to today; Change date opens a picker; Save & Continue persists and you reach the home screen with a success-style message (e.g. snackbar).
result: issue
reported: "fail, only start date can be entered, no end date in case one enters a previous period"
severity: major
notes: "Code: FirstLogScreen inserts PeriodSpan with startUtc only (open period). No end-date UI for a completed past period."

### 5. About replay from home
expected: On home, the AppBar info (About) icon opens About; you can read again the privacy/local-first and estimates-not-medical-advice content (cards or similar), without redoing the wizard.
result: pass

### 6. Relaunch after onboarding complete
expected: Force-close the app and open again. You land on home (not the wizard), assuming you finished the wizard and saved a period.
result: pass

### 7. Resume mid-onboarding
expected: Clear data, start onboarding, advance to screen 2, then force-stop the app. Relaunch — you resume on screen 2 (not screen 1).
result: pass

### 8. Offline / airplane mode
expected: With airplane mode (or network off), you can complete the full flow from launch through first log to home without errors that block you.
result: pass

## Summary

total: 8
passed: 7
issues: 1
pending: 0
skipped: 0
feedback_logged: 2

## Gaps

<!-- Design / UX feedback — optional follow-up (not counted as test failures) -->
- truth: "Optional third onboarding screen shows Skip plus Continue/Get Started (per ONBD-04 / plan)"
  status: failed
  reason: "User feedback (test 3 passed): Skip on the final wizard page feels unnecessary — user must continue to first log anyway."
  severity: minor
  test: 3
  root_cause: "Plan ONBD-04 calls for optional step with Skip; UI mirrors that pattern even though last step only advances to first log (redundant Skip)."
  artifacts:
    - path: "apps/ptrack/lib/features/onboarding/onboarding_screen.dart"
      issue: "Optional step shows TextButton Skip + FilledButton per plan"
  missing:
    - "Product decision: drop Skip on final step or replace with single primary CTA"
  debug_session: ""

- truth: "Required onboarding pages block horizontal swipe; user must tap Continue"
  status: failed
  reason: "User feedback: allow swipe on all onboarding pages — equivalent to Continue for them."
  severity: minor
  test: 1
  root_cause: "OnboardingScreen sets NeverScrollableScrollPhysics on PageView when current page isRequired (Phase 3 plan) so disclosures are not swiped past without an explicit Continue."
  artifacts:
    - path: "apps/ptrack/lib/features/onboarding/onboarding_screen.dart"
      issue: "physics: isRequired ? NeverScrollableScrollPhysics() : null"
  missing:
    - "Product decision: allow swipe to advance same as Continue on required pages"
  debug_session: ""

- truth: "First-log screen lets user record start (and optionally end) for a past period when the period is already over"
  status: failed
  reason: "User reported: only start date can be entered, no end date when logging a previous period"
  severity: major
  test: 4
  root_cause: "FirstLogScreen builds PeriodSpan with startUtc only; no end date picker or closed-period path."
  artifacts:
    - path: "apps/ptrack/lib/features/onboarding/first_log_screen.dart"
      issue: "Single-date flow; open span only via insertPeriod"
  missing:
    - "Optional end date (on or after start) for completed past periods, with repository/validation alignment"
  debug_session: ""

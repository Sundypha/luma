---
status: complete
uat_outcome: failed
phase: 07-app-protection-lock
source:
  - 07-01-SUMMARY.md
  - 07-02-SUMMARY.md
  - 07-03-SUMMARY.md
started: 2026-04-06T20:00:00Z
updated: 2026-04-06T22:00:00Z
---

## Current Test

[testing complete — UAT failed; see Gaps for `/gsd-plan-phase 7 --gaps`]

## Tests

### 1. First launch — no lock; Privacy & Security subtitle
expected: No lock screen on first launch to home; Privacy & Security tile subtitle when lock is off matches the string above.
result: issue
reported: "fail, no lock is asked at all, even after clearing cache"
severity: major

### 2. Enable lock — acknowledgment through optional biometrics
expected: From Privacy & Security, turning app lock on shows an acknowledgment about data loss / export first. After "I understand, continue", you enter a 4-digit PIN, then confirm it; mismatched confirmation shows an inline error. If the device supports biometrics, an offer to enable biometrics appears (you may skip or enable). After completion, lock settings show lock ON with Change PIN and Lock now visible.
result: skipped
reason: UAT closed as failed; not executed.

### 3. Cancel during setup on acknowledgment
expected: Open enable-lock flow again; on the acknowledgment step tap Cancel (or equivalent). App lock stays off — returning to Privacy & Security still shows the "when returning from background" subtitle, not "App lock is on".
result: skipped
reason: UAT closed as failed; not executed.

### 4. Background and resume lock
expected: With app lock enabled, press Home (or switch away) so the app goes to background. Open Luma again. A full-screen lock UI appears with PIN entry. Entering the correct PIN returns you to the home screen.
result: skipped
reason: UAT closed as failed; not executed.

### 5. Lock now
expected: With lock enabled, open Privacy & Security and use "Lock now". The lock screen appears immediately without leaving the app. Correct PIN unlocks back to the app.
result: skipped
reason: UAT closed as failed; not executed.

### 6. Wrong PIN on lock screen
expected: On the lock screen, enter a wrong PIN. You see an error (e.g. "Incorrect PIN"); entry clears or resets. Entering the correct PIN then unlocks normally.
result: skipped
reason: UAT closed as failed; not executed.

### 7. Biometric cancel falls back to PIN (biometric-capable device only)
expected: If you enabled biometrics, the lock screen shows a way to use biometrics. Trigger it, then cancel or dismiss the system biometric dialog. You remain on the lock screen and can still enter the PIN (no blank or stuck state).
result: skipped
reason: UAT closed as failed; not executed.

### 8. Disable lock requires re-auth
expected: With lock on, open Privacy & Security and turn the App lock switch off. A re-auth step appears (PIN and/or biometrics). After successful re-auth, lock is off. Backgrounding the app and returning no longer shows the lock screen.
result: skipped
reason: UAT closed as failed; not executed.

### 9. Forgot PIN — copy and destructive reset
expected: From the lock screen, open "Forgot PIN?". Copy explains there is no PIN recovery without erasing data, tells you to export from Data settings first, and does not suggest email/support/cloud recovery. Confirming the destructive action sends you to onboarding; after going through onboarding, prior period data is gone (empty / fresh state).
result: skipped
reason: UAT closed as failed; not executed.

### 10. Subtitle when lock is off (again)
expected: After any prior tests, with app lock disabled, open Settings again. Privacy & Security subtitle is again "Lock with PIN or biometrics when returning from background."
result: skipped
reason: UAT closed as failed; not executed.

## Summary

total: 10
passed: 0
issues: 1
pending: 0
skipped: 9
uat_result: FAILED — lock behavior still incorrect; gap closure required

## Gaps

<!-- Consumed by: /gsd-plan-phase 7 --gaps -->

- truth: "With app lock enabled on Android or iOS, the user is prompted to unlock after leaving the app and returning (LOCK-02); Lock now shows the lock screen without leaving the app."
  status: failed
  reason: "User UAT: lock still does not work as expected after mobile-only lifecycle scope. Prior report: no lock asked even after clearing cache; issue persists on retest."
  severity: blocker
  test: 4
  requirement: LOCK-02
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Optional app lock is reachable from settings and behaves correctly on first launch and when lock is off (LOCK-01 baseline)."
  status: failed
  reason: "UAT failed before full sign-off; Test 1 reported failure. Treat as unverified / blocked until resume lock and settings flows are fixed and re-tested."
  severity: major
  test: 1
  requirement: LOCK-01
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

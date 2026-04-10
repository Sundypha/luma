---
phase: 07-app-protection-lock
verified: 2026-04-06T18:30:00Z
status: human_needed
score: 2/3
re_verification: false
human_verification:
  - test: "Item 1 — First launch: no lock; Settings → Privacy & Security subtitle when lock off"
    expected: "No lock screen; subtitle reads 'Lock with PIN or biometrics when returning from background.'"
    why_human: "Launch and drawer UX not covered by automated tests."
  - test: "Item 2 — Enable lock: ack → PIN → confirm → biometric offer (if available)"
    expected: "Ack copy shown; continue; 4-digit PIN; mismatch error; optional biometrics; lock ON in settings with Change PIN / Lock now."
    why_human: "Full modal flow and platform biometrics require device or simulator."
  - test: "Item 3 — Cancel during setup on ack"
    expected: "Lock remains disabled after Cancel on acknowledgment."
    why_human: "Integration behavior on device."
  - test: "Item 4 — Background / resume lock"
    expected: "With lock enabled, Home then reopen shows lock screen; correct PIN unlocks to home."
    why_human: "AppLifecycleListener pause/resume is not exercised in widget tests; LOCK-02 depends on this."
  - test: "Item 5 — Lock now"
    expected: "From Privacy & Security, Lock now immediately shows lock screen; PIN unlocks."
    why_human: "ValueNotifier wiring to LockGate is implementation-complete but not runtime-verified."
  - test: "Item 6 — Wrong PIN"
    expected: "'Incorrect PIN' shown; entry resets; correct PIN unlocks."
    why_human: "Covered partially by LockViewModel tests; full screen UX on device."
  - test: "Item 7 — Biometric cancel fallback (biometric-capable device)"
    expected: "Biometric prompt; cancel returns to same screen with PIN still usable."
    why_human: "local_auth and OS UI require device/simulator."
  - test: "Item 8 — Disable lock re-auth"
    expected: "Toggle off prompts re-auth; after success lock disabled; background no longer locks."
    why_human: "Dialog + prefs + lifecycle together on device."
  - test: "Item 9 — Forgot PIN destructive reset"
    expected: "Sheet copy (export-first, no hidden recovery); confirm routes to onboarding; data cleared after re-onboarding."
    why_human: "End-to-end data wipe and navigation require manual run (07-03 Task 2)."
  - test: "Item 10 — Subtitle when lock off"
    expected: "Privacy & Security tile shows off subtitle as in Item 1."
    why_human: "Visual confirmation in running app."
---

# Phase 7: App protection (lock) Verification Report

**Phase goal (ROADMAP):** Users who want extra privacy can opt into PIN or biometric lock without being forced, with reliable resume behavior and honest limitations.

**Verified:** 2026-04-06T18:30:00Z  
**Status:** human_needed  
**Re-verification:** No (initial report; no prior `07-VERIFICATION.md`)

**Note:** `07-03-SUMMARY.md` marks the phase **partial** because **Task 2 (human UAT)** in `07-03-PLAN.md` was not executed by automation. Automated checks below validate code and tests; they do **not** replace the 10-item device checklist.

## Goal achievement

### Observable truths (ROADMAP success criteria + plan must_haves)

| # | Truth | Status | Evidence |
|---|--------|--------|----------|
| SC1 | From settings, user can enable optional PIN/biometric lock (not on first launch) | ✓ VERIFIED (code) | `TabShell` → `LockSettingsTile` → `LockSettingsScreen`; `main.dart` only wraps **home** with `LockGate` (onboarding/first log paths have no gate). `LockService.isEnabled` defaults false. |
| SC2 | With lock enabled, returning from background prompts unlock on supported devices | ? HUMAN | `LockGate` uses `AppLifecycleListener`: `onPause` sets `_isLocked` when enabled; `onResume` rebuilds. Logic matches plan; **no test drives paused/resumed lifecycle**. Matches **LOCK-02** pending in `REQUIREMENTS.md` until UAT. |
| SC3 | Copy does not claim full cryptographic protection; credible recovery narrative | ✓ VERIFIED (code review) | `forgot_pin_sheet.dart`: no recovery fantasy, export-before-reset, destructive reset. **LOCK-03** marked complete in `REQUIREMENTS.md`. ℹ️ Pin setup ack says app lock "encrypts access with a PIN" — product may want softer wording vs hashing/storage; not a wiring gap. |

**Score:** **2/3** success criteria fully satisfied without device; third (resume reliability) needs **Task 2** sign-off.

### Required artifacts (exists + substantive + wired)

| Artifact | Expected | Status | Details |
|----------|-----------|--------|---------|
| `apps/ptrack/pubspec.yaml` | local_auth ^3.0.1, flutter_secure_storage ^10.0.0 | ✓ | Lines 45–46. |
| `apps/ptrack/lib/features/lock/lock_service.dart` | Argon2id, secure storage, biometrics, prefs flags | ✓ | Argon2id parallelism 1, memory 8192, iterations 3; `_auth.authenticate(..., biometricOnly: true)`. |
| `apps/ptrack/test/features/lock/lock_service_test.dart` | Unit tests | ✓ | 195 lines; mocks storage/auth/prefs. |
| `apps/ptrack/lib/features/lock/lock_gate.dart` | Cold start + lifecycle gate | ✓ | `_isLocked = lockService.isEnabled` in `initState`; `AppLifecycleListener`; `LockScreen` / child. |
| `apps/ptrack/test/features/lock/lock_gate_test.dart` | enabled vs disabled | ✓ | Renders child vs `LockScreen`. |
| `apps/ptrack/lib/main.dart` | LockService before `runApp`, `LockGate` + `TabShell` | ✓ | `SharedPreferences.getInstance()` then `LockService(prefs)`; home branch wraps `TabShell` with `LockGate`, `_resetApp` clears prefs, lock, DB file. |
| `apps/ptrack/lib/features/shell/tab_shell.dart` | Privacy & Security / lock tile | ✓ | `LockSettingsTile` with `onReset` / `onLockNow`. |
| `apps/ptrack/lib/features/lock/lock_settings_tile.dart` | Subtitle + navigation | ✓ | Exact subtitle strings per `07-03` plan. |
| Lock UI files (`pin_entry_widget`, `lock_screen`, `lock_view_model`, `pin_setup_sheet`, `forgot_pin_sheet`, `lock_settings_screen`) | Flows in `07-02` | ✓ | Re-auth for disable/change PIN; `showPinSetupSheet` / `showForgotPinSheet` wired; `LockViewModel` tests pass. |
| Android / iOS platform | Biometric prerequisites | ✓ | `FlutterFragmentActivity`; `USE_BIOMETRIC`; `allowBackup=false`; `NSFaceIDUsageDescription`; entitlements with empty `keychain-access-groups`. |

### Key link verification

| From | To | Via | Status |
|------|-----|-----|--------|
| `main.dart` | `LockService` | Constructed with prefs before `runApp` | ✓ WIRED |
| `main.dart` | `LockGate` / `TabShell` | Home branch; `lockNowSignal`, `onReset` | ✓ WIRED |
| `lock_gate.dart` | `AppLifecycleListener` | `onPause` / `onResume` | ✓ WIRED |
| `lock_gate.dart` | `LockScreen` | When `_isLocked` | ✓ WIRED |
| `LockSettingsTile` | `LockSettingsScreen` | `Navigator.push` | ✓ WIRED |
| `lock_view_model.dart` | `lock_service.dart` | `verifyPin`, `authenticateWithBiometrics` | ✓ WIRED |
| `pin_setup_sheet.dart` | `LockService` | `createPin`, `enableLock` after success only | ✓ WIRED |

### Requirements coverage

| ID | Description (REQUIREMENTS.md) | Status | Evidence |
|----|----------------------------------|--------|----------|
| LOCK-01 | Optional PIN/biometric from settings, not forced first use | Pending (tracker) / ✓ code | Settings tile + no gate on onboarding; enable via `LockSettingsScreen`. **Mark complete in REQUIREMENTS.md after UAT Item 1–3, 8.** |
| LOCK-02 | Reliable lock across background/foreground | Pending (tracker) | Implementation present; **needs Task 2 Items 4, 8**. |
| LOCK-03 | Honest limitations; recovery narrative | Complete (tracker) | Forgot + ack copy; destructive reset to onboarding in `_resetApp`. |

### Automated checks run

- `fvm flutter test test/features/lock/` — **all passed** (18 tests: `lock_gate_test`, `lock_view_model_test`, `lock_service_test`).

### Anti-patterns

| File | Pattern | Severity | Notes |
|------|---------|----------|-------|
| — | TODO/FIXME in `lib/features/lock/` | — | None found. |
| `pin_setup_sheet.dart` | "encrypts access with a PIN" | ℹ️ Info | Review against LOCK-03 tone if legal/product wants stricter wording than PIN hashing + gate. |

### Gaps summary

There are **no code gaps** found that block wiring: services, UI, gate, main, settings tile, and lock tests align with plans `07-01`–`07-03` Task 1. **Phase goal achievement** for **resume reliability** and **end-user flows** remains **unproven** until **07-03 Task 2** (10 manual items) is executed and `REQUIREMENTS.md` LOCK-01/LOCK-02 can be checked off.

---

_Verified: 2026-04-06T18:30:00Z_  
_Verifier: Claude (gsd-verifier)_

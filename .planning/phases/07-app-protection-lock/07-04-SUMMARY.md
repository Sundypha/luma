---
phase: 07-app-protection-lock
plan: 04
subsystem: security
tags: [flutter, navigator, app_lifecycle, lock, widget_test]

requires:
  - phase: 07-app-protection-lock
    provides: LockGate, main wiring (07-03)
provides:
  - Root navigatorKey on LumaApp MaterialApp; LockGate.onBeforeLock pops to first route before lock
  - AppLifecycleListener.onHide (mobile) in addition to onPause
  - Widget regression tests for pushed route + lock now / disabled signal
affects:
  - Human UAT Task 3 (07-04-PLAN); LOCK-01/LOCK-02 sign-off in REQUIREMENTS.md

tech-stack:
  added: []
  patterns: "onBeforeLock callback coordinates Navigator.popUntil with LockGate lifecycle and lock-now signal"

key-files:
  created: []
  modified:
    - apps/ptrack/lib/features/lock/lock_gate.dart
    - apps/ptrack/lib/main.dart
    - apps/ptrack/test/features/lock/lock_gate_test.dart

key-decisions:
  - "onHide mirrors onPause for background lock on Android/iOS only; _lockIfEnabled is idempotent."
  - "Lock now signal no-ops when lock is disabled (avoids spurious pop via onBeforeLock)."

patterns-established:
  - "Optional LockGate.onBeforeLock runs only when transitioning to locked state with lock enabled."

requirements-completed: []

duration: —
completed: —
status: partial
---

# Phase 7 Plan 04: UAT gap closure (navigator) Summary

**Automated tasks complete: root navigator pop-before-lock, lifecycle onHide, regression tests — Task 3 device UAT still required for LOCK-01/LOCK-02.**

## Performance

- **Duration:** —
- **Tasks:** 2 of 3 complete (Task 3 `checkpoint:human-verify` pending)
- **Task 1 commit:** `273e1bc` (fix)
- **Task 2 commit:** `a423f43` (test)

## Accomplishments

- `LockGate` accepts optional `onBeforeLock`; `_lockIfEnabled` and `_onLockNowSignal` call it when `lockService.isEnabled` before `setState` to locked.
- `AppLifecycleListener` uses `onHide` as well as `onPause` when `_backgroundLockSupported`.
- `LumaApp` uses `_rootNavigatorKey` on `MaterialApp` and passes `onBeforeLock: popUntil(isFirst)`.
- Tests cover lock-now with pushed route (overlay popped, `LockScreen` visible) and signal when lock disabled (overlay kept).

## Task Commits

1. **Task 1: Pop root routes before locking** — `273e1bc`
2. **Task 2: Widget regression tests** — `a423f43`

**Task 3:** Re-run full Phase 7 UAT checklist and update `07-UAT.md` / `REQUIREMENTS.md` — **pending**.

## Files Created/Modified

- `apps/ptrack/lib/features/lock/lock_gate.dart` — `onBeforeLock`, `onHide`, enabled-guard on lock-now
- `apps/ptrack/lib/main.dart` — `navigatorKey`, `onBeforeLock` wiring
- `apps/ptrack/test/features/lock/lock_gate_test.dart` — two regression tests

## Automated verification

- `fvm flutter analyze` (apps/ptrack) — no issues
- `fvm flutter test test/features/lock/` — pass

## Human verification (Task 3) — pending

Run `fvm flutter run` on device/emulator; complete items in `07-03-PLAN.md` Task 2 / `07-VERIFICATION.md`; update `07-UAT.md` and, if passed, LOCK-01/LOCK-02 in `REQUIREMENTS.md`.

## Self-Check: PASSED (automation scope)

- Tasks 1–2 implemented and committed; SUMMARY recorded.

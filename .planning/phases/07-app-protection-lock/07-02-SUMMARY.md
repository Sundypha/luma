---
phase: 07-app-protection-lock
plan: 02
subsystem: security
tags: [flutter, material, local_auth, pin, biometrics, mocktail, change_notifier]

requires:
  - phase: 07-app-protection-lock
    provides: LockService (07-01) with PIN hashing, biometrics, prefs flags
provides:
  - PinEntryWidget reusable keypad and dot display
  - LockViewModel + LockScreen unlock flow
  - showPinSetupSheet (ack → PIN → confirm → optional biometrics; skipAck/changePinOnly)
  - showForgotPinSheet destructive reset copy (LOCK-03)
  - LockSettingsScreen with re-auth for disable/change PIN and onLockNow hook
affects:
  - 07-03-PLAN (LockGate, main.dart, settings navigation)

tech-stack:
  added: []
  patterns: ListenableBuilder for lock VM; modal bottom sheets for setup/forgot; re-auth AlertDialog with PinEntryWidget + optional biometric

key-files:
  created:
    - apps/ptrack/lib/features/lock/pin_entry_widget.dart
    - apps/ptrack/lib/features/lock/lock_view_model.dart
    - apps/ptrack/lib/features/lock/lock_screen.dart
    - apps/ptrack/lib/features/lock/pin_setup_sheet.dart
    - apps/ptrack/lib/features/lock/forgot_pin_sheet.dart
    - apps/ptrack/lib/features/lock/lock_settings_screen.dart
    - apps/ptrack/test/features/lock/lock_view_model_test.dart
  modified: []

key-decisions:
  - "LockViewModel tests use real LockService with mocked FlutterSecureStorage and LocalAuthentication because LockService is a final class and cannot be implemented by mocktail mocks."
  - "showPinSetupSheet exposes changePinOnly so change-PIN re-auth flow calls createPin without enableLock; skipAck jumps to PIN creation."

patterns-established:
  - "LockSettingsScreen requires onLockNow for 07-03 LockGate to force lock without going through lifecycle."

requirements-completed: [LOCK-03]

duration: 45min
completed: 2026-04-06
---

# Phase 7 Plan 02: App protection lock UI Summary

**PIN keypad, lock screen + ViewModel, setup/forgot sheets with LOCK-03 copy, and settings screen with re-auth-gated disable and change-PIN flows.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-04-06T00:00:00Z (approximate)
- **Completed:** 2026-04-06T00:00:00Z (approximate)
- **Tasks:** 2
- **Files modified:** 7 new Dart files (6 lib + 1 test)

## Accomplishments

- Reusable `PinEntryWidget` with 4-digit dots, 3×4 keypad, backspace, and optional manual submit when `submitOnComplete` is false.
- `LockViewModel` coordinates `verifyPin` / `authenticateWithBiometrics` with loading and error state; `LockScreen` auto-prompts biometrics once when enabled and supports forgot-PIN callback.
- `showPinSetupSheet` implements acknowledgment, PIN confirmation, `createPin` + `enableLock` only on success path, and optional biometric enable step.
- `showForgotPinSheet` uses export-first and destructive-reset copy with no implied server recovery.
- `LockSettingsScreen` enables lock via setup sheet, disables/changes PIN only after re-auth (PIN or biometrics), toggles biometrics when hardware allows, and exposes `onLockNow` for the gate in 07-03.

## Task Commits

Each task was committed atomically:

1. **Task 1: PinEntryWidget, LockViewModel, LockScreen, tests** — `4ab53aa` (feat)
2. **Task 2: PinSetupSheet, ForgotPinSheet, LockSettingsScreen** — `630ace9` (feat)

Planning updates (SUMMARY, STATE, ROADMAP, REQUIREMENTS) are in the follow-up `docs(lock): Complete 07-02 lock UI plan` commit on this branch.

## Files Created/Modified

- `apps/ptrack/lib/features/lock/pin_entry_widget.dart` — Dot display and numeric keypad; `onSubmit` / `onChanged` / `errorText`.
- `apps/ptrack/lib/features/lock/lock_view_model.dart` — `ChangeNotifier` unlock state and service calls.
- `apps/ptrack/lib/features/lock/lock_screen.dart` — Full-screen scaffold, `ListenableBuilder`, conditional biometrics and forgot link.
- `apps/ptrack/lib/features/lock/pin_setup_sheet.dart` — `showPinSetupSheet` multi-step bottom sheet.
- `apps/ptrack/lib/features/lock/forgot_pin_sheet.dart` — `showForgotPinSheet` reset confirmation.
- `apps/ptrack/lib/features/lock/lock_settings_screen.dart` — App lock settings and `_LockReAuthDialog`.
- `apps/ptrack/test/features/lock/lock_view_model_test.dart` — ViewModel tests against real `LockService` with mocks.

## Decisions Made

- Used injected `LockService` dependencies in tests instead of `Mock implements LockService` because `LockService` is declared `final` in its library.
- Added `skipAck` and `changePinOnly` to `showPinSetupSheet` to support change-PIN without re-acknowledgment and without calling `enableLock` again.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Cannot mock final LockService in unit tests**
- **Found during:** Task 1 (`lock_view_model_test.dart`)
- **Issue:** `class MockLockService extends Mock implements LockService` fails compilation (`final class` outside library).
- **Fix:** Tests construct `LockService` with `MockFlutterSecureStorage` and `MockLocalAuthentication` plus `SharedPreferences` mock values, mirroring `lock_service_test.dart`.
- **Files modified:** `apps/ptrack/test/features/lock/lock_view_model_test.dart`
- **Verification:** `fvm flutter test test/features/lock/lock_view_model_test.dart`
- **Committed in:** `4ab53aa`

---

**Total deviations:** 1 auto-fixed (blocking test compile)
**Impact on plan:** Test strategy only; behavior matches plan.

## Issues Encountered

- `gsd-tools state advance-plan` still cannot parse this repo’s free-form `STATE.md` layout; phase position lines were updated manually alongside this summary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- UI and settings logic are ready for `07-03`: wire `LockGate`, `main.dart`, drawer/settings entry, `onReset` / `onLockNow`, and human verification.

**LOCK-01** (enable lock from settings) remains pending until navigation ships in `07-03`; **LOCK-03** was marked complete in `REQUIREMENTS.md` for honest recovery copy in setup/forgot flows.

---
*Phase: 07-app-protection-lock*

*Completed: 2026-04-06*

## Self-Check: PASSED

- `apps/ptrack/lib/features/lock/pin_entry_widget.dart` through `lock_settings_screen.dart` exist.
- Commits `4ab53aa` and `630ace9` present on branch (`git log`).
- `07-02-SUMMARY.md` written under `.planning/phases/07-app-protection-lock/`.

---
phase: 07-app-protection-lock
plan: 03
subsystem: security
tags: [flutter, app_lifecycle, lock, mocktail, shared_preferences]

requires:
  - phase: 07-app-protection-lock
    provides: LockService, LockScreen, LockSettingsScreen, ForgotPinSheet (07-01, 07-02)
provides:
  - LockGate with cold-start and background-pause lock behavior
  - LockService initialization in main before runApp
  - Settings drawer Privacy & Security → LockSettingsScreen with onReset / onLockNow wiring
  - Destructive reset path (prefs clear, onboarding cache reload, DB file delete, route onboarding)
  - lock_gate_test.dart widget coverage
affects:
  - Human UAT (Task 2) for LOCK-01, LOCK-02 end-to-end sign-off

tech-stack:
  added: []
  patterns: ValueNotifier<int> as lock-now signal listened by LockGate; conditional dart:io import for default DB file deletion (ptrack.sqlite)

key-files:
  created:
    - apps/ptrack/lib/features/lock/lock_gate.dart
    - apps/ptrack/lib/features/lock/lock_settings_tile.dart
    - apps/ptrack/lib/features/lock/delete_ptrack_db_file.dart
    - apps/ptrack/lib/features/lock/delete_ptrack_db_file_io.dart
    - apps/ptrack/lib/features/lock/delete_ptrack_db_file_stub.dart
    - apps/ptrack/test/features/lock/lock_gate_test.dart
  modified:
    - apps/ptrack/lib/main.dart
    - apps/ptrack/lib/features/shell/tab_shell.dart
    - apps/ptrack/lib/features/onboarding/onboarding_state.dart
    - apps/ptrack/test/widget_test.dart
    - apps/ptrack/test/logging_test.dart

key-decisions:
  - "Used ValueNotifier<int> (increment) for Lock now instead of GlobalKey on private LockGate state."
  - "Default SQLite file deletion follows openPtrackDatabase IO paths (ptrack.sqlite under documents or application support), not the plan snippet’s ptrack.db; stub implementation on non-IO platforms."
  - "OnboardingState.reloadFromPlatform after SharedPreferences.clear so wizard cache matches wiped storage."

patterns-established:
  - "LockSettingsTile receives onReset and onLockNow from TabShell for app-layer callbacks without global state."

requirements-completed: []

duration: —
completed: —
status: partial
---

# Phase 7 Plan 03: LockGate and app wiring Summary

**Lifecycle LockGate, startup LockService, settings Privacy & Security tile, and automated tests — Task 2 human UAT still outstanding.**

## Performance

- **Duration:** —
- **Tasks:** 1 of 2 complete (Task 2 `checkpoint:human-verify` not executed in automation)
- **Task 1 commit:** `993a892` (feat)

## Accomplishments

- `LockGate` locks on cold start when `lockService.isEnabled`, sets locked on `AppLifecycleListener` pause when enabled, and shows `LockScreen` with forgot-PIN sheet calling `onReset`.
- `main()` builds `LockService` with the same `SharedPreferences` instance used at startup; home stack wraps `TabShell` in `LockGate` with `_lockNowSignal`.
- Settings dialog lists mood settings, divider, and `LockSettingsTile` (subtitle on/off copy per plan); navigation passes `onReset` and `onLockNow` into `LockSettingsScreen`.
- `_resetApp` clears lock data, disables lock, clears legacy prefs, reloads onboarding cache, closes DB, deletes default `ptrack.sqlite` where applicable, and sets `AppScreen.onboarding`.
- Widget tests: `lock_gate_test.dart` (enabled vs disabled); `TabShell` tests updated for new constructor and `local_auth` async getter mocks.

## Task Commits

1. **Task 1: LockGate, main wiring, TabShell, tests** — `993a892` (feat)
2. **Follow-up: Navigator when opening lock settings from dialog** — `a8126a0` (fix)

**Task 2:** Human verification (plan checklist items 1–10) — **pending** (not run; no results fabricated).

## Files Created/Modified

- `apps/ptrack/lib/features/lock/lock_gate.dart` — lifecycle gate and optional `lockNowSignal` listener
- `apps/ptrack/lib/features/lock/lock_settings_tile.dart` — drawer tile → `LockSettingsScreen`
- `apps/ptrack/lib/features/lock/delete_ptrack_db_file*.dart` — web-safe best-effort DB file removal
- `apps/ptrack/lib/main.dart` — `LockService`, `LockGate`, `_resetApp`, `_lockNowSignal`
- `apps/ptrack/lib/features/shell/tab_shell.dart` — `lockService`, callbacks, settings column
- `apps/ptrack/lib/features/onboarding/onboarding_state.dart` — `reloadFromPlatform()`
- `apps/ptrack/test/features/lock/lock_gate_test.dart` — LockScreen vs child
- `apps/ptrack/test/widget_test.dart`, `apps/ptrack/test/logging_test.dart` — `TabShell` constructor + lock mocks

## Deviations from Plan

### Plan vs implementation

**1. [Rule 1 - Correctness] SQLite filename and paths**
- **Found during:** Task 1 (`_resetApp` / DB delete)
- **Issue:** Plan referenced `ptrack.db` under documents; the app opens `ptrack.sqlite` with desktop vs mobile directory split (see `ptrack_database_open_io.dart`).
- **Fix:** Delete helper mirrors that resolution logic; conditional `dart:io` import keeps web analysis clean.

**2. [Rule 2 - Correctness] Onboarding cache after `prefs.clear()`**
- **Found during:** Task 1
- **Issue:** `OnboardingState` uses `SharedPreferencesWithCache`; clearing via `SharedPreferences.getInstance().clear()` can leave in-memory wizard state stale.
- **Fix:** `reloadFromPlatform()` on `OnboardingState` after clear.

**3. [Rule 1 - Bug] Settings dialog navigation**
- **Found during:** Post-commit review
- **Issue:** `LockSettingsTile` called `Navigator.of(context)` again after `pop()`, which can be unsafe if the tile’s context unmounts with the dialog.
- **Fix:** Capture `NavigatorState` once, then `pop` and `push` (`a8126a0`).

## Human verification (Task 2) — pending

Run `cd apps/ptrack && fvm flutter run` on a device or simulator, then complete the ten items in `07-03-PLAN.md` Task 2 (lock off on first launch, enable/cancel flows, background resume, Lock now, wrong PIN, biometrics, disable re-auth, forgot-PIN reset, subtitle when off). **LOCK-01**, **LOCK-02**, and full **LOCK-03** product sign-off remain tied to this checklist.

## Automated verification

- `fvm flutter test test/features/lock/lock_gate_test.dart` — pass
- `fvm flutter test` (full app package) — pass
- `fvm flutter analyze` — no issues

## Self-Check: PASSED

- `apps/ptrack/lib/features/lock/lock_gate.dart` and `lock_settings_tile.dart` exist.
- Commit `993a892` present for Task 1.
- `07-03-SUMMARY.md` recorded under `.planning/phases/07-app-protection-lock/`.

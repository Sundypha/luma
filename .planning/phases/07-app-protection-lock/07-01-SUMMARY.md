---
phase: 07-app-protection-lock
plan: 01
subsystem: security
tags: [flutter, local_auth, flutter_secure_storage, argon2id, cryptography, mocktail]

requires:
  - phase: 06-export-import
    provides: Workspace crypto patterns (Argon2id via cryptography); export/import complete enough for lock phase to proceed
provides:
  - LockService (PIN Argon2id hash in secure storage, biometric prompt, SharedPreferences lock flags)
  - Android/iOS platform config for biometrics and secure storage
  - Unit tests for LockService with mocked storage and LocalAuthentication
affects:
  - 07-02-PLAN (lock UI consumes LockService)
  - 07-03-PLAN (LockGate wires lifecycle + service)

tech-stack:
  added: local_auth ^3.0.1, flutter_secure_storage ^10.0.0, direct cryptography ^2.9.0 + cryptography_flutter ^2.3.4 on app
  patterns: Injectable deps for testability; PIN never stored plaintext; biometricOnly OS auth with app-level PIN fallback later

key-files:
  created:
    - apps/ptrack/lib/features/lock/lock_service.dart
    - apps/ptrack/test/features/lock/lock_service_test.dart
    - apps/ptrack/ios/Runner/Runner.entitlements
    - apps/ptrack/ios/Runner/RunnerDebug.entitlements
  modified:
    - apps/ptrack/pubspec.yaml
    - apps/ptrack/android/app/src/main/kotlin/app/luma/MainActivity.kt
    - apps/ptrack/android/app/src/main/AndroidManifest.xml
    - apps/ptrack/ios/Runner/Info.plist
    - apps/ptrack/ios/Runner.xcodeproj/project.pbxproj

key-decisions:
  - "Declared cryptography + cryptography_flutter on the app package so LockService imports satisfy depend_on_referenced_packages and match ptrack_data versions."
  - "Profile iOS configuration uses Runner.entitlements (same as Release) for CODE_SIGN_ENTITLEMENTS."

patterns-established:
  - "LockService: Argon2id(parallelism 1, memory 8192 KiB, iterations 3, hashLength 32) for PIN KDF; flags in SharedPreferences; hash+salt in flutter_secure_storage."

requirements-completed: []

duration: 22min
completed: 2026-04-06
---

# Phase 7 Plan 01: App protection foundation Summary

**Biometric-ready platform setup plus `LockService` with Argon2id-hashed PIN storage, `local_auth` integration, and mocked unit tests.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-04-06T00:00:00Z (approximate)
- **Completed:** 2026-04-06T00:22:00Z (approximate)
- **Tasks:** 2
- **Files modified:** 11 (Task 1) + 3 (Task 2) at commit granularity; see commits

## Accomplishments

- Added `local_auth` and `flutter_secure_storage` with Android `FlutterFragmentActivity`, `USE_BIOMETRIC`, `allowBackup=false`, and iOS Face ID string plus keychain entitlements wired in Xcode build settings.
- Implemented `LockService` for PIN create/verify, enable/disable lock, biometrics flag, `deletePinData`, and `hasPin`, with `biometricOnly: true` for OS biometric prompts.
- Eleven unit tests covering prefs defaults, storage writes/deletes, Argon2 verify path, and `LocalAuthentication` success/failure.

## Task Commits

Each task was committed atomically:

1. **Task 1: Dependencies and platform setup** — `ce72342` (build)
2. **Task 2: LockService with Argon2id PIN hashing and unit tests** — `4082ebb` (feat)

## Files Created/Modified

- `apps/ptrack/pubspec.yaml` — lock-related dependencies and crypto packages for `LockService`
- `apps/ptrack/lib/features/lock/lock_service.dart` — PIN KDF, secure storage, biometrics, prefs
- `apps/ptrack/test/features/lock/lock_service_test.dart` — mocktail tests
- `apps/ptrack/android/.../MainActivity.kt` — `FlutterFragmentActivity` for `BiometricPrompt`
- `apps/ptrack/android/.../AndroidManifest.xml` — biometric permission, `allowBackup=false`
- `apps/ptrack/ios/Runner/Info.plist` — `NSFaceIDUsageDescription`
- `apps/ptrack/ios/Runner/Runner*.entitlements` — empty `keychain-access-groups` for secure storage
- `apps/ptrack/ios/Runner.xcodeproj/project.pbxproj` — `CODE_SIGN_ENTITLEMENTS` for Runner (Debug → Debug entitlements, Release/Profile → release entitlements)

## Decisions Made

- App-level `cryptography` / `cryptography_flutter` dependencies added in Task 2 so `lock_service.dart` imports are first-party and analyzer-clean (transitive-only would risk lint/policy issues).
- iOS Profile build uses `Runner/Runner.entitlements` alongside Release (standard signing parity).

## Deviations from Plan

None — plan executed as written. Task 2 explicitly depended on cryptography packages already in the workspace; adding them to the app `pubspec.yaml` is the supported way to import them from `apps/ptrack`.

## Issues Encountered

- `gsd-tools state advance-plan` returned a parse error against the current free-form `STATE.md` layout; position updates were applied manually alongside this summary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `LockService` is ready for `07-02` UI and `07-03` lifecycle gate wiring.
- Plan frontmatter lists `LOCK-01` and `LOCK-02`; product-level checkboxes in `REQUIREMENTS.md` should remain open until settings UI and resume behavior ship in later Phase 7 plans.

---

*Phase: 07-app-protection-lock*

*Completed: 2026-04-06*

## Self-Check: PASSED

- `apps/ptrack/lib/features/lock/lock_service.dart` exists.
- Verified task commits `ce72342` and `4082ebb` on current branch via `git log`.
- Verified `07-01-SUMMARY.md` written under `.planning/phases/07-app-protection-lock/`.

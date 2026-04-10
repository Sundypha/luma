---
phase: 16-security-audit-findings-remediation
plan: 01
subsystem: infra
tags: [android, gradle, signing, ci, github-actions, apksigner]

requires:
  - phase: 15-address-full-app-code-review-findings
    provides: clean codebase baseline for security remediation
provides:
  - Dedicated Android release signing config with key.properties
  - CI signing secrets injection and release certificate verification
  - key.properties.example template for reproducible local/CI signing
affects: [16-08-PLAN]

tech-stack:
  added: [apksigner (CI verification)]
  patterns: [conditional signingConfig from external properties file, CI secret-to-file injection]

key-files:
  created:
    - apps/ptrack/android/key.properties.example
  modified:
    - apps/ptrack/android/app/build.gradle.kts
    - .github/workflows/firebase-app-distribution.yml

key-decisions:
  - "Release signingConfig is null (not debug) when key.properties is absent — unsigned builds fail explicitly"
  - "CI uses printf to write key.properties from individual secrets rather than a single composite secret"
  - "apksigner verify --print-certs grepped for 'Android Debug' as release-signing guard"

patterns-established:
  - "Conditional signing: signingConfigs block only created when key.properties exists"
  - "CI signing pipeline: decode base64 keystore → write key.properties → build → verify cert DN"

requirements-completed: [SEC-F3]

duration: 3min
completed: 2026-04-10
---

# Phase 16 Plan 01: Android Release Signing Summary

**Dedicated release signingConfig from key.properties with CI secret injection and apksigner-based debug-cert rejection**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-10T12:04:06Z
- **Completed:** 2026-04-10T12:06:35Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Release build type uses a dedicated `release` signingConfig read from `key.properties`, replacing the debug-key fallback
- CI workflow decodes a base64 keystore from GitHub Secrets and writes `key.properties` before the build step
- Post-build `apksigner verify --print-certs` step rejects APKs signed with debug certificates
- Missing signing secrets fail the CI workflow explicitly with clear error messages

## Task Commits

Each task was committed atomically:

1. **Task 1: Configure release signing in build.gradle.kts** — `fd217f3` (feat)
2. **Task 2: CI signing secrets injection + release artifact verification** — `ccef8c3` (feat)

## Files Created/Modified
- `apps/ptrack/android/key.properties.example` — Template documenting required signing properties
- `apps/ptrack/android/app/build.gradle.kts` — Conditional release signingConfig from key.properties; null when absent
- `.github/workflows/firebase-app-distribution.yml` — Decode signing secrets step, verify release cert step, required secrets documentation

## Decisions Made
- When `key.properties` is absent, `signingConfig` is set to `null` rather than falling back to debug — this makes unsigned builds fail explicitly rather than silently debug-signing
- CI writes `key.properties` via `printf` from individual secret variables (not a composite secret) for clarity and auditability
- `apksigner verify --print-certs` output is grepped for "Android Debug" to reject debug-signed release artifacts

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

The following GitHub Secrets must be configured before the CI workflow can build signed release APKs:

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `release.jks` keystore file |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `release`) |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_STORE_PASSWORD` | Keystore store password |

Generate a release keystore:
```bash
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
base64 -w0 release.jks  # → paste output as ANDROID_KEYSTORE_BASE64
```

## Next Phase Readiness
- SEC-F3 criteria fully met: release signing, CI guard, documentation
- Remaining Phase 16 plans (02–08) can proceed independently per wave dependencies

## Self-Check: PASSED

All files verified present, both commits verified in log.

---
*Phase: 16-security-audit-findings-remediation*
*Completed: 2026-04-10*

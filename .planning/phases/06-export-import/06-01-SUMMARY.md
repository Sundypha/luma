---
phase: 06-export-import
plan: "01"
subsystem: database
tags: [drift, export, json, aes-gcm, argon2id, cryptography]

requires:
  - phase: 04-core-logging
    provides: Day entries and periods in Drift for export source rows
provides:
  - Luma `.luma` JSON schema types and serialization
  - AES-256-GCM + Argon2id encryption helper
  - ExportService building UTF-8 file bytes from PtrackDatabase
  - Format specification in docs/luma-export-format.md
affects:
  - 06-export-import plan 02–04 (import UI consume same format)

tech-stack:
  added: [cryptography ^2.9.0, cryptography_flutter ^2.3.4]
  patterns:
    - File-local ref_id mapping for portable exports
    - Encrypted envelope JSON meta + base64 payload alongside plaintext meta+data shape

key-files:
  created:
    - packages/ptrack_data/lib/src/export/export_schema.dart
    - packages/ptrack_data/lib/src/export/luma_crypto.dart
    - packages/ptrack_data/lib/src/export/export_service.dart
    - packages/ptrack_data/test/export/export_schema_test.dart
    - packages/ptrack_data/test/export/luma_crypto_test.dart
    - packages/ptrack_data/test/export/export_service_test.dart
    - docs/luma-export-format.md
  modified:
    - packages/ptrack_data/pubspec.yaml
    - packages/ptrack_data/lib/ptrack_data.dart
    - .planning/REQUIREMENTS.md

key-decisions:
  - "LumaExportMeta.app_version is a string (e.g. 1.0.0+1) to match semver+build labels; plan prose mentioned int but service and JSON use string."
  - "ExportService tests use in-memory NativeDatabase instead of mocktail stubs on Drift select() chains (practical Drift testing)."

patterns-established:
  - "ProgressCallback uses unified total = period rows + day rows when day data is included; periods-only uses period count only."

requirements-completed: [XPRT-02, XPRT-03]

duration: 35min
completed: 2026-04-06
---

# Phase 6 Plan 01: Export data layer summary

**Luma `.luma` export pipeline from Drift (JSON schema, optional AES-256-GCM + Argon2id, ExportService) with XPRT-03 format documentation.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-06 (executor session)
- **Completed:** 2026-04-06
- **Tasks:** 2
- **Files modified:** 11 (including tests and docs)

## Accomplishments

- Immutable export types with snake_case JSON, null omission, and strict `FormatException` validation on parse.
- `LumaCrypto` binary layout `salt ‖ nonce ‖ ciphertext ‖ mac` compatible with documented import expectations.
- `ExportService` orders periods and day rows, maps DB ids to file-local `ref_id`, filters by `ExportOptions`, optional encryption envelope, and stable backup filename.
- `docs/luma-export-format.md` describes plaintext vs encrypted files, fields, encryption parameters, and versioning.

## Task Commits

1. **Task 1: Export schema types and LumaCrypto encryption** — `87cb5a2` (feat)
2. **Task 2: ExportService and format documentation** — `a365889` (feat)

**Plan metadata:** Planning-only commit on branch (message `docs(06-export-import-01): complete export data layer plan`).

## Files Created/Modified

- `packages/ptrack_data/lib/src/export/export_schema.dart` — `ExportOptions`, `LumaExportMeta`, period/day/export root types.
- `packages/ptrack_data/lib/src/export/luma_crypto.dart` — `LumaCrypto.encrypt` / `decrypt`.
- `packages/ptrack_data/lib/src/export/export_service.dart` — `ExportService`, `ExportResult`, `ProgressCallback`.
- `packages/ptrack_data/lib/ptrack_data.dart` — public exports for consumers.
- `packages/ptrack_data/pubspec.yaml` — cryptography dependencies.
- `packages/ptrack_data/test/export/*` — schema, crypto, and service tests.
- `docs/luma-export-format.md` — XPRT-03 field and encryption reference.

## Decisions Made

- Used string `app_version` in `LumaExportMeta` for values like `1.0.0+1` (aligns with `ExportService` and JSON).
- Chose in-memory `PtrackDatabase` fixtures for `ExportService` tests instead of mocktail on generated Drift query APIs.

## Deviations from Plan

None — plan executed as specified. Test approach differs from the plan’s “mock PtrackDatabase” wording but matches the same verification goals using supported Drift patterns.

## Issues Encountered

- Drift `isNotNull` clashed with matcher in tests; resolved with `import 'package:drift/drift.dart' show Value` only.

## User Setup Required

None.

## Next Phase Readiness

- Plan 02 can implement import against documented format and `LumaCrypto` decryption.
- Plan 03 can call `ExportService` from settings/export UI.

---

*Phase: 06-export-import*

*Completed: 2026-04-06*

## Self-Check: PASSED

- `packages/ptrack_data/lib/src/export/export_schema.dart` — FOUND
- `packages/ptrack_data/lib/src/export/luma_crypto.dart` — FOUND
- `packages/ptrack_data/lib/src/export/export_service.dart` — FOUND
- `docs/luma-export-format.md` — FOUND
- Commit `87cb5a2` — FOUND (Task 1)
- Commit `a365889` — FOUND (Task 2)

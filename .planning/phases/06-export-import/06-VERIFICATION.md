---
phase: 06-export-import
verified: 2026-04-06T00:00:00Z
status: human_needed
score: 11/12 must-haves verified (1 truth requires device UAT)
human_verification:
  - test: "Full export → import round-trip on device/emulator (06-04-PLAN Task 2)"
    expected: "Unencrypted and encrypted backups export and re-import without data loss; duplicate strategies behave as selected; invalid files show readable errors; auto-backup exists under app support before import."
    why_human: "Plan 06-04-SUMMARY.md marks this checkpoint pending; FilePicker, share sheet, and real DB state cannot be fully validated by static review alone."
---

# Phase 6: Export/Import Verification Report

**Phase goal:** Users own their data through a documented full export and a safe import path with readable errors and explained duplicate behavior.

**Verified:** 2026-04-06T00:00:00Z

**Status:** human_needed

**Re-verification:** No — initial verification (no prior `*VERIFICATION.md` in this phase directory).

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Export JSON includes `meta` with `format_version`, `schema_version`, `app_version`, `exported_at`, `encrypted`, `content_types` | ✓ VERIFIED | `LumaExportMeta` in `packages/ptrack_data/lib/src/export/export_schema.dart`; `ExportService` sets fields in `export_service.dart` |
| 2 | Export includes periods and day entries per options (symptoms/notes filtering) | ✓ VERIFIED | `ExportService.exportData`; tests in `export_service_test.dart` |
| 3 | Encryption round-trip and wrong-password failure are detectable | ✓ VERIFIED | `LumaCrypto` + `import_service_test.dart` / `luma_crypto_test.dart` |
| 4 | Format documented with schema/version and encryption layout | ✓ VERIFIED | `docs/luma-export-format.md` |
| 5 | Invalid / version-mismatched / encrypted-without-password inputs yield typed, readable errors | ✓ VERIFIED | `ImportService.parseFileMeta` / `parseFileData` + `LumaImportException` hierarchy in `import_service.dart`; VM surfaces messages in `import_view_model.dart` |
| 6 | Duplicate preview by calendar date; apply uses deterministic skip vs replace | ✓ VERIFIED | `ImportPreview.analyze` in `import_preview.dart`; `applyImport` in `import_service.dart`; tests in `backup_service_test.dart`, `import_service_test.dart` |
| 7 | Import apply is atomic (transaction); invalid `periodRefId` rolls back | ✓ VERIFIED | `_db.transaction` in `applyImport`; rollback test in `backup_service_test.dart` |
| 8 | Auto-backup created before import apply; retention pruning | ✓ VERIFIED | `applyImport` calls `_backup.createBackup()` first; `BackupService` + prune test |
| 9 | User can open export/import from app without account (Drawer → Data) | ✓ VERIFIED | `tab_shell.dart` → `DataSettingsScreen`; export/import tiles wired |
| 10 | Export wizard drives `ExportService` and delivers file (share / save) | ✓ VERIFIED | `ExportViewModel.startExport` → `ExportService.exportData`; `ListenableBuilder` in `export_wizard_screen.dart` |
| 11 | Import UI: picker, password step, preview, strategy copy, progress, result | ✓ VERIFIED | `import_screen.dart`, `import_view_model.dart`; duplicate explanation in strategy step (segment tooltips + body text) |
| 12 | Full export → import round-trip restores data correctly on a real run | ? HUMAN | Explicitly pending per `06-04-SUMMARY.md` Task 2; not proven by automation alone |

**Score:** 11/12 truths verified in code/tests; 1 requires human UAT.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `packages/ptrack_data/lib/src/export/export_schema.dart` | Schema types | ✓ VERIFIED | Substantive; barrel-exported |
| `packages/ptrack_data/lib/src/export/luma_crypto.dart` | AES-GCM + Argon2id | ✓ VERIFIED | Used by export/import |
| `packages/ptrack_data/lib/src/export/export_service.dart` | DB → `.luma` bytes | ✓ VERIFIED | Uses `LumaExportData`, `LumaCrypto.encrypt` in `_finish` |
| `packages/ptrack_data/lib/src/export/import_service.dart` | Parse, validate, apply | ✓ VERIFIED | `LumaCrypto.decrypt`, `LumaExportMeta.fromJson`, `BackupService` before transaction |
| `packages/ptrack_data/lib/src/export/import_preview.dart` | Duplicate counts | ✓ VERIFIED | Wired from `ImportViewModel` |
| `packages/ptrack_data/lib/src/export/backup_service.dart` | Auto-backups | ✓ VERIFIED | Used by `ImportService` |
| `docs/luma-export-format.md` | XPRT-03 documentation | ✓ VERIFIED | Complete schema + encryption |
| `apps/ptrack/lib/features/backup/export_view_model.dart` | Export VM | ✓ VERIFIED | Calls `ExportService.exportData` |
| `apps/ptrack/lib/features/backup/export_wizard_screen.dart` | Export UI | ✓ VERIFIED | `ListenableBuilder` + `ExportViewModel` |
| `apps/ptrack/lib/features/backup/data_settings_screen.dart` | Data hub | ✓ VERIFIED | Export + Import navigation wired |
| `apps/ptrack/lib/features/backup/import_view_model.dart` | Import VM | ✓ VERIFIED | `ImportService`, `ImportPreview.analyze`, `applyImport` |
| `apps/ptrack/lib/features/backup/import_screen.dart` | Import UI | ✓ VERIFIED | `ListenableBuilder` + steps |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `export_service.dart` | `export_schema.dart` | `LumaExportData`, `LumaExportMeta` | ✓ WIRED | Build + `_finish` |
| `export_service.dart` | `luma_crypto.dart` | `LumaCrypto.encrypt` | ✓ WIRED | `_finish` when password set |
| `import_service.dart` | `luma_crypto.dart` | `LumaCrypto.decrypt` | ✓ WIRED | Encrypted branch of `parseFileData` |
| `import_service.dart` | `export_schema.dart` | `LumaExportMeta.fromJson`, `LumaExportData.fromJson` | ✓ WIRED | Parse pipeline |
| `import_service.dart` | `backup_service.dart` | `createBackup` before transaction | ✓ WIRED | Start of `applyImport` |
| `export_wizard_screen.dart` | `export_view_model.dart` | `ListenableBuilder` | ✓ WIRED | |
| `export_view_model.dart` | `ExportService` | `exportData` | ✓ WIRED | Via `ptrack_data` barrel |
| `import_screen.dart` | `import_view_model.dart` | `ListenableBuilder` | ✓ WIRED | |
| `import_view_model.dart` | `ImportService` | parse / preview / apply | ✓ WIRED | |
| `data_settings_screen.dart` | `ImportScreen` | Import tile `onTap` | ✓ WIRED | Shared `BackupService` + `ImportService(db, backupService: backup)` |
| `tab_shell.dart` | `DataSettingsScreen` | Drawer index 1 | ✓ WIRED | Settings, Data, About order |

**Note:** `06-04-PLAN.md` specified `BackupService` calls from the view model; implementation centralizes backup in `ImportService.applyImport` (documented in `06-04-SUMMARY.md`). Behavior matches the intent: one auto-backup per apply, no double backup.

### Requirements Coverage

| Requirement | Source plan(s) | Description (from REQUIREMENTS.md) | Status | Evidence |
|---------------|----------------|-------------------------------------|--------|----------|
| **XPRT-01** | 06-03 | Initiate full local export without an account | ✓ SATISFIED (implementation) | Drawer → Data → Export → `ExportWizardScreen` + `ExportService`; no auth gate |
| **XPRT-02** | 06-01 | Export includes periods, symptoms, notes, metadata for round-trip | ✓ SATISFIED | `ExportOptions`, `ExportedPeriod`, `ExportedDayEntry`, `LumaExportMeta`; export tests |
| **XPRT-03** | 06-01 | Format documented; schema/version markers | ✓ SATISFIED | `docs/luma-export-format.md`; `format_version`, `schema_version` in `meta` |
| **IMPT-01** | 06-04 | Import from a prior valid export file | ⚠ NEEDS HUMAN SIGN-OFF | Code path complete (`ImportScreen`, `ImportService`, file picker); `.planning/REQUIREMENTS.md` checkbox still open pending 06-04 Task 2 UAT |
| **IMPT-02** | 06-02 | Invalid/corrupted files → readable validation errors | ✓ SATISFIED | Typed exceptions + user strings; tests for garbage, version, decryption |
| **IMPT-03** | 06-04 | Duplicate handling deterministic and explained in product copy | ✓ SATISFIED (implementation) | `DuplicateStrategy` + date-keyed logic in `applyImport`; UI copy in `import_screen.dart` (`_buildStrategyStep`, preview dup text). Official requirement checkbox in REQUIREMENTS.md remains pending human confirmation alongside IMPT-01 per executor note |

**Orphaned requirements:** None — all six IDs appear in plan frontmatter (`06-01` … `06-04`) and are mapped above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `data_settings_screen.dart` | 55 | `onTap: () {}` on Auto-backups tile | ℹ️ Info | Planned placeholder from 06-03; does not block export/import core paths |

### Human Verification Required

### 1. Export → import round-trip (blocking for phase closure)

**Test:** Follow the checklist in `06-04-SUMMARY.md` § Task 2 (export unencrypted + encrypted, import with skip/replace, invalid file errors, optional auto-backup folder check).

**Expected:** Data matches expectations on calendar/home after import; errors are clear; strategies match selection.

**Why human:** Real device/emulator, share sheet, and FilePicker behavior are outside automated verification scope; this is the explicit gate in `06-04-PLAN.md` Task 2.

### 2. Duplicate copy clarity (optional confirmation)

**Test:** On a device, open import strategy step with duplicates and read tooltips + helper text.

**Expected:** Users understand “same calendar day” and skip vs replace.

**Why human:** Wording quality is subjective; code presence is verified.

### Automated Test Evidence

- `fvm flutter test packages/ptrack_data/test/export/` — **38 tests, all passed** (2026-04-06).
- `fvm flutter test apps/ptrack/test/features/backup/` — **18 tests, all passed** (2026-04-06).

### Gaps Summary

No **code** gaps were found against plan must-haves: export/import pipelines, documentation, UI wiring, and data-layer tests align with Plans 01–04 Task 1. The remaining gap is **process/acceptance**: human UAT for end-to-end round-trip and formal sign-off for IMPT-01 / IMPT-03 in `REQUIREMENTS.md` (per `06-04-SUMMARY.md`).

---

_Verified: 2026-04-06T00:00:00Z_

_Verifier: Claude (gsd-verifier)_

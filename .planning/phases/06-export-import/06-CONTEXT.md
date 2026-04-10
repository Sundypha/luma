# Phase 6: Export & Import - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Users own their data through a documented full export and a safe import path with readable errors and explained duplicate behavior. Export produces a `.luma` file (compact JSON, optionally encrypted); import validates, previews changes, and handles duplicates deterministically. No cloud sync, no account required.

</domain>

<decisions>
## Implementation Decisions

### Export file format
- Compact (minified) JSON as the data format
- Custom `.luma` file extension with device file association
- Optional password-based encryption (zero-knowledge: key derived from user password, never stored)
- Schema and version markers included in the export for forward compatibility
- Export format documented in the repository (XPRT-03)

### Encryption
- Optional at export time — user chooses whether to set a password
- Password-derived encryption key (e.g. PBKDF2 or Argon2 + AES-256)
- Zero-knowledge: app never stores the password or key
- On import of an encrypted file, prompt for password; wrong password shows clear error

### Export wizard
- Short wizard flow: choose what to include, optionally set password, confirm, share
- Two presets: "Everything" (full backup) and "Periods only" (minimal export)
- User can uncheck individual data types beyond the presets
- Data types selectable: periods, symptoms/flow, notes

### Duplicate handling on import
- User chooses strategy at import time: skip duplicates or replace with imported data
- Duplicate matching key: same date (any entry on the same day is a duplicate)
- Summary preview before applying: "12 new entries, 3 duplicates found" with chosen strategy, then confirm
- Auto-backup before import: snapshot of current data so user can restore if import was wrong

### Import/export UX flow
- Located in Settings screen under a "Data" or "Backup" section
- Import triggered via system file picker (any location the OS picker can access)
- Progress bar with entry count during export and import
- Export errors and import validation failures shown as error dialogs with clear messages explaining what went wrong

### File sharing & storage
- Export delivered via system share sheet (save to Files, AirDrop, email, cloud drive, etc.)
- Filename convention: `luma-backup-YYYY-MM-DD.luma`
- Import from system file picker — works with local files, cloud drives, downloads folder

### Claude's Discretion
- Specific encryption algorithm choice (AES-256-GCM vs AES-256-CBC, PBKDF2 vs Argon2)
- Internal JSON schema structure and field naming
- Export wizard screen layout and step transitions
- Progress bar implementation details
- Auto-backup storage location and retention
- Error message copy and tone

</decisions>

<specifics>
## Specific Ideas

- App name for branding is "Luma" — hence `.luma` file extension
- Export presets should make the common case (full backup) a single tap after the wizard opens
- Password prompt on encrypted import should be clear about "this file is password-protected" rather than a generic auth dialog

</specifics>

<deferred>
## Deferred Ideas

- PDF export for gynecologist/doctor visits — presentation/report feature, separate from data backup
- `.luma` file association (tapping a .luma file on the device opens the app and triggers import) — nice-to-have, can add later

</deferred>

---

*Phase: 06-export-import*
*Context gathered: 2026-04-06*

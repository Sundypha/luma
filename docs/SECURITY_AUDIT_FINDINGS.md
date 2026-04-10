# Security Audit Findings and Closure Criteria

- **Date:** 2026-04-10
- **Scope:** Full app security review, with deep focus on export and encryption paths
- **Status:** Draft remediation guide

## How to use this document

For each finding:
- **Problem:** what is currently risky
- **Potential fix (rough guidance):** pragmatic implementation direction
- **Acceptance criteria:** objective checks to mark the finding as closed

---

## 1) Unencrypted sensitive data at rest and in automatic backups

**Severity:** High  
**Areas:** `ptrack_data` DB open path, backup service

### Problem
Sensitive health data appears to be stored in plaintext SQLite, and automatic `.luma` backups can be created without encryption. If device storage or backups are exposed, full historical data may be recoverable.

### Potential fix (rough guidance)
- Encrypt local data at rest (for example, SQLCipher or envelope encryption with a key stored in platform secure storage).
- Encrypt automatic backups by default.
- If user-managed password encryption remains optional, add a clearly safer default mode and explicit warning for unencrypted exports.
- Add retention and cleanup behavior for backup artifacts.

### Acceptance criteria
- [ ] Database file is encrypted at rest and cannot be read as plaintext SQLite without key material.
- [ ] Automatic backups are encrypted by default.
- [ ] Backup encryption key source is documented and uses secure platform storage.
- [ ] Tests cover encrypted backup creation and decryption success/failure paths.
- [ ] User-facing settings clearly indicate backup encryption state.

---

## 2) PIN/app lock brute-force risk (no lockout or throttling)

**Severity:** High  
**Areas:** lock view model and lock screens

### Problem
PIN verification allows repeated attempts with no meaningful throttling or lockout, and short PINs are accepted. This enables practical brute-force attempts on stolen/unlocked devices.

### Potential fix (rough guidance)
- Enforce stronger PIN requirements (minimum length and optionally complexity).
- Add failed-attempt counters with progressive delay and temporary lockouts.
- Persist lockout state securely so app restarts do not reset the defense.
- Optionally require biometric/OS credential re-auth after repeated failures.

### Acceptance criteria
- [ ] Minimum PIN length policy is enforced by UI and business logic.
- [ ] Failed attempts trigger exponential backoff and lockout windows.
- [ ] Lockout state survives app restart.
- [ ] Unit/widget tests verify lockout timing and reset behavior.
- [ ] Manual test confirms brute-force rate is materially slowed.

---

## 3) Android release signing misconfiguration

**Severity:** High  
**Areas:** Android Gradle release build config

### Problem
Release build configuration references debug signing. Shipping debug-signed release artifacts materially weakens app integrity guarantees.

### Potential fix (rough guidance)
- Use a dedicated release keystore and secure CI-managed signing secrets.
- Add CI/build guard that fails if `release` points to debug signing.
- If any debug-signed artifact was distributed, rotate signing identity before broad release.

### Acceptance criteria
- [ ] `release` build type uses only release signing config.
- [ ] CI/build step fails when debug signing is detected for release.
- [ ] Signing process is documented and reproducible in CI.
- [ ] A release artifact verification step confirms expected signing certificate.

---

## 4) Weak export password posture and KDF hardening opportunity

**Severity:** Medium  
**Areas:** export wizard password validation, crypto KDF config

### Problem
Encrypted exports can still be vulnerable to offline cracking if weak passwords are allowed and KDF cost settings are too low for current threat assumptions.

### Potential fix (rough guidance)
- Enforce stronger password/passphrase minimums and reject trivial inputs.
- Tune Argon2id cost based on target device profile and acceptable UX latency.
- Consider optional stronger modes (for example, passphrase + keyfile).

### Acceptance criteria
- [ ] Export flow enforces minimum password strength requirements.
- [ ] KDF parameters are documented with rationale and benchmark target.
- [ ] Tests validate weak-password rejection and valid-password acceptance.
- [ ] Security test demonstrates improved resistance vs previous baseline.

---

## 5) Import path lacks strict size/complexity guardrails (DoS risk)

**Severity:** Medium  
**Areas:** import parse/decrypt routines

### Problem
A crafted or oversized import file may consume excessive memory/CPU during parse/decode/decrypt, causing hangs or crashes.

### Potential fix (rough guidance)
- Enforce max file size before parse/decrypt.
- Validate decoded payload limits (entry counts, field lengths, nesting).
- Fail fast with explicit user-safe errors when limits are exceeded.

### Acceptance criteria
- [ ] Hard maximum file size is enforced before decoding.
- [ ] Structured payload limits are enforced during import validation.
- [ ] Oversized/malformed imports fail gracefully without app crash.
- [ ] Tests cover boundary values and adversarial malformed files.

---

## 6) Sensitive temp-file exposure in export/share flows

**Severity:** Medium  
**Areas:** export delivery and PDF share/save flows

### Problem
Temporary files and share destinations can retain sensitive data outside app control even when local cleanup is attempted.

### Potential fix (rough guidance)
- Minimize temp-file lifetime and use non-predictable filenames.
- Prefer secure in-memory sharing where platform APIs allow.
- Add explicit warning/consent before sharing sensitive exports.
- Strengthen cleanup and post-share deletion behavior where feasible.

### Acceptance criteria
- [ ] Temp files use unique non-predictable names and short lifetimes.
- [ ] Best-effort cleanup runs on success/failure paths.
- [ ] User is warned before sharing sensitive content to external apps.
- [ ] Tests/manual verification confirm cleanup on normal and error paths.

---

## 7) Reset flow leaves backup artifacts behind

**Severity:** Medium  
**Areas:** app reset + backup storage directory

### Problem
User-triggered reset may delete DB/preferences but leave backup files, creating a mismatch between user expectation and actual data removal.

### Potential fix (rough guidance)
- Include backup directories/files in reset workflow.
- Provide explicit success/failure reporting for each data location wiped.
- Offer an additional “secure wipe local backups” action where supported.

### Acceptance criteria
- [ ] Reset flow deletes backup artifacts in known local backup directories.
- [ ] UI confirms which data stores were successfully wiped.
- [ ] Failure to wipe any location is surfaced clearly to the user.
- [ ] Automated test verifies reset removes both DB and backup artifacts.

---

## 8) Encrypted-export metadata remains plaintext and weakly bound

**Severity:** Low  
**Areas:** export/import metadata handling

### Problem
Some metadata around encrypted payloads may remain plaintext and not strongly authenticated with the ciphertext, enabling metadata leakage or spoofing.

### Potential fix (rough guidance)
- Bind metadata via AEAD associated data (AAD), or move sensitive metadata inside encrypted payload.
- Validate consistency between any outer metadata and decrypted inner content.

### Acceptance criteria
- [ ] Metadata integrity/authenticity is cryptographically enforced.
- [ ] Tampered metadata is detected and import is rejected safely.
- [ ] Tests cover metadata tamper scenarios.

---

## Cross-cutting hardening and verification

### Recommended test/security checks
- [ ] Add security-focused test suite for export/import tamper, limits, and password policy.
- [ ] Add CI checks for release signing correctness and security-sensitive config drift.
- [ ] Add threat-model notes for local attacker classes (casual access, rooted device, forensic extraction).
- [ ] Add release checklist item for encryption defaults and reset/wipe behavior.

### Exit criteria for this audit cycle
- [ ] All High findings are closed or have approved compensating controls with target dates.
- [ ] Medium findings have owners, milestones, and test coverage plan.
- [ ] Regression tests exist for each remediated finding.
- [ ] Product/legal/privacy stakeholders approve user-facing data handling updates.

# Phase 7: App protection (lock) - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Optional PIN and/or biometric app lock: not required on first launch; reliable lock/unlock when returning from background on supported devices; product copy is honest about limitations (no full cryptographic protection claims) and describes failure modes so users are not stranded without a credible recovery narrative where applicable. Scope is **in-app** lock behavior and settings — not OS-level app hiding or server-side secrets.

</domain>

<decisions>
## Implementation Decisions

### Lock timing

- Lock when the app **returns from background** every time (strict interpretation of resume behavior).
- After a **full process kill**, the next launch **always** requires unlock if lock is enabled (consistent with resume).
- Provide an explicit **“Lock now”** (or equivalent) so the user can lock without leaving the app.
- **Foreground idle timeout** (auto-lock while app stays open): planner/implementer discretion; **default assumption: off** unless cheap to add and test, to avoid surprising users who are reading the calendar without interaction.

### PIN vs biometric rules

- **PIN is mandatory** whenever lock is enabled; biometrics are an optional shortcut, not a replacement for having a PIN.
- After PIN is created, **offer biometric enrollment once** in the setup flow, easy to skip; user can enable/disable biometrics later in settings.
- If biometric auth fails or the user chooses to use PIN, **fall back to PIN on the same screen** (no separate exotic flow).
- **Disabling lock** or **changing the PIN** requires **re-authentication** (PIN or biometric) first.

### Forgot PIN / recovery (LOCK-03)

- **Primary recovery path (builder discretion):** **destructive reset** of local app data as the honest local-first option, with copy that does **not** imply a hidden recovery channel.
- Before first PIN is set, require a dedicated **acknowledgment step** (sheet or equivalent) that the user must complete so limitations are hard to miss.
- After destructive reset, route the user through **full onboarding again** (or the app’s equivalent empty-state first-run experience).
- On forgot-PIN / reset flows, **always mention exporting data first** as the way to preserve data before reset (Phase 6 export).

### Settings entry & first enable flow

- Place the feature under **Privacy / Security** (or the closest existing grouping with that mental model).
- First-time enable: use a **short linear setup** (acknowledgment → PIN creation → one-time biometric offer); exact step breakdown and visuals are implementer discretion as long as acknowledgment is explicit and lock is **only enabled when setup completes**.
- If the user **cancels** setup before completion, **lock remains off** (no partial enable).
- When lock is **off**, the settings row includes a **one-line subtitle** explaining PIN/biometric and that the app locks on return from background (and “Lock now” if present).

### Claude's Discretion

- Foreground idle auto-lock: default off; include only if low-cost and well-tested.
- PIN length, wrong-attempt limits, cooldown timing, and exact lock screen layout (within Material/app patterns).
- Exact strings and illustration presence on ack sheet; biometric permission prompts and platform edge cases.
- Technical approach (e.g. `local_auth`, secure storage) and test strategy.

</decisions>

<specifics>
## Specific Ideas

- User pointed to **strict resume locking** and **always unlock after process kill** for predictable privacy behavior.
- **“Lock now”** is valued for shared-device moments.
- **Re-auth** before turning lock off or changing PIN is a deliberate trust choice.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 07-app-protection-lock*
*Context gathered: 2026-04-06*

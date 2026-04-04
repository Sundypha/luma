# Phase 1: Foundation & engineering guardrails - Context

**Gathered:** 2026-04-04  
**Status:** Ready for planning (full discuss-phase pass)

<domain>
## Phase Boundary

Reproducible Flutter workspace **pinned with FVM**, **CI** that runs analyzer and tests on every relevant change, and a **dependency posture** that satisfies NFR-03 and NFR-04 (**no** analytics, ad identifiers, third-party ads/profiling SDKs, or hidden telemetry). Phase 1 establishes **tooling, package layout, and policies** only—not product features (logging, calendar, sync, etc.). Minimal app/UI is whatever is required so that **tests run** and the tree is a valid Flutter project.

</domain>

<decisions>
## Implementation Decisions

### Global: use existing libraries (no NIH)

- **Prefer mature `pub.dev` packages** with clear maintenance and usage; **do not** introduce custom shared libraries, “util” packages, or wrappers whose only job is style or tiny indirection.
- **Do not** add packages “for the sake of it” or speculative codegen; add dependencies when a **concrete** Phase requirement needs them.
- **Internal `packages/`** are allowed **early** (see below)—that is **structural decomposition**, not a license to invent thin wrappers; each package should have a **clear boundary** (e.g. domain vs data).

### FVM & Flutter SDK

- **Channel:** **Stable only** for Phase 1.
- **Pinning:** **Exact** Flutter version in FVM config (`.fvmrc` / `fvm_config.json`) so developers and CI match.
- **Contributor docs:** **README only** for Phase 1 setup (FVM install, `fvm use`, `fvm flutter pub get` / `test`). Keep it short and copy-paste friendly.
- **Steering to FVM:** Add **small repo scripts or documented tasks** so day-to-day commands default to **`fvm flutter`** (avoid accidental use of a random system Flutter).
- **Lockfile:** **Commit `pubspec.lock`** for the application (and for any package that ships as an app-style artifact) for reproducible installs and CI.
- **Automation OS:** Canonical automation is **Linux/bash (CI)** and **Python** for anything non-trivial or cross-platform. **Do not** treat Windows-only scripts (e.g. PowerShell) as the **only** supported path for maintainers; Windows developers follow README steps or use WSL/Git Bash where needed. (Aligns with Ubuntu CI.)

### CI test gate

- **Host:** **GitHub Actions** on **Ubuntu**.
- **Triggers:** **`pull_request` and `push` to `main`**.
- **Jobs:** `fvm flutter pub get`, `fvm flutter analyze`, `fvm flutter test`.
- **Analyzer strictness:** **Errors only** (do **not** turn all warnings into CI failures in Phase 1 unless you tighten later).
- **Workflow shape:** **GitHub Actions + bash** for the bulk; use **small Python scripts** for steps that would otherwise be fragile or non-portable.
- **Tests:** Run **everything under `test/`** (unit and widget tests) as soon as they exist—no “unit-only” split in Phase 1 unless a later change adds a separate integration job.
- **Deferred:** **macOS / iOS** build or simulator jobs remain **out of Phase 1** unless explicitly added later (signing, runners, cost).

### Privacy & dependencies (NFR-03, NFR-04)

- **Product rule:** **Do not include** analytics, advertising, profiling, or telemetry SDKs—**at all**.
- **Git / path dependencies:** **Avoid**—**`pub.dev` only** unless an **exceptional** case with **maintainer approval** and clear rationale in the PR.
- **Transitive risk:** Rely on **Dependabot (or equivalent) PRs for `pub`** plus **human review** of dependency changes; reviewers still use judgment on sensitive additions (health data). (No mandatory custom grep/blocklist pipeline required in Phase 1.)
- **Dependabot:** **Enable** for pub version bumps; treat PRs like any other dep change (review + CI).
- **Policy document:** Put the **forbidden dependency / privacy expectations** in **`SECURITY.md`** (or a linked doc) and **link from README**—README stays the entrypoint; detailed policy is not buried only in random PR comments.

### Monorepo & layered code

- **Early `packages/`:** Use a **multi-package layout from Phase 1** (e.g. app + `packages/*`) with **clear boundaries** (domain, data, etc.)—**not** a single monolithic `lib/` only.
- **Tooling:** Use an **existing** multi-package workflow (**Melos** and/or **pub workspaces**, whichever matches the chosen Flutter/Dart SDK—planner picks one; **do not** hand-roll a bespoke package manager).
- **Default UI/state stack (for later phases):** **Riverpod** (`flutter_riverpod`) when state management is introduced—planners treat this as the **default** unless a PR explicitly argues otherwise.
- **Tests:** Add **`mocktail`** as a **dev_dependency** in Phase 1 as the standard mocking approach when tests need it.
- **Codegen:** Introduce **`build_runner` / codegen** only when a **chosen** dependency requires it (e.g. drift, json_serializable)—**not** speculatively on day one.

### Static analysis

- **`flutter_lints`** via `package:flutter_lints/flutter.yaml` as baseline `analysis_options.yaml`.

### Platform focus (development)

- **Android-first:** First **developer** platform is **Android** (Android SDK + emulators—widely available). Document **local** run/debug on Android; iOS remains supported by Flutter but is **not** the primary early focus for every contributor.

### Claude's Discretion

- Exact **Flutter patch** to pin at scaffold time.
- **Package naming** under `packages/` and whether the **app** lives at repo root or `apps/ptrack`.
- **Melos vs pub workspaces** wiring details and CI `working-directory` layout.
- **Dependabot** YAML specifics (schedule, groups).
- Minor **README** wording and **SECURITY.md** section structure.

</decisions>

<specifics>
## Specific Ideas

- **FVM + TDD** are project-level commitments; Phase 1 encodes them in repo shape and CI.
- **Linux/Python** bias for automation; **Windows** dev is supported via documented paths, not Windows-only canonical scripts.
- **Android emulators** as the default local device story for early development.

</specifics>

<deferred>
## Deferred Ideas

- **macOS / iOS CI** and simulator/integration jobs—when signing and runner strategy exist.
- **Optional** dependency grep/blocklist in CI if the team wants stronger enforcement later.
- **iOS-first** developer onboarding polish—after Android path is stable.

</deferred>

---

## Discussion log (full pass)

| Area | Depth |
|------|--------|
| FVM | README-only setup doc; FVM-oriented scripts/tasks; commit lockfile; automation = Linux/bash + Python; “next” to CI |
| CI | PR + main; analyze errors-only; GHA + Python for non-trivial; run full `test/`; “next” to privacy |
| Privacy/deps | Transitive awareness via Dependabot + review; no git/path deps; Dependabot on; policy in SECURITY.md linked from README; “next” to scaffold |
| Libraries | `packages/` early; Riverpod default later; mocktail day 1; codegen when required; Android-first dev; final “lock context” |

---

*Phase: 01-foundation-engineering-guardrails*  
*Context gathered: 2026-04-04 (full discuss-phase)*

# Phase 1: Foundation & engineering guardrails - Context

**Gathered:** 2026-04-04  
**Status:** Ready for planning

<domain>
## Phase Boundary

Reproducible Flutter project **pinned with FVM**, a **CI gate** that runs analyzer and tests on every PR, and a **dependency posture** that satisfies NFR-03 and NFR-04: **no** analytics, ad identifiers, third-party ads/profiling SDKs, or hidden telemetry—without expanding scope into app features (logging, calendar, sync, etc.). This phase does **not** implement product UI beyond what `flutter create` needs to run tests.

</domain>

<decisions>
## Implementation Decisions

### FVM & Flutter SDK

- **Channel:** **Stable only** for Phase 1 (no beta unless formally revisited).
- **Pinning:** **Exact** Flutter version in FVM config (`.fvmrc` / `fvm_config.json` per project convention) so developers and CI use the same SDK.
- **Documentation:** README (or CONTRIBUTING) must state: install FVM, `fvm use`, `fvm flutter pub get`, `fvm flutter test`.

### CI test gate

- **Platform:** **GitHub Actions** on **Ubuntu** for Phase 1.
- **PR gate:** On pull requests (and typically `main` pushes): checkout, install FVM + pinned Flutter, `fvm flutter pub get`, `fvm flutter analyze`, `fvm flutter test`.
- **Deferred:** macOS / iOS simulator builds are **out of Phase 1** unless explicitly added later when signing/runner strategy exists—user chose Ubuntu-only baseline.

### Privacy & dependencies (NFR-03, NFR-04)

- **Product rule:** **Do not include** analytics, advertising, profiling, or telemetry SDKs—**at all**. The bar is **absence** of these categories in direct and intentional dependencies.
- **Process:** **Lightweight:** any change to `pubspec.yaml` / `pubspec.lock` is reviewed for prohibited categories; no mandatory automated blocklist/grep in Phase 1 unless the planner adds a minimal check as a later task.
- **Evidence:** Keep `pubspec.yaml` minimal and auditable; document in-repo what “allowed” vs “forbidden” dependency classes means for contributors.

### Initial scaffold & layout

- **Template:** Standard `flutter create` app suitable for iOS + Android targets.
- **Layout:** **Layered** structure from day one: `lib/data`, `lib/domain`, `lib/presentation` (or equivalent naming consistent across the repo). Tests live alongside or under `test/` mirroring layers as appropriate for TDD.
- **TDD:** New packages/code paths should be introduced with tests from the start per project constraint (planner breaks down concrete test tasks).

### Static analysis

- **`flutter_lints`** via `package:flutter_lints/flutter.yaml` as the baseline `analysis_options.yaml` (no custom very_strict package in Phase 1 unless added later).

### Claude's Discretion

- Exact **Flutter patch version** to pin when scaffolding (use current stable at scaffold time).
- **CI workflow** file names, job structure, caching strategy for Flutter pub.
- Whether to add a **minimal** `dependabot.yml` for pub only (optional; user did not require heavy automation).
- Exact subdirectory names under `lib/` if minor variants (`application` vs `presentation`, etc.) read cleaner for Flutter conventions.

</decisions>

<specifics>
## Specific Ideas

- User previously chose **Flutter + FVM** and **TDD** for the product; Phase 1 encodes that in tooling and repo shape.
- Privacy enforcement preference: **no** analytics/ads/profiling stack—**inclusion is unacceptable**; rely on **not adding** those dependencies plus normal PR review rather than building a large scanning pipeline in Phase 1.

</specifics>

<deferred>
## Deferred Ideas

- **macOS / iOS CI** and simulator builds — when Apple signing and runner cost are decided (post–Phase 1 or late Phase 1 add-on).
- **Automated dependency grep/blocklist** — optional hardening if the team later wants CI enforcement beyond review.
- **Melos / multi-package** — defer unless the planner explicitly splits packages in a later phase.

</deferred>

---
*Phase: 01-foundation-engineering-guardrails*  
*Context gathered: 2026-04-04*

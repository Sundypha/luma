# Phase 17: release management with release bumps, release apks iin github release, and ran apk push to firebase app distribution - Context

**Gathered:** 2026-04-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Standardize **release versioning**, **GitHub Releases** (signed release APK + draft publication + notes), and **Firebase App Distribution** pushes so they are repeatable and aligned. Phase scope is automation and process around shipping builds—not new in-app features.

</domain>

<decisions>
## Implementation Decisions

### Version bumps & tags
- Canonical version: **Flutter `pubspec.yaml` only** (Android/iOS consume from standard Flutter wiring).
- **Semver (MAJOR.MINOR.PATCH)** with **human-chosen** bump level each release.
- **Annotated version tag** is the source of truth for “this is a release” (e.g. `v*`).
- **CHANGELOG.md** (or equivalent) updated in the same change set as the version bump.

### GitHub Releases
- Attach **signed release APK only** (no AAB requirement in this phase unless planner finds an existing mandatory dual-artifact policy).
- Create **draft** GitHub Release first; human publishes after review.
- Release body: **slice from CHANGELOG** for that version.
- **Prerelease tags** (e.g. `v1.0.0-beta.1`) map to GitHub **prerelease** semantics.

### Firebase App Distribution
- **Trigger:** Same as GitHub release flow — **version tag** (not ad-hoc main/nightly unless later amended).
- **Tester group:** **Beta** is used for all FAD deployments today. If stable vs prerelease audiences must diverge, add a **second group** (e.g. stable/internal) — see Claude's Discretion for naming and rules.
- **Release notes on FAD:** **Match** the CHANGELOG/GitHub slice for that version (same substance as GitHub).
- **Pipeline shape:** **One APK build**, **no duplicate builds** for the two destinations — exact job graph is **Claude's Discretion** (single workflow vs reusable workflow) as long as artifact is identical.

### Triggers & gates
- **Tag push** starts release, plus **`workflow_dispatch`** for dry runs or controlled rebuilds.
- Tag-based releases: tag must resolve to a commit on **`main`** (enforce in workflow).
- **GitHub Environment** with **required reviewers** before upload steps (signing/upload to GitHub and Firebase).
- On failure: **fail the whole workflow** — **no partial** upload (all-or-nothing).

### Claude's Discretion
- Workflow layout (jobs, reusable workflows, artifact handoff) while preserving **one build → GitHub draft + FAD**.
- Whether/when to introduce a **second FAD group** beyond **Beta** for stable vs prerelease; default stays **Beta** until needed.
- Exact Environment name(s), reviewer rules, and tag pattern regex (`v*`, prerelease conventions).

</decisions>

<specifics>
## Specific Ideas

- User already has Firebase App Distribution **Beta** group for deployments; stable-specific group is optional follow-up if process requires it.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 17-release-management-with-release-bumps-release-apks-iin-github-release-and-ran-apk-push-to-firebase-app-distribution*
*Context gathered: 2026-04-10*

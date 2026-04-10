---
phase: 17-release-management-with-release-bumps-release-apks-iin-github-release-and-ran-apk-push-to-firebase-app-distribution
plan: "01"
subsystem: infra
tags: [changelog, semver, dart, melos, fvm, release]

requires: []
provides:
  - Root Keep a Changelog with Unreleased + retrospective 1.0.0
  - Dart bump script for pubspec semver+build and CHANGELOG prepending
affects:
  - 17-02 unified release workflow (tag naming, release notes)

tech-stack:
  added: []
  patterns:
    - "Bump script resolves repo root from tool/ location; only replaces the pubspec version line"
    - "New version section inserted immediately after ## [Unreleased]"

key-files:
  created:
    - CHANGELOG.md
    - tool/bump_version.dart
  modified: []

key-decisions:
  - "Use fvm dart run from repo root because workspace SDK (^3.11) exceeds typical system Dart; script is plain dart:io"

patterns-established:
  - "Release bumps: major|minor|patch; build number +1 every time; optional --tag runs git add/commit/annotated tag"

requirements-completed: [REL-01]

duration: 12min
completed: 2026-04-10
---

# Phase 17 Plan 01: Version management foundation Summary

**Keep a Changelog at repo root plus a Dart `dart:io` bump script that updates `apps/ptrack/pubspec.yaml`, prepends a dated release section after `[Unreleased]`, and prints (or runs) git tag steps.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-04-10T18:00:00Z (approx.)
- **Completed:** 2026-04-10T18:12:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 2 (created)

## Accomplishments

- Root `CHANGELOG.md` in Keep a Changelog format with `[Unreleased]` and retrospective `[1.0.0] - 2026-04-07`
- `tool/bump_version.dart` supports `major|minor|patch`, `--dry-run`, `--help`, and `--tag` (git add, commit `release: vX.Y.Z`, annotated `vX.Y.Z`)

## Task Commits

1. **Task 1: Create CHANGELOG.md with retrospective 1.0.0 entry** — `3c36bd3` (feat)
2. **Task 2: Create cross-platform version bump script** — `980eb23` (feat)
3. **Plan metadata / docs** — `docs(17-01)` (SUMMARY, STATE, ROADMAP)

## Files Created/Modified

- `CHANGELOG.md` — Keep a Changelog; Unreleased bucket + v1.0.0 ship notes
- `tool/bump_version.dart` — Semver + build bump, CHANGELOG insertion, optional git tag flow

## Decisions Made

- None beyond plan; script uses regex in-place `version:` replacement to avoid reformatting `pubspec.yaml`.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- Plain `dart run tool/bump_version.dart` failed on this machine with “language version 3.11 … highest supported is 3.9” because the workspace root `pubspec.yaml` targets SDK ^3.11. **`fvm dart run tool/bump_version.dart`** matches the repo’s FVM toolchain and succeeds. Document this for developers and CI (already consistent with `melos` scripts using `fvm`).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- REL-01 satisfied: versioning contract and changelog structure ready for **17-02** (tag-triggered release workflow and release-note extraction).

---
*Phase: 17-release-management-with-release-bumps-release-apks-iin-github-release-and-ran-apk-push-to-firebase-app-distribution*
*Completed: 2026-04-10*

## Self-Check: PASSED

- `CHANGELOG.md` exists at repo root
- Commits `3c36bd3`, `980eb23`, and `docs(17-01)` completion commit present on branch
- `tool/bump_version.dart` exists

---
status: complete
phase: 17-release-management
source:
  - 17-01-SUMMARY.md
  - 17-02-SUMMARY.md
started: 2026-04-10T20:00:00Z
updated: 2026-04-10T23:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Root CHANGELOG (Keep a Changelog)
expected: CHANGELOG.md at repo root matches Keep a Changelog with [Unreleased] and retrospective [1.0.0] - 2026-04-07 as described in 17-01.
result: pass

### 2. Version bump script (dry-run)
expected: From repo root, `fvm dart run tool/bump_version.dart patch --dry-run` prints a bump from the current `apps/ptrack/pubspec.yaml` version to the next patch with build number +1 (e.g. 1.0.0+1 → 1.0.1+2), lists files that would change, and does not modify files (working tree stays clean if you had no other edits).
result: pass

### 3. Release workflow on GitHub
expected: On github.com for this repo, **Actions** lists a **Release** workflow. Its triggers include pushing tags matching `v*` and **Run workflow** (workflow_dispatch) with tag + optional dry run. (Workflow YAML may live only on a branch until merged to default branch — you should still see it when that branch is selected or after merge.)
result: pass

### 4. Firebase workflow cross-reference
expected: The top of `.github/workflows/firebase-app-distribution.yml` includes a NOTE that version-tagged releases should use `.github/workflows/release.yml`, and that this workflow remains for ad-hoc workflow_dispatch testing.
result: pass

### 5. End-to-end tagged release (on main)
expected: After the release workflow is on **`main`**: you bump/edit changelog, commit on `main`, create an annotated `v*` tag, push with `--follow-tags`; the **Release** workflow runs; you approve the **`release`** environment; the run finishes green; GitHub shows a **draft** release for that tag with the APK attached and release notes from the CHANGELOG slice for that version; Firebase App Distribution (Beta group from repo variables) shows the same build with matching release notes. Optional — workflow_dispatch with **dry_run** builds without running publish uploads.
result: pass
notes: "User verified after release.yml artifact/notes path fix on main (2026-04-10)."

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0

## Gaps

<!-- none -->

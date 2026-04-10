---
phase: 17-release-management-with-release-bumps-release-apks-iin-github-release-and-ran-apk-push-to-firebase-app-distribution
plan: "02"
subsystem: infra
tags: [github-actions, release, firebase-app-distribution, apk, changelog]

requires:
  - phase: 17-01
    provides: CHANGELOG format, bump_version.dart, version/tag conventions
provides:
  - Unified release.yml (validate → build → publish) with draft GitHub Release + FAD
  - FAD workflow header cross-reference to release.yml for tagged releases
affects:
  - Release operations and CI maintenance

tech-stack:
  added: []
  patterns:
    - "Quoted YAML key 'on' so strict PyYAML parses triggers (GitHub Actions compatible)"
    - "Publish skipped when workflow_dispatch dry_run is true; tag pushes always run publish"

key-files:
  created:
    - .github/workflows/release.yml
  modified:
    - .github/workflows/firebase-app-distribution.yml

key-decisions:
  - "Publish job uses github.event_name != workflow_dispatch || inputs.dry_run != true so tag pushes are not gated by missing workflow_dispatch inputs"

patterns-established:
  - "Single APK artifact reused for gh release create and firebase appdistribution:distribute"

requirements-completed: []

duration: TBD
completed: checkpoint-2026-04-10
checkpoint: Task 3 human-verify pending — do not mark REL-02/03/04 complete until verified
---

# Phase 17 Plan 02: Unified release workflow (checkpoint) Summary

**Tag-triggered `release.yml` with validate/build/publish, draft GitHub Release plus Firebase App Distribution, Environment gate on publish, and FAD workflow header pointing adopters at the unified path — Tasks 1–2 shipped; Task 3 end-to-end verification is outstanding.**

## Performance

- **Duration:** ~15 min (automation only; Task 3 not timed)
- **Started:** 2026-04-10 (executor session)
- **Completed:** N/A — paused at Task 3 (`checkpoint:human-verify`)
- **Tasks:** 2/3 automated tasks committed; Task 3 awaits human verification
- **Files modified:** 2

## Accomplishments

- New `.github/workflows/release.yml`: `validate` (tag regex, `origin/main` ancestry via `git merge-base --is-ancestor`, CHANGELOG section → `release-notes` artifact), `build` (same signing and APK path as FAD), `publish` (`environment: release`, draft `gh release create`, WIF + `firebase appdistribution:distribute`, rollback `gh release delete` on downstream failure)
- `firebase-app-distribution.yml` header documents `release.yml` as the primary path for version-tagged releases and this workflow for ad-hoc `workflow_dispatch` testing

## Task Commits

1. **Task 1: Create unified release workflow** — `9ef364b` (ci)
2. **Task 2: Update existing FAD workflow with cross-reference** — `22ae7ca` (ci)

**Task 3:** Not executed — **human verification required** (see plan `how-to-verify` and checkpoint section below). After approval, continuation agent should: confirm checks, mark requirements REL-02–REL-04, run `gsd-tools` state/roadmap advance if applicable, and append Task 3 verification notes here.

## Files Created/Modified

- `.github/workflows/release.yml` — Release workflow (`'on'` quoted for YAML 1.1 compatibility)
- `.github/workflows/firebase-app-distribution.yml` — Documentation-only NOTE block after the first header line

## Decisions Made

- Quoted `'on'` at the workflow root so local `yaml.safe_load` validation matches GitHub’s expected keys (unquoted `on` parses as boolean `true` in PyYAML 1.1).

## Deviations from Plan

None — plan executed as written for Tasks 1–2.

## Issues Encountered

None blocking implementation.

## User Setup Required

- GitHub **Environment** named `release` with at least one required reviewer (repo → Settings → Environments), as described in `17-02-PLAN.md` `user_setup` and workflow comments.

## Next Phase Readiness

- **Blocked on Task 3:** End-to-end verification on GitHub (tag push, Environment approval, draft release + FAD, optional dry-run and rollback tests). Resume signal: `approved` or a description of issues per plan `resume-signal`.

## Self-Check: PASSED (Tasks 1–2 artifacts)

- `.github/workflows/release.yml` exists
- Commits `9ef364b`, `22ae7ca` present on branch (`git log --oneline -5`)
- PyYAML structure check: `validate` / `build` / `publish`, `environment: release`, `v*` tag trigger

---
*Phase: 17-release-management-with-release-bumps-release-apks-iin-github-release-and-ran-apk-push-to-firebase-app-distribution*  
*Checkpoint: 2026-04-10 — Task 3 human-verify pending*

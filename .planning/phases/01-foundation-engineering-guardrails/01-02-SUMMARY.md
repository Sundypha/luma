---
phase: 01-foundation-engineering-guardrails
plan: 02
requirements-completed: [NFR-03, NFR-04]
completed: 2026-04-04
---

# Phase 1 plan 02 summary

GitHub Actions **CI** on Ubuntu for `pull_request` and `push` to `main`: Dart pub get, FVM install from `.fvm`, Melos bootstrap, Python **pubspec policy** script (`tool/ci/verify_pubspec_policy.py`, requires PyYAML), `melos exec` **flutter analyze** and **flutter test** across packages.

## Key files

- `.github/workflows/ci.yml`
- `tool/ci/verify_pubspec_policy.py`
- README **CI parity** section

## Self-Check: PASSED

- Workflow references FVM config version via Python JSON read
- Policy script exits 0 on clean tree

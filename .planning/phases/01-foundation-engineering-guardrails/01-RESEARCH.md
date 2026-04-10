# Phase 1 research: Foundation & engineering guardrails

**Phase:** 01 — Foundation & engineering guardrails  
**Researched:** 2026-04-04  
**Requirement IDs:** NFR-03, NFR-04

## User constraints

(Copied from `01-CONTEXT.md` — planner MUST honor.)

- **Libraries:** Prefer mature `pub.dev` packages; no NIH “util” packages; no speculative deps; `packages/` for clear boundaries only.
- **FVM:** Stable channel only; exact pin; README setup; scripts steer to `fvm flutter`; commit `pubspec.lock`; automation = Linux/bash + Python (not PowerShell-only canonical).
- **CI:** GitHub Actions Ubuntu; `pull_request` + `push` to `main`; `fvm flutter pub get`, `analyze` (errors only), `test` all `test/`; GHA + Python for non-trivial; no macOS/iOS CI in Phase 1.
- **Privacy/deps:** No analytics/ads/profiling SDKs; no `git:`/`path:` deps unless exceptional; Dependabot for pub; policy in `SECURITY.md` linked from README.
- **Monorepo:** `packages/` early; **Melos and/or Dart pub workspace** — use existing tooling, no hand-rolled orchestration.
- **Later default:** Riverpod when UI/state arrives — **not required in Phase 1** if app is placeholder-only.
- **Tests:** `mocktail` dev_dependency from Phase 1; codegen only when a dep requires it.
- **Lint:** `flutter_lints` / `package:flutter_lints/flutter.yaml`.
- **Dev platform:** Android-first (SDK + emulators) in docs.

## Standard stack

| Concern | Recommendation | Confidence |
|---------|----------------|------------|
| SDK pin | **FVM** + `.fvmrc` (and `.fvm/fvm_config.json` as generated) | HIGH |
| Monorepo | **Melos** (`melos` CLI) + root `melos.yaml`; prefer **Dart 3.6+ pub workspace** in root `pubspec.yaml` if SDK allows | HIGH |
| App location | `apps/ptrack` (or `apps/ptrack_app`) — keeps root clean for Melos | MEDIUM |
| Packages | `packages/ptrack_domain`, `packages/ptrack_data` — minimal placeholders (`lib/ptrack_domain.dart` exports) | MEDIUM |
| CI Flutter install | **subosito/flutter-action** with `channel: stable` **or** install FVM in CI then `fvm flutter` (align with repo FVM pin) | HIGH |
| FVM in CI | Pattern: checkout → setup Dart → `dart pub global activate fvm` → `fvm install` → `fvm flutter ...` | MEDIUM |
| Dependabot | `.github/dependabot.yml` with `package-ecosystem: pub` and directory `/` or per-package (GitHub supports pub) | MEDIUM |
| Python in CI | `actions/setup-python` + small script under `tool/ci/` e.g. `verify_no_forbidden_deps.py` optional; CONTEXT allows Python for non-trivial steps — **optional** for Phase 1 if policy is doc-only | MEDIUM |

## Architecture patterns

- **Root:** `melos.yaml`, `pubspec.yaml` (workspace member list if using workspaces), `README.md`, `SECURITY.md`, `.github/workflows/ci.yml`, `dependabot.yml`.
- **Bootstrap:** `melos bootstrap` resolves path deps between app and packages.
- **CI:** Single job: install toolchain → `melos bootstrap` (or `dart pub get` at root) → `melos exec --scope=ptrack_app -- fvm flutter analyze` OR run from `apps/ptrack` with FVM.
- **TDD:** At least one **unit test** in `apps/ptrack/test/` or package test proving `flutter test` passes (e.g. trivial `expect(1+1, 2)` plus future domain tests in `packages/ptrack_domain/test/`).

## Do not hand-roll

- Custom pub substitute for Melos/workspace.
- Bespoke FVM installer scripts duplicating documented `fvm install`.
- Internal “logging wrapper” packages with no domain meaning.

## Common pitfalls

- **CI / local mismatch:** Pin same Flutter in FVM and document; CI must call `fvm flutter` not system `flutter`.
- **Melos + FVM:** Run `fvm flutter pub get` inside each package or use `melos bootstrap` after FVM is on PATH — verify order in one dry run.
- **Empty packages:** Analyzer errors on empty lib — add minimal `library` / export file.
- **Dependabot paths:** Multi-package repos may need multiple `directory` entries or root only — check GitHub docs for monorepo layout.

## Validation architecture

| Layer | What proves Phase 1 |
|-------|---------------------|
| Automated | CI: `flutter analyze` + `flutter test` green on Ubuntu |
| Policy | `SECURITY.md` + README link; reviewer checklist for new deps |
| Manual | Optional: Android Studio run on emulator (documented, not CI) |

## Code examples / references

- FVM: https://fvm.app/documentation/getting-started  
- Melos: https://melos.invertase.dev/  
- flutter-action: https://github.com/subosito/flutter-action  
- flutter_lints: https://pub.dev/packages/flutter_lints  

---
## RESEARCH COMPLETE

# Code review: repository (root commit → HEAD)

- **Date:** 2026-04-04  
- **Scope:** `a30a09f` (root) → `HEAD` on branch `chore/gsd-project-init`  
- **Approximate change:** ~30 commits, ~12.9k lines added (includes Flutter platform scaffolding)  
- **Focus:** CI, tooling, Dart packages (`ptrack_domain`, `ptrack_data`, `apps/ptrack`); generated/boilerplate skimmed  

## Verdict

**Approve with minor notes.** Architecture is clear (domain → Drift data → app), validation and prediction logic are test-backed, schema handling fails closed on unsupported versions, and CI enforces analyze, tests, and pubspec policy. Nothing blocking for an MVP / local-first scope.

## Strengths

- **Layering:** `ptrack_domain` owns models, validation, engine, and copy; `ptrack_data` owns persistence and coordination; the app stays thin (`main.dart` is a shell).
- **Write path:** `PeriodRepository` validates inside a single Drift transaction and returns sealed outcomes (`Success` / `Rejected` / `NotFound`) so invalid rows are not persisted.
- **Schema safety:** `assertSupportedSchemaUpgrade` plus tests for fresh DB, v1 fixture, and newer `user_version` fails closed align with stated NFRs.
- **Prediction pipeline:** Completed cycles only, local-calendar cycle length via `timezone`, deterministic engine with documented thresholds and explanation steps; PRED-04-style guardrails on copy (forbidden phrases, careful insufficient-history wording).
- **CI:** FVM version pinned via config + PATH, Melos bootstrap, `tool/ci/verify_pubspec_policy.py` (no `git:` deps, path deps confined), analyze + tests across packages.

## Findings

| Severity   | Area     | Finding |
|-----------|----------|---------|
| Minor     | Docs     | In `packages/ptrack_domain/lib/src/period/period_validation.dart`, the `validateForSave` doc comment around duplicate-start rules reads broken (“`existing + candidate`) is not needed—we only check…”). Fix so future readers are not misled. |
| Minor     | CI / DX  | `.github/workflows/ci.yml` runs `melos exec … flutter analyze/test` after putting FVM’s `flutter` on `PATH`, while root `melos` scripts use `fvm flutter` explicitly (`pubspec.yaml`). CI behavior should match; locally, running `melos run ci:test` without FVM on PATH could hit the wrong SDK. A README note or aligning CI to `fvm flutter` would reduce drift. |
| Minor     | Performance | `insertPeriod` / `updatePeriod` load **all** period rows for validation each time. Fine for MVP volumes; if history grows large, consider indexed queries or bounding reads (document as future work). |
| Suggestion | Tests   | Coverage for domain, data, and a widget path looks strong for phase 02. E2E/device tests are out of scope until needed. |
| Suggestion | Security | Local SQLite + no sync: no IDOR/network surface yet. `SECURITY.md` and conservative health copy are appropriate; revisit when sync/accounts land. |

**Blocking:** none.

## Out of scope (not treated as defects)

- Large generated/boilerplate trees (Android/iOS/desktop/web templates, `ptrack_database.g.dart`): assumed standard `flutter create` / Drift codegen.
- PRD/planning markdown volume: useful for traceability; no code-review issues in this pass.

## Summary

From the first commit through `HEAD`, the codebase reads as a deliberate Phase 1–2 foundation: guardrails in CI and pubspec policy, explicit domain rules (time zones, overlaps, duplicate local starts), a careful prediction engine and user-facing copy policy, and transactional persistence with schema versioning. Address the garbled validation doc comment when convenient; consider CI/Melos `flutter` vs `fvm flutter` wording for contributor clarity.

---

## Related: UAT document review (`.planning/.../02-UAT.md`)

A separate pass on the untracked phase UAT checklist yielded **approve with minor notes**: align Test 3 wording between “Current Test” and the numbered section; make `awaiting:` explicit; standardize `melos`/`fvm` command patterns; optional note to recompute summary counts from the Tests section; optional cross-reference to full CI (`melos run ci:test`).

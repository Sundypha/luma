# Phase 2: Domain, persistence & prediction v1 - Research

**Researched:** 2026-04-04  
**Domain:** Flutter/Dart local persistence (SQLite), deterministic cycle prediction, schema migrations  
**Confidence:** HIGH (stack choices); MEDIUM (exact Drift API surface — verify against locked versions at implementation)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked decisions (summary)

- **Phase boundary:** Domain, persistence, deterministic explainable prediction; not full product UI.
- **UTC storage**; calendar labels use **device local timezone at view time**.
- **Overlapping periods:** invalid on save/edit. **Open periods** excluded from cycle-length stats until closed.
- **Long gaps:** cycles exceeding configurable threshold **excluded from averages** (still stored).
- **Very long bleeding:** outliers excluded with **visible marker/reason** in domain layer.
- **Single-day periods** valid; **end before start** invalid; **duplicate same-day starts** rejected.
- **Cycle length:** implement one canonical definition (recommended: start → day before next start); document in code/tests.
- **Prediction:** last **6** completed cycles; **median**; deterministic within-window outlier rule; **≥2 completed cycles** for a point next-start date, else insufficient-history outcome.
- **Uncertainty:** point + range when appropriate; widen range when variability high; downgrade presentation tier when spread exceeds threshold; insufficient → structured outcome + template.
- **Explanation (PRED-03):** ordered list of factual steps for UI.
- **Persistence:** transactional migrations, fail closed; **each schema bump** has fixture test *N*→*N+1*; **schema version** integer documented for future export; **newer on-disk schema than app** → detect and refuse (no silent corruption).
- **PRED-04:** non-medical, non-contraception framing for any user-facing strings introduced here.

### Claude's discretion

- UTC/local mapping utilities and DST edge tests; numeric thresholds; Drift vs raw sqlite (Drift recommended); file location under sandbox; wording of errors/explanations subject to PRED-04.

### Deferred (out of scope)

- Dedicated PRED-04 copy review pass; calendar/home visualization (Phase 5); onboarding copy (Phase 3).

</user_constraints>

<phase_requirements>
## Phase requirements

| ID | Description | Research support |
|----|-------------|------------------|
| PRED-01 | Deterministic documented rules | Median, fixed window, outlier/long-gap rules in pure Dart + golden-vector tests |
| PRED-02 | Uncertainty vs false precision | Sealed `PredictionResult` (insufficient, range-only, point+range); tier downgrade |
| PRED-03 | Plain-language explanation | `ExplanationStep` list + formatter producing bullets/paragraph |
| PRED-04 | Safe copy | Centralized strings + tests scanning for forbidden framing patterns |
| NFR-02 | Migrations, no silent loss | Drift migrations + fixture DB tests per version; downgrade/newer-schema guards |

</phase_requirements>

## Summary

Phase 2 should land **immutable domain types** and **pure prediction math** in `ptrack_domain` (TDD), **SQLite persistence with versioned migrations** in `ptrack_data` using **Drift**, and a thin **repository** that loads stored periods, derives completed cycles per locked semantics, runs the predictor, and returns a **structured result plus ordered explanation steps** for later UI (Phase 5). User context locks **UTC storage**, **median** over up to **six completed cycles**, **deterministic outlier/long-gap exclusion**, **no ML**, and **transactional fail-closed migrations** with **per-bump fixture tests**.

**Primary recommendation:** Add **Drift** (+ `sqlite3_flutter_libs` on mobile) in `ptrack_data`, keep **prediction and explanation assembly** free of Flutter UI dependencies inside `ptrack_domain`, and prove **NFR-02** with **pre-generated SQLite fixture files** opened in tests via Drift’s migration API.

## Standard stack

### Core

| Library | Version | Purpose | Why standard |
|---------|---------|---------|--------------|
| **Drift** | ^2.x (pin at `pub add` time) | SQLite ORM, migrations, typed queries | De facto Flutter choice; migration helpers; works with `sqlite3` |
| **sqlite3_flutter_libs** | ^0.5.x | Bundles SQLite on Android/iOS | Required companion for Drift on mobile |
| **path** / **path_provider** | pub.dev stable | DB file path | Standard for app sandbox location |

### Supporting

| Library | Purpose | When |
|---------|---------|------|
| **drift_dev** + **build_runner** | Code generation for `.drift` / `@DriftDatabase` | Dev dependency in `ptrack_data` |
| **mocktail** | Test doubles | Already in workspace |

### Alternatives considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| Drift | isar, hive | We need **relational** period rows + **SQL migrations** for NFR-02; Hive/Isar migration story differs |
| Drift | raw `sqflite` | More hand-rolled migration/error handling |

**Installation (indicative):**

```bash
cd packages/ptrack_data
fvm dart pub add drift sqlite3_flutter_libs path path_provider
fvm dart pub add -d drift_dev build_runner
```

## Architecture patterns

### Recommended layout

```
packages/ptrack_domain/lib/
  src/
    period/           # Period, validation, CompletedCycle, cycle length def
    prediction/       # PredictionEngine, PredictionResult, ExplanationStep
packages/ptrack_data/lib/
  src/
    db/               # Drift database, tables, migrations
    mappers/          # row <-> domain
    period_repository.dart
```

### Pattern: pure domain + IO at edge

- **Domain:** no `BuildContext`, no Drift imports.
- **Data:** maps DB rows to domain types; runs transactions for writes/migrations.

### Pattern: migration safety

- Every schema change: **bump user_version**, implement `onUpgrade` steps **in order**, wrap in **transaction**, on failure **rethrow** (no partial apply).
- Tests: commit a **binary or SQL fixture** for version *n*, open with Drift, run migrations, assert row counts and representative fields.

### Anti-patterns

- **Silent catch** around migration or save paths.
- **Storing local calendar dates** without timezone context for “instant” events (use UTC DateTime for starts/ends per context).
- **ML or heuristic opacity** in prediction path.

## Don't hand-roll

| Problem | Don't build | Use instead |
|---------|-------------|-------------|
| SQL migration versioning | Ad-hoc integer in random file | Drift migration API + `schemaVersion` |
| Nullable raw maps for periods | Dynamic JSON blobs | Typed tables + domain types |
| Date arithmetic for cycles | Manual +480 hacks | `DateTime.utc`, tests for DST |

## Common pitfalls

### Pitfall: migration partial apply

**What goes wrong:** Half the columns migrate; app runs with inconsistent schema.  
**How to avoid:** Single transaction per upgrade step; test fixtures per bump.

### Pitfall: open period in statistics

**What goes wrong:** Inflates or corrupts cycle lengths.  
**How to avoid:** Filter `end != null` before computing cycle lengths (per CONTEXT).

### Pitfall: “prediction” copy implies medical certainty

**What goes wrong:** PRED-04 violation.  
**How to avoid:** Template strings reviewed in tests; avoid “will”, “guarantee”, contraception-adjacent language.

## Code examples

### Drift database sketch (illustrative)

```dart
// Source: https://drift.simonbinder.eu/docs/getting-started/
@DriftDatabase(tables: [Periods])
class PtrackDatabase extends _$PtrackDatabase {
  PtrackDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
```

## State of the art

| Old | Current | Notes |
|-----|---------|-------|
| sqflite only | Drift on top of sqflite/sqlite3 | Stronger typing + migrations |

## Open questions

1. **Exact Drift generator layout** (single file vs modular) — resolve during Plan 02 implementation to match repo conventions.
2. **Fixture format** — SQL dump vs Drift’s `moor_schema` — choose fastest stable approach for CI (LOW risk).

## Sources

### Primary (HIGH)

- Drift documentation: https://drift.simonbinder.eu/
- Dart DateTime / timezone guidance: https://dart.dev/guides/libraries/library-tour#dartcore---dates-times-and-duration

### Secondary (MEDIUM)

- Flutter local persistence ecosystem consensus (Drift maintainer activity, pub scores)

## Metadata

**Confidence breakdown:**

- Standard stack: **HIGH** — Drift is the common choice for SQLite + migrations in Flutter.
- Architecture: **HIGH** — aligns with existing `ptrack_domain` / `ptrack_data` split.
- Pitfalls: **MEDIUM** — DST edge cases need executable tests.

**Research date:** 2026-04-04  
**Valid until:** ~2026-05-04 (re-validate if Dart/Drift majors ship)

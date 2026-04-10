# Quality Observations and Risks

**Analysis date:** 2026-04-04

## `file.py` — purpose

**File:** `file.py`

The script **generates the PRD markdown package** by writing five files (`README.md` plus four phase PRDs) from large embedded string constants into a target directory. It is a **content publishing utility**, not part of the future mobile product.

## `file.py` — dependencies

- **Python standard library only:** `pathlib.Path` for directory creation and file writes.
- **No** `requirements.txt`, **no** third-party packages.

## `file.py` — quality and maintainability notes

| Topic | Observation |
|-------|-------------|
| **Output path** | Uses `base = Path("/mnt/data/period_tracker_prds")` — a **Linux/colab-style absolute path**. On a typical Windows dev machine this path is unlikely to exist or match the repo layout; the canonical docs in the repo live under `period_tracker_prds/` instead. Risk: running the script writes **outside** `D:/CODE/ptrack` unless edited. |
| **Single source of truth** | PRD bodies live **both** as committed Markdown under `period_tracker_prds/` **and** as duplicated strings inside `file.py`. Drift is possible if one copy is edited without the other. |
| **Size / reviewability** | The file is very large (~2000+ lines) because it inlines full PRDs; diffs and code review are heavy compared to maintaining Markdown only or using a small template/build step. |
| **Encoding** | Uses `write_text(..., encoding="utf-8")` — appropriate for Markdown. |
| **Idempotency** | Re-running overwrites files in the target directory — expected for a generator. |

**Prescriptive guidance for implementers:** Either (1) treat `period_tracker_prds/*.md` as source of truth and delete or repoint `file.py`, or (2) make generation write **into** the repo (e.g., `Path(__file__).resolve().parent / "period_tracker_prds"`) and document a single workflow so content cannot diverge.

## Documentation quality (PRDs)

The PRDs in `period_tracker_prds/` are **detailed and testable**: acceptance criteria, pitfalls, anti-patterns, and explicit non-goals. They are suitable for phase planning and test design.

**Gap:** There is still **no technical design** for export schema, database schema, or platform choice—by design the PRDs stay product-focused; engineering must add ADRs or specs.

## Security and privacy hooks (from PRDs)

These are **requirements on the future app**, not verifiable in the current repo:

| Theme | PRD reference | Engineering implication |
|-------|---------------|-------------------------|
| **No telemetry / ads** | Phase 1 NFRs (`period_tracker_prds/PRD_Phase_1_MVP.md`) | Dependency audit, network traffic review, crash SDK policy. |
| **Local-first** | Phase 1 | No remote gates for read/write of health data; avoid SDKs that phone home by default. |
| **App lock ≠ crypto guarantee** | Phase 1 | Copy and docs must not overclaim; storage encryption depends on platform choices. |
| **E2E sync confidentiality** | Phase 3 (`period_tracker_prds/PRD_Phase_3_Secure_Sync.md`) | Threat model for metadata, key recovery, conflict UX; avoid “zero knowledge” hype without analysis. |
| **Non-medical positioning** | All phases | UI copy, prediction labels, and insights must stay descriptive; regulatory boundary if scope creeps. |

## Repository-level risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **No implementation** | PRDs are unvalidated against real constraints (performance, platform APIs, migration edge cases). | Spike: choose stack, prototype persistence + export schema + prediction v1. |
| **Generator path** | Accidental writes to wrong directory or confusion about canonical docs. | Fix `file.py` base path or remove generator from workflow. |
| **Duplicate PRD content** | `file.py` vs `period_tracker_prds/` divergence. | Single source workflow (see above). |
| **Phase creep** | Health domain invites feature expansion. | PRDs already freeze scope; enforce phase gates in planning. |

## Open questions for implementers

1. **Mobile stack:** Native (Swift/Kotlin), Flutter, React Native, or other—PRD does not decide; choice affects local DB, biometrics, and file export UX.
2. **Export format:** JSON with documented schema, SQLite dump, or other—must satisfy Phase 1 round-trip and Phase 2 backward compatibility.
3. **Prediction v1 specification:** PRD requires documented rules; need a standalone algorithm spec + golden tests before UI polish.
4. **Internationalization and accessibility:** Phase 1 requires inclusive, non-color-only cues; pick design system early.
5. **Release and signing:** FOSS distribution model (stores, F-Droid) affects build pipeline and permission review for Phase 1 “no network” claim.

## Test coverage

**Not applicable** — no automated tests in repository. Future work should add tests aligned with PRD acceptance summaries (especially migrations, import validation, prediction reproducibility, and offline behavior).

---

*Quality and risk notes for planning and first implementation milestone.*

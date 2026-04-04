# Security & privacy (ptrack)

This document describes **dependency and telemetry expectations** for the ptrack codebase. It supports NFR-03 and NFR-04 in the Phase 1 requirements.

## Telemetry and third-party SDKs

We **do not** add:

- Analytics or crash reporting SDKs that send reproductive-health or usage events to third parties
- Advertising SDKs, ad identifiers, or profiling SDKs
- Hidden telemetry of period or symptom data

Pull requests that introduce such dependencies should be **rejected** unless the product scope and this document are explicitly updated through maintainers.

## Dependencies

- Prefer packages published on **pub.dev** with clear licenses and maintenance.
- **`git:` dependencies** are **not allowed** in normal development (see `tool/ci/verify_pubspec_policy.py`).
- **`path:` dependencies** are allowed only for **internal** packages under `apps/` and `packages/` in this repository.

Review **transitive** dependencies when accepting version bumps (including Dependabot PRs). If a transitive package conflicts with the rules above, find an alternative or pin/work around with maintainer agreement.

## Reporting concerns

Open a **GitHub issue** (or use maintainer contact if configured later) if you believe a dependency or build step violates this policy.

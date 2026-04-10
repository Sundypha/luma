# Pitfalls Research

**Domain:** Local-first period trackers / health logging  
**Researched:** 2026-04-04  
**Source:** `PRD_Phase_1_MVP.md` pitfalls sections + common mobile data patterns

## Pitfall: Silent data loss on upgrade

| | |
|--|--|
| **Warning signs** | Ad-hoc JSON blobs without version; “just wipe DB” dev habits |
| **Prevention** | Schema version in DB; migration tests; export before risky migrations in docs |
| **Phase** | Phase 1 (persistence hardening) |

## Pitfall: Opaque or unstable prediction

| | |
|--|--|
| **Warning signs** | Magic numbers in UI code; prediction changes without tests when editing history |
| **Prevention** | Documented rules in one module; table-driven tests; explicit “insufficient data” states |
| **Phase** | Phase 1 (prediction v1) |

## Pitfall: Actual vs predicted visually ambiguous

| | |
|--|--|
| **Warning signs** | Only color distinguishes states; colorblind failure |
| **Prevention** | Patterns/icons/text labels per PRD §7.4 |
| **Phase** | Phase 1 (calendar/home) |

## Pitfall: Dependency telemetry

| | |
|--|--|
| **Warning signs** | Packages that open network by default; opaque closed SDKs |
| **Prevention** | Dependency allowlist review; network permission minimal; CI grep for known SDKs |
| **Phase** | Phase 1 (from first `pubspec.yaml`) |

## Pitfall: Import duplicates / silent merge

| | |
|--|--|
| **Warning signs** | Unclear UX copy; IDs regenerated on import |
| **Prevention** | Deterministic policy (e.g. reject, replace, or explicit merge) documented + tested |
| **Phase** | Phase 1 (import) |

## Pitfall: Lock screen bricks app

| | |
|--|--|
| **Warning signs** | No recovery path; lost PIN = lost data perception |
| **Prevention** | Clear copy that lock is not encryption; recovery flows per platform guidelines |
| **Phase** | Phase 1 (optional lock) |

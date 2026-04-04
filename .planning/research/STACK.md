# Stack Research

**Domain:** Privacy-first local-first mobile health (menstrual cycle tracking)  
**Researched:** 2026-04-04  
**Confidence:** HIGH (stack chosen by project; Flutter ecosystem verified against PRD constraints)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Flutter** | Pin via **FVM** (`fvm_config.json` / `.fvmrc`) | Cross-platform UI + single codebase for iOS/Android | Mature mobile stack; fits offline-first UI; strong test tooling |
| **Dart** | Bundled with pinned Flutter SDK | App & unit/widget/integration test language | First-class Flutter support |
| **Local persistence** | TBD in implementation plan | Period logs, settings, schema version | SQLite via **drift** or **sqflite** are common; choice should favor migrations + testability |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **flutter_test** / **integration_test** | SDK | Unit, widget, integration tests | TDD workflow; golden tests optional for calendar |
| **mocktail** or **mockito** | Latest compatible | Isolating persistence & platform channels in tests | When testing use cases without real DB |
| **local_auth** | Latest compatible | Optional biometric lock (PRD §6.8) | If biometric path is in scope for target platforms |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **FVM** | Pin Flutter per repo | Document in README; CI must use same version |
| **flutter analyze** / **dart analyze** | Static quality | Gate in CI |
| **melos** (optional) | Monorepo packages later | Defer unless splitting `domain` / `data` / `app` packages early |

## Installation

```bash
# Example — exact versions live in FVM config once scaffold exists
fvm install
fvm flutter pub get
fvm flutter test
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Flutter | Kotlin/Swift native | Maximum platform-specific polish; higher cost for FOSS small team |
| drift | isar, hive | Prefer SQL migrations & query clarity for health data timelines |

## What NOT to Use

- **Analytics, ads, crash SDKs that phone home by default** — violates PRD §7.3 and Phase 1 offline trust model.
- **Auth/social SDKs “for later”** — invites network assumptions and scope creep in Phase 1.
- **Opaque ML services** for prediction in Phase 1 — contradicts explainable rules mandate.

## Alignment with Project Decisions

- **FVM:** All contributors and CI use the same Flutter SDK.
- **TDD:** Prefer pure Dart tests for prediction rules and import/export validation; widget tests for critical flows (logging, calendar distinction actual vs predicted).

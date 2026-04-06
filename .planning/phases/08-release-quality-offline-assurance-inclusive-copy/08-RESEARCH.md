# Phase 8: Release quality, offline assurance & inclusive copy - Research

**Researched:** 2026-04-06
**Domain:** Flutter app polish — performance feel, UX copy, inclusive language, offline verification
**Confidence:** HIGH

## Summary

Phase 8 is a polish and verification pass over the entire Phase 1 feature set (Phases 1–7). The codebase is already in strong shape: no network calls exist, no gendered language is present, labels mostly follow the verb-action / noun-navigation pattern, and the MVVM architecture with `ChangeNotifier` + `ListenableBuilder` provides a solid reactive foundation. The main work is targeted refinement, not structural change.

The four NFRs break into two categories: **copy audit** (NFR-05, NFR-07) which is a systematic string-by-string review with prescribed fixes, and **runtime verification** (NFR-01, NFR-08) which requires measurement-then-fix for performance and end-to-end walkthrough for offline assurance. The app has zero network dependencies in production code, so NFR-08 is primarily a verification exercise with a documented checklist.

**Primary recommendation:** Audit all user-facing strings against the CONTEXT.md voice/terminology rules, fix the small set of identified copy issues (prediction explanation anthropomorphism, technical jargon leaks), verify performance feel by profiling the initial-load spinner gap on Home/Calendar screens, and run a documented offline walkthrough from onboarding through lock.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None — all four areas are at Claude's discretion with approved defaults.

### Claude's Discretion
All four areas below are at Claude's discretion. The user approved these defaults — deviate only if a concrete technical reason emerges.

#### Copy voice & terminology
- Warm but not cutesy — direct, clear sentences. No emoji in functional copy.
- "Period" (not "menstruation" or "menses"). "Cycle" for the full cycle. "Flow" for intensity.
- Second person where natural ("Your period started") but avoid overusing "your" — context makes ownership obvious.

#### Inclusive language boundaries
- No gendered pronouns in app copy — use "you/your" (already second person).
- No "women" or "female" — the app tracks periods, no need to address who uses it.
- Medical disclaimers stay short and factual: "Predictions are estimates based on your history, not medical advice." No lecturing.

#### Action & label clarity
- Icon + text for primary actions. Icon-only acceptable for well-known patterns (back, close, delete) with accessibility labels.
- Labels are verbs for actions ("Log today", "Export data"), nouns for navigation ("Calendar", "Settings").
- No tooltips — if a label needs a tooltip, the label is wrong.

#### Performance feel & priorities
- Calendar month scrolling and day taps should feel instant (no visible loading state).
- Logging actions (mark day, save symptoms) should complete without spinners.
- Export/import can show progress — those are inherently slow operations.
- No gratuitous animations; transitions should be fast (200–300ms max).

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NFR-01 | Common screens and logging actions feel immediate on mainstream supported devices | Performance audit patterns, initial-load spinner analysis, `IndexedStack` confirmation, `shouldRepaint` verification |
| NFR-05 | Primary actions are understandable without dense tutorial text | Full string audit methodology, verb/noun label convention, icon+text pairing review |
| NFR-07 | Copy avoids unnecessary gendered assumptions and unsupported medical claims | Gendered language grep (clean), anthropomorphism fixes in prediction_copy, medical disclaimer review |
| NFR-08 | Full Phase 1 feature set works in airplane mode after install | Zero HTTP calls confirmed, no INTERNET permission in release manifest, all-local dependency audit, walkthrough checklist |
</phase_requirements>

## Standard Stack

### Core

This phase adds no new dependencies. All work uses the existing stack:

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter | 3.41.2 (FVM) | Framework | Already pinned |
| Drift | 2.28.1 | Local SQLite | Already used for all persistence |
| table_calendar | 3.2.0 | Calendar grid | Already used; performance is rendering-layer concern |
| shared_preferences | 2.5.5 | Settings | Already used for onboarding, mood display |

### Supporting

No new supporting libraries. Flutter's built-in `Stopwatch`, `Timeline`, and the DevTools performance overlay are sufficient for profiling.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual string audit | flutter_lints custom rules | Lint rules can't judge voice/tone; manual audit is necessary for copy quality |
| DevTools profiling | integration_test + `traceAction` | Full integration tests add complexity; DevTools profiling is sufficient for this scope |

## Architecture Patterns

### Phase 8 Work Structure

This is an audit/verification phase, not a feature phase. The work pattern is:

```
Phase 8/
├── Copy audit          # NFR-05, NFR-07: systematic string review
│   ├── Prediction copy fixes (prediction_copy.dart)
│   ├── Label consistency pass (all UI files)
│   └── Medical disclaimer review
├── Performance audit   # NFR-01: measure, then fix
│   ├── Initial-load spinner gap (Home + Calendar)
│   ├── Calendar scroll/tap responsiveness
│   └── Logging action latency
└── Offline walkthrough # NFR-08: end-to-end verification
    └── Airplane-mode checklist (onboarding → lock)
```

### Pattern: Copy Constants Module

All user-facing strings should be auditable in a single pass. The current codebase inlines strings at widget sites, which is standard for Flutter (no l10n needed for single-language v1). The audit strategy is:

1. Grep all string literals in `lib/` Dart files
2. Check each against CONTEXT.md voice rules
3. Fix in place (no extraction to constants file — that's a v2 concern)

### Pattern: Performance Verification Without Integration Tests

For NFR-01, the verification approach is:

1. **Identify spinners on fast paths** — `CircularProgressIndicator` on Home and Calendar screens fires before `watchPeriodsWithDays()` emits its first event
2. **Measure the gap** — on a real/emulated device, the SQLite stream should emit within one frame (~16ms). If the spinner never becomes visible, no fix needed
3. **If visible** — seed the ViewModel with initial data synchronously from `main()` (the `listOrderedByStartUtc()` call already runs before `runApp`)
4. **Calendar scroll** — `table_calendar` with `PageView` is inherently smooth; custom painters have correct `shouldRepaint`. Profile only if user reports jank
5. **Logging actions** — `markDay()` and `save()` are single SQLite writes. No spinner shown (by design). Verify with manual tap test

### Anti-Patterns to Avoid
- **Over-optimizing without measurement:** Don't add `RepaintBoundary`, `const` constructors, or caching without profiling evidence
- **Extracting strings prematurely:** Don't create a centralized strings file for single-language v1 — it adds indirection without benefit
- **Adding integration tests for performance:** DevTools profiling is faster and more accurate for this scope

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| String audit | Custom lint rules | Manual grep + review | Voice/tone judgment is human work; lints can't evaluate "warm but not cutesy" |
| Performance profiling | Custom timing code | Flutter DevTools Performance overlay | Built-in tool is comprehensive and accurate |
| Offline testing | Network mocking framework | Airplane mode on device/emulator | Real condition testing is the gold standard for NFR-08 |

## Common Pitfalls

### Pitfall 1: Flash-of-Spinner on Initial Load
**What goes wrong:** `CircularProgressIndicator` shows for a single frame on HomeScreen and CalendarScreen before the Drift stream emits its first event, creating a visible flicker.
**Why it happens:** ViewModels subscribe to `watchPeriodsWithDays()` in their constructor. The first stream event arrives asynchronously, so `hasInitialEvent` is `false` for the first build.
**How to avoid:** In `main()`, the app already calls `repository.listOrderedByStartUtc()` synchronously before `runApp()`. Pass this initial data to the ViewModels (or to a shared state) so they can render immediately without waiting for the stream.
**Warning signs:** Visible spinner or blank screen when switching to Home/Calendar tab.

### Pitfall 2: Anthropomorphic Copy in Prediction Explanations
**What goes wrong:** Prediction copy uses "We reviewed", "we usually look for", "we show a range" — this anthropomorphizes the app.
**Why it happens:** The prediction explanation was written for readability but doesn't match the CONTEXT.md voice guideline ("warm but not cutesy — direct, clear sentences").
**How to avoid:** Rewrite to passive or impersonal voice: "Based on X recent cycle lengths…", "At least Y cycles are typically needed…", "Because variability is high, a range is shown…"
**Warning signs:** Any first-person plural ("we") in user-facing copy.

### Pitfall 3: Technical Jargon Leaking to Users
**What goes wrong:** Prediction copy includes "(UTC calendar days)" which is meaningless to users. Error messages expose raw exception text via `${outcome.reason}` or `e.toString()`.
**Why it happens:** Developer-facing terms weren't stripped before shipping.
**How to avoid:** Remove "(UTC calendar days)" from prediction text. Wrap raw error outputs in user-friendly messages.
**Warning signs:** Any string containing "UTC", "null", "Exception", "Error:" in user-facing paths.

### Pitfall 4: Missing Accessibility Labels on Icon-Only Buttons
**What goes wrong:** Icon-only buttons (back arrow, close, lock icon) may lack `Semantics` labels for screen readers.
**Why it happens:** Material icons have default semantic labels, but custom icon usage may not.
**How to avoid:** Audit all `IconButton` and `Icon` widgets for `tooltip` or `Semantics` wrapper. The CONTEXT.md rule allows icon-only for "well-known patterns (back, close, delete) with accessibility labels."
**Warning signs:** `IconButton` without `tooltip` parameter set.

### Pitfall 5: Forgetting to Test Biometric Lock Offline
**What goes wrong:** `local_auth` biometric prompts might behave differently when network is off (some Android implementations may check for Play Services).
**Why it happens:** Biometric APIs are platform-dependent.
**How to avoid:** Include biometric unlock in the airplane-mode walkthrough checklist.
**Warning signs:** Biometric prompt fails or hangs with network off.

## Code Examples

### Copy Fixes — Prediction Explanation Anthropomorphism

Current (problematic):
```dart
return 'We reviewed $count recent cycle lengths from your saved history '
    '(${lengths.join(', ')} days).';
```

Fixed:
```dart
return 'Based on $count recent cycle lengths from your history '
    '(${lengths.join(', ')} days).';
```

Current:
```dart
return 'Right now there are not enough comparable completed cycles to '
    'pin a next start. After filters, $avail cycle(s) are available; '
    'we usually look for at least $need for this estimate.';
```

Fixed:
```dart
return 'There are not enough completed cycles yet to estimate a next start. '
    '$avail cycle(s) are available after filtering; '
    'at least $need are typically needed.';
```

Current:
```dart
return 'Because variability is high, we show a range instead of a single '
    'day: about $ds through $de (UTC calendar days).';
```

Fixed:
```dart
return 'Because variability is high, a range is shown instead of a single '
    'day: approximately $ds through $de.';
```

### Initial Load Spinner Elimination

If profiling reveals the spinner is visible, the fix pattern is:

```dart
// In main(), before runApp:
final initialPeriods = await repository.listOrderedByStartUtc();
// ... then pass to LumaApp, which passes to TabShell, which seeds VMs

// In HomeViewModel — add optional initial seed:
HomeViewModel(this._repository, this._calendar, {
  List<StoredPeriodWithDays>? initialData,
}) {
  if (initialData != null) {
    _onData(initialData);
  }
  _subscription = _repository.watchPeriodsWithDays().listen(
    _onData,
    onError: _onStreamError,
  );
}
```

### Offline Walkthrough Checklist Pattern

```markdown
## Airplane-Mode Verification Checklist

Pre-condition: Install app, then enable airplane mode.

1. [ ] Onboarding wizard completes (3 screens + Get Started)
2. [ ] First log screen: pick date, save period
3. [ ] Home screen: cycle position displays, today card works
4. [ ] Calendar: month navigation, day tap, period band rendering
5. [ ] Day detail: mark day, add symptoms, save
6. [ ] Symptom form: flow/pain/mood sliders, notes, save
7. [ ] Export: wizard completes, share sheet opens (file saves locally)
8. [ ] Import: pick file, preview, apply
9. [ ] Settings: mood display toggle persists
10. [ ] Lock: enable PIN, lock, unlock with PIN
11. [ ] Lock: biometric prompt (if device supports)
12. [ ] Lock: forgot PIN → reset flow
13. [ ] About screen: privacy and estimates text renders
```

## Identified Copy Issues (Full Audit)

### Files and specific strings requiring changes:

| File | Current Copy | Issue | Fix |
|------|-------------|-------|-----|
| `prediction_copy.dart:81` | "We reviewed $count recent cycle lengths…" | Anthropomorphism ("We") | "Based on $count recent cycle lengths…" |
| `prediction_copy.dart:103` | "we usually look for at least $need" | Anthropomorphism ("we") | "at least $need are typically needed" |
| `prediction_copy.dart:111` | "we show a range…(UTC calendar days)" | Anthropomorphism + technical jargon | "a range is shown…" (remove UTC reference) |
| `first_log_screen.dart:150` | "last bleeding day" | Could use consistent "period" terminology | "last period day" |
| `prediction_copy.dart:102` | "pin a next start" | Informal phrasing | "estimate a next start" |

### Already clean (no changes needed):

| Area | Status |
|------|--------|
| Gendered language (she/her/women/female) | None found ✓ |
| "Period" terminology (not menstruation/menses) | Consistent ✓ |
| Second person (you/your) | Used correctly ✓ |
| Medical disclaimers | Present and factual ✓ |
| PRED-04 forbidden phrases | Guard list active ✓ |
| Navigation labels (nouns) | Home, Calendar, Settings, Data, About ✓ |
| Action labels (verbs) | Save, Cancel, Edit, Add symptoms, Export, Import ✓ |
| Icon + text on primary actions | Drawer, bottom nav, filled buttons ✓ |
| No "women" or "female" | Grep confirms clean ✓ |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `StatefulWidget` ad-hoc state | MVVM with `ChangeNotifier` | Phase 05.1 | Already refactored; performance patterns are modern |
| `StreamBuilder` in widgets | `ListenableBuilder` + ViewModel streams | Phase 05.1 | Cleaner rebuild scope; already in place |

**Deprecated/outdated:** Nothing relevant — the codebase uses current Flutter patterns.

## Performance Inventory

### Existing Performance-Positive Patterns
- `IndexedStack` keeps Home and Calendar tabs alive — instant tab switching ✓
- `shouldRepaint` on all 4 custom painters — avoids unnecessary repaints ✓
- `watchPeriodsWithDays()` dedupes consecutive identical snapshots — avoids redundant rebuilds ✓
- Modal bottom sheets for logging — no full-screen navigation overhead ✓
- `AnimatedSize` at 200ms, page transitions at 300ms — within 200–300ms spec ✓

### Potential Performance Concerns (Measure Before Fixing)
- **Initial load gap:** `CircularProgressIndicator` on Home/Calendar before first stream event (~1 frame)
- **Dual subscriptions:** Both `HomeViewModel` and `CalendarViewModel` subscribe to `watchPeriodsWithDays()` independently. With `IndexedStack` keeping both alive, every DB change triggers two stream events, two `_recompute()` calls, and two `notifyListeners()`. Likely imperceptible for typical data sizes but worth noting.
- **PredictionCoordinator instantiation:** `PredictionCoordinator()` is created fresh on every stream event in both VMs. The constructor is lightweight (no heavy initialization), so this is likely fine.
- **buildCalendarDayDataMap:** Re-iterates all periods on every stream event. For typical usage (<100 periods), this is sub-millisecond.

## Network Dependency Audit

### Production Code: ZERO Network Calls
- Grep for `http`, `HttpClient`, `Uri.parse`, `dio`, `fetch` — **no matches** in any `.dart` file
- No Firebase, analytics, crash reporting, or telemetry SDKs

### Platform Manifests
- **Android release:** No `INTERNET` permission (only in `debug/` and `profile/` manifests for Flutter tooling)
- **iOS:** No `NSAppTransportSecurity` exceptions needed

### Dependencies (All Local-Only)
| Dependency | Network Usage | Offline Safe |
|------------|---------------|-------------|
| `flutter` | None in release | ✓ |
| `drift` (SQLite) | None | ✓ |
| `shared_preferences` | None | ✓ |
| `flutter_secure_storage` | None (keychain/keystore) | ✓ |
| `local_auth` | None (device biometrics) | ✓ |
| `table_calendar` | None (pure rendering) | ✓ |
| `smooth_page_indicator` | None (pure rendering) | ✓ |
| `timezone` | None (bundled data) | ✓ |
| `share_plus` | System share sheet (local) | ✓ |
| `file_picker` | System file picker (local) | ✓ |
| `cryptography` / `cryptography_flutter` | None (local crypto) | ✓ |
| `cupertino_icons` | None (bundled font) | ✓ |

**Conclusion:** The app is fundamentally offline-first. NFR-08 work is a documented verification walkthrough, not remediation.

## Open Questions

1. **Does the initial-load spinner actually flash visibly?**
   - What we know: The code path exists (`!hasInitialEvent → CircularProgressIndicator`). SQLite stream should emit within one frame on warm DB.
   - What's unclear: Whether it's actually perceptible on real devices vs. always below the rendering threshold.
   - Recommendation: Test on a real device or emulator. If invisible, document as verified. If visible, apply the initial-data seeding pattern from Code Examples.

2. **Biometric behavior with network off on all target Android OEMs**
   - What we know: `local_auth` uses the Android BiometricPrompt API, which is local. But some OEMs modify biometric stacks.
   - What's unclear: Whether any supported device's biometric stack requires network.
   - Recommendation: Include in airplane-mode walkthrough. If any device fails, document as a known limitation in LOCK-03 copy.

## Sources

### Primary (HIGH confidence)
- **Codebase audit** — full read of all 43 `lib/` Dart files and 28 `packages/` Dart files
- **AndroidManifest.xml** — confirmed no INTERNET permission in release manifest
- **pubspec.yaml** — confirmed dependency list is local-only

### Secondary (MEDIUM confidence)
- **Flutter MVVM patterns** — `ChangeNotifier` + `ListenableBuilder` is standard Flutter pattern per official docs
- **table_calendar performance** — `PageView`-based month navigation with custom painters is standard performant pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; existing stack is well-understood from Phases 1–7
- Architecture: HIGH — audit/verification phase uses existing patterns, not new architecture
- Copy audit findings: HIGH — based on full codebase read, not sampling
- Performance concerns: MEDIUM — identified from code analysis, not profiling measurements
- Offline assurance: HIGH — confirmed zero network calls via grep, zero INTERNET permission in release

**Research date:** 2026-04-06
**Valid until:** Indefinite (polish patterns don't change with library updates)

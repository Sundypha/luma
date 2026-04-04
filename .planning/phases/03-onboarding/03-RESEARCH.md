# Phase 3: Onboarding - Research

**Researched:** 2026-04-05
**Domain:** Flutter onboarding flow, local persistence, privacy-first health UX
**Confidence:** HIGH

## Summary

Phase 3 delivers a short wizard onboarding flow for a privacy-first period tracker. The flow must communicate local-only storage (ONBD-01), non-medical-advice framing (ONBD-02), reach first logging in under one minute (ONBD-03), and support skip on optional screens while working fully offline (ONBD-04). The user's locked decisions specify a multi-screen wizard with step dots, warm conversational tone, medium-length copy, light illustrations, per-screen skip on optional steps only, required-disclosure acknowledgment gates, mid-session resume on relaunch, and a straight-into-period-logging handoff after completion.

Two viable approaches exist for the onboarding mechanism: the `introduction_screen` package (most popular Flutter onboarding library, 2.9K likes) or a custom `PageView` + `smooth_page_indicator` build. After evaluating both against the project's minimal-dependency policy (NFR-03/04) and the need for per-screen required-vs-optional gating, the custom approach is recommended with `smooth_page_indicator` for animated dots. The `introduction_screen` package remains a viable alternative if faster iteration is preferred. For onboarding state persistence, use `shared_preferences` with the newer `SharedPreferencesWithCache` API.

**Primary recommendation:** Build a custom `PageView`-based wizard using `smooth_page_indicator` for dots and `shared_preferences` for state persistence — gives full control over required-vs-skippable screen gating with minimal dependency footprint.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Short wizard: several focused screens (one main idea per screen), not a single long-scroll page.
- Order of required disclosures: **privacy & local-first first**, then **estimates / not medical advice**.
- Show **subtle step progress** (e.g. dots or step indicator).
- Default path is **balanced**: enough context per screen for comprehension without adding new product capabilities; still optimized for low friction.
- **Warm, conversational** tone; plain, reassuring language.
- **Medium** copy length per screen: short paragraphs or bullets, still scannable.
- **Light illustration or hero graphic** per major idea (not icons-only).
- **Explicit heading or callout** for the not-medical-advice framing, plus short supporting explanation (must satisfy ONBD-02 clearly).
- **Skip applies only to non-essential** steps; required disclosures must be acknowledged before continuing (ONBD-04).
- **Skip affordance per screen** on optional steps; required steps use Continue (no global "skip everything").
- **Replay**: user can read onboarding-style privacy/estimates content again from **Settings → About (or equivalent)**.
- **Mid-onboarding app close**: **resume** where they left off on next launch (persist minimal progress).
- After onboarding: go **straight into period-start logging** (minimal fields; today or change date).
- **One short inline hint** on first logging screen (e.g. logging current or most recent period start).
- **Default period start date: today** (user can change).
- After first save: **brief success acknowledgment**, then enter the **main app shell** as implemented by surrounding work (home/calendar when available).

### Claude's Discretion
- Exact number of wizard steps, precise strings, illustration style, and stepper visuals.
- Persistence keys and edge cases (e.g. data clear / reinstall) unless requirements add constraints later.
- Exact Settings entry label and layout for "About / privacy & estimates" replay.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ONBD-01 | User sees that data is stored locally on the device and no account is required | Privacy-first disclosure screen pattern; warm conversational copy; explicit heading; light illustration of device-local concept |
| ONBD-02 | User sees that predictions are estimates based on entered history (not medical advice) | Explicit callout/heading pattern from health app UX research; "not a substitute for professional medical advice" framing; short supporting explanation |
| ONBD-03 | User can reach the first logging action in under one minute (minimal friction path) | Short wizard (3-5 screens), Continue button on each, fast PageView transitions; straight-into-logging handoff; default date = today |
| ONBD-04 | User can skip non-essential education and continue; onboarding works fully offline | Per-screen skip affordance on optional steps; required steps gate with Continue/acknowledge; no network calls; all assets bundled; shared_preferences for state |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter `PageView` + `PageController` | Built-in | Swipeable multi-screen wizard | Zero-dependency, full control over per-screen gating, built-in animation support |
| `smooth_page_indicator` | ^2.0.1 | Animated step dots / progress indicator | 4K pub likes, 474K downloads/month, 12+ effects, flutter-only dependency, MIT, theme-aware |
| `shared_preferences` | ^2.5.5 | Persist onboarding completion and step progress | Official Flutter team package, 10.4K likes, 4.37M downloads, new `SharedPreferencesWithCache` API |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_test` + `mocktail` | (already in project) | Widget and unit tests | Testing onboarding screens, navigation, state persistence |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom PageView + smooth_page_indicator | `introduction_screen` ^4.0.0 | Faster to build (pre-made skip/done/next buttons, page decorations), but pulls in `dots_indicator`, `collection`, and `flutter_keyboard_visibility_temp_fork` as transitive deps; per-screen required/optional gating requires workarounds; 2.9K likes, well-maintained |
| `smooth_page_indicator` | `dots_indicator` ^3.0.0 | Simpler API but fewer animation effects; used internally by `introduction_screen` |
| `shared_preferences` | Direct file I/O or Drift table | Overkill for simple boolean/int flags; shared_preferences is the standard Flutter solution for this |
| `shared_preferences` | `is_first_run` ^1.0.0 / `is_first_run_plus` ^1.2.1 | Convenient `isFirstRun()` API but adds a dependency for what is a 3-line shared_preferences check |

**Why custom PageView over introduction_screen:**

1. **Per-screen gating**: CONTEXT.md requires "required disclosures must be acknowledged before continuing" while optional screens get skip. `introduction_screen` has a global `showSkipButton` toggle; per-screen control requires raw page overrides that negate much of the package's value.
2. **Dependency policy (NFR-03/04)**: `introduction_screen` transitively depends on `flutter_keyboard_visibility_temp_fork` — a forked package that would need policy review. The custom approach adds only `smooth_page_indicator` (flutter-only dep).
3. **Scope is small**: 3-5 screens of onboarding is lightweight enough that custom PageView boilerplate is minimal (~100-150 lines of scaffolding).
4. **Testing**: Custom widgets are simpler to test than third-party widget internals.

**Installation:**
```bash
# In apps/ptrack/pubspec.yaml
flutter pub add smooth_page_indicator shared_preferences
```

## Architecture Patterns

### Recommended Project Structure
```
apps/ptrack/lib/
├── features/
│   └── onboarding/
│       ├── onboarding_screen.dart        # Main wizard widget (PageView + controller)
│       ├── onboarding_page.dart          # Reusable single-page layout widget
│       ├── onboarding_content.dart       # Static content definitions (title, body, image, required flag)
│       └── onboarding_state.dart         # Persistence helper (SharedPreferencesWithCache wrapper)
├── features/
│   └── settings/
│       └── about_screen.dart             # Replay of privacy/estimates content (CONTEXT.md replay requirement)
└── main.dart                             # Routing: check onboarding state → show wizard or home
```

### Pattern 1: Onboarding Page Data Model
**What:** Define each wizard screen as a data class with `title`, `body`, `imagePath`, `isRequired`, and `requiresAcknowledgment` fields.
**When to use:** To separate content from layout and enable per-screen skip/required behavior.
**Example:**
```dart
class OnboardingPageData {
  final String title;
  final String body;
  final String imagePath;
  final bool isRequired;

  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.imagePath,
    this.isRequired = false,
  });
}

const onboardingPages = [
  OnboardingPageData(
    title: 'Your data stays here',
    body: 'Everything is stored on this device. No account needed, no cloud, no sign-up.',
    imagePath: 'assets/images/onboarding_local.svg',
    isRequired: true,
  ),
  OnboardingPageData(
    title: 'Estimates, not medical advice',
    body: 'Predictions are based on the history you enter — they're personal estimates, not a diagnosis.',
    imagePath: 'assets/images/onboarding_estimates.svg',
    isRequired: true,
  ),
  // Optional: welcome / quick-start hint (skippable)
];
```

### Pattern 2: Required vs Optional Screen Gating
**What:** Required screens show only a "Continue" button (no skip). Optional screens show both "Skip" and "Continue". The PageView's `physics` can optionally be set to `NeverScrollableScrollPhysics()` on required pages to prevent swiping past without acknowledgment.
**When to use:** When onboarding has a mix of mandatory disclosure screens and optional education screens.
**Example:**
```dart
Widget _buildBottomControls(int pageIndex) {
  final page = onboardingPages[pageIndex];
  if (page.isRequired) {
    return FilledButton(
      onPressed: _advancePage,
      child: const Text('Continue'),
    );
  }
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton(onPressed: _advancePage, child: const Text('Skip')),
      FilledButton(onPressed: _advancePage, child: const Text('Continue')),
    ],
  );
}
```

### Pattern 3: Onboarding State Persistence (Resume Support)
**What:** Persist the current step index and completion flag via `SharedPreferencesWithCache`. On app launch, check completion flag; if incomplete, restore to last saved step.
**When to use:** CONTEXT.md mandates mid-onboarding resume on app close/relaunch.
**Example:**
```dart
class OnboardingState {
  static const _keyCompleted = 'onboarding_completed';
  static const _keyCurrentStep = 'onboarding_current_step';

  final SharedPreferencesWithCache _prefs;

  OnboardingState(this._prefs);

  bool get isCompleted => _prefs.getBool(_keyCompleted) ?? false;
  int get currentStep => _prefs.getInt(_keyCurrentStep) ?? 0;

  Future<void> saveStep(int step) => _prefs.setInt(_keyCurrentStep, step);
  Future<void> markCompleted() async {
    await _prefs.setBool(_keyCompleted, true);
    await _prefs.remove(_keyCurrentStep);
  }
}
```

### Pattern 4: App Launch Routing
**What:** On `main.dart` startup, read onboarding state before building the widget tree. Route to onboarding wizard (at saved step) or main app shell.
**When to use:** Every app launch needs this check.
**Example:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {'onboarding_completed', 'onboarding_current_step'},
    ),
  );
  final onboardingState = OnboardingState(prefs);
  runApp(PtrackApp(onboardingState: onboardingState));
}
```

### Anti-Patterns to Avoid
- **Global "skip everything" button**: CONTEXT.md explicitly forbids this. Required disclosures must be individually acknowledged.
- **Storing onboarding state only in memory**: App close loses progress. Must persist to SharedPreferences.
- **Network calls during onboarding**: ONBD-04 requires full offline capability. All assets must be bundled, no remote image loading.
- **Heavy animation libraries**: Keep the onboarding lightweight. Use built-in Flutter animations (AnimatedOpacity, AnimatedContainer) rather than adding Lottie or Rive for this phase.
- **Checking `SharedPreferences` in a constructor**: Async operations fail there. Use `WidgetsFlutterBinding.ensureInitialized()` + async initialization before `runApp()`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Animated page dots | Custom dot painting with CustomPainter | `smooth_page_indicator` ^2.0.1 | 12+ polished effects, theme-aware colors, handles edge cases (RTL, vertical, accessibility) |
| Key-value persistence | Raw file I/O or Drift table for boolean flags | `shared_preferences` ^2.5.5 | Official Flutter team plugin, platform-native storage, tested migration path |
| First-launch detection | Custom timestamp file or database flag | `shared_preferences` boolean check | 3 lines of code; `is_first_run` package is unnecessary overhead |

**Key insight:** The onboarding wizard itself (PageView + controller + per-screen gating) is simple enough to build custom. The only things worth importing are the animated dots indicator (genuinely complex to polish) and the persistence layer (platform-native, officially maintained).

## Common Pitfalls

### Pitfall 1: SharedPreferences Cleared on App Cache Clear
**What goes wrong:** User clears app cache/data; onboarding re-shows even though they've seen it before.
**Why it happens:** SharedPreferences is backed by platform key-value storage that is wiped on cache clear.
**How to avoid:** Accept this as expected behavior — re-showing onboarding after data clear is actually correct since the user's period data (in Drift/SQLite) is also cleared. Document in tests.
**Warning signs:** N/A — this is expected, not a bug.

### Pitfall 2: Async SharedPreferences in Widget Constructor
**What goes wrong:** Onboarding always shows on restart, or app crashes on startup.
**Why it happens:** `SharedPreferences.getInstance()` is async but called in a synchronous constructor or build method.
**How to avoid:** Initialize SharedPreferences in `main()` before `runApp()` using `WidgetsFlutterBinding.ensureInitialized()` then pass the instance down. Use `SharedPreferencesWithCache` for synchronous reads after initial async creation.
**Warning signs:** Onboarding flickers or shows briefly before redirecting.

### Pitfall 3: Missing Accessibility on Skip/Continue Buttons
**What goes wrong:** Screen readers can't distinguish Skip from Continue, or the dot indicator is meaningless.
**Why it happens:** No semantic labels on buttons or indicators.
**How to avoid:** Add `Semantics` labels: "Skip this step", "Continue to next step", "Step 2 of 4". `smooth_page_indicator` does not provide built-in semantics — wrap it in a `Semantics(label: 'Page $current of $total')` widget.
**Warning signs:** TalkBack/VoiceOver testing reveals unlabeled buttons.

### Pitfall 4: Not Bundling Assets for Offline
**What goes wrong:** Illustrations show as broken images when offline.
**Why it happens:** Images loaded from network URLs instead of bundled assets.
**How to avoid:** All onboarding images must be in `assets/` and declared in `pubspec.yaml`. Use `Image.asset()`, never `Image.network()`. ONBD-04 requires full offline operation.
**Warning signs:** Blank image areas when toggling airplane mode before first launch.

### Pitfall 5: PageView Allowing Swipe Past Required Screens
**What goes wrong:** User swipes past the privacy disclosure without reading it, violating ONBD-01.
**Why it happens:** Default `PageView` physics allow free swiping in both directions.
**How to avoid:** On required screens, either use `NeverScrollableScrollPhysics()` and only advance via the Continue button, or intercept the `onPageChanged` callback and snap back if the user hasn't acknowledged. The Continue-button-only approach is simpler and more reliable.
**Warning signs:** Test where tester swipes on a required page successfully navigates without tapping Continue.

### Pitfall 6: Onboarding State Race Condition
**What goes wrong:** User taps "Continue" rapidly, step persistence writes interleave, saved step is wrong on resume.
**Why it happens:** Multiple `setInt` calls to SharedPreferences without awaiting previous write.
**How to avoid:** Gate the Continue button — disable it after first tap until `saveStep()` completes, or debounce. Since `SharedPreferencesWithCache` writes are fast (cached locally, async to disk), this is unlikely but worth a defensive guard.
**Warning signs:** Intermittent test failures where resumed step is off by one.

## Code Examples

### Complete Onboarding Screen Skeleton
```dart
// Source: Custom pattern based on Flutter PageView + smooth_page_indicator official docs
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final int initialPage;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.initialPage = 0,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _controller = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < onboardingPages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == onboardingPages.length - 1;
    final page = onboardingPages[_currentPage];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: page.isRequired
                    ? const NeverScrollableScrollPhysics()
                    : null,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemCount: onboardingPages.length,
                itemBuilder: (context, index) =>
                    _buildPage(onboardingPages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: onboardingPages.length,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildControls(page, isLastPage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(OnboardingPageData page, bool isLast) {
    final label = isLast ? 'Get Started' : 'Continue';
    if (page.isRequired) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: _goToNext, child: Text(label)),
      );
    }
    return Row(
      children: [
        TextButton(onPressed: _goToNext, child: const Text('Skip')),
        const Spacer(),
        FilledButton(onPressed: _goToNext, child: Text(label)),
      ],
    );
  }
}
```

### Mocking SharedPreferences in Widget Tests
```dart
// Source: https://blog.victoreronmosele.com/mocking-shared-preferences-flutter
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows onboarding on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // ... build widget tree, verify onboarding is shown
  });

  testWidgets('skips onboarding when already completed', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
    });
    // ... build widget tree, verify main app is shown
  });
}
```

### smooth_page_indicator with Theme Integration
```dart
// Source: https://pub.dev/packages/smooth_page_indicator (official docs)
SmoothPageIndicator(
  controller: _controller,
  count: onboardingPages.length,
  effect: ExpandingDotsEffect(
    dotHeight: 8,
    dotWidth: 8,
    expansionFactor: 3,
    spacing: 6,
    activeDotColor: Theme.of(context).colorScheme.primary,
    dotColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
  ),
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `SharedPreferences.getInstance()` (legacy) | `SharedPreferencesWithCache.create()` | shared_preferences 2.3.0 (2024) | New API with allowlist, sync reads after init; legacy API deprecated |
| `introduction_screen` 3.x | `introduction_screen` 4.0.0 | Aug 2025 | Refactored button overrides; breaking change to override signatures |
| `smooth_page_indicator` 1.x | `smooth_page_indicator` 2.0.1 | Jan 2026 | Added `SmoothPageIndicatorTheme` for app-wide defaults, theme-based colors |
| Custom dot indicators | `smooth_page_indicator` | 2020+ | Package dominates the space; 4K likes, actively maintained |

**Deprecated/outdated:**
- `SharedPreferences.getInstance()`: Legacy API, being phased out. Use `SharedPreferencesWithCache` for new code.
- `onboarding` package (pub.dev): Last updated 2021, not null-safe, avoid.
- `flutter_overboard` package: Not maintained, last update 2022.

## Open Questions

1. **Illustration assets**
   - What we know: CONTEXT.md requires "light illustration or hero graphic" per major idea.
   - What's unclear: Whether to use SVG, PNG, or Flutter CustomPaint for illustrations. No design assets exist yet.
   - Recommendation: Use placeholder `Icon` widgets or simple SVG placeholders during implementation. SVG via `flutter_svg` is a common choice but adds a dependency; consider using Material Icons or Flutter's built-in drawing for v1, upgrading to custom assets later.

2. **Exact number of wizard steps**
   - What we know: Minimum 2 required (privacy disclosure, not-medical-advice). CONTEXT.md says "several focused screens."
   - What's unclear: Whether to add a welcome screen and/or a quick-start tip screen beyond the two required.
   - Recommendation: 3-4 screens: (1) Welcome + privacy/local-first, (2) Estimates/not-medical-advice, (3) Optional quick-start tip. This satisfies "several" while hitting the under-one-minute target (ONBD-03).

3. **Settings "About" replay screen**
   - What we know: CONTEXT.md requires replay of privacy/estimates content from Settings.
   - What's unclear: Whether Settings screen exists yet (it doesn't in current codebase).
   - Recommendation: Create a minimal Settings shell with an "About" entry that reuses the onboarding content data model. The Settings shell can be expanded in later phases.

## Sources

### Primary (HIGH confidence)
- pub.dev `smooth_page_indicator` 2.0.1 — https://pub.dev/packages/smooth_page_indicator (version, API, effects, theme support verified)
- pub.dev `shared_preferences` 2.5.5 — https://pub.dev/packages/shared_preferences (version, new APIs, migration path verified)
- pub.dev `introduction_screen` 4.0.0 — https://pub.dev/packages/introduction_screen (version, API, dependencies verified)
- Flutter official docs — PageView, PageController, widget testing APIs

### Secondary (MEDIUM confidence)
- Adapty blog "7 Mobile App Onboarding Best Practices in 2026" — https://adapty.io/blog/how-to-fix-your-onboarding-flow/ (UX patterns, A/B testing data)
- UX Collective "From hello to healthy habits: onboarding in healthcare apps" — https://uxdesign.cc/what-i-learned-from-leading-apps-about-signup-and-onboarding-f58921d69e30 (trust patterns)
- DesignX "Healthcare App Design: 7 Patterns That Build Patient Trust" — https://designx.co/healthcare-app-design-patient-trust (progressive disclosure, privacy messaging)
- dev.to "Building a Privacy-First Period Tracker" — https://dev.to/getinfotoyou/building-a-privacy-first-period-tracker-why-i-ditched-the-database-for-local-storage-412m (local storage patterns)

### Tertiary (LOW confidence)
- Various Medium/StackOverflow posts on PageView onboarding patterns (implementation details verified against official docs)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All packages verified on pub.dev with current versions, download stats, and dependency trees
- Architecture: HIGH - Patterns are standard Flutter (PageView + PageController), well-documented, used in production apps
- Pitfalls: HIGH - Identified from StackOverflow common issues, official docs warnings, and Flutter team deprecation notices
- UX patterns: MEDIUM - Based on 2025-2026 blog posts and health app case studies; specific to this domain but not Flutter-specific

**Research date:** 2026-04-05
**Valid until:** 2026-05-05 (30 days — stable ecosystem, no fast-moving changes expected)

# Phase 7: App Protection (Lock) - Research

**Researched:** 2026-04-06
**Domain:** Flutter biometric/PIN authentication, app lifecycle, secure storage
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Lock timing:**
- Lock when the app returns from background every time (strict interpretation of resume behavior).
- After a full process kill, the next launch always requires unlock if lock is enabled (consistent with resume).
- Provide an explicit "Lock now" (or equivalent) so the user can lock without leaving the app.
- Foreground idle timeout: default assumption **off** unless cheap to add and well-tested.

**PIN vs biometric rules:**
- PIN is mandatory whenever lock is enabled; biometrics are an optional shortcut, not a replacement for having a PIN.
- After PIN is created, offer biometric enrollment **once** in the setup flow, easy to skip; user can enable/disable biometrics later in settings.
- If biometric auth fails or the user chooses to use PIN, fall back to PIN on the same screen (no separate exotic flow).
- Disabling lock or changing the PIN requires re-authentication (PIN or biometric) first.

**Forgot PIN / recovery (LOCK-03):**
- Primary recovery path: **destructive reset** of local app data as the honest local-first option, with copy that does **not** imply a hidden recovery channel.
- Before first PIN is set, require a dedicated **acknowledgment step** (sheet or equivalent) that the user must complete so limitations are hard to miss.
- After destructive reset, route the user through full onboarding again (or the app's equivalent empty-state first-run experience).
- On forgot-PIN / reset flows, **always mention exporting data first** as the way to preserve data before reset (Phase 6 export).

**Settings entry & first enable flow:**
- Place the feature under **Privacy / Security** (or the closest existing grouping with that mental model).
- First-time enable: short linear setup (acknowledgment → PIN creation → one-time biometric offer); lock only enabled when setup completes.
- If the user cancels setup before completion, lock remains off (no partial enable).
- When lock is off, the settings row includes a one-line subtitle explaining PIN/biometric and that the app locks on return from background (and "Lock now" if present).

### Claude's Discretion
- Foreground idle auto-lock: default off; include only if low-cost and well-tested.
- PIN length, wrong-attempt limits, cooldown timing, and exact lock screen layout (within Material/app patterns).
- Exact strings and illustration presence on ack sheet; biometric permission prompts and platform edge cases.
- Technical approach (e.g. `local_auth`, secure storage) and test strategy.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LOCK-01 | User can enable optional PIN or biometric lock from settings (not forced on first use) | Settings integration in existing drawer/settings dialog; `LockService` + `LockSettingsScreen`; setup wizard pattern |
| LOCK-02 | Lock behavior is reliable across background/foreground transitions on supported devices | `AppLifecycleListener.onPause`/`onResume` pattern; `LockGate` widget in widget tree; cold-start gate in `main()` |
| LOCK-03 | Lock is not described as full cryptographic protection; failure modes avoid stranding users without data recovery narrative | Acknowledgment sheet before first enable; destructive reset path; "export first" reminder copy |
</phase_requirements>

---

## Summary

Phase 7 adds an optional PIN + biometric app lock to Luma using two well-established Flutter packages: `local_auth` (official flutter.dev package, v3.0.1) for biometric prompts and `flutter_secure_storage` (v10.0.0) for encrypted PIN hash storage. The app already has `cryptography ^2.9.0` (with Argon2id) in the workspace, so PIN hashing can reuse the same KDF already trusted for export encryption — no new crypto primitives needed.

The lock gate is a widget that wraps `TabShell` high in the widget tree and uses `AppLifecycleListener` (available since Flutter 3.13, well within the project's SDK requirement of ≥3.11) to detect background/resume transitions and overlay the lock screen. Cold-start lock is handled in `main()` / `LumaApp` initialization, exactly like the existing onboarding routing pattern.

Platform changes are minimal but mandatory: Android `MainActivity` must inherit `FlutterFragmentActivity` (not `FlutterActivity`) and the manifest needs the `USE_BIOMETRIC` permission. iOS needs `NSFaceIDUsageDescription` in `Info.plist` and a Keychain Sharing entitlement file. These are one-line/small-file changes with no impact on the rest of the app.

**Primary recommendation:** Use `local_auth ^3.0.1` + `flutter_secure_storage ^10.0.0`; store PIN as `Argon2id(salt+hash)` in secure storage; use `AppLifecycleListener` for lifecycle gate; keep all lock code in `apps/ptrack/lib/features/lock/`.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `local_auth` | `^3.0.1` | Biometric authentication dialog (Face ID, fingerprint) | Official flutter.dev package; covers Android/iOS/macOS/Windows; v3.0.0 is the current breaking-change release (Feb 2026) |
| `flutter_secure_storage` | `^10.0.0` | Encrypted storage for PIN hash + salt | Keychain (iOS) and EncryptedSharedPreferences+Tink (Android); 2M+ weekly downloads; v10.0.0 replaces deprecated Jetpack Crypto |
| `cryptography` | `^2.9.0` | Argon2id for PIN hashing | **Already in workspace** (`ptrack_data`); same KDF used for export; designed for low-entropy inputs like PINs |
| `shared_preferences` | `^2.5.5` | Lock-enabled flag, biometrics-enabled flag | **Already in app**; non-sensitive config belongs here, not in secure storage |
| `AppLifecycleListener` | Flutter SDK | Background/foreground lifecycle detection | Built-in since Flutter 3.13; supersedes `WidgetsBindingObserver` for lifecycle |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `local_auth_android` | (auto via `local_auth`) | Android biometric dialog customization | When customizing Android BiometricPrompt strings (signInTitle, cancelButton) |
| `local_auth_darwin` | (auto via `local_auth`) | iOS FaceID/TouchID dialog | When customizing iOS LocalAuthentication strings |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `flutter_secure_storage` for PIN | `shared_preferences` | SharedPreferences is not encrypted; do NOT store hashes there — they would be plaintext in app storage |
| `Argon2id` for PIN hash | `SHA-256` via `crypto` package | SHA-256 is too fast for PINs; Argon2id's memory cost protects against brute-force. Using the existing `cryptography` package also avoids adding a new dependency. |
| `AppLifecycleListener` | `WidgetsBindingObserver.didChangeAppLifecycleState` | Both work; `AppLifecycleListener` is the current recommended API (Flutter 3.13+), named callbacks clearer than a switch statement |

**Installation (apps/ptrack/pubspec.yaml additions):**
```yaml
local_auth: ^3.0.1
flutter_secure_storage: ^10.0.0
```

`cryptography` and `shared_preferences` already present — no new entries needed for them.

---

## Architecture Patterns

### Recommended Project Structure

```
apps/ptrack/lib/features/lock/
├── lock_service.dart          # PIN CRUD, biometric check, lock enabled state
├── lock_gate.dart             # Widget + AppLifecycleListener; overlay lock screen on resume
├── lock_screen.dart           # Full-screen PIN entry + biometric trigger button
├── lock_view_model.dart       # ChangeNotifier; attempt state, loading, error
├── lock_settings_screen.dart  # Enable/disable lock, change PIN, biometric toggle
├── pin_setup_sheet.dart       # Multi-step sheet: ack → PIN creation → biometric offer
├── pin_entry_widget.dart      # Reusable PIN keypad + dot display
└── forgot_pin_sheet.dart      # Destructive reset confirmation + export reminder

apps/ptrack/android/app/src/main/kotlin/app/luma/
└── MainActivity.kt            # FlutterActivity → FlutterFragmentActivity

apps/ptrack/android/app/src/main/
└── AndroidManifest.xml        # + USE_BIOMETRIC permission

apps/ptrack/ios/Runner/
├── Info.plist                 # + NSFaceIDUsageDescription
├── Runner.entitlements        # NEW: keychain-access-groups: []
└── RunnerDebug.entitlements   # NEW: keychain-access-groups: []
```

`LockService` is app-layer only (no database dependency), initialized in `main()` alongside `OnboardingState`.

### Pattern 1: LockService — PIN storage and biometric auth

```dart
// Source: official flutter_secure_storage + local_auth docs
class LockService {
  LockService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    SharedPreferences? prefs,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _auth = localAuth ?? LocalAuthentication(),
        _prefs = prefs;

  static const _hashKey = 'lock_pin_hash';
  static const _saltKey = 'lock_pin_salt';
  static const _enabledKey = 'lock_enabled';
  static const _biometricsKey = 'lock_biometrics_enabled';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;
  final SharedPreferences? _prefs;

  bool get isEnabled => _prefs?.getBool(_enabledKey) ?? false;
  bool get isBiometricsEnabled => _prefs?.getBool(_biometricsKey) ?? false;

  Future<bool> canUseBiometrics() async =>
      await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

  // Hash PIN with Argon2id, store salt + hash in secure storage
  Future<void> createPin(String pin) async { ... }

  // Argon2id hash input, compare to stored hash
  Future<bool> verifyPin(String pin) async { ... }

  // biometricOnly: true → no PIN fallback at OS level (we handle PIN ourselves)
  Future<bool> authenticateWithBiometrics(String localizedReason) async {
    return _auth.authenticate(
      localizedReason: localizedReason,
      biometricOnly: true,
    );
  }

  Future<void> enableLock() async {
    await _prefs?.setBool(_enabledKey, true);
  }

  Future<void> disableLock() async {
    await _prefs?.setBool(_enabledKey, false);
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
  }
}
```

Source: [local_auth 3.0.1 README](https://pub.dev/packages/local_auth), [flutter_secure_storage 10.0.0 README](https://pub.dev/packages/flutter_secure_storage)

### Pattern 2: LockGate — lifecycle-aware widget wrapper

```dart
// Source: Flutter AppLifecycleListener API docs
// https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.lockService, required this.child});
  final LockService lockService;
  final Widget child;
  @override State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  late final AppLifecycleListener _listener;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    // Lock immediately on init if lock is enabled (cold start / process kill)
    _isLocked = widget.lockService.isEnabled;
    _listener = AppLifecycleListener(
      onPause: _onPause,
      onResume: _onResume,
    );
  }

  void _onPause() {
    if (widget.lockService.isEnabled) {
      setState(() => _isLocked = true);
    }
  }

  void _onResume() {
    // _isLocked may already be true from onPause; just rebuild to show lock screen
    if (widget.lockService.isEnabled && _isLocked) {
      setState(() {}); // trigger rebuild to show LockScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return LockScreen(
        lockService: widget.lockService,
        onUnlocked: () => setState(() => _isLocked = false),
      );
    }
    return widget.child;
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }
}
```

### Pattern 3: Settings integration — adding lock tile to existing settings dialog

The current settings dialog in `tab_shell.dart._openSettings()` renders `MoodSettingsTile`. Add a `LockSettingsTile` that navigates to `LockSettingsScreen`:

```dart
// In _openSettings dialog content:
content: const SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MoodSettingsTile(),
      Divider(),
      LockSettingsTile(lockService: lockService), // new
    ],
  ),
),
```

`LockSettingsTile` when tapped closes the dialog and pushes `LockSettingsScreen` via `Navigator.push`. When lock is off, it shows a subtitle: "Lock app with PIN or biometrics when returning from background."

### Pattern 4: PIN hashing with existing Argon2id

```dart
// Uses cryptography package already in workspace
import 'package:cryptography/cryptography.dart';

// In LockService.createPin():
final salt = _generateSalt(); // 16 random bytes
final kdf = Argon2id(parallelism: 1, memory: 8192, iterations: 3, hashLength: 32);
final hash = await kdf.deriveKeyFromPassword(password: pin, nonce: salt);
final hashBytes = await hash.extractBytes();
await _storage.write(key: _saltKey, value: base64.encode(salt));
await _storage.write(key: _hashKey, value: base64.encode(hashBytes));
```

Note: Use lighter Argon2id params than export (parallelism 1, memory 8MB, iterations 3) — PIN is ≤6 digits so full export params would make unlock take ~300ms vs ~100ms. Still brute-force resistant given device-side rate limiting.

### Anti-Patterns to Avoid

- **Storing PIN hash in SharedPreferences**: Not encrypted, accessible in device file system. Use flutter_secure_storage.
- **Using `biometricOnly: false` with local_auth as PIN fallback**: This would show the *system* PIN/passcode screen, not our custom PIN. Use `biometricOnly: true` for biometrics and implement our own PIN UI for the fallback.
- **Not guarding cold-start lock**: If `LockGate` only handles `onPause`/`onResume`, a freshly killed-and-relaunched app won't lock. The `initState` must also check `lockService.isEnabled`.
- **Calling `local_auth.authenticate()` with `biometricOnly: true` on unsupported devices**: Returns false (not an exception in most cases). Always check `canCheckBiometrics` first and hide the biometric button if false.
- **Triggering biometric auth immediately on `onResume`**: The system auth dialog may appear before Flutter's widget tree is ready. Show the lock screen first, let the user tap the biometric button explicitly (or auto-trigger after a short delay with `WidgetsBinding.instance.addPostFrameCallback`).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Biometric prompt dialog | Custom native channel for fingerprint/face | `local_auth ^3.0.1` | Cross-platform, handles Android BiometricPrompt + iOS LocalAuthentication correctly; covers permission errors, lockout states, temporary lockout |
| Encrypted key-value store | Encrypted SharedPreferences, manual SQLCipher | `flutter_secure_storage ^10.0.0` | Uses OS keystore (Keychain / Android KeyStore); platform handles key management; v10 uses Tink, not deprecated Jetpack Crypto |
| PIN hashing | Raw SHA-256 or bcrypt port | `cryptography ^2.9.0` Argon2id (already present) | Argon2id is memory-hard, designed for low-entropy PINs; already trusted for export; no new dependency |
| Lifecycle detection | Background isolate, platform channels | `AppLifecycleListener` (Flutter SDK) | Built-in, well-tested, handles all state transitions cleanly including Android multi-window edge cases |

**Key insight:** The custom PIN _entry UI_ (keypad + dots) must be hand-built (no suitable package fits the project's design patterns), but PIN _storage and verification_ must use proven primitives.

---

## Common Pitfalls

### Pitfall 1: Android FlutterFragmentActivity requirement
**What goes wrong:** Biometric prompt crashes or never shows on Android.
**Why it happens:** `local_auth` requires `FragmentActivity` to show `BiometricPrompt`; default generated `MainActivity` inherits `FlutterActivity`.
**How to avoid:** Change `MainActivity.kt` to `class MainActivity : FlutterFragmentActivity()`. Also add `USE_BIOMETRIC` permission to `AndroidManifest.xml`.
**Warning signs:** Android crash at auth call: `"FragmentManager is already executing transactions"` or biometric dialog never appears.

### Pitfall 2: iOS NSFaceIDUsageDescription missing
**What goes wrong:** App crashes on iOS 14+ when Face ID is triggered without the usage description key.
**Why it happens:** iOS privacy policy requires reason strings for any biometric API use.
**How to avoid:** Add `NSFaceIDUsageDescription` to `ios/Runner/Info.plist` before any `local_auth` call.
**Warning signs:** `NSFaceIDUsageDescription` runtime crash in Xcode console.

### Pitfall 3: iOS flutter_secure_storage requires Keychain Sharing entitlement
**What goes wrong:** `flutter_secure_storage` writes appear to succeed but reads always return `null` on iOS.
**Why it happens:** The plugin requires `keychain-access-groups` in entitlements even if the value is empty.
**How to avoid:** Create `ios/Runner/Runner.entitlements` and `ios/Runner/RunnerDebug.entitlements` (or `DebugProfile.entitlements`) with an empty `keychain-access-groups` array. Add these to the Xcode project or `project.pbxproj`.
**Warning signs:** `flutter_secure_storage.read()` always returns null on iOS device/simulator despite successful writes.

### Pitfall 4: Async secure storage read at cold start blocks first frame
**What goes wrong:** Blank screen or jank on first launch when lock is enabled because `flutter_secure_storage.read()` is async.
**Why it happens:** PIN hash check requires an I/O round-trip before knowing whether to show lock screen.
**How to avoid:** Initialize `LockService` in `main()` with a single `await lockService.loadState()` call (reads lock-enabled flag from `SharedPreferences` only — synchronous after `SharedPreferences.getInstance()`). The PIN hash is not needed at startup; only the `isEnabled` flag is.
**Warning signs:** Visible flash of unlocked content before lock screen appears.

### Pitfall 5: Argon2id blocking the UI thread during PIN verify
**What goes wrong:** Perceptible freeze (100–300ms) when the user enters their PIN.
**Why it happens:** Argon2id is intentionally slow; by default, `cryptography` runs on the Dart isolate.
**How to avoid:** Run `kdf.deriveKeyFromPassword` inside `compute()` or ensure `cryptography_flutter` is in the dependency tree (it delegates to native implementations that run off the main thread). `ptrack_data` already uses `cryptography_flutter ^2.3.4` — the Flutter binding is available.
**Warning signs:** UI janks during PIN verification on slower Android devices.

### Pitfall 6: Lock screen shown when biometric prompt is cancelled mid-background-switch
**What goes wrong:** User receives a phone call while authenticating; on resume the auth is rejected and no clear path back.
**Why it happens:** System cancels in-progress biometric auth when app goes to background.
**How to avoid:** Use `persistAcrossBackgrounding: true` (not available in v3.0 API — removed; use `biometricOnly: true` and handle `LocalAuthExceptionCode` gracefully). On any biometric failure, always fall back to showing the PIN entry UI, never return to a dead state.
**Warning signs:** Lock screen shows no input options after a failed biometric attempt.

### Pitfall 7: Android backup exposes flutter_secure_storage keys
**What goes wrong:** Google Drive backup restores encrypted storage keys without the corresponding Android KeyStore entry, making all stored values unreadable after a restore.
**Why it happens:** Android auto-backup backs up shared preferences files but not KeyStore-protected keys.
**How to avoid:** Add a `backup_rules.xml` file that excludes the flutter_secure_storage shared preferences file from backup (per flutter_secure_storage README). This is a one-time setup step.
**Warning signs:** Blank PIN hash after device restore; users locked out on fresh restore.

---

## Code Examples

Verified patterns from official sources:

### Biometric capability check + availability guard

```dart
// Source: https://pub.dev/packages/local_auth
final LocalAuthentication auth = LocalAuthentication();
final bool canCheckBiometrics = await auth.canCheckBiometrics;
final bool isSupported = canCheckBiometrics || await auth.isDeviceSupported();

// Show biometric option only when available
if (isSupported) {
  final List<BiometricType> available = await auth.getAvailableBiometrics();
  showBiometricButton = available.isNotEmpty;
}
```

### Biometric-only authentication (PIN entry is our custom UI)

```dart
// Source: https://pub.dev/packages/local_auth
import 'package:local_auth/local_auth.dart';

try {
  final bool success = await auth.authenticate(
    localizedReason: 'Authenticate to unlock Luma',
    biometricOnly: true, // our own PIN handles fallback
  );
  if (success) onUnlocked();
} on LocalAuthException catch (e) {
  if (e.code == LocalAuthExceptionCode.notEnrolled) {
    // No biometrics enrolled — hide biometric button
  } else if (e.code == LocalAuthExceptionCode.temporaryLockout ||
             e.code == LocalAuthExceptionCode.biometricLockout) {
    // Show "use PIN instead" message
  }
  // Fall through to PIN entry in all failure cases
}
```

### flutter_secure_storage write/read

```dart
// Source: https://pub.dev/packages/flutter_secure_storage
const storage = FlutterSecureStorage();

// Write
await storage.write(key: 'lock_pin_hash', value: base64EncodedHash);

// Read
final String? hash = await storage.read(key: 'lock_pin_hash');

// Delete all lock keys (on reset)
await storage.delete(key: 'lock_pin_hash');
await storage.delete(key: 'lock_pin_salt');
```

### AppLifecycleListener for background detection

```dart
// Source: https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html
// Introduced Flutter 3.13
final _listener = AppLifecycleListener(
  onPause: () {
    // App going to background — set locked flag
    if (lockService.isEnabled) setState(() => _isLocked = true);
  },
  onResume: () {
    // App returning from background — lock screen will show via _isLocked flag
    setState(() {}); // triggers rebuild
  },
);

// Dispose in State.dispose():
@override
void dispose() {
  _listener.dispose();
  super.dispose();
}
```

### Destructive reset — clearing all app data

```dart
// Full reset: clear secure storage + SharedPreferences + close and delete DB
Future<void> resetAllAppData(
  FlutterSecureStorage storage,
  SharedPreferences prefs,
  PtrackDatabase database,
) async {
  await storage.deleteAll();
  await prefs.clear();
  await database.close();
  // Delete the SQLite file via path_provider + dart:io
  final dir = await getApplicationDocumentsDirectory();
  final dbFile = File('${dir.path}/ptrack.db');
  if (await dbFile.exists()) await dbFile.delete();
}
// After reset: setState to AppScreen.onboarding in LumaApp
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `local_auth` `AuthenticationOptions` class | Named parameters (`biometricOnly`, `persistAcrossBackgrounding`) | v3.0.0, Feb 2026 | Breaking change: remove `AuthenticationOptions` wrapper |
| `flutter_secure_storage` Jetpack Crypto (deprecated) | Tink library | v10.0.0, Dec 2024 | More secure, supported long-term; migration handled automatically on first read |
| `WidgetsBindingObserver.didChangeAppLifecycleState` | `AppLifecycleListener` named callbacks | Flutter 3.13 | Cleaner API; old approach still works but new is recommended |

**Deprecated / outdated:**
- `AuthenticationOptions` class: removed in `local_auth` v3.0.0. Samples online using `options: AuthenticationOptions(biometricOnly: true)` are outdated — use `biometricOnly: true` as a named parameter on `authenticate()`.
- `FlutterSecureStorage` with `EncryptedSharedPreferences` (pre-v10): uses deprecated Jetpack Crypto; v10 is the correct target.

---

## Open Questions

1. **Linux platform biometrics**
   - What we know: `local_auth` does not support Linux (Android/iOS/macOS/Windows only per pub.dev). The project has `linux/CMakeLists.txt`.
   - What's unclear: Is Linux a real ship target or just a Flutter default scaffold? Whether to show an error or just hide the biometric option on Linux.
   - Recommendation: Guard all `local_auth` calls with `await auth.isDeviceSupported()`. On Linux, biometric option is simply never shown; PIN-only lock still works via `flutter_secure_storage` (which does support Linux via libsecret).

2. **flutter_secure_storage iOS entitlements file setup in pbxproj**
   - What we know: The iOS entitlements files don't exist yet in the project. They need to be created AND referenced in `ios/Runner.xcodeproj/project.pbxproj`.
   - What's unclear: The exact pbxproj edits needed (fragile XML).
   - Recommendation: Add the two entitlements files (`Runner.entitlements` for Release, `RunnerDebug.entitlements` for Debug+Profile) and update pbxproj `CODE_SIGN_ENTITLEMENTS` build settings. Alternatively, document this as a manual step for the developer to complete in Xcode GUI (set Signing & Capabilities → + Keychain Sharing).

3. **Android backup exclusion rules**
   - What we know: Without backup exclusion, flutter_secure_storage keys may be restored without corresponding KeyStore entries, causing read failures after device restore.
   - What's unclear: Whether this affects the current app's Android backup config (no `backup_rules.xml` found in the project).
   - Recommendation: Add `android:allowBackup="false"` to the application element in `AndroidManifest.xml`, or add a `backup_rules.xml` that excludes the secure storage file. The former is simpler and consistent with a privacy-focused local-first app.

---

## Sources

### Primary (HIGH confidence)
- `https://pub.dev/packages/local_auth` — v3.0.1, full README, platform support matrix, `biometricOnly`, `LocalAuthException` codes
- `https://pub.dev/packages/local_auth_android` — v2.0.7, FlutterFragmentActivity requirement, USE_BIOMETRIC permission, LaunchTheme requirement
- `https://pub.dev/packages/flutter_secure_storage` — v10.0.0, full README, encryption options table, iOS Keychain setup, Android backup warning
- `https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html` — official Flutter API docs, `onPause`/`onResume` callbacks
- `packages/ptrack_data/lib/src/export/luma_crypto.dart` — project's existing Argon2id usage pattern (confirmed in codebase)
- `apps/ptrack/pubspec.yaml` — confirmed `shared_preferences ^2.5.5` already present
- `packages/ptrack_data/pubspec.yaml` — confirmed `cryptography ^2.9.0` + `cryptography_flutter ^2.3.4` already in workspace

### Secondary (MEDIUM confidence)
- Multiple community sources consistent: SHA-256 insufficient for PINs; Argon2id is the correct KDF for low-entropy secrets — corroborated by NIST guidance and the `cryptography` package docs.

### Tertiary (LOW confidence)
- Exact pbxproj edits for iOS entitlements: documentation found in flutter_secure_storage README is prescriptive but the exact pbxproj build setting key (`CODE_SIGN_ENTITLEMENTS`) needs validation against the current project's pbxproj structure.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against pub.dev official pages and existing codebase
- Architecture: HIGH — follows established project patterns (ViewModel + ChangeNotifier, service classes, feature folders)
- Platform setup: HIGH for Android (official README); MEDIUM for iOS entitlements (correct but pbxproj edits need care)
- Pitfalls: HIGH — most sourced from official READMEs or codebase inspection

**Research date:** 2026-04-06
**Valid until:** 2026-05-06 (local_auth and flutter_secure_storage are stable; AppLifecycleListener API is stable in Flutter 3.x)

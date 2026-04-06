# Phase 6: Export & Import - Research

**Researched:** 2026-04-06
**Domain:** Flutter data serialization, file I/O, optional encryption, import validation
**Confidence:** HIGH

## Summary

Phase 6 adds full data export and import to Luma. The data model is compact (two tables: `periods` and `day_entries`, schema version 3, Drift-backed SQLite), making JSON serialization straightforward with `dart:convert` — no code generation required. The export produces a `.luma` file (minified JSON with a metadata envelope, optionally encrypted with AES-256-GCM + Argon2id key derivation). Import reads the file, validates schema/version, detects encryption, previews changes with duplicate detection (date-based matching), and applies data with an auto-backup safety net.

The Flutter ecosystem provides mature packages for every component: `share_plus` for system share sheet delivery, `file_picker` for import file selection, and `cryptography` (with `cryptography_flutter`) for platform-accelerated encryption. All dependencies are well-maintained with broad platform support.

**Primary recommendation:** Use `dart:convert` for manual JSON serialization of the two-table schema, `cryptography` for optional AES-256-GCM encryption with Argon2id password-derived keys, `share_plus` for export delivery, and `file_picker` for import selection. Place export/import business logic in `ptrack_data` package alongside `PeriodRepository`, with UI in a new `features/backup/` folder following the existing MVVM pattern.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Export file format: Compact (minified) JSON as the data format with custom `.luma` file extension
- Schema and version markers included in the export for forward compatibility
- Export format documented in the repository (XPRT-03)
- Optional password-based encryption at export time (zero-knowledge: key derived from user password, never stored)
- On import of an encrypted file, prompt for password; wrong password shows clear error
- Export wizard flow: choose what to include, optionally set password, confirm, share
- Two presets: "Everything" (full backup) and "Periods only" (minimal export)
- User can uncheck individual data types beyond the presets
- Data types selectable: periods, symptoms/flow, notes
- Duplicate handling: user chooses strategy at import time — skip duplicates or replace with imported data
- Duplicate matching key: same date (any entry on the same day is a duplicate)
- Summary preview before applying: "12 new entries, 3 duplicates found" with chosen strategy, then confirm
- Auto-backup before import: snapshot of current data so user can restore if import was wrong
- Located in Settings screen under a "Data" or "Backup" section
- Import triggered via system file picker
- Export delivered via system share sheet
- Progress bar with entry count during export and import
- Filename convention: `luma-backup-YYYY-MM-DD.luma`

### Claude's Discretion
- Specific encryption algorithm choice (AES-256-GCM vs AES-256-CBC, PBKDF2 vs Argon2)
- Internal JSON schema structure and field naming
- Export wizard screen layout and step transitions
- Progress bar implementation details
- Auto-backup storage location and retention
- Error message copy and tone

### Deferred Ideas (OUT OF SCOPE)
- PDF export for gynecologist/doctor visits — presentation/report feature, separate from data backup
- `.luma` file association (tapping a .luma file on the device opens the app and triggers import) — nice-to-have, can add later
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| XPRT-01 | User can initiate full local export without an account | Export service reads all data from Drift DB; no auth needed; share_plus delivers file |
| XPRT-02 | Export includes periods, symptoms, notes, and metadata needed for round-trip restoration | JSON schema includes all Period/DayEntry fields + metadata envelope with schema version |
| XPRT-03 | Export format is documented in the repository and includes schema/version markers | Metadata envelope contains `format_version`, `schema_version`, `app_version`; docs go in `docs/luma-export-format.md` |
| IMPT-01 | User can import from a prior valid export file | file_picker selects `.luma` files; ImportService validates and writes to DB in a transaction |
| IMPT-02 | Invalid or corrupted files fail with readable validation errors (no silent corruption) | Multi-layer validation: JSON parse → schema check → version check → data integrity; all in try/catch with typed errors |
| IMPT-03 | Duplicate-handling behavior is deterministic and explained in product copy | Date-based matching with user-chosen strategy (skip/replace); preview shows counts before apply |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dart:convert` | (SDK) | JSON encode/decode | Built-in; sufficient for 2-table manual serialization; no codegen overhead |
| `cryptography` | ^2.9.0 | AES-256-GCM encryption + Argon2id KDF | Platform-native acceleration (CryptoKit/javax.crypto/WebCrypto); well-maintained; 300+ likes |
| `cryptography_flutter` | ^2.3.4 | Flutter platform bridge for `cryptography` | Enables hardware-accelerated crypto on iOS/Android; recommended companion |
| `share_plus` | ^12.0.2 | System share sheet for export delivery | Official Flutter Favorites; supports files via XFile on Android/iOS/macOS/Windows/Web |
| `file_picker` | ^11.0.0 | System file picker for import | Cross-platform (Android/iOS/macOS/Windows/Linux); supports custom extension filter |
| `path_provider` | ^2.1.5 | App directories for auto-backup storage | Already in project (`ptrack_data` dependency) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `drift` | ^2.28.1 | Database access for bulk read/write | Already in project; use `transaction()` for atomic import writes |
| `intl` | (if needed) | Date formatting for filename | Only if `DateFormat` not already available; can use manual formatting |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `cryptography` | `aes256` ^2.2.2 | Simpler API (single encrypt/decrypt call) but uses PBKDF2 not Argon2id; no platform acceleration; less established (newer package) |
| `cryptography` | `pointycastle` ^4.0.0 | Very established (BouncyCastle port) but low-level API; more boilerplate for GCM + KDF; no platform delegation |
| `share_plus` | `open_file_plus` | Only opens files, doesn't share; share_plus supports save-to-location via share sheet |
| `file_picker` | Manual platform channels | Enormous effort; file_picker covers all platforms |
| `dart:convert` (manual) | `json_serializable` | Code generation overhead unjustified for 2 tables; manual serialization is ~60 lines total |

**Installation (new dependencies only):**
```bash
# In packages/ptrack_data/
flutter pub add cryptography cryptography_flutter

# In apps/ptrack/
flutter pub add share_plus file_picker
```

Note: `share_plus` and `file_picker` go in the app package (they're UI/platform concerns). `cryptography` goes in `ptrack_data` (encryption is a data-layer concern applied before/after serialization).

## Architecture Patterns

### Recommended Project Structure
```
packages/ptrack_data/lib/src/
├── export/
│   ├── export_schema.dart         # JSON schema types + version constants
│   ├── export_service.dart        # Reads DB → builds JSON → optional encrypt → bytes
│   ├── import_service.dart        # Bytes → optional decrypt → validate → write DB
│   ├── import_preview.dart        # Diff analysis: new vs duplicate counts
│   ├── luma_crypto.dart           # AES-256-GCM encrypt/decrypt with Argon2id KDF
│   └── backup_service.dart        # Auto-backup before import + restore
apps/ptrack/lib/features/
├── backup/
│   ├── export_wizard_screen.dart  # Multi-step export wizard
│   ├── export_view_model.dart     # Export state: selection, progress, errors
│   ├── import_screen.dart         # Import flow: pick → validate → preview → apply
│   ├── import_view_model.dart     # Import state: progress, preview, errors
│   └── backup_settings_tile.dart  # Settings entry point (tile in drawer/settings)
docs/
└── luma-export-format.md          # XPRT-03: documented export format specification
```

### Pattern 1: Service Layer with Progress Callbacks
**What:** Export and import operations run as async methods on service classes, accepting progress callbacks for UI updates.
**When to use:** Always — keeps business logic testable and separate from UI.
**Example:**
```dart
typedef ProgressCallback = void Function(int current, int total);

class ExportService {
  ExportService(this._db);
  final PtrackDatabase _db;

  Future<List<int>> exportData({
    required ExportOptions options,
    ProgressCallback? onProgress,
  }) async {
    final data = await _readAllData(options, onProgress: onProgress);
    final json = jsonEncode(data.toJson());
    if (options.password != null) {
      return LumaCrypto.encrypt(utf8.encode(json), options.password!);
    }
    return utf8.encode(json);
  }
}
```

### Pattern 2: MVVM with ChangeNotifier for Wizard State
**What:** Each screen gets a ChangeNotifier ViewModel that holds wizard step state, validation, and async operation status.
**When to use:** All export/import UI — consistent with existing CalendarViewModel, HomeViewModel pattern.
**Example:**
```dart
class ExportViewModel extends ChangeNotifier {
  ExportStep _step = ExportStep.selectContent;
  bool _includePeriods = true;
  bool _includeSymptoms = true;
  bool _includeNotes = true;
  String? _password;
  double _progress = 0;
  ExportError? _error;

  // Step navigation
  void nextStep() { _step = _step.next; notifyListeners(); }
  void previousStep() { _step = _step.previous; notifyListeners(); }
  
  // Export execution
  Future<void> startExport(ExportService service) async {
    _step = ExportStep.exporting;
    notifyListeners();
    // ...
  }
}
```

### Pattern 3: Transaction-Based Atomic Import
**What:** Import writes all data inside a single Drift `transaction()` so partial failures leave existing data untouched.
**When to use:** Always during import apply step.
**Example:**
```dart
Future<ImportResult> applyImport(
  LumaExportData data,
  DuplicateStrategy strategy,
) {
  return _db.transaction(() async {
    int created = 0, skipped = 0, replaced = 0;
    for (final period in data.periods) {
      // ... insert/update logic with duplicate handling
    }
    return ImportResult(created: created, skipped: skipped, replaced: replaced);
  });
}
```

### Pattern 4: Envelope JSON Schema
**What:** The `.luma` file always contains a top-level JSON object with a `meta` envelope (always readable) and a `data` field (plaintext JSON or base64-encoded encrypted blob).
**When to use:** Every export file.
**Rationale:** The `meta` section is always readable even for encrypted files, allowing the import flow to detect encryption and prompt for password before attempting decryption.

```dart
// Unencrypted:
{
  "meta": {
    "format_version": 1,
    "schema_version": 3,
    "app_version": "1.0.0+1",
    "exported_at": "2026-04-06T14:30:00Z",
    "encrypted": false,
    "content_types": ["periods", "symptoms", "notes"]
  },
  "data": {
    "periods": [...],
    "day_entries": [...]
  }
}

// Encrypted:
{
  "meta": {
    "format_version": 1,
    "schema_version": 3,
    "app_version": "1.0.0+1",
    "exported_at": "2026-04-06T14:30:00Z",
    "encrypted": true,
    "content_types": ["periods", "symptoms", "notes"]
  },
  "payload": "<base64-encoded encrypted bytes>"
}
```

### Anti-Patterns to Avoid
- **Encrypting the entire file including metadata:** Makes it impossible to detect encryption status or check version compatibility before decryption. Always keep `meta` in plaintext.
- **Using auto-increment IDs as matching keys during import:** IDs are storage-local and not stable across devices. Use calendar dates for duplicate matching.
- **Writing imported rows one-by-one outside a transaction:** A crash mid-import would leave partial data. Always wrap in `_db.transaction()`.
- **Blocking the UI thread during export/import:** Use `compute()` isolate for large datasets, or at minimum use `Future` microtasks with progress callbacks.
- **Storing encryption password or derived key:** Zero-knowledge means derive the key from the password on each encrypt/decrypt call, then discard.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| AES-256-GCM encryption | Custom cipher implementation | `cryptography` package `AesGcm` | Constant-time operations, platform-native, audited; crypto bugs are invisible and catastrophic |
| Password → key derivation | Manual PBKDF2/Argon2 with raw bytes | `cryptography` package `Argon2id` | Memory-hard KDF; correct parameter selection (iterations, memory, parallelism); salt generation |
| File picker dialog | Platform channels for file selection | `file_picker` ^11.0.0 | Handles SAF (Android), UIDocumentPicker (iOS), native dialogs per OS; permissions baked in |
| Share sheet | Platform-specific share intents | `share_plus` ^12.0.2 | Wraps ACTION_SEND (Android), UIActivityViewController (iOS), platform dialogs |
| Temporary file management | Manual temp dir + cleanup | `path_provider` `getTemporaryDirectory()` | OS-managed cleanup; correct per-platform paths |
| Base64 encoding | Custom encoder | `dart:convert` `base64Encode`/`base64Decode` | Standard, fast, correct padding handling |

**Key insight:** The encryption chain (Argon2id → AES-256-GCM) is the highest-risk component. A single implementation error (wrong nonce reuse, bad padding, timing leak) can silently destroy security. Use established libraries exclusively.

## Common Pitfalls

### Pitfall 1: file_picker Custom Extension Filtering Unreliable on Some Platforms
**What goes wrong:** `FileType.custom` with `allowedExtensions: ['luma']` may not filter correctly on all Android versions or file managers. Some file managers ignore extension hints.
**Why it happens:** Android's Storage Access Framework (SAF) relies on MIME types, not extensions. Custom extensions without registered MIME types may be ignored.
**How to avoid:** Use `FileType.custom` with `allowedExtensions: ['luma']` as the primary filter, but always validate the selected file's extension in Dart code after selection. If the extension is wrong, show a clear error: "Please select a .luma backup file."
**Warning signs:** Users report "no files visible" in the picker on certain devices.

### Pitfall 2: share_plus Linux Limitation
**What goes wrong:** `share_plus` does not support file sharing on Linux. Export fails silently or crashes.
**Why it happens:** Linux lacks a standard share sheet API. The package documents this limitation.
**How to avoid:** On Linux (and as a desktop fallback), use `file_picker`'s `saveFile()` dialog instead of the share sheet. Detect platform at runtime:
```dart
if (Platform.isLinux) {
  // Use file_picker saveFile dialog
} else {
  // Use share_plus share sheet
}
```
**Warning signs:** Export appears to succeed but file is never saved on Linux.

### Pitfall 3: JSON DateTime Serialization Inconsistency
**What goes wrong:** `DateTime.toIso8601String()` in Dart includes microseconds and timezone suffix inconsistently depending on whether the DateTime is UTC or local.
**Why it happens:** Dart's `DateTime` has UTC/local distinction that affects string representation.
**How to avoid:** Always normalize to UTC before serialization. Use a consistent format: `dateTime.toUtc().toIso8601String()`. On deserialization, always parse with `DateTime.parse()` which handles ISO 8601 correctly and preserves UTC flag.
**Warning signs:** Import fails on files exported from different timezone settings.

### Pitfall 4: Large Export Blocking UI Thread
**What goes wrong:** Exporting hundreds of periods with thousands of day entries on the main isolate causes jank or ANR.
**Why it happens:** JSON encoding + optional encryption is CPU-bound work.
**How to avoid:** For the JSON serialization + encryption step, use `Isolate.run()` (Dart 2.19+) or `compute()` to offload to a background isolate. Keep DB reads on the main isolate (Drift doesn't support cross-isolate access without setup). Pattern:
```dart
final rawData = await _readFromDb(); // main isolate
final bytes = await Isolate.run(() => _serializeAndEncrypt(rawData, password)); // background
```
**Warning signs:** Export progress bar freezes, app becomes unresponsive.

### Pitfall 5: Encryption Wrong-Password Detection
**What goes wrong:** AES-GCM decryption with wrong password throws a generic exception that's hard to distinguish from corrupted data.
**Why it happens:** GCM authentication tag verification fails identically for wrong key and corrupted ciphertext.
**How to avoid:** Catch the `SecretBoxAuthenticationError` (or equivalent from `cryptography` package) specifically and map it to a user-friendly "Incorrect password or corrupted file" message. Don't try to distinguish wrong-password from corruption — they're cryptographically indistinguishable.
**Warning signs:** Users see "unexpected error" instead of "wrong password" prompt.

### Pitfall 6: Auto-Backup File Accumulation
**What goes wrong:** Every import creates an auto-backup. Over time, the app's support directory fills with stale backups.
**Why it happens:** No retention policy; backups accumulate indefinitely.
**How to avoid:** Keep only the last N backups (recommend N=3). After creating a new backup, delete oldest files beyond the retention limit. Store backups in a dedicated subdirectory: `getApplicationSupportDirectory()/backups/`.
**Warning signs:** Disk usage grows unexpectedly; user storage warnings.

### Pitfall 7: Import Without Referential Integrity
**What goes wrong:** Imported day entries reference period IDs that don't exist in the target database, causing foreign key violations.
**Why it happens:** Exported data uses source-database auto-increment IDs; these IDs don't exist in the target DB.
**How to avoid:** During import, create periods first and capture their new IDs, then insert day entries with the new period IDs. Never use exported IDs as import IDs — they're for internal reference within the export file only.
**Warning signs:** Import fails with "FOREIGN KEY constraint failed" errors.

## Code Examples

### Example 1: Export JSON Schema Structure
```dart
// export_schema.dart
const int lumaFormatVersion = 1;

class LumaExportMeta {
  final int formatVersion;
  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final bool encrypted;
  final List<String> contentTypes;

  Map<String, dynamic> toJson() => {
    'format_version': formatVersion,
    'schema_version': schemaVersion,
    'app_version': appVersion,
    'exported_at': exportedAt.toUtc().toIso8601String(),
    'encrypted': encrypted,
    'content_types': contentTypes,
  };

  factory LumaExportMeta.fromJson(Map<String, dynamic> json) {
    // Validate required fields, throw typed errors
  }
}

class LumaExportData {
  final LumaExportMeta meta;
  final List<ExportedPeriod>? periods;
  final List<ExportedDayEntry>? dayEntries;
  // ...
}

class ExportedPeriod {
  final int refId; // internal reference within export file only
  final String startUtc;
  final String? endUtc;

  Map<String, dynamic> toJson() => {
    'ref_id': refId,
    'start_utc': startUtc,
    'end_utc': endUtc,
  };
}

class ExportedDayEntry {
  final int periodRefId; // references ExportedPeriod.refId within this file
  final String dateUtc;
  final int? flowIntensity;
  final int? painScore;
  final int? mood;
  final String? notes;
}
```

### Example 2: AES-256-GCM Encryption with Argon2id (cryptography package)
```dart
// luma_crypto.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class LumaCrypto {
  static const _nonceLength = 12;
  static const _saltLength = 16;

  static final _algorithm = AesGcm.with256bits();
  static final _kdf = Argon2id(
    parallelism: 2,
    memory: 19456,   // ~19 MB
    iterations: 2,
    hashLength: 32,  // 256 bits for AES-256
  );

  /// Encrypts [plaintext] bytes with a key derived from [password].
  /// Returns: salt(16) + nonce(12) + ciphertext + mac(16)
  static Future<Uint8List> encrypt(List<int> plaintext, String password) async {
    final salt = Uint8List(_saltLength);
    // Fill salt with secure random bytes
    fillBytesWithSecureRandom(salt);

    final secretKey = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
    );

    // Assemble: salt + nonce + ciphertext + mac
    final result = BytesBuilder();
    result.add(salt);
    result.add(secretBox.nonce);
    result.add(secretBox.cipherText);
    result.add(secretBox.mac.bytes);
    return result.toBytes();
  }

  /// Decrypts bytes produced by [encrypt]. Throws on wrong password.
  static Future<Uint8List> decrypt(List<int> encrypted, String password) async {
    final salt = Uint8List.sublistView(
      Uint8List.fromList(encrypted), 0, _saltLength);
    final nonce = Uint8List.sublistView(
      Uint8List.fromList(encrypted), _saltLength, _saltLength + _nonceLength);
    final cipherAndMac = Uint8List.sublistView(
      Uint8List.fromList(encrypted), _saltLength + _nonceLength);
    final macBytes = cipherAndMac.sublist(cipherAndMac.length - 16);
    final cipherText = cipherAndMac.sublist(0, cipherAndMac.length - 16);

    final secretKey = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final decrypted = await _algorithm.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(decrypted);
  }
}
```

### Example 3: Import Duplicate Detection
```dart
// import_preview.dart
class ImportPreview {
  final int newEntries;
  final int duplicateEntries;
  final int totalImported;

  static Future<ImportPreview> analyze(
    LumaExportData importData,
    PtrackDatabase db,
  ) async {
    final existingDays = <DateTime>{};
    final allDayEntries = await db.select(db.dayEntries).get();
    for (final entry in allDayEntries) {
      existingDays.add(DateTime.utc(
        entry.dateUtc.year, entry.dateUtc.month, entry.dateUtc.day,
      ));
    }

    int newCount = 0, dupCount = 0;
    for (final entry in importData.dayEntries ?? []) {
      final date = DateTime.parse(entry.dateUtc);
      final day = DateTime.utc(date.year, date.month, date.day);
      if (existingDays.contains(day)) {
        dupCount++;
      } else {
        newCount++;
      }
    }

    return ImportPreview(
      newEntries: newCount,
      duplicateEntries: dupCount,
      totalImported: (importData.periods?.length ?? 0),
    );
  }
}
```

### Example 4: File Pick + Validation
```dart
// In import flow
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['luma'],
  withData: true,
);

if (result == null || result.files.isEmpty) return; // user cancelled

final file = result.files.single;
final bytes = file.bytes;

if (bytes == null) {
  // Fallback: read from path (non-web)
  final fileObj = File(file.path!);
  bytes = await fileObj.readAsBytes();
}

// Validate extension as safety net
if (file.extension?.toLowerCase() != 'luma') {
  showError('Please select a .luma backup file.');
  return;
}

// Attempt parse
try {
  final content = utf8.decode(bytes);
  final json = jsonDecode(content) as Map<String, dynamic>;
  final meta = LumaExportMeta.fromJson(json['meta']);
  // ... proceed with encrypted check, version check, etc.
} on FormatException {
  showError('This file is not a valid Luma backup.');
}
```

### Example 5: Export via Share Sheet with Linux Fallback
```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

Future<void> deliverExport(List<int> bytes, String filename) async {
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/$filename');
  await tempFile.writeAsBytes(bytes);

  if (Platform.isLinux) {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save backup',
      fileName: filename,
    );
    if (savePath != null) {
      await File(savePath).writeAsBytes(bytes);
    }
  } else {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path)],
        text: 'Luma backup',
      ),
    );
  }

  // Clean up temp file
  if (await tempFile.exists()) {
    await tempFile.delete();
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| PBKDF2 for password KDF | Argon2id (memory-hard) | Argon2 won PHC 2015; standard since | More resistant to GPU/ASIC brute-force attacks |
| AES-CBC + separate HMAC | AES-GCM (authenticated encryption) | GCM standard since ~2007, widely adopted | Single-pass encrypt + authenticate; no MAC-then-encrypt bugs |
| `share` (old package) | `share_plus` (Flutter Community) | share_plus superseded share | Active maintenance, file sharing support, ShareResult feedback |
| `file_picker` < 10.x | `file_picker` 11.x | 2025-2026 | Better platform support, save-file dialog, stream support for large files |
| Manual isolate setup | `Isolate.run()` | Dart 2.19+ / Flutter 3.7+ | One-liner background computation; no port management |

**Deprecated/outdated:**
- `share` package: Superseded by `share_plus`; no longer maintained
- `encrypt` package: Thin wrapper around pointycastle; prefer `cryptography` for platform-native acceleration
- `file_picker` < 8.x: Significant API changes in 8+; use 11.x

## Open Questions

1. **Duplicate handling at period vs day-entry level**
   - What we know: CONTEXT.md says "same date" is the matching key, meaning day-level duplicate detection. An imported day entry on a date that already has an entry is a "duplicate."
   - What's unclear: When a new period is imported that overlaps an existing period in date range, should the periods themselves be merged, or should new periods always be created with only day entries deduplicated? If an imported period has no day entries (just a date span), how do we handle overlap with an existing period span?
   - Recommendation: Treat periods and day entries separately. Periods are imported as-is (date ranges). Day entries within those periods are deduplicated by date. If an imported period fully overlaps an existing period, don't create a duplicate period — merge the day entries into the existing period. If partially overlapping, create a new period for the non-overlapping portion. Document this clearly in the format spec and preview UI. **The planner should define the exact merge algorithm.**

2. **"Periods only" preset — what exactly is included?**
   - What we know: Two presets: "Everything" and "Periods only". User can also uncheck individual data types.
   - What's unclear: Does "Periods only" include just the period date ranges (start/end), or also the flow intensity (which is logged per-day as a day entry)?
   - Recommendation: "Periods only" exports period spans (start_utc, end_utc) WITHOUT day entries. "Everything" includes periods + all day entries (symptoms, flow, notes). The toggle granularity is: periods (spans), symptoms/flow (day entry flow + pain + mood fields), notes (day entry notes field). This maps cleanly to the `content_types` array in the metadata.

3. **Forward compatibility: importing from a newer format version**
   - What we know: The export includes `format_version` and `schema_version` markers.
   - What's unclear: Should the app attempt a best-effort import of files with a higher `format_version` than it knows, or reject them?
   - Recommendation: Reject files with unknown `format_version` (major version bump means breaking changes). Accept files with `schema_version` ≤ current app schema — the app knows how to map older schemas. Reject files with `schema_version` > current. Show error: "This backup was created by a newer version of Luma. Please update the app."

## Encryption Algorithm Decision

**Recommendation: AES-256-GCM + Argon2id** via the `cryptography` package.

**Why AES-256-GCM over AES-256-CBC:**
- GCM provides authenticated encryption (integrity + confidentiality) in one pass
- CBC requires a separate MAC step (encrypt-then-MAC) to prevent padding oracle attacks
- GCM is the modern standard for symmetric encryption

**Why Argon2id over PBKDF2:**
- Argon2id is memory-hard, making GPU/ASIC brute-force attacks impractical
- Won the Password Hashing Competition (2015); recommended by OWASP
- PBKDF2 with SHA-256 is still acceptable but Argon2id is the current best practice
- The `cryptography` package has Argon2id built in with sensible defaults

**Parameters:**
- Argon2id: parallelism=2, memory=19456 (19 MB), iterations=2, hashLength=32
- AES-GCM: 256-bit key, 12-byte nonce (random), 16-byte authentication tag
- Random salt: 16 bytes per encryption (stored alongside ciphertext)

These parameters balance security with mobile performance (key derivation takes ~200-500ms on modern phones, acceptable for a user-initiated operation).

## JSON Schema Design Decision

**Field naming convention:** snake_case (matches Dart DB column naming in Drift tables).

**Date format:** ISO 8601 UTC strings (`"2026-01-15T00:00:00.000Z"`). All dates normalized to UTC calendar midnight before serialization, consistent with existing `_calendarDateAsUtc` pattern in `day_entry_mapper.dart`.

**Internal references:** Exported periods get a sequential `ref_id` (1, 2, 3...) used only within the export file for day_entry→period association. These are NOT database IDs and are not used during import except to group day entries with their parent period.

**Null handling:** Null optional fields (e.g., `end_utc`, `flow_intensity`, `notes`) are omitted from JSON rather than serialized as `null`, keeping file size minimal.

## Auto-Backup Design Decision

**Location:** `getApplicationSupportDirectory()/luma_backups/`
**Format:** Same `.luma` format (unencrypted, "Everything" preset)
**Filename:** `auto-backup-YYYY-MM-DD-HHmmss.luma`
**Retention:** Keep last 3 auto-backups; delete oldest on new backup creation
**Trigger:** Created automatically before every import apply step
**Restore:** Settings > Data section shows "Restore from auto-backup" option listing available backups with timestamps

## Sources

### Primary (HIGH confidence)
- `cryptography` ^2.9.0 — pub.dev package page; AES-GCM and Argon2id APIs verified
- `share_plus` ^12.0.2 — pub.dev package page; file sharing via ShareParams/XFile confirmed
- `file_picker` ^11.0.0 — pub.dev package page; custom extension filter and saveFile dialog confirmed
- Existing codebase analysis — `ptrack_data` tables.dart, period_repository.dart, mappers, pubspec.yaml files
- `path_provider` ^2.1.5 — already in project; getApplicationSupportDirectory() for backup storage

### Secondary (MEDIUM confidence)
- file_picker custom extension issue #1658 — GitHub issue confirms some platforms may ignore custom extension filters; workaround: post-selection validation
- share_plus Linux limitation — documented in pub.dev; file sharing not supported on Linux; fallback to file_picker saveFile dialog
- Flutter JSON serialization guide — docs.flutter.dev; confirms dart:convert is sufficient for manual serialization

### Tertiary (LOW confidence)
- Argon2id parameter tuning — parameters based on OWASP recommendations and cryptography package defaults; may need performance testing on low-end Android devices

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages verified on pub.dev with current versions; codebase architecture understood from source
- Architecture: HIGH — patterns follow existing MVVM/ChangeNotifier conventions in the project; JSON schema is straightforward for the 2-table model
- Pitfalls: HIGH — file_picker extension issue verified via GitHub; share_plus Linux gap documented; encryption pitfalls are well-known patterns
- Encryption: MEDIUM — Argon2id parameters need validation on target devices; cryptography package API verified but encrypt/decrypt flow not tested end-to-end

**Research date:** 2026-04-06
**Valid until:** 2026-05-06 (stable domain; packages unlikely to break in 30 days)

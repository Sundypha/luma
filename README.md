# ptrack

Local-first period tracker (Flutter). Product specs live in [`period_tracker_prds/`](period_tracker_prds/).

## Security & privacy

Dependency and telemetry rules are documented in **[SECURITY.md](SECURITY.md)**. Read this before adding or upgrading packages.

**Android-first:** use the **Android SDK and an emulator or device** as your default local run target. Flutter supports iOS as well; iOS setup is not the primary early onboarding path for every contributor.

## Flutter SDK (FVM)

This repo pins Flutter **3.41.2** via [FVM](https://fvm.app/).

```bash
# Install FVM, then from repo root:
fvm install
fvm use 3.41.2
fvm flutter --version
```

## Workspace (Melos + Dart pub workspaces)

Packages live under `apps/` and `packages/`. The root `pubspec.yaml` declares a [pub workspace](https://dart.dev/tools/pub/workspaces).

**Melos calls `flutter` internally.** If `flutter` is not on your `PATH`, bootstrap fails with `'flutter' is not recognized` (common on Windows).

### Recommended (all platforms): run Melos through FVM

From the repo root, use **`fvm exec`** so Melos sees the project’s Flutter SDK:

```bash
fvm dart pub get
fvm dart pub global activate melos
fvm exec melos bootstrap
```

Analyze / test across packages:

```bash
fvm exec melos run ci:analyze
fvm exec melos run ci:test
```

There is no `fvm melos` subcommand — wrap Melos with `fvm exec` as above.

### Alternative: put Flutter on `PATH`

If you prefer bare `melos`:

- **macOS/Linux:** `export PATH="$HOME/fvm/versions/3.41.2/bin:$PATH"` (adjust version if `.fvm/fvm_config.json` changes).
- **Windows (PowerShell):** `$env:PATH = "C:\Users\<you>\fvm\versions\3.41.2\bin;" + $env:PATH`

Then `dart pub get`, `melos bootstrap`, etc.

### Windows: “Can’t load Kernel binary” when running `melos`

That usually means the global **Melos** binary was built with a different Dart than the one running it. Activate Melos with the **same** SDK as the project:

```powershell
fvm dart pub global activate melos
```

Then always run **`fvm exec melos …`** from this repo (or fix `PATH` as above).

## Run the app (Android-first)

```bash
cd apps/ptrack
fvm flutter run
```

Use an Android emulator or device with the Android SDK installed.

## Useful commands

```bash
cd apps/ptrack && fvm flutter analyze
cd apps/ptrack && fvm flutter test
```

From repo root (all packages), with FVM wrapping Melos:

```bash
fvm exec melos run ci:analyze
fvm exec melos run ci:test
```

## CI parity (same idea as GitHub Actions)

From the repository root (after `fvm install` / `fvm use`):

**Linux/macOS (CI adds FVM Flutter to `PATH`, then runs Melos):**

```bash
dart pub get
dart pub global activate melos
melos bootstrap
pip install pyyaml
python3 tool/ci/verify_pubspec_policy.py
melos exec -c 1 -- flutter analyze
melos exec -c 1 --dir-exists=test -- flutter test
```

**Windows (PowerShell) — use `fvm exec` so `flutter` is found:**

```powershell
fvm dart pub get
fvm dart pub global activate melos
fvm exec melos bootstrap
pip install pyyaml
python tool\ci\verify_pubspec_policy.py
fvm exec melos exec -c 1 -- flutter analyze
fvm exec melos exec -c 1 --dir-exists=test -- flutter test
```

These steps mirror `.github/workflows/ci.yml` (Ubuntu adds FVM’s `bin` to `PATH` before `melos`).

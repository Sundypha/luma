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

```bash
# Ensure the pinned Flutter SDK is on PATH so `melos` can run `flutter pub get`
# (example: prepend FVM’s SDK bin — adjust to your FVM cache path)
# macOS/Linux:
#   export PATH="$HOME/fvm/versions/3.41.2/bin:$PATH"
# Windows (PowerShell): prepend C:\Users\<you>\fvm\versions\3.41.2\bin

dart pub get
dart pub global activate melos
melos bootstrap
```

If `melos bootstrap` fails with `'flutter' is not recognized`, add the FVM Flutter `bin` directory for **3.41.2** to `PATH`, then retry.

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

Run tests in every package (from repo root, with `flutter` on PATH as above):

```bash
melos run ci:test
```

## CI parity (same idea as GitHub Actions)

From the repository root, after `fvm use` / `fvm install` and with **FVM’s Flutter `bin` on `PATH`** (see above):

```bash
dart pub get
dart pub global activate melos
melos bootstrap
pip install pyyaml   # or pip3
python3 tool/ci/verify_pubspec_policy.py
melos exec -c 1 -- flutter analyze
melos exec -c 1 --dir-exists=test -- flutter test
```

These steps mirror `.github/workflows/ci.yml` (Ubuntu). On Windows, use `python` instead of `python3` if needed.

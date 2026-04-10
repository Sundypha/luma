# Luma

A local-first period tracker built with Flutter. Your data stays on your device — no accounts, no cloud sync, no ads, no tracking.

## Why Luma?

Most popular cycle trackers harvest intimate health data to sell ads or feed opaque recommendation engines. Your menstrual cycle is not a product.

Luma exists because **period tracking should be private by default**. It stores everything locally on your phone, never phones home, and ships zero analytics or advertising SDKs. No sign-up, no account, no data leaving your device — ever.

## Features

### Cycle & symptom tracking
- Mark and unmark period days on a calendar; Luma derives period spans automatically.
- Log **flow intensity**, **pain**, **mood**, and free-text **notes** for any day.
- Visual calendar with colour-coded period bands (start/middle/end) and a clear legend.

### Smart predictions
- **Ensemble prediction engine** — combines up to four algorithms and shows a per-day confidence score:
  - **Median baseline** — sliding-window average with outlier removal.
  - **EWMA** — exponentially weighted moving average.
  - **Bayesian** — Normal–Inverse-Gamma model that works from just one logged cycle.
  - **Linear trend** — least-squares regression gated by R² (activates at 5+ cycles).
- Configurable prediction horizon (1, 3, or 6 future cycles).
- Milestone banners when enough data unlocks a new algorithm.

### Fertility window (optional)
- Calendar-method fertile-window estimate based on configurable luteal-phase length.
- Opt-in only, with a clear disclaimer that it is educational, not medical advice.

### Data you control
- **`.luma` export format** — plain JSON or password-encrypted backups.
- **Export wizard** — choose what to include (periods, symptoms, notes) and share the file however you like.
- **Import with preview** — see what's new vs duplicate before merging, with automatic pre-import backup.
- **Auto-backups** — keeps the three most recent snapshots on-device.
- **PDF reports** — summary, standard, or full detail; configurable date range, with print and share.

### Privacy & security
- **No analytics, crash-reporting, or ad SDKs** that touch reproductive-health data (enforced by CI policy).
- **App lock** — PIN protected with Argon2id hashing, optional biometric unlock.
- **Encrypted backups** — AES encryption for exported `.luma` files.
- Everything lives in a local SQLite database; nothing is transmitted.

### Localisation
- English and German, with device-language detection or manual override.

### Platform support
- Android-first. iOS, Linux, macOS, Windows, and web targets are present in the Flutter project structure.

## Getting started

### Prerequisites

- [FVM](https://fvm.app/) (Flutter Version Management)
- Android SDK with an emulator or device

### Setup

```bash
fvm install
fvm use 3.41.2
fvm dart pub get
fvm dart pub global activate melos
fvm exec melos bootstrap
```

### Run the app

```bash
cd apps/ptrack
fvm flutter run
```

### Analyse & test

```bash
fvm exec melos run ci:analyze
fvm exec melos run ci:test
```

### CI parity

The pubspec policy script needs **PyYAML**. Use [uv](https://docs.astral.sh/uv/getting-started/installation/):

```bash
uv run --python 3.12 --with pyyaml python3 tool/ci/verify_pubspec_policy.py
```

Full CI mirror (Linux/macOS):

```bash
dart pub get
dart pub global activate melos
melos bootstrap
uv run --python 3.12 --with pyyaml python3 tool/ci/verify_pubspec_policy.py
melos exec -c 1 -- flutter analyze
melos exec -c 1 --dir-exists=test -- flutter test
```

Windows (PowerShell) — use `fvm exec` so `flutter` is found:

```powershell
fvm dart pub get
fvm dart pub global activate melos
fvm exec melos bootstrap
uv run --python 3.12 --with pyyaml python tool\ci\verify_pubspec_policy.py
fvm exec melos exec -c 1 -- flutter analyze
fvm exec melos exec -c 1 --dir-exists=test -- flutter test
```

## Project structure

```
apps/ptrack          Flutter application (package name: luma)
packages/ptrack_domain   Domain models, prediction algorithms, validation
packages/ptrack_data     Database, repositories, import/export services
docs/                Additional documentation
tool/ci/             CI helper scripts
```

## Security

See [SECURITY.md](SECURITY.md) for the dependency and telemetry policy.

## License

Luma is released under the **MIT License** with an additional **health disclaimer**. See [LICENSE](LICENSE) for the full text.

**Luma is not a medical device.** Predictions and estimates are statistical approximations based on past data. They are not diagnoses, medical advice, or a substitute for professional healthcare. Do not rely on Luma for contraception, fertility planning, or any health decision. See the LICENSE for the complete disclaimer.

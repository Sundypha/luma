# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2026-04-10

### Added
- `tool/bump_version.dart` to bump `apps/ptrack` semver and Android `versionCode` (patch / minor / major, optional `--dry-run`)
- GitHub Actions **Release** workflow for `v*` tags: signed release APK, draft GitHub Release with changelog slice, optional Firebase App Distribution upload

### Changed
- Firebase App Distribution workflow documents that version-tagged releases should use the Release workflow; third-party Actions in CI workflows pinned to full commit SHAs
- App version **1.0.1+2** for release alignment; no functional changes to the Luma app since 1.0.0

## [1.0.0] - 2026-04-07

### Added
- Local-first menstrual cycle tracker (Flutter, FVM, melos monorepo)
- Period logging with symptom tracking via calendar and home card
- Ensemble next-period prediction with agreement-based confidence tiers
- Export/import of period data (.luma format with AES-GCM encryption)
- Optional app lock with biometric and PIN authentication
- Onboarding flow with inclusive, clinical copy
- Offline-first: no accounts, no required network

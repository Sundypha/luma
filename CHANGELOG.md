# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-04-14

### Added
- **Standalone diary**: dedicated tab, entries on any calendar day (not only logged period days), paginated list with search, date range filter, tag filters, and floating action button
- **Diary tags**: create, edit, and delete tags in settings; filter entries and assign multiple tags per entry
- **Schema v5** with `diary_entries`, `diary_tags`, and join table; upgrade from v4 migrates former in-row personal diary text into diary rows while **notes** stay on the day entry for clinical / PDF use
- **Backup format v2** can include diary data when export options enable it; importing older `.luma` files still maps legacy personal notes into diary entries

### Changed
- **Calendar** and **Today** surfaces show diary activity (day marker, legend) with shortcuts into the diary composer
- **Day detail** presents symptom logging and diary as separate moods and actions from one hub
- **Symptom form** no longer hosts personal free-text journaling; use Diary instead (supersedes the in-form personal notes flow introduced in 1.1.0)

### Fixed
- **Diary list** could show duplicate rows when a save and a database invalidation both triggered reload; reloads are now serialized with a pending pass so the list stays consistent

## [1.1.0] - 2026-04-12

### Added
- **Personal diary notes** on logged days: private free-text journaling in the symptom form, stored locally and included in encrypted backup/import, while existing **notes** remain the clinician- and PDF-oriented field

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

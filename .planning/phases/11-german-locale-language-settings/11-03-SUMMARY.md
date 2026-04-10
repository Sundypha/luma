---
phase: 11-german-locale-language-settings
plan: 03
subsystem: ui
tags: [flutter, i18n, intl, table_calendar, ci, arb]

requires:
  - phase: 11-german-locale-language-settings
    provides: Language settings and active MaterialApp locale (`11-02`)

provides:
  - TableCalendar wired to `Localizations.localeOf` and locale-first week start via MaterialLocalizations
  - Prediction copy dates and numeric steps formatted with `intl` + `AppLocalizations.localeName`
  - ICU plural ARB strings (methods, cycles, forecast months, milestone methods) in en/de
  - `tool/arb_de_key_parity.dart`, `melos run ci:arb`, and CI workflow step for I18N-05

affects:
  - Future calendar or prediction UI copy
  - Contributors adding ARB keys (must update `app_de.arb`)

tech-stack:
  added:
    - Explicit `intl` dependency on `luma` app package
  patterns:
    - Prefer `DateFormat` / `NumberFormat` with `l10n.localeName` for user-visible prediction narrative
    - ARB parity script compares non-@ keys between `app_en.arb` and `app_de.arb`

key-files:
  created:
    - tool/arb_de_key_parity.dart
  modified:
    - apps/ptrack/lib/features/calendar/calendar_screen.dart
    - apps/ptrack/lib/l10n/app_en.arb
    - apps/ptrack/lib/l10n/app_de.arb
    - apps/ptrack/lib/l10n/app_localizations.dart
    - apps/ptrack/lib/l10n/app_localizations_en.dart
    - apps/ptrack/lib/l10n/app_localizations_de.dart
    - apps/ptrack/lib/l10n/prediction_localizations.dart
    - apps/ptrack/pubspec.yaml
    - apps/ptrack/test/prediction_explanation_widget_test.dart
    - pubspec.yaml
    - pubspec.lock
    - .github/workflows/ci.yml

key-decisions:
  - "Week start follows `MaterialLocalizations.firstDayOfWeekIndex` mapped to table_calendar `StartingDayOfWeek` (no user toggle)."
  - "CI runs `dart run tool/arb_de_key_parity.dart` with workspace `dart pub get` (stable SDK on Actions); local dev uses `melos run ci:arb` (`fvm dart run`)."

patterns-established:
  - "DE ARB must be a key superset of EN message keys; extras in DE allowed."

requirements-completed: [I18N-04, I18N-05]

duration: 45min
completed: 2026-04-07
---

# Phase 11 Plan 03: Locale formatting and ARB CI guard summary

**TableCalendar and prediction copy use active locale for headers, week start, dates, decimals, and plurals; CI fails if German ARB drops any English message key.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-07 (executor session)
- **Completed:** 2026-04-07
- **Tasks:** 2
- **Files modified:** 13 (excluding generated l10n counted in task scope)

## Accomplishments

- Calendar month view uses `TableCalendar` `locale` and `startingDayOfWeek` derived from Flutter material locale defaults.
- `PredictionLocalizations` replaces ISO date literals and raw `toStringAsFixed` with `DateFormat.yMMMd` and `NumberFormat.decimalPattern` keyed by `AppLocalizations.localeName`.
- English and German ARBs gained ICU plural forms where grammar matters; calendar hint/legend/today strings moved into ARB.
- Repository script + `melos ci:arb` + GitHub Actions enforce DE ⊇ EN message keys.

## Task commits

1. **Task 1: Locale-aware dates and numbers in UI** — `7085b9c` (feat)
2. **Task 2: ARB key parity CI guard** — `60bbe45` (ci)

**Plan metadata:** Docs commit `docs(11-03): Record plan summary, state, and roadmap for phase 11 close` (see `git log -1 --oneline` on branch).

## Widgets and surfaces touched (verification traceability)

| Area | Widget / file | Notes |
|------|----------------|-------|
| Calendar | `CalendarScreen` | `TableCalendar` locale, week start, ARB strings for hint/legend/Today, load error via `homeCouldNotLoadPeriods` |
| Prediction copy | `PredictionLocalizations` | All user-facing dates in ensemble/coordinator narrative; decimal formatting for EWMA, Bayesian, linear trend |
| ARB | `app_en.arb` / `app_de.arb` | Plural messages: `homePredictionMethodsLine`, `predStepInsufficientHistory`, `dayDetailForecastMonthsTitle`, `dayDetailDisclaimerHopN`, `dayDetailDisclaimerHopNSpread`, `ensembleMilestoneExpanded`; new `calendar*` keys |

**Out of scope (per plan):** export/import filenames unchanged; `DayDetailSheet` / `SymptomFormSheet` not fully migrated to ARB in this task (dates there already use `MaterialLocalizations` where applicable).

## Contributor command (I18N-05)

From repository root (with FVM):

```bash
melos run ci:arb
```

Equivalent: `fvm dart run tool/arb_de_key_parity.dart`

## Decisions made

- Mapped material `firstDayOfWeekIndex` (Sunday = 0) to `StartingDayOfWeek` enum order (Monday-first indices).
- Parity check uses the same key set as typical gen-l10n usage: top-level ARB entries whose keys do not start with `@`.

## Deviations from plan

None - plan executed as written.

## Issues encountered

- Workspace `dart` on PATH below SDK `^3.11.0`; `melos ci:arb` uses `fvm dart run` so local runs match the FVM SDK. CI uses `setup-dart` stable after `pub get`, which satisfies the workspace constraint.

## User setup required

None.

## Next phase readiness

Phase 11 requirement set for I18N-04/I18N-05 is satisfied; roadmap can advance to phase 12 planning per `ROADMAP.md`.

---

## Self-check: PASSED

- `11-03-SUMMARY.md` present at `.planning/phases/11-german-locale-language-settings/11-03-SUMMARY.md`
- Task commits `7085b9c`, `60bbe45` and docs commit for this summary present on branch (`git log --oneline -5`)

---
*Phase: 11-german-locale-language-settings*  
*Completed: 2026-04-07*

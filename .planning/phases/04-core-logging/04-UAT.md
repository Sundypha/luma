---
status: diagnosed
phase: 04-core-logging
source:
  - 04-01-SUMMARY.md
  - 04-02-SUMMARY.md
  - 04-03-SUMMARY.md
started: 2026-04-05T18:00:00Z
updated: 2026-04-05T22:00:00Z
---

## Current Test

[code fixes landed — re-run Task 3 manual UAT on device]

## Tests

### 1. Phase 4 Task 3 — full logging flow (manual)
expected: FAB, bottom sheet, three-way period intent, edit period end buttons, pain labels, day logs on open period, validation, deletes
result: issue
reported: "Edit period: Ongoing/Change buttons wrong; day log on ongoing overlaps error; Pain Moderate truncated; date picker accessibility deprecation log on Android"
severity: major

## Summary

total: 1
passed: 0
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Edit period end shows Ongoing only when an end date is set; when ongoing, only Change; order Ongoing then Change so Change stays right-aligned"
  status: resolved
  reason: "User reported: Period end always showed both Change and Ongoing; ongoing should only clear a fixed end; order should be Ongoing then Change."
  severity: major
  test: 1
  root_cause: "Edit-period ListTile trailing always rendered both TextButtons regardless of _periodEditHasEnd."
  resolution: "Conditional trailing in `logging_bottom_sheet.dart`: ongoing → single Change; fixed end → Row(Ongoing, Change)."

- truth: "User can add daily logs for an ongoing period without insertPeriod overlap errors"
  status: resolved
  reason: "User reported: Only Start new vs End open; logging a day while a period is open tried insertPeriod and overlapped the open range."
  severity: blocker
  test: 1
  root_cause: "Create flow used a bool (start new vs end open); no path that only upserts a day entry on the open period id."
  resolution: "`_SheetCreateIntent` with Start new / Log day / End …; default Log day when an open period exists; `PeriodRepository.upsertDayEntryForPeriod`; end-open + day details uses upsert to avoid duplicate day rows."

- truth: "Pain level labels fit inside SegmentedButton segments (Moderate not truncated)"
  status: resolved
  reason: "User reported: Moderate shows as Modera."
  severity: minor
  test: 1
  root_cause: "Five full-word labels exceed equal segment width on typical phones."
  resolution: "`PainScore.compactLabel` in domain; pain `SegmentedButton` uses compact labels (e.g. Mod., V. sev.)."

- truth: "Opening the date picker does not emit Android accessibility deprecation warnings"
  status: failed
  reason: "User reported: AnnounceSemanticsEvent / AccessibilityBridge deprecation when opening date picker."
  severity: minor
  test: 1
  root_cause: "Flutter Material CalendarDatePicker still uses deprecated announcement path on some Android versions; tracked upstream (e.g. flutter/flutter#165510, #180096)."
  artifacts:
    - path: "Flutter SDK date_picker / calendar_date_picker"
  missing:
    - "Upgrade Flutter when framework fix ships; no reliable app-only workaround without replacing showDatePicker"

- truth: "User can add day logs to any period (including closed) from the home list; FAB log-day only covered open period"
  status: resolved
  severity: blocker
  test: 1
  root_cause: "`existingPeriod` without `existingDayEntry` always opened edit-dates sheet; no `addDayEntryForPeriod` path."
  resolution: "`addDayEntryForPeriod` + menu 'Log day in period' + tappable empty day row; `initialDate` defaults to period start; `upsertDayEntryForPeriod` matches rows by calendar UTC day."

- truth: "Shrinking period dates flags day entries that would fall outside the new span"
  status: resolved
  severity: major
  test: 1
  root_cause: "`updatePeriod` did not check day rows against new span."
  resolution: "`PeriodWriteBlockedByOrphanDayEntries`; dialog Remove vs New period; `updatePeriodDeletingOrphanDayEntries` / `updatePeriodSplittingOrphansIntoNewPeriod`; end-open flow uses same orphan resolver."

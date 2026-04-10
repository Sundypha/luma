---
phase: 12-optional-fertility-window-estimator
verified: 2026-04-08T12:00:00Z
approved: 2026-04-08
status: passed
score: 5/5 roadmap success criteria; 12-04 Task 3 UAT approved (owner: pass)
re_verification: false
gaps: []
human_verification:
  - test: "Fresh state (clear data or fresh install)"
    expected: "Home shows suggestion card (grayed if fewer than 2 complete cycles logged). Settings fertility switch is OFF. Calendar shows no fertility dots."
    why_human: "Install/state and visual gray-out require a device or emulator."
  - test: "Log 3+ periods across months"
    expected: "Data exists for downstream calendar/home estimates."
    why_human: "Realistic multi-month logging is manual."
  - test: "Suggestion card with enough data"
    expected: "Card is active (not grayed). Use **Enable** (opens Settings) or open Settings manually."
    why_human: "Opacity and affordance are visual."
  - test: "Enable flow"
    expected: "Toggle fertility ON → disclaimer bottom sheet → **I understand** → input form with auto-filled cycle length where applicable → adjust luteal slider → **Save** → toggle stays ON."
    why_human: "Modal sequence and form behavior need interactive verification."
  - test: "Calendar"
    expected: "Teal hatched-circle markers (same pattern as period predictions) on estimated fertile days; legend includes fertile (est.) entry; tap a fertile day → day detail shows estimated fertile day copy."
    why_human: "Marker pattern, contrast, and legend layout are visual/accessibility checks."
  - test: "Home card"
    expected: "**Fertile window** card with date range and **Estimate only** footer when enabled and a window can be computed."
    why_human: "Layout and readable date formatting on target devices."
  - test: "Disable"
    expected: "Toggle OFF → calendar dots and home fertility card disappear; re-enable skips disclaimer, inputs pre-filled."
    why_human: "Cross-screen consistency after navigation."
  - test: "Dismiss suggestion"
    expected: "With fertility OFF, dismiss suggestion (X) → card does not return after restart."
    why_human: "Persistence + prominence are behavioral."
  - test: "German locale"
    expected: "All fertility strings appear in German when DE is active."
    why_human: "Copy length and truncation in UI are human-judged."
  - test: "12-04 Task 3 approval"
    expected: "Owner types **approved** or files issues per `12-04-PLAN.md` resume signal after completing the checklist above."
    why_human: "Explicit human gate — **completed 2026-04-08** (user: pass)."
---

# Phase 12: Optional fertility window estimator — verification report

**Phase goal (ROADMAP):** Optional on-device fertile-window estimate: opt-in with limitations, input collection when needed, calendar and/or home visualization with non-color-only cues, clean disable, deterministic tested math (**FERT-01**–**FERT-05**).

**Verified:** 2026-04-08 (UTC)  
**Status:** **passed** — code, automated tests, and **12-04 Task 3 UAT** approved (owner sign-off: `pass`, 2026-04-08).  
**Re-verification:** Initial report amended after UAT.

## Goal achievement (code-backward)

### ROADMAP success criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Off by default; first opt-in shows limitations (**FERT-01**) | ✓ CODE VERIFIED | `FertilitySettings.loadEnabled()` → `prefs.getBool(...) ?? false` (`fertility_settings.dart`). `HomeViewModel` / `CalendarViewModel` default `_fertilityEnabled = false`. Disclaimer via `showFertilityDisclaimerSheet` before first enable when `loadDisclaimerAcknowledged()` is false; body from ARB `fertilityDisclaimerBody`. |
| 2 | If enabled and assumptions needed, prompt collects/confirms inputs (**FERT-02**) | ✓ CODE VERIFIED | On toggle ON: disclaimer (if needed) then `showFertilityInputSheet` with cycle length + luteal slider; persists via `SharedPreferences`. |
| 3 | Calendar and/or home show window with non-color-only distinction (**FERT-03**) | ✓ CODE + UAT | Teal **`ConfidenceHatchedCirclePainter` (`fertilityEstimate: true`)** — same hatch pattern as period predictions; `fertilityCalendarLegendLabel`; `day_detail_sheet` → `fertilityCalendarDayDetail`; home `_FertilityWindowHomeCard` with title, range, footer `fertilityHomeCardFooter`. |
| 4 | Disabling removes visuals/prompts; period data intact (**FERT-04**) | ✓ CODE VERIFIED | `_onChanged(false)` → `saveEnabled(false)` only; `_fertileDaysForStored` returns `null` when `!_fertilityEnabled`; home `_fertileWindow = null` when disabled. No period row deletion in fertility code paths. |
| 5 | On-device deterministic math, documented, with automated tests (**FERT-05**) | ✓ CODE VERIFIED | `fertility_window.dart` documents formula, assumptions, caveats; `ptrack_domain.dart` exports module; `prediction_copy.dart` includes `safe days` / `birth control` + tests. **`fvm flutter test`** (from `apps/ptrack`): `../../packages/ptrack_domain/test/fertility_window_test.dart` and `prediction_copy_test.dart` — all passed. |

**Score:** 5/5 criteria supported in code and core tests; **12-04 Task 3** UAT **approved**.

### Plan must-haves (12-01 — 12-04)

| Plan | Artifact / link | Status |
|------|-----------------|--------|
| 12-01 | `fertility_window.dart`, barrel export, forbidden phrases | ✓ Exists, substantive, wired into VMs |
| 12-01 | `fertility_window_test.dart` (≥80 lines) | ✓ ~134 lines, passing |
| 12-02 | `fertility_settings.dart` (≥150 lines) | ✓ ~483 lines; `SharedPreferences` load/save; tile + sheets |
| 12-02 | `FertilitySettingsTile` in `tab_shell.dart` `_SettingsScreen` | ✓ Wired with `repository`, `calendar`, `onFertilityToggled` |
| 12-02 | Fertility keys in `app_en.arb` / `app_de.arb` | ✓ Present (e.g. `fertilitySettingsTitle`, full block) |
| 12-03 | `isFertileDay`, teal fertility hatch (`fertilityEstimate`), VM `FertilityWindowCalculator` | ✓ `calendar_day_data.dart`, `calendar_painters.dart`, `calendar_view_model.dart` |
| 12-03 | Legend + day detail | ✓ `calendar_screen.dart` `showFertilityLegend: viewModel.fertilityEnabled`; `_fertilityDetailNote` used in `day_detail_sheet.dart` |
| 12-04 | `HomeViewModel` fertile window + suggestion state | ✓ `fertileWindow`, `showSuggestionCard`, `hasEnoughDataForFertility`, `updateFertilityEnabled`, `dismissSuggestionCard` |
| 12-04 | Home UI | ✓ `_FertilitySuggestionCard`, `_FertilityWindowHomeCard` in `home_screen.dart` |
| 12-04 | `tab_shell` → both VMs | ✓ `onFertilityToggled` calls `_calendarVm.updateFertilityEnabled` and `_homeVm.updateFertilityEnabled` |
| 12-04 | Task 3 human-verify | ✓ **Approved** 2026-04-08 |

### Requirements coverage (`REQUIREMENTS.md`)

| ID | Status | Notes |
|----|--------|-------|
| **FERT-01** | ✓ SATISFIED (code) | Opt-in + disclaimer + ARB copy |
| **FERT-02** | ✓ SATISFIED (code) | Input sheet + persistence |
| **FERT-03** | ✓ SATISFIED (code) | Calendar + home + text labels |
| **FERT-04** | ✓ SATISFIED (code) | Toggle off hides UI; settings retained |
| **FERT-05** | ✓ SATISFIED (code + tests) | Domain tests + documentation |

*REQUIREMENTS.md marks FERT-* complete; phase **12** closed in `ROADMAP.md` / `STATE.md` after Task 3 approval.*

### Anti-patterns (spot check)

Searched `fertility_settings.dart` for `TODO` / `FIXME` / `PLACEHOLDER` — no blocking hits (only benign `.toDouble()`). No empty fertility stubs found in traced paths.

### Automated tests run

- `fvm flutter test ../../packages/ptrack_domain/test/fertility_window_test.dart ../../packages/ptrack_domain/test/prediction_copy_test.dart` — **pass**
- `fvm flutter test test/features/home/home_view_model_test.dart test/features/calendar/calendar_day_data_test.dart test/calendar_painters_test.dart` — **pass**  
  *(Existing suite does not assert fertility-specific branches; fertility coverage is primarily domain + manual UAT.)*

### Gaps summary

**No code gaps** identified. **Phase sign-off:** complete after Task 3 approval.

---

_Verifier: Claude (gsd-verifier)_  
_Do not commit from this step — orchestrator bundles artifacts._

# Architectural Change: Migrate State Management to Riverpod

## Status

**Proposed** — input for next GSD phase planning.

## Executive Summary

The app's current `ChangeNotifier` + manual-DI architecture has reached its complexity ceiling. Phase 18 (diary table migration) exposed race conditions, duplicate stream subscriptions, and fragile manual wiring that required multiple rounds of bug fixes for what should have been a straightforward reactive list. Riverpod resolves every one of these issues structurally rather than with per-feature workarounds.

---

## Current Architecture

```
main.dart
  └─ constructs PtrackDatabase, PeriodRepository, DiaryRepository
       └─ passes them as constructor args to LumaApp
            └─ passes them as constructor args to TabShell
                 └─ TabShell.initState() constructs:
                      ├─ HomeViewModel(repo, calendar, diaryRepo)
                      ├─ CalendarViewModel(repo, calendar, diaryRepo)
                      └─ DiaryViewModel(diaryRepo)
                           └─ each VM manually subscribes to Drift streams
                           └─ each VM manually cancels subscriptions in dispose()
```

### ViewModels (9 total, all ChangeNotifier)

| ViewModel | Dependencies | Stream subscriptions |
|-----------|-------------|---------------------|
| HomeViewModel | PeriodRepository, PeriodCalendarContext, DiaryRepository | `watchPeriodsWithDays()`, `watchAllEntries()` |
| CalendarViewModel | PeriodRepository, PeriodCalendarContext, DiaryRepository | `watchPeriodsWithDays()`, `watchAllEntries()` |
| DiaryViewModel | DiaryRepository | `watchEntryCount()` |
| PdfExportViewModel | PeriodRepository, PeriodCalendarContext | one-shot `.first` |
| ImportViewModel | ImportService, PtrackDatabase | none |
| ExportViewModel | (none — service passed to method) | none |
| LockViewModel | LockService | none |
| SymptomFormViewModel | PeriodRepository + day/period/entry | none |

---

## Problems Encountered (Phase 18 evidence)

### 1. Race conditions from manual reload coordination

The diary FAB saves an entry, then two things happen: the Drift `watchEntryCount()` stream fires `reload()`, and the FAB handler also calls `reload()`. Both clear the list and fetch page 1 concurrently, appending the same entries twice — every record appeared duplicated.

**Fix required**: A `_reloadPending` flag as a manual concurrency guard. This is a symptom of imperative state management where the developer must reason about every possible call ordering. With Riverpod, `ref.invalidate()` coalesces automatically — no user-written guards needed.

### 2. Duplicate Drift stream subscriptions (wasted resources)

`HomeViewModel` and `CalendarViewModel` both independently subscribe to:
- `watchPeriodsWithDays()` — triggers two separate SQLite watch queries on `periods` + `day_entries`
- `watchAllEntries()` — triggers two separate SQLite watch queries on `diary_entries`

That is **4 active Drift watchers** for data that could be served by **2 shared providers**. Each redundant watcher means extra SQLite polling, extra deserialization, and extra GC pressure.

### 3. Manual dependency threading ("prop drilling")

`DiaryRepository` is constructed in `main.dart` and threaded through **5 layers** of widget constructors before it reaches `DiaryFormSheet`:

```
main.dart → LumaApp → TabShell → DiaryScreen → _DiaryEntryCard → showDiaryFormSheet
main.dart → LumaApp → TabShell → HomeScreen → TodayCard → showDiaryFormSheet
main.dart → LumaApp → TabShell → CalendarScreen → DayDetailSheet → showDiaryFormSheet
```

Every intermediate widget must declare and forward the parameter even though it doesn't use it. Adding a new repository or service means editing every widget in every forwarding chain.

### 4. Lifecycle management is error-prone

Every ViewModel with streams must:
1. Declare a `StreamSubscription?` field
2. Assign it in the constructor or `init()`
3. Cancel it in `dispose()`
4. Hope that the widget actually calls `dispose()` at the right time

`TabShell.dispose()` manually calls `.dispose()` on three ViewModels. If a new VM is added and the developer forgets to add the dispose call, streams leak silently. Riverpod's `ref.onDispose` and `autoDispose` handle this structurally.

### 5. No shared reactive state between screens

When the diary form saves an entry from the Calendar tab's day-detail sheet, the Diary tab's list must update. Currently this only works because `DiaryViewModel` has its own stream subscription to `watchEntryCount()`. But the data flow is indirect and fragile:

```
DayDetailSheet → diaryRepository.saveEntry() → SQLite table changes
  → Drift polls and fires watchEntryCount() → DiaryViewModel.reload()
  → Drift polls and fires watchAllEntries() → CalendarViewModel rebuilds
  → Drift polls and fires watchAllEntries() → HomeViewModel rebuilds
```

Three independent stream subscriptions react to the same write. With Riverpod, a single `diaryEntriesProvider` would invalidate once, and all consumers (diary list, calendar dots, home card) would rebuild from the same cached state.

### 6. Cannot scope or override dependencies for testing

Widget tests for screens that need a `DiaryRepository` must construct the entire dependency chain from `PtrackDatabase` upward. There is no way to inject a mock repository without modifying the widget's constructor signature or adding a test-only parameter. Riverpod's `ProviderScope.overrides` solves this in one line.

---

## Why Riverpod (not Provider, Bloc, or keeping ChangeNotifier)

| Criterion | ChangeNotifier (current) | Provider | Bloc | Riverpod |
|-----------|-------------------------|----------|------|----------|
| Compile-safe DI | No | Partial (runtime `ProviderNotFoundException`) | No (uses Provider) | Yes (`ref.watch` is typed, no runtime lookups) |
| Auto-dispose | Manual | Manual | Manual (via `BlocProvider`) | Built-in `autoDispose` |
| Shared state dedup | Manual stream mgmt | Possible but verbose | Possible | Native — providers are singletons within scope |
| Coalesced invalidation | Must implement yourself | No | Streams only | `ref.invalidate()` coalesces rebuilds |
| Test overrides | Constructor injection only | `ProviderScope` but runtime-typed | `BlocProvider.value` | `ProviderScope.overrides` with compile-time safety |
| Pagination + reactivity | Race-prone (as demonstrated) | Same issue | Can model, but complex | `AsyncNotifierProvider` + `ref.invalidateSelf()` |
| Code generation | N/A | N/A | N/A | `@riverpod` annotation eliminates boilerplate |

The project already uses **Drift code generation** and **build_runner**, so adding Riverpod's `@riverpod` codegen has zero new tooling cost.

---

## Migration Scope

### New packages to add

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

dev_dependencies:
  riverpod_generator: ^2.6.5
  riverpod_lint: ^2.6.5
```

### Phase structure (suggested breakdown)

#### Wave 1: Foundation (no UI changes)

1. **Repository providers** — wrap `PtrackDatabase`, `PeriodRepository`, `DiaryRepository`, `PeriodCalendarContext` as Riverpod providers. Keep the existing classes unchanged.
2. **ProviderScope** — wrap `LumaApp` in `ProviderScope`. Pass database instance via `ProviderScope.overrides` from `main.dart`.
3. **Smoke test** — app boots and behaves identically, all state still comes from ChangeNotifier VMs.

#### Wave 2: Shared data layer

4. **`periodsWithDaysProvider`** — single `StreamProvider` replacing the two duplicate `watchPeriodsWithDays()` subscriptions in Home and Calendar VMs.
5. **`diaryEntriesProvider`** — single `StreamProvider` for `watchAllEntries()`, consumed by Calendar (dots) and Home (today card). Replaces two duplicate subscriptions.
6. **`diaryEntryCountProvider`** — `StreamProvider<int>` replacing the manual `watchEntryCount()` + `StreamSubscription` in DiaryViewModel.

#### Wave 3: ViewModel migration (screen by screen)

7. **DiaryViewModel → `diaryNotifierProvider`** — `AsyncNotifier` with paginated loading. Watches `diaryEntryCountProvider` for invalidation. Eliminates manual `StreamSubscription`, `_reloadPending` guard, and `dispose()`.
8. **HomeViewModel → `homeNotifierProvider`** — watches shared `periodsWithDaysProvider` and `diaryEntriesProvider`. Eliminates two manual subscriptions.
9. **CalendarViewModel → `calendarNotifierProvider`** — same shared providers, eliminates two more manual subscriptions.
10. **Remaining VMs** (PdfExport, Import, Export, Lock, SymptomForm) — simpler migrations, most have no streams.

#### Wave 4: Cleanup

11. **Remove prop drilling** — screens read repositories from `ref.watch(repositoryProvider)` instead of constructor parameters. Simplify widget signatures throughout.
12. **Remove `TabShell` VM lifecycle code** — no more manual `initState` / `dispose` for VMs.
13. **Test refactor** — use `ProviderScope.overrides` for widget tests with mock repositories.

### Files affected (estimated)

| Area | Files | Complexity |
|------|-------|------------|
| New provider definitions | ~6 new files | Low |
| ViewModel rewrites | 8 files | Medium |
| Screen widget updates | ~12 files | Low (remove constructor params, add `ConsumerWidget`) |
| `main.dart` + `tab_shell.dart` | 2 files | Medium (remove manual wiring) |
| Tests | ~8 files | Low-Medium |
| **Total** | **~36 files** | |

---

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Large diff, hard to review | Wave-based approach: each wave is a self-contained PR that keeps the app working |
| Learning curve for contributors | Riverpod lint rules catch common mistakes at analysis time; codegen reduces boilerplate |
| Drift + Riverpod integration unknowns | Well-documented pattern: `StreamProvider` wrapping Drift `.watch()` queries. Multiple open-source examples. |
| Regression in existing features | Each wave includes running the full test suite. Wave 1 changes zero behavior. |

---

## Success Criteria

- [ ] Zero manual `StreamSubscription` fields in any ViewModel
- [ ] Zero duplicate Drift stream watchers for the same query
- [ ] `DiaryRepository` is accessible from any widget via `ref.watch` — no prop drilling
- [ ] The diary duplication race condition is structurally impossible (no manual reload guards)
- [ ] Widget tests can override any repository with a mock in one line
- [ ] `fvm flutter analyze` clean, all existing tests pass

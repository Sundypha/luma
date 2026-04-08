import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../../l10n/app_localizations.dart';
import '../calendar/calendar_screen.dart';
import '../calendar/calendar_view_model.dart';
import '../home/home_screen.dart';
import '../home/home_view_model.dart';
import '../logging/symptom_form_sheet.dart';
import '../backup/data_settings_screen.dart';
import '../pdf_export/pdf_export_screen.dart';
import '../lock/lock_service.dart';
import '../lock/lock_settings_tile.dart';
import '../settings/about_screen.dart';
import '../settings/app_language_settings.dart';
import '../settings/fertility_settings.dart';
import '../settings/mood_settings.dart';
import '../settings/prediction_settings.dart';

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen({
    required this.repository,
    required this.calendar,
    required this.lockService,
    required this.onReset,
    required this.onLockNow,
    this.onModeChanged,
    this.onEnabledAlgorithmsChanged,
    this.onHorizonChanged,
    this.onFertilityToggled,
  });

  final PeriodRepository repository;
  final PeriodCalendarContext calendar;
  final LockService lockService;
  final VoidCallback onReset;
  final VoidCallback onLockNow;
  final ValueChanged<PredictionDisplayMode>? onModeChanged;
  final ValueChanged<Set<AlgorithmId>>? onEnabledAlgorithmsChanged;
  final ValueChanged<int>? onHorizonChanged;
  final ValueChanged<bool>? onFertilityToggled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          const AppLanguageSettingsSection(),
          const Divider(),
          const MoodSettingsTile(),
          const Divider(),
          PredictionSettingsTile(
            onModeChanged: onModeChanged,
            onEnabledAlgorithmsChanged: onEnabledAlgorithmsChanged,
            onHorizonChanged: onHorizonChanged,
          ),
          const Divider(),
          FertilitySettingsTile(
            repository: repository,
            calendar: calendar,
            onFertilityToggled: onFertilityToggled,
          ),
          const Divider(),
          LockSettingsTile(
            lockService: lockService,
            onReset: onReset,
            onLockNow: onLockNow,
          ),
        ],
      ),
    );
  }
}

/// Root shell after onboarding: bottom tabs, drawer, and global FAB for logging.
class TabShell extends StatefulWidget {
  const TabShell({
    super.key,
    required this.repository,
    required this.calendar,
    required this.lockService,
    required this.onReset,
    required this.onLockNow,
    this.initialPeriodsWithDays,
  });

  final PeriodRepository repository;
  final PeriodCalendarContext calendar;

  /// When non-null, home and calendar ViewModels start with data (no loading flash).
  final List<StoredPeriodWithDays>? initialPeriodsWithDays;
  final LockService lockService;
  final VoidCallback onReset;
  final VoidCallback onLockNow;

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  int _tabIndex = 0;
  late final CalendarViewModel _calendarVm;
  late final HomeViewModel _homeVm;

  @override
  void initState() {
    super.initState();
    _calendarVm = CalendarViewModel(
      widget.repository,
      widget.calendar,
      initialData: widget.initialPeriodsWithDays,
    );
    _homeVm = HomeViewModel(
      widget.repository,
      widget.calendar,
      initialData: widget.initialPeriodsWithDays,
    );
  }

  @override
  void dispose() {
    _calendarVm.dispose();
    _homeVm.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _SettingsScreen(
          repository: widget.repository,
          calendar: widget.calendar,
          lockService: widget.lockService,
          onReset: widget.onReset,
          onLockNow: widget.onLockNow,
          onModeChanged: (mode) => unawaited(_calendarVm.updateDisplayMode(mode)),
          onEnabledAlgorithmsChanged: (ids) {
            unawaited(_calendarVm.updateEnabledAlgorithms(ids));
            unawaited(_homeVm.updateEnabledAlgorithms(ids));
          },
          onHorizonChanged: (horizon) {
            unawaited(_calendarVm.updateHorizonCycles(horizon));
            unawaited(_homeVm.updateHorizonCycles(horizon));
          },
          onFertilityToggled: (enabled) {
            unawaited(_calendarVm.updateFertilityEnabled(enabled));
            unawaited(_homeVm.updateFertilityEnabled(enabled));
          },
        ),
      ),
    );
  }

  void _onFabPressed(BuildContext context) {
    if (!_homeVm.isTodayMarked) {
      _homeVm.markToday();
      return;
    }
    final today = DateTime.now();
    final dayUtc = DateTime.utc(today.year, today.month, today.day);
    final periodId = _homeVm.todayPeriodId;
    if (periodId == null) return;
    showSymptomFormSheet(
      context,
      repository: widget.repository,
      day: dayUtc,
      periodId: periodId,
      existing: _homeVm.todayStoredEntry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (_tabIndex == 0)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: l10n.pdfExportTitle,
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PdfExportScreen(
                      repository: widget.repository,
                      calendar: widget.calendar,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      drawer: NavigationDrawer(
        onDestinationSelected: (index) {
          Navigator.pop(context);
          if (index == 0) {
            _openSettings(context);
          } else if (index == 1) {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => DataSettingsScreen(
                  repository: widget.repository,
                  calendar: widget.calendar,
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => const AboutScreen(),
              ),
            );
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '1.0.0+1',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: Text(l10n.drawerSettingsLabel),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: Text(l10n.drawerDataLabel),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.info_outline),
            selectedIcon: const Icon(Icons.info),
            label: Text(l10n.drawerAboutLabel),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeScreen(
            viewModel: _homeVm,
            onOpenSettings: () => _openSettings(context),
          ),
          CalendarScreen(viewModel: _calendarVm),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navCalendar,
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _homeVm,
        builder: (context, _) {
          final marked = _homeVm.isTodayMarked;
          return FloatingActionButton(
            tooltip: marked ? l10n.fabTooltipAddSymptoms : l10n.fabTooltipMarkToday,
            onPressed: () => _onFabPressed(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

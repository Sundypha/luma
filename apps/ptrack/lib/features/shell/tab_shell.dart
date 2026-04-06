import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../calendar/calendar_screen.dart';
import '../calendar/calendar_view_model.dart';
import '../home/home_screen.dart';
import '../home/home_view_model.dart';
import '../logging/symptom_form_sheet.dart';
import '../backup/data_settings_screen.dart';
import '../lock/lock_service.dart';
import '../lock/lock_settings_tile.dart';
import '../settings/about_screen.dart';
import '../settings/mood_settings.dart';

/// Root shell after onboarding: bottom tabs, drawer, and global FAB for logging.
class TabShell extends StatefulWidget {
  const TabShell({
    super.key,
    required this.repository,
    required this.calendar,
    required this.lockService,
    required this.onReset,
    required this.onLockNow,
  });

  final PeriodRepository repository;
  final PeriodCalendarContext calendar;
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
    _calendarVm = CalendarViewModel(widget.repository, widget.calendar);
    _homeVm = HomeViewModel(widget.repository, widget.calendar);
  }

  @override
  void dispose() {
    _calendarVm.dispose();
    _homeVm.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MoodSettingsTile(),
              const Divider(),
              LockSettingsTile(
                lockService: widget.lockService,
                onReset: widget.onReset,
                onLockNow: widget.onLockNow,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luma'),
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
                  'Luma',
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
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Settings'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: Text('Data'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: Text('About'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeScreen(viewModel: _homeVm),
          CalendarScreen(viewModel: _calendarVm),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _homeVm,
        builder: (context, _) {
          final marked = _homeVm.isTodayMarked;
          return FloatingActionButton(
            tooltip: marked ? 'Add symptoms' : 'Mark today',
            onPressed: () => _onFabPressed(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

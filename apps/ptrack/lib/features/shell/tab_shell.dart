import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../calendar/calendar_screen.dart';
import '../calendar/calendar_view_model.dart';
import '../home/home_screen.dart';
import '../home/home_view_model.dart';
import '../logging/logging_bottom_sheet.dart';
import '../settings/about_screen.dart';
import '../settings/mood_settings.dart';

/// Root shell after onboarding: bottom tabs, drawer, and global FAB for logging.
class TabShell extends StatefulWidget {
  const TabShell({
    super.key,
    required this.repository,
    required this.calendar,
  });

  final PeriodRepository repository;
  final PeriodCalendarContext calendar;

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
        content: const SingleChildScrollView(
          child: MoodSettingsTile(),
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
    showLoggingBottomSheet(
      context,
      repository: widget.repository,
      calendar: widget.calendar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ptrack'),
      ),
      drawer: NavigationDrawer(
        onDestinationSelected: (index) {
          Navigator.pop(context);
          if (index == 0) {
            _openSettings(context);
          } else if (index == 1) {
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
                  'ptrack',
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

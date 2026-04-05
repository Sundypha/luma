import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'features/logging/home_screen.dart';
import 'features/onboarding/first_log_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/onboarding_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final onboardingState = await OnboardingState.create();
  final db = openPtrackDatabase();
  final calendar = calendarForDevice();
  final repository = PeriodRepository(database: db, calendar: calendar);
  final periods = await repository.listOrderedByStartUtc();

  final AppScreen initialScreen;
  if (!onboardingState.isCompleted) {
    initialScreen = AppScreen.onboarding;
  } else if (periods.isEmpty) {
    initialScreen = AppScreen.firstLog;
  } else {
    initialScreen = AppScreen.home;
  }

  runApp(
    PtrackApp(
      onboardingState: onboardingState,
      repository: repository,
      database: db,
      calendar: calendar,
      initialScreen: initialScreen,
    ),
  );
}

/// Resolves [PeriodCalendarContext] using the device zone when IANA lookup works.
///
/// Falls back to UTC if names are abbreviations or unknown. Apps may refine this
/// later (e.g. platform channel for canonical IANA id).
PeriodCalendarContext calendarForDevice() {
  for (final name in <String>{tz.local.name, DateTime.now().timeZoneName}) {
    if (name.isEmpty) continue;
    try {
      return PeriodCalendarContext.fromTimeZoneName(name);
    } on Object {
      continue;
    }
  }
  return PeriodCalendarContext.fromTimeZoneName('UTC');
}

enum AppScreen { onboarding, firstLog, home }

class PtrackApp extends StatefulWidget {
  const PtrackApp({
    super.key,
    this.onboardingState,
    this.repository,
    this.database,
    this.calendar,
    this.initialScreen,
    this.homeOverride,
  }) : assert(
          homeOverride != null ||
              (onboardingState != null &&
                  repository != null &&
                  database != null &&
                  calendar != null &&
                  initialScreen != null),
        );

  /// When set, [MaterialApp] uses this home and ignores routing fields (tests).
  final Widget? homeOverride;

  final OnboardingState? onboardingState;
  final PeriodRepository? repository;
  final PtrackDatabase? database;
  final PeriodCalendarContext? calendar;
  final AppScreen? initialScreen;

  @override
  State<PtrackApp> createState() => _PtrackAppState();
}

class _PtrackAppState extends State<PtrackApp> {
  late AppScreen _screen;

  @override
  void initState() {
    super.initState();
    _screen = widget.homeOverride != null
        ? AppScreen.home
        : widget.initialScreen!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    );

    if (widget.homeOverride != null) {
      return MaterialApp(
        title: 'ptrack',
        theme: theme,
        home: widget.homeOverride,
      );
    }

    final onboardingState = widget.onboardingState!;
    final repository = widget.repository!;
    final database = widget.database!;
    final calendar = widget.calendar!;

    Widget home;
    switch (_screen) {
      case AppScreen.onboarding:
        home = OnboardingScreen(
          onboardingState: onboardingState,
          onComplete: () => setState(() => _screen = AppScreen.firstLog),
        );
      case AppScreen.firstLog:
        home = FirstLogScreen(
          repository: repository,
          onComplete: () => setState(() => _screen = AppScreen.home),
        );
      case AppScreen.home:
        home = HomeScreen(
          repository: repository,
          database: database,
          calendar: calendar,
        );
    }

    return MaterialApp(
      title: 'ptrack',
      theme: theme,
      home: home,
    );
  }
}

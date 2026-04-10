import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'features/lock/delete_ptrack_db_file.dart';
import 'features/lock/reset_ptrack_database_file.dart';
import 'features/lock/lock_gate.dart';
import 'features/lock/lock_service.dart';
import 'features/settings/app_language_settings.dart';
import 'features/shell/tab_shell.dart';
import 'features/onboarding/first_log_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/onboarding_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final onboardingState = await OnboardingState.create();
  final prefs = await SharedPreferences.getInstance();
  final appLanguagePreference = await AppLanguageSettings.load(prefs: prefs);
  final lockService = LockService(prefs: prefs);
  final db = openPtrackDatabase();
  final calendar = calendarForDevice();
  final repository = PeriodRepository(database: db, calendar: calendar);
  final periods = await repository.listOrderedByStartUtc();
  final periodsWithDays = await repository.watchPeriodsWithDays().first;

  final AppScreen initialScreen;
  if (!onboardingState.isCompleted) {
    initialScreen = AppScreen.onboarding;
  } else if (periods.isEmpty) {
    initialScreen = AppScreen.firstLog;
  } else {
    initialScreen = AppScreen.home;
  }

  runApp(
    LumaApp(
      onboardingState: onboardingState,
      repository: repository,
      database: db,
      calendar: calendar,
      initialScreen: initialScreen,
      lockService: lockService,
      appLanguagePreference: appLanguagePreference,
      initialPeriodsWithDays: periodsWithDays,
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

class LumaApp extends StatefulWidget {
  const LumaApp({
    super.key,
    this.onboardingState,
    this.repository,
    this.database,
    this.calendar,
    this.initialScreen,
    this.lockService,
    this.homeOverride,
    this.appLanguagePreference = AppLanguagePreference.followDevice,
    this.initialPeriodsWithDays,
    this.deletePtrackDatabaseOverride,
    this.onAfterPtrackDbDelete,
  }) : assert(
          homeOverride != null ||
              (onboardingState != null &&
                  repository != null &&
                  database != null &&
                  calendar != null &&
                  initialScreen != null &&
                  lockService != null),
        );

  /// When set, [MaterialApp] uses this home and ignores routing fields (tests).
  final Widget? homeOverride;

  final OnboardingState? onboardingState;
  final PeriodRepository? repository;
  final PtrackDatabase? database;
  final PeriodCalendarContext? calendar;
  final AppScreen? initialScreen;
  final LockService? lockService;
  final AppLanguagePreference appLanguagePreference;
  final List<StoredPeriodWithDays>? initialPeriodsWithDays;

  /// When set (e.g. tests), replaces [deletePtrackDatabaseFileIfExists] during reset.
  final Future<PtrackDbDeleteResult> Function()? deletePtrackDatabaseOverride;

  /// Optional hook after the DB file delete attempt (e.g. tests asserting outcomes).
  final void Function(PtrackDbDeleteResult result)? onAfterPtrackDbDelete;

  @override
  State<LumaApp> createState() => _LumaAppState();
}

class _LumaAppState extends State<LumaApp> {
  late AppScreen _screen;
  final ValueNotifier<int> _lockNowSignal = ValueNotifier<int>(0);
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _screen = widget.homeOverride != null
        ? AppScreen.home
        : widget.initialScreen!;
  }

  @override
  void dispose() {
    _lockNowSignal.dispose();
    super.dispose();
  }

  /// [MaterialApp.locale] and [MaterialApp.localeListResolutionCallback] from
  /// cold-start preference (manual language changes apply after restart).
  ({
    Locale? locale,
    Locale? Function(List<Locale>?, Iterable<Locale>)? localeListResolutionCallback,
  }) _localeFromPreference() {
    final pref = widget.appLanguagePreference;
    return switch (pref) {
      AppLanguagePreference.followDevice => (
          locale: null,
          localeListResolutionCallback:
              (locales, supported) =>
                  AppLanguageSettings.resolveFromDeviceLocales(locales),
        ),
      AppLanguagePreference.english => (
          locale: const Locale('en'),
          localeListResolutionCallback: null,
        ),
      AppLanguagePreference.german => (
          locale: const Locale('de'),
          localeListResolutionCallback: null,
        ),
    };
  }

  Future<void> _resetApp() async {
    await widget.lockService?.deletePinData();
    await widget.lockService?.disableLock();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await widget.onboardingState?.reloadFromPlatform();
    await deleteDbEncryptionKey();
    await closeAndDeletePtrackDatabaseFile(
      closeDatabase: () async {
        await widget.database?.close();
      },
      deleteDatabaseFile: () async {
        final override = widget.deletePtrackDatabaseOverride;
        if (override != null) {
          return override();
        }
        return deletePtrackDatabaseFileIfExists();
      },
      onAfterDelete: widget.onAfterPtrackDbDelete,
    );
    if (mounted) {
      setState(() => _screen = AppScreen.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
    );
    final (:locale, :localeListResolutionCallback) = _localeFromPreference();

    if (widget.homeOverride != null) {
      return MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: theme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        localeListResolutionCallback: localeListResolutionCallback,
        home: widget.homeOverride,
      );
    }

    final onboardingState = widget.onboardingState!;
    final repository = widget.repository!;
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
        home = LockGate(
          lockService: widget.lockService!,
          lockNowSignal: _lockNowSignal,
          onBeforeLock: () {
            _rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
          },
          onReset: () {
            _resetApp();
          },
          child: TabShell(
            repository: repository,
            calendar: calendar,
            lockService: widget.lockService!,
            onReset: () {
              _resetApp();
            },
            onLockNow: () => _lockNowSignal.value++,
            initialPeriodsWithDays: widget.initialPeriodsWithDays,
          ),
        );
    }

    return MaterialApp(
      navigatorKey: _rootNavigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: theme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      localeListResolutionCallback: localeListResolutionCallback,
      home: home,
    );
  }
}

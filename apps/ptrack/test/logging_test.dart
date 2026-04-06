import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:luma/features/logging/symptom_form_sheet.dart';
import 'package:luma/features/lock/lock_service.dart';
import 'package:luma/features/settings/mood_settings.dart';
import 'package:luma/features/shell/tab_shell.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class MockPeriodRepository extends Mock implements PeriodRepository {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

/// Closed span that includes today so [HomeViewModel.isTodayMarked] is true.
StoredPeriodWithDays closedPeriodContainingToday() {
  final now = DateTime.now();
  final todayUtc = DateTime.utc(now.year, now.month, now.day);
  final startUtc = todayUtc.subtract(const Duration(days: 3));
  final endUtc = todayUtc.add(const Duration(days: 2));
  return StoredPeriodWithDays(
    period: StoredPeriod(
      id: 1,
      span: PeriodSpan(startUtc: startUtc, endUtc: endUtc),
    ),
    dayEntries: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockRepo;
  late MockFlutterSecureStorage mockStorage;
  late MockLocalAuthentication mockAuth;
  late PeriodCalendarContext calendar;

  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(
      PeriodSpan(startUtc: DateTime.utc(2020, 1, 1), endUtc: null),
    );
    registerFallbackValue(DayEntryData(dateUtc: DateTime.utc(2020, 1, 1)));
    registerFallbackValue(DateTime.utc(2020, 1, 1));
  });

  setUp(() {
    mockRepo = MockPeriodRepository();
    mockStorage = MockFlutterSecureStorage();
    mockAuth = MockLocalAuthentication();
    calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
    when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);
    SharedPreferences.setMockInitialValues({});
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value(const []),
    );
    when(() => mockRepo.listOrderedByStartUtc()).thenAnswer((_) async => []);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final lockService = LockService(
      prefs: prefs,
      storage: mockStorage,
      localAuth: mockAuth,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TabShell(
          repository: mockRepo,
          calendar: calendar,
          lockService: lockService,
          onReset: () {},
          onLockNow: () {},
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapBottomSheetSave(WidgetTester tester) async {
    final save = find.text('Save');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('FAB calls markToday when today is not in a period', (tester) async {
    when(() => mockRepo.markDay(any())).thenAnswer((_) async => const DayMarkSuccess());
    await pumpHome(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    verify(() => mockRepo.markDay(any())).called(1);
    expect(find.byType(SymptomFormSheet), findsNothing);
  });

  testWidgets('FAB opens symptom form when today is marked', (tester) async {
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([closedPeriodContainingToday()]),
    );
    await pumpHome(tester);
    await tester.pump();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(SymptomFormSheet), findsOneWidget);
    expect(find.text('Add symptoms'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('mark today then FAB opens symptom form and save upserts day',
      (tester) async {
    final controller = StreamController<List<StoredPeriodWithDays>>.broadcast();
    final periods = <StoredPeriod>[];
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer((_) => controller.stream);
    when(() => mockRepo.listOrderedByStartUtc()).thenAnswer((_) async => [...periods]);
    when(() => mockRepo.markDay(any())).thenAnswer((_) async {
      final now = DateTime.now();
      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      final startUtc = todayUtc.subtract(const Duration(days: 1));
      final open = StoredPeriod(
        id: 1,
        span: PeriodSpan(startUtc: startUtc, endUtc: null),
      );
      periods
        ..clear()
        ..add(open);
      controller.add([StoredPeriodWithDays(period: open, dayEntries: const [])]);
      return const DayMarkSuccess(periodId: 1);
    });
    when(() => mockRepo.upsertDayEntryForPeriod(any(), any())).thenAnswer(
      (_) async => 1,
    );

    await pumpHome(tester);
    controller.add([]);
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    verify(() => mockRepo.markDay(any())).called(1);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(periods, isNotEmpty);
    controller.add([
      StoredPeriodWithDays(period: periods[0], dayEntries: const []),
    ]);
    await tester.pumpAndSettle();
    await tapBottomSheetSave(tester);

    verifyNever(() => mockRepo.insertPeriod(any()));
    verify(() => mockRepo.upsertDayEntryForPeriod(1, any())).called(1);
    expect(find.byType(SymptomFormSheet), findsNothing);

    await controller.close();
  });

  testWidgets('home shows cycle day when latest period is not active today',
      (tester) async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final startUtc = todayUtc.subtract(const Duration(days: 7));
    final endUtc = todayUtc.subtract(const Duration(days: 1));
    final item = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(startUtc: startUtc, endUtc: endUtc),
      ),
      dayEntries: const [],
    );
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([item]),
    );
    await pumpHome(tester);
    await tester.pump();
    expect(find.text('Cycle day 8'), findsOneWidget);
  });

  testWidgets('drawer Settings opens mood settings dialog', (tester) async {
    await pumpHome(tester);
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MoodSettingsTile), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('FAB opens symptom form on Calendar tab when today marked',
      (tester) async {
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([closedPeriodContainingToday()]),
    );
    await pumpHome(tester);
    await tester.pump();
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(SymptomFormSheet), findsOneWidget);
  });

  testWidgets('FAB on marked today opens symptom form; save upserts without insertPeriod',
      (tester) async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final startUtc = todayUtc.subtract(const Duration(days: 2));
    final open = StoredPeriod(
      id: 1,
      span: PeriodSpan(startUtc: startUtc, endUtc: null),
    );
    final openPwd = StoredPeriodWithDays(period: open, dayEntries: const []);
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([openPwd]),
    );
    when(() => mockRepo.listOrderedByStartUtc()).thenAnswer(
      (_) async => [open],
    );
    when(() => mockRepo.upsertDayEntryForPeriod(any(), any())).thenAnswer(
      (_) async => 1,
    );

    await pumpHome(tester);
    await tester.pump();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add symptoms'), findsOneWidget);
    await tapBottomSheetSave(tester);
    verifyNever(() => mockRepo.insertPeriod(any()));
    verify(() => mockRepo.upsertDayEntryForPeriod(1, any())).called(1);
    expect(find.byType(SymptomFormSheet), findsNothing);
  });

  testWidgets('today card shows logged flow for today', (tester) async {
    final now = DateTime.now();
    final dayUtc = DateTime.utc(now.year, now.month, now.day);
    final startUtc = dayUtc.subtract(const Duration(days: 3));
    final item = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(startUtc: startUtc, endUtc: null),
      ),
      dayEntries: [
        StoredDayEntry(
          id: 7,
          periodId: 1,
          data: DayEntryData(
            dateUtc: dayUtc,
            flowIntensity: FlowIntensity.heavy,
          ),
        ),
      ],
    );
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([item]),
    );

    await pumpHome(tester);
    await tester.pump();
    expect(find.text("Today's log"), findsOneWidget);
    expect(find.textContaining('Heavy'), findsWidgets);
  });
}

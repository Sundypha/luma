import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack/features/logging/logging_bottom_sheet.dart';
import 'package:ptrack/features/settings/mood_settings.dart';
import 'package:ptrack/features/shell/tab_shell.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class MockPeriodRepository extends Mock implements PeriodRepository {}

class MockPtrackDatabase extends Mock implements PtrackDatabase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockRepo;
  late MockPtrackDatabase mockDb;
  late PeriodCalendarContext calendar;

  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(
      PeriodSpan(startUtc: DateTime.utc(2020, 1, 1), endUtc: null),
    );
    registerFallbackValue(DayEntryData(dateUtc: DateTime.utc(2020, 1, 1)));
  });

  setUp(() {
    mockRepo = MockPeriodRepository();
    mockDb = MockPtrackDatabase();
    calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value(const []),
    );
    when(() => mockRepo.listOrderedByStartUtc()).thenAnswer((_) async => []);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TabShell(
          repository: mockRepo,
          database: mockDb,
          calendar: calendar,
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

  testWidgets('FAB opens logging bottom sheet', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(LoggingBottomSheet), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('create period saves and closes sheet', (tester) async {
    when(() => mockRepo.insertPeriod(any())).thenAnswer(
      (_) async => const PeriodWriteSuccess(1),
    );
    await pumpHome(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapBottomSheetSave(tester);
    verify(() => mockRepo.insertPeriod(any())).called(1);
    expect(find.byType(LoggingBottomSheet), findsNothing);
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

  testWidgets('validation error shows inline message', (tester) async {
    final existing = StoredPeriod(
      id: 9,
      span: PeriodSpan(
        startUtc: DateTime.utc(2024, 1, 1),
        endUtc: DateTime.utc(2024, 1, 10),
      ),
    );
    when(() => mockRepo.listOrderedByStartUtc()).thenAnswer(
      (_) async => [existing],
    );
    when(() => mockRepo.insertPeriod(any())).thenAnswer(
      (_) async => const PeriodWriteRejected([OverlappingPeriod(0)]),
    );

    await pumpHome(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapBottomSheetSave(tester);
    expect(find.textContaining('overlaps'), findsOneWidget);
  });

  testWidgets('FAB opens logging sheet on Calendar tab', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(LoggingBottomSheet), findsOneWidget);
  });

  testWidgets('log day on open period upserts without insertPeriod',
      (tester) async {
    final open = StoredPeriod(
      id: 1,
      span: PeriodSpan(
        startUtc: DateTime.utc(2024, 6, 1),
        endUtc: null,
      ),
    );
    when(() => mockRepo.listOrderedByStartUtc()).thenAnswer(
      (_) async => [open],
    );
    when(() => mockRepo.upsertDayEntryForPeriod(any(), any())).thenAnswer(
      (_) async => 1,
    );

    await pumpHome(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Log day'), findsOneWidget);
    await tapBottomSheetSave(tester);
    verifyNever(() => mockRepo.insertPeriod(any()));
    verify(() => mockRepo.upsertDayEntryForPeriod(1, any())).called(1);
    expect(find.byType(LoggingBottomSheet), findsNothing);
  });

  testWidgets(
      'log day inside completed period when no open period upserts without insert',
      (tester) async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final closed = StoredPeriod(
      id: 3,
      span: PeriodSpan(
        startUtc: todayUtc.subtract(const Duration(days: 2)),
        endUtc: todayUtc.add(const Duration(days: 4)),
      ),
    );
    when(() => mockRepo.listOrderedByStartUtc()).thenAnswer(
      (_) async => [closed],
    );
    when(() => mockRepo.upsertDayEntryForPeriod(any(), any())).thenAnswer(
      (_) async => 1,
    );

    await pumpHome(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Log day'), findsOneWidget);
    expect(find.text('Start new'), findsOneWidget);
    await tapBottomSheetSave(tester);
    verifyNever(() => mockRepo.insertPeriod(any()));
    verify(() => mockRepo.upsertDayEntryForPeriod(3, any())).called(1);
    expect(find.byType(LoggingBottomSheet), findsNothing);
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

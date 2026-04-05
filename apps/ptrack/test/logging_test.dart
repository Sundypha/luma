import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack/features/logging/home_screen.dart';
import 'package:ptrack/features/logging/logging_bottom_sheet.dart';
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
        home: HomeScreen(
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

  testWidgets('period list shows periods from stream', (tester) async {
    final a = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(
          startUtc: DateTime.utc(2024, 6, 1),
          endUtc: DateTime.utc(2024, 6, 3),
        ),
      ),
      dayEntries: const [],
    );
    final b = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 2,
        span: PeriodSpan(
          startUtc: DateTime.utc(2024, 5, 1),
          endUtc: DateTime.utc(2024, 5, 4),
        ),
      ),
      dayEntries: const [],
    );
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([a, b]),
    );
    await pumpHome(tester);
    await tester.pump();
    expect(find.byType(ExpansionTile), findsNWidgets(2));
  });

  testWidgets('delete period shows confirmation dialog', (tester) async {
    final item = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 42,
        span: PeriodSpan(
          startUtc: DateTime.utc(2024, 6, 1),
          endUtc: DateTime.utc(2024, 6, 3),
        ),
      ),
      dayEntries: const [],
    );
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([item]),
    );
    when(() => mockRepo.deletePeriod(42)).thenAnswer((_) async => true);

    await pumpHome(tester);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete period'));
    await tester.pumpAndSettle();
    expect(find.text('Delete period?'), findsOneWidget);
    final dialogDelete = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, 'Delete'),
    );
    await tester.tap(dialogDelete);
    await tester.pumpAndSettle();
    verify(() => mockRepo.deletePeriod(42)).called(1);
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

  testWidgets('edit mode pre-fills existing data', (tester) async {
    final day = StoredDayEntry(
      id: 7,
      periodId: 1,
      data: DayEntryData(
        dateUtc: DateTime.utc(2024, 6, 3),
        flowIntensity: FlowIntensity.heavy,
      ),
    );
    final item = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(
          startUtc: DateTime.utc(2024, 6, 1),
          endUtc: null,
        ),
      ),
      dayEntries: [day],
    );
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([item]),
    );

    await pumpHome(tester);
    await tester.pump();
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<int>(7)));
    await tester.pumpAndSettle();

    final flowFinder = find.descendant(
      of: find.byType(LoggingBottomSheet),
      matching: find.byKey(const Key('flow_intensity_segments')),
    );
    await tester.ensureVisible(flowFinder);
    await tester.pumpAndSettle();

    final flow = tester.widget<SegmentedButton<FlowIntensity>>(flowFinder);
    expect(flow.selected, {FlowIntensity.heavy});
  });
}

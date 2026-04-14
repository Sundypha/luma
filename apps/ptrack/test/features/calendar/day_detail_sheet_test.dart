import 'package:flutter/material.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:luma/features/calendar/calendar_day_data.dart';
import 'package:luma/features/calendar/calendar_view_model.dart';
import 'package:luma/features/calendar/day_detail_sheet.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class MockPeriodRepository extends Mock implements PeriodRepository {}

class MockDiaryRepository extends Mock implements DiaryRepository {}

/// Overrides map/periods/diary for deterministic widget tests without relying on prediction streams.
class DayDetailTestViewModel extends CalendarViewModel {
  // ignore: use_super_parameters — superclass stores repos in private fields.
  DayDetailTestViewModel(
    PeriodRepository repo,
    PeriodCalendarContext calendar,
    DiaryRepository diary,
  ) : super(repo, calendar, diary);

  Map<DateTime, CalendarDayData>? _mapOverride;
  List<StoredPeriodWithDays>? _periodsOverride;
  Map<DateTime, StoredDiaryEntry>? _diaryByUtcDay;

  void setTestData({
    Map<DateTime, CalendarDayData>? map,
    List<StoredPeriodWithDays>? periods,
    Map<DateTime, StoredDiaryEntry>? diaryByUtcDay,
  }) {
    _mapOverride = map;
    _periodsOverride = periods;
    _diaryByUtcDay = diaryByUtcDay;
    notifyListeners();
  }

  @override
  Map<DateTime, CalendarDayData> get dayDataMap =>
      _mapOverride ?? super.dayDataMap;

  @override
  List<StoredPeriodWithDays> get periodsWithDays =>
      _periodsOverride ?? super.periodsWithDays;

  @override
  StoredDiaryEntry? diaryEntryForDay(DateTime dayNorm) {
    final key = DateTime.utc(dayNorm.year, dayNorm.month, dayNorm.day);
    final injected = _diaryByUtcDay?[key];
    if (injected != null) return injected;
    return super.diaryEntryForDay(dayNorm);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockRepo;
  late MockDiaryRepository mockDiary;
  late PeriodCalendarContext calendar;

  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(
      PeriodSpan(startUtc: DateTime.utc(2020, 1, 1), endUtc: null),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockPeriodRepository();
    mockDiary = MockDiaryRepository();
    calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value(const []),
    );
    when(() => mockDiary.watchAllEntries()).thenAnswer(
      (_) => Stream<List<StoredDiaryEntry>>.value(const []),
    );
    when(() => mockRepo.markDay(any())).thenAnswer(
      (_) async => const DayMarkSuccess(),
    );
    when(() => mockRepo.unmarkDay(any())).thenAnswer(
      (_) async => const DayMarkSuccess(),
    );
    when(() => mockRepo.deleteDayEntry(any())).thenAnswer((_) async => true);
    when(() => mockRepo.deletePeriod(any())).thenAnswer((_) async => true);
  });

  /// Sheet embedded under [home] (no extra route). Fine for read-only layout checks.
  Future<DayDetailTestViewModel> pumpSheet(
    WidgetTester tester, {
    required DateTime selectedDay,
    required void Function(DayDetailTestViewModel vm) configure,
  }) async {
    final vm = DayDetailTestViewModel(mockRepo, calendar, mockDiary);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 800,
            child: DayDetailSheet(
              selectedDay: selectedDay,
              viewModel: vm,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    configure(vm);
    await tester.pump();
    return vm;
  }

  /// Sheet on a pushed route so successful [Navigator.pop] leaves the opener visible again.
  Future<DayDetailTestViewModel> pumpDayDetailOnPushedRoute(
    WidgetTester tester, {
    required DateTime selectedDay,
    required void Function(DayDetailTestViewModel vm) configure,
  }) async {
    final vm = DayDetailTestViewModel(mockRepo, calendar, mockDiary);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          body: DayDetailSheet(
                            selectedDay: selectedDay,
                            viewModel: vm,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('OPEN_DAY_DETAIL_ROUTE'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN_DAY_DETAIL_ROUTE'));
    await tester.pumpAndSettle();
    configure(vm);
    await tester.pumpAndSettle();
    return vm;
  }

  testWidgets('empty past day shows I had my period button', (tester) async {
    final vm = await pumpSheet(
      tester,
      selectedDay: DateTime.utc(2020, 3, 10),
      configure: (vm) {
        vm.setTestData(
          map: {
            DateTime.utc(2020, 3, 10): const CalendarDayData(),
          },
          periods: const [],
        );
      },
    );
    expect(find.text('I had my period'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('empty future day shows view-only text, no action buttons',
      (tester) async {
    final vm = await pumpSheet(
      tester,
      selectedDay: DateTime.utc(2035, 8, 20),
      configure: (vm) {
        vm.setTestData(
          map: {
            DateTime.utc(2035, 8, 20): const CalendarDayData(),
          },
          periods: const [],
        );
      },
    );
    expect(
      find.text('Future dates — check back when this day arrives.'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('I had my period'), findsNothing);
    vm.dispose();
  });

  testWidgets('predicted past day shows prediction card and I had my period',
      (tester) async {
    final vm = await pumpSheet(
      tester,
      selectedDay: DateTime.utc(2020, 5, 5),
      configure: (vm) {
        vm.setTestData(
          map: {
            DateTime.utc(2020, 5, 5): const CalendarDayData(
              predictionConfidenceTier: 1,
              predictionAgreementCount: 1,
            ),
          },
          periods: const [],
        );
      },
    );
    expect(find.text('Period expected around this day'), findsOneWidget);
    expect(find.text('I had my period'), findsOneWidget);
    vm.dispose();
  });

  testWidgets(
      'predicted future day shows prediction card and view-only message',
      (tester) async {
    final vm = await pumpSheet(
      tester,
      selectedDay: DateTime.utc(2035, 1, 1),
      configure: (vm) {
        vm.setTestData(
          map: {
            DateTime.utc(2035, 1, 1): const CalendarDayData(
              predictionConfidenceTier: 1,
              predictionAgreementCount: 1,
            ),
          },
          periods: const [],
        );
      },
    );
    expect(find.text('Period expected around this day'), findsOneWidget);
    expect(
      find.text('You can log this once the day arrives.'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
    vm.dispose();
  });

  testWidgets(
      'period day without entry shows Edit period record, Add diary entry, and Remove this day',
      (tester) async {
    final dayNorm = DateTime.utc(2025, 4, 10);
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 4, 8),
          endUtc: DateTime.utc(2025, 4, 14),
        ),
      ),
      dayEntries: const [],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 4, 12),
    );
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    expect(find.text('Edit period record'), findsOneWidget);
    expect(find.text('Add diary entry'), findsOneWidget);
    expect(find.text('Remove this day'), findsOneWidget);
    expect(find.text('Period day 3'), findsOneWidget);
    vm.dispose();
  });

  testWidgets(
      'period day with entry shows symptom data and period/diary actions without Clear symptoms row',
      (tester) async {
    final dayNorm = DateTime.utc(2025, 4, 10);
    final entry = StoredDayEntry(
      id: 99,
      periodId: 1,
      data: DayEntryData(
        dateUtc: dayNorm,
        flowIntensity: FlowIntensity.light,
        painScore: PainScore.mild,
        mood: Mood.good,
        notes: 'ok',
      ),
    );
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 4, 8),
          endUtc: DateTime.utc(2025, 4, 14),
        ),
      ),
      dayEntries: [entry],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 4, 12),
    );
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    expect(find.text('Light'), findsWidgets);
    expect(find.text('Edit period record'), findsOneWidget);
    expect(find.text('Add diary entry'), findsOneWidget);
    expect(find.text('Remove this day'), findsOneWidget);
    expect(find.text('Clear symptoms'), findsNothing);
    vm.dispose();
  });

  testWidgets('diary-only past day shows had period and edit diary, not delete period',
      (tester) async {
    final dayNorm = DateTime.utc(2024, 2, 14);
    final diary = StoredDiaryEntry(
      id: 7,
      data: DiaryEntryData(
        dateUtc: dayNorm,
        mood: Mood.bad,
        notes: 'note text',
      ),
      tags: const [],
    );
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(
          map: {
            dayNorm: const CalendarDayData(
              hasDiaryEntry: true,
              loggedPeriodState: PeriodDayState.none,
            ),
          },
          periods: const [],
          diaryByUtcDay: {dayNorm: diary},
        );
      },
    );
    expect(find.text('I had my period'), findsOneWidget);
    expect(find.text('Edit diary entry'), findsOneWidget);
    expect(find.text('Delete entire period'), findsNothing);
    expect(find.text('note text'), findsOneWidget);
    vm.dispose();
  });

  testWidgets(
      'period plus diary shows both mood rows, diary tags, clear symptoms, and delete period',
      (tester) async {
    final dayNorm = DateTime.utc(2025, 7, 7);
    final entry = StoredDayEntry(
      id: 50,
      periodId: 2,
      data: DayEntryData(
        dateUtc: dayNorm,
        flowIntensity: FlowIntensity.heavy,
        painScore: PainScore.severe,
        mood: Mood.good,
        notes: 'symptom notes',
      ),
    );
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 2,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 7, 6),
          endUtc: DateTime.utc(2025, 7, 10),
        ),
      ),
      dayEntries: [entry],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 7, 8),
    );
    final diary = StoredDiaryEntry(
      id: 8,
      data: DiaryEntryData(
        dateUtc: dayNorm,
        mood: Mood.neutral,
        notes: 'diary only',
      ),
      tags: const [DiaryTag(id: 1, name: 'TagA')],
    );
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(
          map: map,
          periods: [fixture],
          diaryByUtcDay: {dayNorm: diary},
        );
      },
    );
    expect(find.text('TagA'), findsOneWidget);
    expect(find.text('Clear symptoms'), findsOneWidget);
    expect(find.text('Edit diary entry'), findsOneWidget);
    expect(find.text('Delete entire period'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('symptom entry with null metrics shows em dash placeholders',
      (tester) async {
    final dayNorm = DateTime.utc(2025, 8, 1);
    final entry = StoredDayEntry(
      id: 51,
      periodId: 3,
      data: DayEntryData(
        dateUtc: dayNorm,
        flowIntensity: null,
        painScore: null,
        mood: null,
        notes: null,
      ),
    );
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 3,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 7, 28),
          endUtc: DateTime.utc(2025, 8, 5),
        ),
      ),
      dayEntries: [entry],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 8, 2),
    );
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    expect(find.text('—'), findsWidgets);
    expect(find.text('No symptoms or notes logged for this day.'), findsNothing);
    vm.dispose();
  });

  testWidgets('fertile day shows fertility explainer under the date', (tester) async {
    final dayNorm = DateTime.utc(2024, 3, 1);
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(
          map: {
            dayNorm: const CalendarDayData(isFertileDay: true),
          },
          periods: const [],
        );
      },
    );
    expect(
      find.text('Estimated fertile day — based on your cycle history'),
      findsOneWidget,
    );
    vm.dispose();
  });

  testWidgets('projected cycle hop uses forecast title, not next-period title',
      (tester) async {
    final dayNorm = DateTime.utc(2020, 1, 1);
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(
          map: {
            dayNorm: const CalendarDayData(
              predictionConfidenceTier: 1,
              predictionAgreementCount: 1,
              predictionCycleIndex: 2,
            ),
          },
          periods: const [],
        );
      },
    );
    expect(find.text('Forecast ≈ 3 months out'), findsOneWidget);
    expect(find.text('Period expected around this day'), findsNothing);
    vm.dispose();
  });

  testWidgets('when two periods overlap the last list entry wins for actions',
      (tester) async {
    final dayNorm = DateTime.utc(2025, 9, 15);
    final older = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 10,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 9, 1),
          endUtc: DateTime.utc(2025, 9, 30),
        ),
      ),
      dayEntries: [
        StoredDayEntry(
          id: 701,
          periodId: 10,
          data: DayEntryData(
            dateUtc: dayNorm,
            flowIntensity: FlowIntensity.light,
          ),
        ),
      ],
    );
    final newer = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 11,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 9, 10),
          endUtc: DateTime.utc(2025, 9, 20),
        ),
      ),
      dayEntries: [
        StoredDayEntry(
          id: 700,
          periodId: 11,
          data: DayEntryData(
            dateUtc: dayNorm,
            flowIntensity: FlowIntensity.heavy,
            painScore: null,
            mood: null,
            notes: null,
          ),
        ),
      ],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [older, newer],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 9, 16),
    );
    final vm = await pumpDayDetailOnPushedRoute(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [older, newer]);
      },
    );
    expect(find.text('Heavy'), findsWidgets);
    expect(find.text('Light'), findsNothing);
    await tester.tap(find.text('Delete entire period'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await tester.pumpAndSettle();
    verify(() => mockRepo.deletePeriod(11)).called(1);
    verifyNever(() => mockRepo.deletePeriod(10));
    vm.dispose();
  });

  testWidgets('I had my period calls markDay with UTC midnight then pops route',
      (tester) async {
    final day = DateTime.utc(2019, 12, 31);
    final vm = await pumpDayDetailOnPushedRoute(
      tester,
      selectedDay: day,
      configure: (vm) {
        vm.setTestData(
          map: {DateTime.utc(2019, 12, 31): const CalendarDayData()},
          periods: const [],
        );
      },
    );
    await tester.tap(find.text('I had my period'));
    await tester.pumpAndSettle();
    verify(() => mockRepo.markDay(DateTime.utc(2019, 12, 31))).called(1);
    expect(find.text('OPEN_DAY_DETAIL_ROUTE'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('markDay failure shows snackbar and stays on sheet', (tester) async {
    when(() => mockRepo.markDay(any())).thenAnswer(
      (_) async => const DayMarkFailure('ignored'),
    );
    final vm = await pumpDayDetailOnPushedRoute(
      tester,
      selectedDay: DateTime.utc(2018, 6, 6),
      configure: (vm) {
        vm.setTestData(
          map: {DateTime.utc(2018, 6, 6): const CalendarDayData()},
          periods: const [],
        );
      },
    );
    await tester.tap(find.text('I had my period'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not mark this day. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('I had my period'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('remove day without entry skips dialog and pops on success',
      (tester) async {
    final dayNorm = DateTime.utc(2025, 10, 1);
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 5,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 9, 28),
          endUtc: DateTime.utc(2025, 10, 5),
        ),
      ),
      dayEntries: const [],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 10, 2),
    );
    final vm = await pumpDayDetailOnPushedRoute(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    await tester.tap(find.text('Remove this day'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this day?'), findsNothing);
    verify(() => mockRepo.unmarkDay(dayNorm)).called(1);
    expect(find.text('OPEN_DAY_DETAIL_ROUTE'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('remove day with entry confirms then unmarks and pops',
      (tester) async {
    final dayNorm = DateTime.utc(2025, 11, 3);
    final entry = StoredDayEntry(
      id: 600,
      periodId: 6,
      data: DayEntryData(
        dateUtc: dayNorm,
        flowIntensity: FlowIntensity.light,
        painScore: null,
        mood: null,
        notes: null,
      ),
    );
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 6,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 11, 1),
          endUtc: DateTime.utc(2025, 11, 8),
        ),
      ),
      dayEntries: [entry],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 11, 4),
    );
    final vm = await pumpDayDetailOnPushedRoute(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    await tester.tap(find.text('Remove this day'));
    await tester.pumpAndSettle();
    expect(find.text('Remove this day?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Remove'),
      ),
    );
    await tester.pumpAndSettle();
    verify(() => mockRepo.unmarkDay(dayNorm)).called(1);
    expect(find.text('OPEN_DAY_DETAIL_ROUTE'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('remove day cancel leaves sheet and does not call unmark',
      (tester) async {
    final dayNorm = DateTime.utc(2025, 11, 10);
    final entry = StoredDayEntry(
      id: 601,
      periodId: 7,
      data: DayEntryData(dateUtc: dayNorm, flowIntensity: FlowIntensity.light),
    );
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 7,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 11, 8),
          endUtc: DateTime.utc(2025, 11, 14),
        ),
      ),
      dayEntries: [entry],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 11, 11),
    );
    final vm = await pumpDayDetailOnPushedRoute(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    await tester.tap(find.text('Remove this day'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    verifyNever(() => mockRepo.unmarkDay(any()));
    expect(find.text('Remove this day'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('unmarkDay failure shows snackbar', (tester) async {
    when(() => mockRepo.unmarkDay(any())).thenAnswer(
      (_) async => const DayMarkFailure('x'),
    );
    final dayNorm = DateTime.utc(2025, 12, 1);
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 8,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 11, 28),
          endUtc: DateTime.utc(2025, 12, 5),
        ),
      ),
      dayEntries: const [],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 12, 2),
    );
    final vm = await pumpDayDetailOnPushedRoute(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    await tester.tap(find.text('Remove this day'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not remove this day. Please try again.'),
      findsOneWidget,
    );
    vm.dispose();
  });

  testWidgets('clear symptoms calls deleteDayEntry; failure shows snackbar',
      (tester) async {
    final dayNorm = DateTime.utc(2025, 12, 20);
    final entry = StoredDayEntry(
      id: 888,
      periodId: 9,
      data: DayEntryData(dateUtc: dayNorm, flowIntensity: FlowIntensity.light),
    );
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 9,
        span: PeriodSpan(
          startUtc: DateTime.utc(2025, 12, 18),
          endUtc: DateTime.utc(2025, 12, 24),
        ),
      ),
      dayEntries: [entry],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2025, 12, 21),
    );
    final diary = StoredDiaryEntry(
      id: 9,
      data: DiaryEntryData(dateUtc: dayNorm),
      tags: const [],
    );
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(
          map: map,
          periods: [fixture],
          diaryByUtcDay: {dayNorm: diary},
        );
      },
    );
    await tester.tap(find.text('Clear symptoms'));
    await tester.pumpAndSettle();
    verify(() => mockRepo.deleteDayEntry(888)).called(1);

    when(() => mockRepo.deleteDayEntry(any())).thenAnswer((_) async => false);
    await tester.tap(find.text('Clear symptoms'));
    await tester.pumpAndSettle();
    expect(find.text('Could not clear symptoms.'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('delete entire period closed span shows dialog then deletes and pops',
      (tester) async {
    final dayNorm = DateTime.utc(2026, 1, 10);
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 42,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 1, 5),
          endUtc: DateTime.utc(2026, 1, 15),
        ),
      ),
      dayEntries: const [],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2026, 1, 11),
    );
    final vm = await pumpDayDetailOnPushedRoute(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    await tester.tap(find.text('Delete entire period'));
    await tester.pumpAndSettle();
    expect(find.text('Delete entire period?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await tester.pumpAndSettle();
    verify(() => mockRepo.deletePeriod(42)).called(1);
    expect(find.text('OPEN_DAY_DETAIL_ROUTE'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('delete entire period cancel does not call repository',
      (tester) async {
    final dayNorm = DateTime.utc(2026, 2, 2);
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 43,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 2, 1),
          endUtc: DateTime.utc(2026, 2, 10),
        ),
      ),
      dayEntries: const [],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2026, 2, 3),
    );
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    await tester.tap(find.text('Delete entire period'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    verifyNever(() => mockRepo.deletePeriod(any()));
    vm.dispose();
  });

  testWidgets('delete period failure shows snackbar', (tester) async {
    when(() => mockRepo.deletePeriod(any())).thenAnswer((_) async => false);
    final dayNorm = DateTime.utc(2026, 3, 5);
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 44,
        span: PeriodSpan(
          startUtc: DateTime.utc(2026, 3, 1),
          endUtc: DateTime.utc(2026, 3, 8),
        ),
      ),
      dayEntries: const [],
    );
    final map = buildCalendarDayDataMap(
      periodsWithDays: [fixture],
      prediction: const PredictionInsufficientHistory(
        completedCyclesAvailable: 0,
        minCompletedCyclesNeeded: 2,
      ),
      today: DateTime.utc(2026, 3, 6),
    );
    final vm = await pumpSheet(
      tester,
      selectedDay: dayNorm,
      configure: (vm) {
        vm.setTestData(map: map, periods: [fixture]);
      },
    );
    await tester.tap(find.text('Delete entire period'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not delete period.'), findsOneWidget);
    vm.dispose();
  });
}

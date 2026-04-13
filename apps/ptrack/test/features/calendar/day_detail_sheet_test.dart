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

/// Overrides map/periods for deterministic widget tests without relying on prediction.
class DayDetailTestViewModel extends CalendarViewModel {
  // ignore: use_super_parameters — superclass stores repos in private fields.
  DayDetailTestViewModel(
    PeriodRepository repo,
    PeriodCalendarContext calendar,
    DiaryRepository diary,
  ) : super(repo, calendar, diary);

  Map<DateTime, CalendarDayData>? _mapOverride;
  List<StoredPeriodWithDays>? _periodsOverride;

  void setTestData({
    Map<DateTime, CalendarDayData>? map,
    List<StoredPeriodWithDays>? periods,
  }) {
    _mapOverride = map;
    _periodsOverride = periods;
    notifyListeners();
  }

  @override
  Map<DateTime, CalendarDayData> get dayDataMap =>
      _mapOverride ?? super.dayDataMap;

  @override
  List<StoredPeriodWithDays> get periodsWithDays =>
      _periodsOverride ?? super.periodsWithDays;
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
  });

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

  testWidgets('predicted future day shows prediction card and view-only message',
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

  testWidgets('period day without entry shows Add symptoms and Remove this day',
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
    expect(find.text('Add symptoms'), findsOneWidget);
    expect(find.text('Remove this day'), findsOneWidget);
    vm.dispose();
  });

  testWidgets(
      'period day with entry shows data and Edit, Clear symptoms, Remove this day',
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
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Clear symptoms'), findsOneWidget);
    expect(find.text('Remove this day'), findsOneWidget);
    vm.dispose();
  });
}

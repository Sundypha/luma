import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:luma/features/calendar/calendar_painters.dart';
import 'package:luma/features/calendar/calendar_screen.dart';
import 'package:luma/features/calendar/calendar_view_model.dart';
import 'package:luma/features/calendar/day_detail_sheet.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class MockPeriodRepository extends Mock implements PeriodRepository {}

bool _hasPeriodBandPainter(Widget widget) =>
    widget is CustomPaint && widget.painter is PeriodBandPainter;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockRepo;
  late PeriodCalendarContext calendar;

  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(
      PeriodSpan(startUtc: DateTime.utc(2020, 1, 1), endUtc: null),
    );
    registerFallbackValue(DayEntryData(dateUtc: DateTime.utc(2020, 1, 1)));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockPeriodRepository();
    calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value(const []),
    );
    when(() => mockRepo.listOrderedByStartUtc()).thenAnswer((_) async => []);
  });

  Future<CalendarViewModel> pumpCalendar(WidgetTester tester) async {
    final vm = CalendarViewModel(mockRepo, calendar);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarScreen(viewModel: vm),
        ),
      ),
    );
    await tester.pump();
    return vm;
  }

  testWidgets('calendar renders month grid with weekday headers', (tester) async {
    final vm = await pumpCalendar(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TableCalendar<void>), findsOneWidget);

    final element = tester.element(find.byType(TableCalendar<void>));
    final locale = Localizations.localeOf(element);
    final localeName = locale.countryCode != null &&
            locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    final mondayLabel =
        DateFormat.E(localeName).format(DateTime(2024, 1, 1));
    expect(find.text(mondayLabel), findsWidgets);

    final now = DateTime.now();
    expect(
      find.text(DateFormat.yMMMM(localeName).format(now)),
      findsWidgets,
    );
    expect(find.text('${now.day}'), findsWidgets);
    vm.dispose();
  });

  testWidgets('calendar shows period marks for logged period', (tester) async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final startUtc = todayUtc.subtract(const Duration(days: 3));
    final endUtc = todayUtc.subtract(const Duration(days: 1));
    final midDay = todayUtc.subtract(const Duration(days: 2));

    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(startUtc: startUtc, endUtc: endUtc),
      ),
      dayEntries: [
        StoredDayEntry(
          id: 1,
          periodId: 1,
          data: DayEntryData(dateUtc: midDay),
        ),
      ],
    );

    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([fixture]),
    );

    final vm = await pumpCalendar(tester);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => _hasPeriodBandPainter(w)),
      findsWidgets,
    );
    expect(find.text('${midDay.day}'), findsWidgets);
    vm.dispose();
  });

  testWidgets(
      'tapping period band day with no log opens day detail, not logging',
      (tester) async {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final startUtc = todayUtc.subtract(const Duration(days: 3));
    final endUtc = todayUtc.subtract(const Duration(days: 1));
    final midDay = todayUtc.subtract(const Duration(days: 2));
    final dayNoLog = endUtc;

    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(startUtc: startUtc, endUtc: endUtc),
      ),
      dayEntries: [
        StoredDayEntry(
          id: 1,
          periodId: 1,
          data: DayEntryData(dateUtc: midDay),
        ),
      ],
    );

    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value([fixture]),
    );

    final vm = await pumpCalendar(tester);
    await tester.pumpAndSettle();

    final dayFinder = find.descendant(
      of: find.byType(TableCalendar<void>),
      matching: find.text('${dayNoLog.day}'),
    );
    await tester.ensureVisible(dayFinder.first);
    await tester.tap(dayFinder.first);
    await tester.pumpAndSettle();

    expect(find.byType(DayDetailSheet), findsOneWidget);
    expect(find.text('Delete entire period'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('calendar rebuilds when view model receives new data',
      (tester) async {
    final controller = StreamController<List<StoredPeriodWithDays>>.broadcast();
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer((_) => controller.stream);

    final vm = CalendarViewModel(mockRepo, calendar);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarScreen(viewModel: vm),
        ),
      ),
    );
    controller.add([]);
    await tester.pump();

    expect(
      find.byWidgetPredicate((w) => _hasPeriodBandPainter(w)),
      findsNothing,
    );

    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(
          startUtc: todayUtc.subtract(const Duration(days: 2)),
          endUtc: todayUtc.subtract(const Duration(days: 1)),
        ),
      ),
      dayEntries: const [],
    );
    controller.add([fixture]);
    await tester.pump();

    expect(
      find.byWidgetPredicate((w) => _hasPeriodBandPainter(w)),
      findsWidgets,
    );

    vm.dispose();
    await controller.close();
  });

  testWidgets('Today button appears when navigated to different month',
      (tester) async {
    final vm = await pumpCalendar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('tapping a day triggers onDaySelected', (tester) async {
    final vm = await pumpCalendar(tester);
    await tester.pumpAndSettle();

    final dayFinder = find.descendant(
      of: find.byType(TableCalendar<void>),
      matching: find.text('15'),
    );
    await tester.ensureVisible(dayFinder.first);
    await tester.tap(dayFinder.first);
    await tester.pumpAndSettle();

    expect(find.byType(DayDetailSheet), findsOneWidget);
    vm.dispose();
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack/features/calendar/calendar_painters.dart';
import 'package:ptrack/features/calendar/calendar_screen.dart';
import 'package:ptrack/features/logging/logging_bottom_sheet.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class MockPeriodRepository extends Mock implements PeriodRepository {}

class MockPtrackDatabase extends Mock implements PtrackDatabase {}

bool _hasPeriodBandPainter(Widget widget) =>
    widget is CustomPaint && widget.painter is PeriodBandPainter;

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

  Future<void> pumpCalendar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarScreen(
            repository: mockRepo,
            database: mockDb,
            calendar: calendar,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('calendar renders month grid with weekday headers', (tester) async {
    await pumpCalendar(tester);
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

    await pumpCalendar(tester);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => _hasPeriodBandPainter(w)),
      findsWidgets,
    );
    expect(find.text('${midDay.day}'), findsWidgets);
  });

  testWidgets('calendar rebuilds when data stream emits', (tester) async {
    final controller = StreamController<List<StoredPeriodWithDays>>();
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer((_) => controller.stream);

    await pumpCalendar(tester);
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

    await controller.close();
  });

  testWidgets('Today button appears when navigated to different month',
      (tester) async {
    await pumpCalendar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('tapping a day triggers onDaySelected', (tester) async {
    await pumpCalendar(tester);
    await tester.pumpAndSettle();

    final dayFinder = find.descendant(
      of: find.byType(TableCalendar<void>),
      matching: find.text('15'),
    );
    await tester.ensureVisible(dayFinder.first);
    await tester.tap(dayFinder.first);
    await tester.pumpAndSettle();

    expect(find.byType(LoggingBottomSheet), findsOneWidget);
  });
}

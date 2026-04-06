import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack/features/calendar/calendar_view_model.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class MockPeriodRepository extends Mock implements PeriodRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockRepo;
  late PeriodCalendarContext calendar;
  late StreamController<List<StoredPeriodWithDays>> controller;

  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(
      PeriodSpan(startUtc: DateTime.utc(2020, 1, 1), endUtc: null),
    );
  });

  setUp(() {
    mockRepo = MockPeriodRepository();
    calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    controller = StreamController<List<StoredPeriodWithDays>>.broadcast();
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await controller.close();
  });

  test('starts without initial event until stream emits', () {
    final vm = CalendarViewModel(mockRepo, calendar);
    expect(vm.hasInitialEvent, isFalse);
    expect(vm.dayDataMap, isEmpty);
    vm.dispose();
  });

  test('after emitting period data, dayDataMap and prediction update', () async {
    final vm = CalendarViewModel(mockRepo, calendar);
    final start = DateTime.utc(2025, 6, 1);
    final end = DateTime.utc(2025, 6, 3);
    final fixture = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(startUtc: start, endUtc: end),
      ),
      dayEntries: const [],
    );
    controller.add([fixture]);
    await Future<void>.delayed(Duration.zero);
    expect(vm.hasInitialEvent, isTrue);
    expect(vm.periodsWithDays, [fixture]);
    expect(vm.dayDataMap, isNotEmpty);
    expect(vm.prediction, isA<PredictionResult>());
    vm.dispose();
  });

  test('selectDay updates selectedDay and focusedDay', () async {
    final vm = CalendarViewModel(mockRepo, calendar);
    controller.add(const []);
    await Future<void>.delayed(Duration.zero);
    final d = DateTime.utc(2025, 7, 15);
    final f = DateTime.utc(2025, 7, 20);
    vm.selectDay(d, f);
    expect(vm.selectedDay, d);
    expect(vm.focusedDay, f);
    vm.dispose();
  });

  test('goToToday resets focusedDay to current month and clears selection',
      () async {
    final vm = CalendarViewModel(mockRepo, calendar);
    controller.add(const []);
    await Future<void>.delayed(Duration.zero);
    vm.changeFocusedMonth(DateTime.utc(2020, 1, 1));
    vm.selectDay(DateTime.utc(2020, 1, 5));
    vm.goToToday();
    final now = DateTime.now();
    expect(vm.focusedDay.year, now.year);
    expect(vm.focusedDay.month, now.month);
    expect(vm.selectedDay, isNull);
    vm.dispose();
  });

  test('dispose cancels subscription without errors on further adds', () async {
    final vm = CalendarViewModel(mockRepo, calendar);
    controller.add(const []);
    await Future<void>.delayed(Duration.zero);
    vm.dispose();
    controller.add(const []);
    await Future<void>.delayed(Duration.zero);
  });

  test('markDay and unmarkDay forward to repository', () async {
    when(() => mockRepo.markDay(any())).thenAnswer((_) async => const DayMarkSuccess());
    when(() => mockRepo.unmarkDay(any())).thenAnswer((_) async => const DayMarkSuccess());
    final vm = CalendarViewModel(mockRepo, calendar);
    controller.add(const []);
    await Future<void>.delayed(Duration.zero);
    final day = DateTime.utc(2025, 8, 10);
    await vm.markDay(day);
    await vm.unmarkDay(day);
    verify(() => mockRepo.markDay(day)).called(1);
    verify(() => mockRepo.unmarkDay(day)).called(1);
    vm.dispose();
  });
}

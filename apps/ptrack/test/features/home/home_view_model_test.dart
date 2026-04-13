import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luma/features/home/home_view_model.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class MockPeriodRepository extends Mock implements PeriodRepository {}

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockRepo;
  late MockDiaryRepository mockDiary;
  late PeriodCalendarContext calendar;
  late StreamController<List<StoredPeriodWithDays>> controller;

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
    controller = StreamController<List<StoredPeriodWithDays>>.broadcast();
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer((_) => controller.stream);
    when(() => mockDiary.watchAllEntries()).thenAnswer(
      (_) => Stream<List<StoredDiaryEntry>>.value(const []),
    );
  });

  tearDown(() async {
    await controller.close();
  });

  test('starts with null cycle snapshot, null todayEntry, not marked', () {
    final vm = HomeViewModel(mockRepo, calendar, mockDiary);
    expect(vm.hasInitialEvent, isFalse);
    expect(vm.cyclePosition, isNull);
    expect(vm.todayEntry, isNull);
    expect(vm.isTodayMarked, isFalse);
    vm.dispose();
  });

  test('when today lies in a period span, isTodayMarked and todayEntry update',
      () async {
    final vm = HomeViewModel(mockRepo, calendar, mockDiary);
    final now = DateTime.now();
    final utc = now.toUtc();
    final todayCal = DateTime.utc(utc.year, utc.month, utc.day);
    final startUtc = todayCal.subtract(const Duration(days: 2));
    final item = StoredPeriodWithDays(
      period: StoredPeriod(
        id: 1,
        span: PeriodSpan(startUtc: startUtc, endUtc: null),
      ),
      dayEntries: [
        StoredDayEntry(
          id: 1,
          periodId: 1,
          data: DayEntryData(
            dateUtc: todayCal,
            flowIntensity: FlowIntensity.medium,
          ),
        ),
      ],
    );
    controller.add([item]);
    await Future<void>.delayed(Duration.zero);
    expect(vm.hasInitialEvent, isTrue);
    expect(vm.isTodayMarked, isTrue);
    expect(vm.todayEntry, isNotNull);
    expect(vm.todayEntry!.flowIntensity, FlowIntensity.medium);
    expect(vm.cyclePosition, isNotNull);
    vm.dispose();
  });

  test('markToday calls repository.markDay with calendar day matching now',
      () async {
    when(() => mockRepo.markDay(any())).thenAnswer((_) async => const DayMarkSuccess());
    final vm = HomeViewModel(mockRepo, calendar, mockDiary);
    controller.add(const []);
    await Future<void>.delayed(Duration.zero);
    await vm.markToday();
    final captured = verify(() => mockRepo.markDay(captureAny())).captured.single
        as DateTime;
    final n = DateTime.now();
    expect(captured.year, n.year);
    expect(captured.month, n.month);
    expect(captured.day, n.day);
    vm.dispose();
  });
}

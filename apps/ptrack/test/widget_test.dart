import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack/features/logging/home_screen.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

class MockPeriodRepository extends Mock implements PeriodRepository {}

class MockPtrackDatabase extends Mock implements PtrackDatabase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockRepo;
  late MockPtrackDatabase mockDb;
  late PeriodCalendarContext calendar;

  setUp(() {
    mockRepo = MockPeriodRepository();
    mockDb = MockPtrackDatabase();
    calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value(const []),
    );
  });

  testWidgets('home shows empty state and ptrack title', (tester) async {
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
    expect(find.text('ptrack'), findsWidgets);
    expect(find.text('No periods logged yet'), findsOneWidget);
    expect(find.textContaining('Tap + to log'), findsOneWidget);
  });

  testWidgets('About opens from home AppBar', (tester) async {
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
    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();
    expect(find.text('About ptrack'), findsOneWidget);
    expect(find.text('Your privacy & how estimates work'), findsOneWidget);
  });
}

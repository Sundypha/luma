import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:luma/features/shell/tab_shell.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class MockPeriodRepository extends Mock implements PeriodRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late MockPeriodRepository mockRepo;
  late PeriodCalendarContext calendar;

  setUp(() {
    mockRepo = MockPeriodRepository();
    calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value(const []),
    );
  });

  testWidgets('home shows insufficient-data state and tab labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TabShell(
          repository: mockRepo,
          calendar: calendar,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Luma'), findsWidgets);
    expect(
      find.text('Log a few more periods to see cycle insights'),
      findsOneWidget,
    );
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
  });

  testWidgets('About opens from drawer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TabShell(
          repository: mockRepo,
          calendar: calendar,
        ),
      ),
    );
    await tester.pump();
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('About Luma'), findsOneWidget);
    expect(find.text('Your privacy & how estimates work'), findsOneWidget);
  });
}

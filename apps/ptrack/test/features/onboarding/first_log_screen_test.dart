import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack/features/onboarding/first_log_screen.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

class MockPeriodRepository extends Mock implements PeriodRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockRepo;

  setUp(() {
    mockRepo = MockPeriodRepository();
  });

  setUpAll(() {
    registerFallbackValue(
      PeriodSpan(
        startUtc: DateTime.utc(2020, 1, 1),
        endUtc: DateTime.utc(2020, 1, 2),
      ),
    );
  });

  testWidgets('shows period-start hint', (tester) async {
    when(() => mockRepo.insertPeriod(any())).thenAnswer(
      (_) async => const PeriodWriteSuccess(1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FirstLogScreen(
          repository: mockRepo,
          onComplete: () {},
        ),
      ),
    );
    expect(
      find.textContaining('current or most recent period start'),
      findsOneWidget,
    );
  });

  testWidgets('ended period toggle shows end date row', (tester) async {
    when(() => mockRepo.insertPeriod(any())).thenAnswer(
      (_) async => const PeriodWriteSuccess(1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FirstLogScreen(
          repository: mockRepo,
          onComplete: () {},
        ),
      ),
    );
    expect(find.text('Change end date'), findsNothing);
    await tester.tap(find.text('This period has already ended'));
    await tester.pumpAndSettle();
    expect(find.text('Change end date'), findsOneWidget);
  });

  testWidgets('default date label matches today', (tester) async {
    when(() => mockRepo.insertPeriod(any())).thenAnswer(
      (_) async => const PeriodWriteSuccess(1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FirstLogScreen(
          repository: mockRepo,
          onComplete: () {},
        ),
      ),
    );
    final n = DateTime.now();
    final todayLocal = DateTime(n.year, n.month, n.day);
    final label = MaterialLocalizations.of(
      tester.element(find.byType(FirstLogScreen)),
    ).formatFullDate(todayLocal);
    expect(find.text(label), findsOneWidget);
  });

  testWidgets('Save & Continue calls insertPeriod and onComplete on success',
      (tester) async {
    var completed = false;
    final n = DateTime.now();
    final todayLocal = DateTime(n.year, n.month, n.day);
    final expectedUtc = DateTime.utc(
      todayLocal.year,
      todayLocal.month,
      todayLocal.day,
    );

    when(() => mockRepo.insertPeriod(any())).thenAnswer(
      (_) async => const PeriodWriteSuccess(1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FirstLogScreen(
          repository: mockRepo,
          onComplete: () => completed = true,
        ),
      ),
    );
    await tester.tap(find.text('Save & Continue'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(
      () => mockRepo.insertPeriod(
        PeriodSpan(startUtc: expectedUtc),
      ),
    ).called(1);
    expect(completed, isTrue);
  });

  testWidgets('Save with ended period sends start and end UTC (same day)',
      (tester) async {
    var completed = false;
    final n = DateTime.now();
    final todayLocal = DateTime(n.year, n.month, n.day);
    final dayUtc = DateTime.utc(
      todayLocal.year,
      todayLocal.month,
      todayLocal.day,
    );

    when(() => mockRepo.insertPeriod(any())).thenAnswer(
      (_) async => const PeriodWriteSuccess(1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FirstLogScreen(
          repository: mockRepo,
          onComplete: () => completed = true,
        ),
      ),
    );
    await tester.tap(find.text('This period has already ended'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & Continue'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(
      () => mockRepo.insertPeriod(
        PeriodSpan(startUtc: dayUtc, endUtc: dayUtc),
      ),
    ).called(1);
    expect(completed, isTrue);
  });

  testWidgets('PeriodWriteRejected shows SnackBar and skips onComplete',
      (tester) async {
    var completed = false;
    when(() => mockRepo.insertPeriod(any())).thenAnswer(
      (_) async => PeriodWriteRejected(const []),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FirstLogScreen(
          repository: mockRepo,
          onComplete: () => completed = true,
        ),
      ),
    );
    await tester.tap(find.text('Save & Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Could not save'), findsWidgets);
    expect(completed, isFalse);
  });
}

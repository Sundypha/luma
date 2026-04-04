import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack/features/onboarding/onboarding_screen.dart';
import 'package:ptrack/features/onboarding/onboarding_state.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingState onboardingState;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    onboardingState = await OnboardingState.create();
  });

  testWidgets('first page shows privacy / local-first title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onboardingState: onboardingState,
          onComplete: () {},
        ),
      ),
    );
    expect(find.text('Your data stays here'), findsOneWidget);
  });

  testWidgets('second page shows estimates / not-medical-advice title',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onboardingState: onboardingState,
          onComplete: () {},
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Estimates, not medical advice'), findsOneWidget);
  });

  testWidgets('required page has Continue, no Skip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onboardingState: onboardingState,
          onComplete: () {},
        ),
      ),
    );
    expect(find.text('Skip'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });

  testWidgets('last optional page shows Get Started only, no Skip',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onboardingState: onboardingState,
          onComplete: () {},
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Skip'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);
  });

  testWidgets('swipe on required page advances like Continue', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onboardingState: onboardingState,
          onComplete: () {},
        ),
      ),
    );
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
  });

  testWidgets('primary action on last page invokes onComplete', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onboardingState: onboardingState,
          onComplete: () => completed = true,
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Get Started'));
    await tester.pump();
    expect(completed, isTrue);
  });

  testWidgets('SmoothPageIndicator present with step count 3', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onboardingState: onboardingState,
          onComplete: () {},
        ),
      ),
    );
    final indicatorFinder = find.byType(SmoothPageIndicator);
    expect(indicatorFinder, findsOneWidget);
    final indicator = tester.widget<SmoothPageIndicator>(indicatorFinder);
    expect(indicator.count, 3);
  });
}

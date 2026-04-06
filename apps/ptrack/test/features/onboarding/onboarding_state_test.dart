import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/onboarding/onboarding_state.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('isCompleted defaults to false on fresh state', () async {
    final state = await OnboardingState.create();
    expect(state.isCompleted, isFalse);
  });

  test('currentStep defaults to 0 on fresh state', () async {
    final state = await OnboardingState.create();
    expect(state.currentStep, 0);
  });

  test('saveStep(2) then currentStep returns 2', () async {
    final state = await OnboardingState.create();
    await state.saveStep(2);
    expect(state.currentStep, 2);
  });

  test('markCompleted sets isCompleted and resets currentStep to 0', () async {
    final state = await OnboardingState.create();
    await state.saveStep(2);
    await state.markCompleted();
    expect(state.isCompleted, isTrue);
    expect(state.currentStep, 0);
  });

  test('round-trip: saveStep persists across new OnboardingState instance', () async {
    final first = await OnboardingState.create();
    await first.saveStep(1);
    final second = await OnboardingState.create();
    expect(second.currentStep, 1);
  });
}

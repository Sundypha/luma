import 'package:shared_preferences/shared_preferences.dart';

/// Persisted onboarding wizard progress (local-first; no network).
class OnboardingState {
  OnboardingState._(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const _keyCompleted = 'onboarding_completed';
  static const _keyStep = 'onboarding_current_step';

  static Future<OnboardingState> create() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_keyCompleted, _keyStep},
      ),
    );
    return OnboardingState._(prefs);
  }

  /// Wizard finished (user reached the end of the flow or equivalent).
  bool get isCompleted => _prefs.getBool(_keyCompleted) ?? false;

  /// Last saved page index while the wizard is in progress.
  int get currentStep => _prefs.getInt(_keyStep) ?? 0;

  Future<void> saveStep(int step) => _prefs.setInt(_keyStep, step);

  Future<void> markCompleted() async {
    await _prefs.setBool(_keyCompleted, true);
    await _prefs.remove(_keyStep);
  }
}

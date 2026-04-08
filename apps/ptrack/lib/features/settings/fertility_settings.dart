import 'package:shared_preferences/shared_preferences.dart';

/// Persisted preferences for the optional fertile-window estimate feature.
class FertilitySettings {
  FertilitySettings._();

  static const _keyEnabled = 'fertility_enabled';
  static const _keyDisclaimerAcknowledged = 'fertility_disclaimer_acknowledged';
  static const _keyCycleLengthOverride = 'fertility_cycle_length_override';
  static const _keyLutealPhaseDays = 'fertility_luteal_phase_days';
  static const _keySuggestionCardDismissed = 'fertility_suggestion_card_dismissed';

  static const int defaultLutealPhaseDays = 14;
  static const int minLutealPhaseDays = 5;
  static const int maxLutealPhaseDays = 20;

  static Future<bool> loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<void> saveEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  static Future<bool> loadDisclaimerAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDisclaimerAcknowledged) ?? false;
  }

  static Future<void> saveDisclaimerAcknowledged(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDisclaimerAcknowledged, value);
  }

  static Future<int?> loadCycleLengthOverride() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyCycleLengthOverride)) return null;
    return prefs.getInt(_keyCycleLengthOverride);
  }

  static Future<void> saveCycleLengthOverride(int? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_keyCycleLengthOverride);
    } else {
      await prefs.setInt(_keyCycleLengthOverride, value);
    }
  }

  static Future<int> loadLutealPhaseDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_keyLutealPhaseDays);
    return (raw ?? defaultLutealPhaseDays)
        .clamp(minLutealPhaseDays, maxLutealPhaseDays);
  }

  static Future<void> saveLutealPhaseDays(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLutealPhaseDays,
      value.clamp(minLutealPhaseDays, maxLutealPhaseDays),
    );
  }

  static Future<bool> loadSuggestionCardDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySuggestionCardDismissed) ?? false;
  }

  static Future<void> saveSuggestionCardDismissed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySuggestionCardDismissed, value);
  }
}

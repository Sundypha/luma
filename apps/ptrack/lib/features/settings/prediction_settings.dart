import 'package:shared_preferences/shared_preferences.dart';

/// How predicted days are shown on the calendar (ensemble agreement tiers).
enum PredictionDisplayMode {
  /// Only days where at least two methods agree (cold-start: single-method still shown).
  consensusOnly,

  /// Every predicted day, including lone-algorithm estimates.
  showAll,

  /// Same inclusion as [showAll]; UI may label lone-method days.
  showAllWithNote,
}

/// Persists [PredictionDisplayMode] for calendar prediction display.
class PredictionSettings {
  PredictionSettings._();

  static const _key = 'prediction_display_mode';

  static Future<PredictionDisplayMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == PredictionDisplayMode.showAll.name) {
      return PredictionDisplayMode.showAll;
    }
    if (raw == PredictionDisplayMode.showAllWithNote.name) {
      return PredictionDisplayMode.showAllWithNote;
    }
    return PredictionDisplayMode.consensusOnly;
  }

  static Future<void> save(PredictionDisplayMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

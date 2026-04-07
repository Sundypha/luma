import 'package:flutter/material.dart';
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

  static String subtitleForMode(PredictionDisplayMode mode) => switch (mode) {
        PredictionDisplayMode.consensusOnly =>
          'Show days where 2+ methods agree',
        PredictionDisplayMode.showAll => 'Show all predicted days',
        PredictionDisplayMode.showAllWithNote =>
          'Show all predicted days, with a note when one method applies',
      };
}

/// Picker for [PredictionDisplayMode], persisted like [MoodSettingsTile].
class PredictionSettingsTile extends StatefulWidget {
  const PredictionSettingsTile({super.key, this.onModeChanged});

  /// Notified after save; use to refresh calendar (e.g. [CalendarViewModel]).
  final ValueChanged<PredictionDisplayMode>? onModeChanged;

  @override
  State<PredictionSettingsTile> createState() => _PredictionSettingsTileState();
}

class _PredictionSettingsTileState extends State<PredictionSettingsTile> {
  PredictionDisplayMode _mode = PredictionDisplayMode.consensusOnly;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    PredictionSettings.load().then((m) {
      if (mounted) {
        setState(() {
          _mode = m;
          _loading = false;
        });
      }
    });
  }

  Future<void> _onChanged(PredictionDisplayMode? next) async {
    if (next == null || next == _mode) return;
    setState(() => _mode = next);
    await PredictionSettings.save(next);
    widget.onModeChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        title: Text('Prediction display'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return ListTile(
      title: const Text('Prediction display'),
      subtitle: Text(PredictionSettings.subtitleForMode(_mode)),
      trailing: DropdownButton<PredictionDisplayMode>(
        value: _mode,
        underline: const SizedBox.shrink(),
        isDense: true,
        items: [
          DropdownMenuItem(
            value: PredictionDisplayMode.consensusOnly,
            child: const Text('Consensus'),
          ),
          DropdownMenuItem(
            value: PredictionDisplayMode.showAll,
            child: const Text('All days'),
          ),
          DropdownMenuItem(
            value: PredictionDisplayMode.showAllWithNote,
            child: const Text('All + note'),
          ),
        ],
        onChanged: _onChanged,
      ),
    );
  }
}

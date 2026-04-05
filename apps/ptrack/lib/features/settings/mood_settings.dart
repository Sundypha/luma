import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How mood is shown on logging surfaces.
enum MoodDisplayMode {
  emoji,
  wordChip,
}

/// Persists [MoodDisplayMode] for accessibility / preference.
class MoodSettings {
  MoodSettings._();

  static const _key = 'mood_display_mode';

  static Future<MoodDisplayMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == MoodDisplayMode.wordChip.name) {
      return MoodDisplayMode.wordChip;
    }
    return MoodDisplayMode.emoji;
  }

  static Future<void> save(MoodDisplayMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

/// Toggle for word labels vs emoji in mood pickers.
class MoodSettingsTile extends StatefulWidget {
  const MoodSettingsTile({super.key});

  @override
  State<MoodSettingsTile> createState() => _MoodSettingsTileState();
}

class _MoodSettingsTileState extends State<MoodSettingsTile> {
  MoodDisplayMode _mode = MoodDisplayMode.emoji;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    MoodSettings.load().then((m) {
      if (mounted) {
        setState(() {
          _mode = m;
          _loading = false;
        });
      }
    });
  }

  Future<void> _onChanged(bool useWordLabels) async {
    final next =
        useWordLabels ? MoodDisplayMode.wordChip : MoodDisplayMode.emoji;
    setState(() => _mode = next);
    await MoodSettings.save(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        title: Text('Mood display'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return SwitchListTile(
      title: const Text('Use word labels for mood'),
      subtitle: const Text('Show text labels instead of emoji faces'),
      value: _mode == MoodDisplayMode.wordChip,
      onChanged: _onChanged,
    );
  }
}

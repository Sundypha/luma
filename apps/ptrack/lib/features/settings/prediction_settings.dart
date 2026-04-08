import 'package:flutter/material.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How many predicted days to show on the calendar.
enum PredictionDisplayMode {
  /// Only days where at least two methods agree (cold-start exception: when
  /// only one method can run it still shows).
  consensusOnly,

  /// Every predicted day, even if only one method covers it.
  showAll,

  /// Same inclusion as [showAll]; UI may add a note on single-method days.
  showAllWithNote,
}

/// Persistence for prediction display, enabled algorithms, and forecast horizon.
class PredictionSettings {
  PredictionSettings._();

  static const _displayKey = 'prediction_display_mode';
  static const _enabledAlgorithmsKey = 'prediction_enabled_algorithm_ids';
  static const _horizonKey = 'prediction_horizon_cycles';

  /// Default: 3 cycles ahead (~3 months for a typical cycle).
  static const int defaultHorizonCycles = 3;

  static Set<AlgorithmId> get defaultEnabledAlgorithms => {
        AlgorithmId.median,
        AlgorithmId.ewma,
        AlgorithmId.bayesian,
        AlgorithmId.linearTrend,
      };

  static const List<AlgorithmId> algorithmPickerOrder = [
    AlgorithmId.median,
    AlgorithmId.ewma,
    AlgorithmId.bayesian,
    AlgorithmId.linearTrend,
  ];

  static String userFacingName(AppLocalizations l10n, AlgorithmId id) =>
      switch (id) {
        AlgorithmId.median => l10n.algoNameMedian,
        AlgorithmId.ewma => l10n.algoNameEwma,
        AlgorithmId.bayesian => l10n.algoNameBayesian,
        AlgorithmId.linearTrend => l10n.predSettingsLinearTrendTitle,
      };

  static String userFacingHint(AppLocalizations l10n, AlgorithmId id) =>
      switch (id) {
        AlgorithmId.median => l10n.predSettingsHintMedian,
        AlgorithmId.ewma => l10n.predSettingsHintEwma,
        AlgorithmId.bayesian => l10n.predSettingsHintBayesian,
        AlgorithmId.linearTrend => l10n.predSettingsHintLinearTrend,
      };

  static Future<PredictionDisplayMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_displayKey);
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
    await prefs.setString(_displayKey, mode.name);
  }

  static Future<Set<AlgorithmId>> loadEnabledAlgorithms() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_enabledAlgorithmsKey)) {
      return Set<AlgorithmId>.from(defaultEnabledAlgorithms);
    }
    final raw = prefs.getString(_enabledAlgorithmsKey) ?? '';
    if (raw.isEmpty) return {};
    final parsed = <AlgorithmId>{};
    for (final part in raw.split(',')) {
      final name = part.trim();
      if (name.isEmpty) continue;
      for (final id in AlgorithmId.values) {
        if (id.name == name) parsed.add(id);
      }
    }
    return parsed.isEmpty ? {} : parsed;
  }

  static Future<void> saveEnabledAlgorithms(Set<AlgorithmId> enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final names = algorithmPickerOrder
        .where((id) => enabled.contains(id))
        .map((id) => id.name)
        .join(',');
    await prefs.setString(_enabledAlgorithmsKey, names);
  }

  /// Returns the stored horizon (clamped to 1–12). Defaults to [defaultHorizonCycles].
  static Future<int> loadHorizonCycles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_horizonKey);
    return (raw ?? defaultHorizonCycles).clamp(1, 12);
  }

  static Future<void> saveHorizonCycles(int horizon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_horizonKey, horizon.clamp(1, 12));
  }
}

/// Settings dialog entry: a single [ListTile] that navigates to [PredictionSettingsScreen].
class PredictionSettingsTile extends StatelessWidget {
  const PredictionSettingsTile({
    super.key,
    this.onModeChanged,
    this.onEnabledAlgorithmsChanged,
    this.onHorizonChanged,
  });

  final ValueChanged<PredictionDisplayMode>? onModeChanged;
  final ValueChanged<Set<AlgorithmId>>? onEnabledAlgorithmsChanged;
  final ValueChanged<int>? onHorizonChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.auto_awesome_outlined),
      title: Text(l10n.predSettingsTileTitle),
      subtitle: Text(l10n.predSettingsTileSubtitle),
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => PredictionSettingsScreen(
              onModeChanged: onModeChanged,
              onEnabledAlgorithmsChanged: onEnabledAlgorithmsChanged,
              onHorizonChanged: onHorizonChanged,
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen prediction settings page (same style as DataSettingsScreen).
class PredictionSettingsScreen extends StatefulWidget {
  const PredictionSettingsScreen({
    super.key,
    this.onModeChanged,
    this.onEnabledAlgorithmsChanged,
    this.onHorizonChanged,
  });

  final ValueChanged<PredictionDisplayMode>? onModeChanged;
  final ValueChanged<Set<AlgorithmId>>? onEnabledAlgorithmsChanged;
  final ValueChanged<int>? onHorizonChanged;

  @override
  State<PredictionSettingsScreen> createState() =>
      _PredictionSettingsScreenState();
}

class _PredictionSettingsScreenState extends State<PredictionSettingsScreen> {
  PredictionDisplayMode _mode = PredictionDisplayMode.consensusOnly;
  Set<AlgorithmId> _enabled =
      Set<AlgorithmId>.from(PredictionSettings.defaultEnabledAlgorithms);
  int _horizonCycles = PredictionSettings.defaultHorizonCycles;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.wait<Object>([
      PredictionSettings.load(),
      PredictionSettings.loadEnabledAlgorithms(),
      PredictionSettings.loadHorizonCycles(),
    ]).then((results) {
      if (!mounted) return;
      setState(() {
        _mode = results[0] as PredictionDisplayMode;
        _enabled = Set<AlgorithmId>.from(results[1] as Set<AlgorithmId>);
        _horizonCycles = results[2] as int;
        _loading = false;
      });
    });
  }

  Future<void> _onModeChanged(PredictionDisplayMode? next) async {
    if (next == null || next == _mode) return;
    setState(() => _mode = next);
    await PredictionSettings.save(next);
    widget.onModeChanged?.call(next);
  }

  Future<void> _onAlgorithmToggled(AlgorithmId id, bool on) async {
    final next = Set<AlgorithmId>.from(_enabled);
    if (on) {
      next.add(id);
    } else {
      next.remove(id);
    }
    setState(() => _enabled = next);
    await PredictionSettings.saveEnabledAlgorithms(next);
    widget.onEnabledAlgorithmsChanged?.call(next);
  }

  Future<void> _onHorizonChanged(int? next) async {
    if (next == null || next == _horizonCycles) return;
    setState(() => _horizonCycles = next);
    await PredictionSettings.saveHorizonCycles(next);
    widget.onHorizonChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.predSettingsAppBarTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _SectionHeader(l10n.predSettingsSectionHowManyDays),
                RadioListTile<PredictionDisplayMode>(
                  title: Text(l10n.predSettingsModeConsensusTitle),
                  subtitle: Text(
                    l10n.predSettingsModeConsensusSubtitle,
                    style: caption,
                  ),
                  value: PredictionDisplayMode.consensusOnly,
                  groupValue: _mode,
                  onChanged: _onModeChanged,
                ),
                RadioListTile<PredictionDisplayMode>(
                  title: Text(l10n.predSettingsModeAllTitle),
                  subtitle: Text(
                    l10n.predSettingsModeAllSubtitle,
                    style: caption,
                  ),
                  value: PredictionDisplayMode.showAll,
                  groupValue: _mode,
                  onChanged: _onModeChanged,
                ),
                RadioListTile<PredictionDisplayMode>(
                  title: Text(l10n.predSettingsModeAllNotesTitle),
                  subtitle: Text(
                    l10n.predSettingsModeAllNotesSubtitle,
                    style: caption,
                  ),
                  value: PredictionDisplayMode.showAllWithNote,
                  groupValue: _mode,
                  onChanged: _onModeChanged,
                ),
                const Divider(),
                _SectionHeader(l10n.predSettingsSectionHorizon),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l10n.predSettingsHorizonCaption,
                    style: caption,
                  ),
                ),
                RadioListTile<int>(
                  title: Text(l10n.predSettingsHorizonNextOnly),
                  value: 1,
                  groupValue: _horizonCycles,
                  onChanged: _onHorizonChanged,
                ),
                RadioListTile<int>(
                  title: Text(l10n.predSettingsHorizon3Title),
                  subtitle:
                      Text(l10n.predSettingsHorizon3Subtitle, style: caption),
                  value: 3,
                  groupValue: _horizonCycles,
                  onChanged: _onHorizonChanged,
                ),
                RadioListTile<int>(
                  title: Text(l10n.predSettingsHorizon6Title),
                  subtitle: Text(
                    l10n.predSettingsHorizon6Subtitle,
                    style: caption,
                  ),
                  value: 6,
                  groupValue: _horizonCycles,
                  onChanged: _onHorizonChanged,
                ),
                const Divider(),
                _SectionHeader(l10n.predSettingsSectionMethods),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l10n.predSettingsMethodsCaption,
                    style: caption,
                  ),
                ),
                ...PredictionSettings.algorithmPickerOrder.map(
                  (id) => SwitchListTile(
                    title: Text(PredictionSettings.userFacingName(l10n, id)),
                    subtitle: Text(
                      PredictionSettings.userFacingHint(l10n, id),
                      style: caption,
                    ),
                    value: _enabled.contains(id),
                    onChanged: (v) => _onAlgorithmToggled(id, v),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Compact section header matching the style used in [DataSettingsScreen].
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

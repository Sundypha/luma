import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
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
  static const int minCycleLengthDays = 20;
  static const int maxCycleLengthDays = 45;

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

/// Summary of completed cycle intervals from history (for setup auto-fill).
@immutable
class FertilityCycleHistorySummary {
  const FertilityCycleHistorySummary({
    required this.completedIntervalCount,
    this.averageCycleLengthDays,
  });

  /// Number of cycle-length intervals derived from logged periods.
  final int completedIntervalCount;

  /// Rounded mean length in days when [completedIntervalCount] is positive.
  final int? averageCycleLengthDays;
}

Future<FertilityCycleHistorySummary> loadFertilityCycleHistorySummary({
  required PeriodRepository repository,
  required PeriodCalendarContext calendar,
}) async {
  final stored = await repository.listOrderedByStartUtc();
  final inputs = predictionCycleInputsFromStored(
    stored: stored,
    calendar: calendar,
  );
  if (inputs.isEmpty) {
    return const FertilityCycleHistorySummary(completedIntervalCount: 0);
  }
  final sum = inputs.fold<int>(0, (a, c) => a + c.lengthInDays);
  final avg = (sum / inputs.length).round();
  return FertilityCycleHistorySummary(
    completedIntervalCount: inputs.length,
    averageCycleLengthDays: avg,
  );
}

Future<bool> showFertilityDisclaimerSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: 24 + MediaQuery.viewPaddingOf(ctx).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.fertilityDisclaimerTitle,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.fertilityDisclaimerBody,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.fertilityDisclaimerAccept),
              ),
            ],
          ),
        ),
      );
    },
  );
  return accepted == true;
}

Future<bool> showFertilityInputSheet(
  BuildContext context, {
  required PeriodRepository repository,
  required PeriodCalendarContext calendar,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) {
      return _FertilityInputSheet(
        repository: repository,
        calendar: calendar,
      );
    },
  );
  return saved == true;
}

class _FertilityInputSheet extends StatefulWidget {
  const _FertilityInputSheet({
    required this.repository,
    required this.calendar,
  });

  final PeriodRepository repository;
  final PeriodCalendarContext calendar;

  @override
  State<_FertilityInputSheet> createState() => _FertilityInputSheetState();
}

class _FertilityInputSheetState extends State<_FertilityInputSheet> {
  final _cycleController = TextEditingController();
  bool _loading = true;
  double _luteal = FertilitySettings.defaultLutealPhaseDays.toDouble();
  int _intervalCount = 0;
  bool _hasEnoughForAuto = false;
  int? _averageRounded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cycleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final summary = await loadFertilityCycleHistorySummary(
      repository: widget.repository,
      calendar: widget.calendar,
    );
    final override = await FertilitySettings.loadCycleLengthOverride();
    final luteal = await FertilitySettings.loadLutealPhaseDays();
    final hasEnough = summary.completedIntervalCount >= 2;
    final avg = summary.averageCycleLengthDays;
    final initialCycle = (override ??
            (hasEnough && avg != null
                ? avg.clamp(
                    FertilitySettings.minCycleLengthDays,
                    FertilitySettings.maxCycleLengthDays,
                  )
                : 28))
        .clamp(
      FertilitySettings.minCycleLengthDays,
      FertilitySettings.maxCycleLengthDays,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _cycleController.text = '$initialCycle';
      _luteal = luteal.toDouble();
      _intervalCount = summary.completedIntervalCount;
      _hasEnoughForAuto = hasEnough;
      _averageRounded = avg;
    });
  }

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final parsed = int.tryParse(_cycleController.text.trim());
    if (parsed == null ||
        parsed < FertilitySettings.minCycleLengthDays ||
        parsed > FertilitySettings.maxCycleLengthDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.fertilityInputCycleLengthLabel} '
            '(${FertilitySettings.minCycleLengthDays}–'
            '${FertilitySettings.maxCycleLengthDays})',
          ),
        ),
      );
      return;
    }
    final avgClamped = _averageRounded?.clamp(
      FertilitySettings.minCycleLengthDays,
      FertilitySettings.maxCycleLengthDays,
    );
    if (_hasEnoughForAuto && avgClamped != null && parsed == avgClamped) {
      await FertilitySettings.saveCycleLengthOverride(null);
    } else {
      await FertilitySettings.saveCycleLengthOverride(parsed);
    }
    await FertilitySettings.saveLutealPhaseDays(_luteal.round());
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.fertilityInputTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.fertilityInputCycleLengthLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  if (_hasEnoughForAuto)
                    Text(
                      l10n.fertilityInputCycleLengthAutoHint(_intervalCount),
                      style: caption,
                    )
                  else
                    Text(
                      l10n.fertilityInputNotEnoughData,
                      style: caption,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.fertilityInputCycleLengthManualHint,
                    style: caption,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cycleController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixText:
                          '${FertilitySettings.minCycleLengthDays}–${FertilitySettings.maxCycleLengthDays}',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.fertilityInputLutealPhaseLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.fertilityInputLutealPhaseExplanation,
                    style: caption,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          min: FertilitySettings.minLutealPhaseDays.toDouble(),
                          max: FertilitySettings.maxLutealPhaseDays.toDouble(),
                          divisions: FertilitySettings.maxLutealPhaseDays -
                              FertilitySettings.minLutealPhaseDays,
                          value: _luteal.clamp(
                            FertilitySettings.minLutealPhaseDays.toDouble(),
                            FertilitySettings.maxLutealPhaseDays.toDouble(),
                          ),
                          label: l10n.fertilityInputLutealPhaseDaysUnit(
                            _luteal.round(),
                          ),
                          onChanged: (v) => setState(() => _luteal = v),
                        ),
                      ),
                      SizedBox(
                        width: 88,
                        child: Text(
                          l10n.fertilityInputLutealPhaseDaysUnit(
                            _luteal.round(),
                          ),
                          style: theme.textTheme.titleSmall,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _save(context),
                    child: Text(l10n.fertilityInputSave),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Opt-in toggle for the fertile-window estimate; runs disclaimer then setup sheet.
class FertilitySettingsTile extends StatefulWidget {
  const FertilitySettingsTile({
    super.key,
    required this.repository,
    required this.calendar,
    this.onFertilityToggled,
  });

  final PeriodRepository repository;
  final PeriodCalendarContext calendar;
  final ValueChanged<bool>? onFertilityToggled;

  @override
  State<FertilitySettingsTile> createState() => _FertilitySettingsTileState();
}

class _FertilitySettingsTileState extends State<FertilitySettingsTile> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    FertilitySettings.loadEnabled().then((v) {
      if (mounted) {
        setState(() {
          _enabled = v;
          _loading = false;
        });
      }
    });
  }

  Future<void> _onChanged(bool wantOn) async {
    if (!wantOn) {
      await FertilitySettings.saveEnabled(false);
      if (mounted) {
        setState(() => _enabled = false);
        widget.onFertilityToggled?.call(false);
      }
      return;
    }

    if (!mounted) return;
    if (!await FertilitySettings.loadDisclaimerAcknowledged()) {
      if (!mounted) return;
      final accepted = await showFertilityDisclaimerSheet(context);
      if (!mounted) return;
      if (!accepted) return;
      await FertilitySettings.saveDisclaimerAcknowledged(true);
    }

    if (!mounted) return;
    final inputOk = await showFertilityInputSheet(
      context,
      repository: widget.repository,
      calendar: widget.calendar,
    );
    if (!mounted) return;
    if (!inputOk) return;

    await FertilitySettings.saveEnabled(true);
    if (mounted) {
      setState(() => _enabled = true);
      widget.onFertilityToggled?.call(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return ListTile(
        leading: const Icon(Icons.spa_outlined),
        title: Text(l10n.fertilitySettingsTitle),
        trailing: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return SwitchListTile(
      secondary: const Icon(Icons.spa_outlined),
      title: Text(l10n.fertilitySettingsTitle),
      subtitle: Text(l10n.fertilitySettingsSubtitle),
      value: _enabled,
      onChanged: _onChanged,
    );
  }
}

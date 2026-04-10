import 'package:flutter/material.dart';

import 'package:luma/features/lock/lock_service.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:luma/features/lock/pin_entry_widget.dart';
import 'package:luma/features/lock/pin_setup_sheet.dart';

/// Settings surface for PIN lock, biometrics, and immediate lock.
class LockSettingsScreen extends StatefulWidget {
  const LockSettingsScreen({
    super.key,
    required this.lockService,
    required this.onReset,
    required this.onLockNow,
  });

  final LockService lockService;
  final VoidCallback onReset;
  final VoidCallback onLockNow;

  @override
  State<LockSettingsScreen> createState() => _LockSettingsScreenState();
}

class _LockSettingsScreenState extends State<LockSettingsScreen> {
  bool _isEnabled = false;
  bool _bioEnabled = false;
  bool _canUseBiometrics = false;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.lockService.isEnabled;
    _bioEnabled = widget.lockService.isBiometricsEnabled;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBiometricAvailability());
  }

  Future<void> _loadBiometricAvailability() async {
    final can = await widget.lockService.canUseBiometrics();
    if (!mounted) {
      return;
    }
    setState(() {
      _canUseBiometrics = can;
      _loadingPrefs = false;
    });
  }

  Future<void> _refreshFromService() async {
    setState(() {
      _isEnabled = widget.lockService.isEnabled;
      _bioEnabled = widget.lockService.isBiometricsEnabled;
    });
  }

  Future<void> _enableLock() async {
    final ok = await showPinSetupSheet(
      context,
      lockService: widget.lockService,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      await _refreshFromService();
    }
  }

  Future<void> _onLockSwitchChanged(bool wantOn) async {
    if (wantOn) {
      await _enableLock();
    } else {
      await _disableLock();
    }
  }

  Future<void> _disableLock() async {
    final authed = await _showReAuthDialog();
    if (!authed || !mounted) {
      return;
    }
    await widget.lockService.disableLock();
    await _refreshFromService();
  }

  Future<void> _changePin() async {
    final authed = await _showReAuthDialog();
    if (!authed || !mounted) {
      return;
    }
    final ok = await showPinSetupSheet(
      context,
      lockService: widget.lockService,
      skipAck: true,
      changePinOnly: true,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      await _refreshFromService();
    }
  }

  Future<bool> _showReAuthDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _LockReAuthDialog(
          lockService: widget.lockService,
          canUseBiometrics: _canUseBiometrics,
        );
      },
    );
    return result ?? false;
  }

  Future<void> _setBiometrics(bool enabled) async {
    await widget.lockService.setBiometricsEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(() => _bioEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lockSettingsAppBar),
      ),
      body: _loadingPrefs
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SwitchListTile(
                  title: Text(l10n.lockSettingsSwitchTitle),
                  subtitle: Text(l10n.lockSettingsSwitchSubtitle),
                  value: _isEnabled,
                  onChanged: _onLockSwitchChanged,
                ),
                if (_isEnabled) ...[
                  ListTile(
                    title: Text(l10n.lockSettingsChangePin),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePin,
                  ),
                  if (_canUseBiometrics)
                    SwitchListTile(
                      title: Text(l10n.lockSettingsUseBiometrics),
                      value: _bioEnabled,
                      onChanged: _setBiometrics,
                    ),
                  ListTile(
                    title: Text(l10n.lockSettingsLockNow),
                    trailing: IconButton(
                      icon: const Icon(Icons.lock_outlined),
                      tooltip: l10n.lockSettingsLockNowTooltip,
                      onPressed: widget.onLockNow,
                    ),
                    onTap: widget.onLockNow,
                  ),
                ],
              ],
            ),
    );
  }
}

class _LockReAuthDialog extends StatefulWidget {
  const _LockReAuthDialog({
    required this.lockService,
    required this.canUseBiometrics,
  });

  final LockService lockService;
  final bool canUseBiometrics;

  @override
  State<_LockReAuthDialog> createState() => _LockReAuthDialogState();
}

class _LockReAuthDialogState extends State<_LockReAuthDialog> {
  bool _busy = false;
  bool _hasError = false;
  int _attemptKey = 0;

  Future<void> _verifyPin(String pin) async {
    setState(() {
      _busy = true;
      _hasError = false;
    });
    final ok = await widget.lockService.verifyPin(pin);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _hasError = true;
        _attemptKey++;
      });
    }
  }

  Future<void> _tryBiometric() async {
    setState(() {
      _busy = true;
      _hasError = false;
    });
    final l10n = AppLocalizations.of(context);
    final ok = await widget.lockService.authenticateWithBiometrics(
      l10n.lockBiometricSettingsReason,
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.lockReauthTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.lockReauthBody,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              PinEntryWidget(
                key: ValueKey<int>(_attemptKey),
                pinLength: 20,
                submitOnComplete: false,
                showExpectedLength: false,
                onSubmit: _verifyPin,
                errorText: _hasError ? l10n.lockIncorrectPin : null,
              ),
              if (widget.canUseBiometrics) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _tryBiometric,
                  child: Text(l10n.lockUseBiometrics),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.importCancel),
        ),
      ],
    );
  }
}

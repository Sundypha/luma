import 'package:flutter/material.dart';

import 'package:luma/features/lock/lock_service.dart';
import 'package:luma/features/lock/pin_entry_widget.dart';

/// Multi-step bottom sheet: acknowledgment, PIN create/confirm, optional biometrics.
///
/// Returns `true` only after PIN is set (and lock enabled when [changePinOnly] is false).
Future<bool> showPinSetupSheet(
  BuildContext context, {
  required LockService lockService,
  bool skipAck = false,
  bool changePinOnly = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _PinSetupSheetBody(
        lockService: lockService,
        startStep: skipAck ? 1 : 0,
        changePinOnly: changePinOnly,
      );
    },
  );
  return result ?? false;
}

class _PinSetupSheetBody extends StatefulWidget {
  const _PinSetupSheetBody({
    required this.lockService,
    required this.startStep,
    required this.changePinOnly,
  });

  final LockService lockService;
  final int startStep;
  final bool changePinOnly;

  @override
  State<_PinSetupSheetBody> createState() => _PinSetupSheetBodyState();
}

class _PinSetupSheetBodyState extends State<_PinSetupSheetBody> {
  late int _step;
  String? _firstPin;
  int _confirmKey = 0;
  String? _confirmError;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _step = widget.startStep;
  }

  void _cancel() {
    Navigator.of(context).pop(false);
  }

  void _finishSuccess() {
    Navigator.of(context).pop(true);
  }

  Future<void> _onFirstEntry(String pin) async {
    setState(() {
      _firstPin = pin;
      _step = 2;
      _confirmError = null;
    });
  }

  Future<void> _onConfirmEntry(String pin) async {
    if (_firstPin != pin) {
      setState(() {
        _confirmKey++;
        _confirmError = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _confirmError = null;
      _finishing = true;
    });

    await widget.lockService.createPin(pin);
    if (!widget.changePinOnly) {
      await widget.lockService.enableLock();
    }

    if (!mounted) {
      return;
    }

    setState(() => _finishing = false);

    final canBio = await widget.lockService.canUseBiometrics();
    if (!mounted) {
      return;
    }
    if (canBio) {
      setState(() => _step = 3);
    } else {
      _finishSuccess();
    }
  }

  Future<void> _enableBiometrics() async {
    await widget.lockService.setBiometricsEnabled(true);
    if (!mounted) {
      return;
    }
    _finishSuccess();
  }

  void _skipBiometrics() {
    _finishSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: switch (_step) {
          0 => _buildAckStep(theme),
          1 => _buildCreatePinStep(theme),
          2 => _buildConfirmPinStep(theme),
          _ => _buildBiometricStep(theme),
        },
      ),
    );
  }

  Widget _buildAckStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Set up app lock', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          'App lock encrypts access with a PIN. If you forget your PIN, the only '
          'recovery option is a data reset — your period data will be erased. '
          'Export your data regularly to avoid data loss.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('I understand, continue'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildCreatePinStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create a PIN', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Enter a 4-digit PIN.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        PinEntryWidget(
          pinLength: 4,
          submitOnComplete: true,
          onSubmit: _onFirstEntry,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildConfirmPinStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm your PIN', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        if (_finishing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          PinEntryWidget(
            key: ValueKey<int>(_confirmKey),
            pinLength: 4,
            submitOnComplete: true,
            onSubmit: _onConfirmEntry,
            errorText: _confirmError,
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildBiometricStep(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enable biometrics for faster unlock?',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _enableBiometrics,
          child: const Text('Enable biometrics'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: _skipBiometrics,
          style: FilledButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
          ),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:luma/features/lock/lock_service.dart';
import 'package:luma/features/lock/lock_view_model.dart';
import 'package:luma/features/lock/pin_entry_widget.dart';

/// Full-screen lock UI with optional biometrics and forgot-PIN entry point.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.lockService,
    required this.onUnlocked,
    this.onForgotPin,
  });

  final LockService lockService;
  final VoidCallback onUnlocked;
  final VoidCallback? onForgotPin;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final LockViewModel _viewModel;
  bool _canUseBio = false;
  bool _didAutoBio = false;

  @override
  void initState() {
    super.initState();
    _viewModel = LockViewModel(lockService: widget.lockService);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBiometrics());
  }

  Future<void> _initBiometrics() async {
    final can = await widget.lockService.canUseBiometrics();
    if (!mounted) {
      return;
    }
    setState(() => _canUseBio = can);
    if (!_didAutoBio &&
        can &&
        widget.lockService.isBiometricsEnabled) {
      _didAutoBio = true;
      await _viewModel.authenticateBiometric(onUnlocked: widget.onUnlocked);
    }
  }

  Future<void> _triggerBio() async {
    _viewModel.clearError();
    await _viewModel.authenticateBiometric(onUnlocked: widget.onUnlocked);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Luma',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 32),
                    PinEntryWidget(
                      key: ValueKey<int>(_viewModel.attemptCount),
                      pinLength: 4,
                      submitOnComplete: true,
                      onSubmit: (pin) => _viewModel.verifyPin(
                        pin,
                        onUnlocked: widget.onUnlocked,
                      ),
                      errorText: _viewModel.hasError
                          ? _viewModel.errorMessage
                          : null,
                    ),
                    if (_viewModel.isLoading) ...[
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                    if (_canUseBio) ...[
                      const SizedBox(height: 24),
                      FilledButton.tonal(
                        onPressed:
                            _viewModel.isLoading ? null : _triggerBio,
                        child: const Text('Use biometrics'),
                      ),
                    ],
                    if (widget.onForgotPin != null) ...[
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: widget.onForgotPin,
                        child: const Text('Forgot PIN?'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

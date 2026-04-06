import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:luma/features/lock/forgot_pin_sheet.dart';
import 'package:luma/features/lock/lock_screen.dart';
import 'package:luma/features/lock/lock_service.dart';

/// Shows [LockScreen] when the app should be locked (cold start or lifecycle).
class LockGate extends StatefulWidget {
  const LockGate({
    super.key,
    required this.lockService,
    required this.child,
    required this.onReset,
    this.lockNowSignal,
  });

  final LockService lockService;
  final Widget child;
  final VoidCallback onReset;
  final ValueListenable<int>? lockNowSignal;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  late bool _isLocked;
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.lockService.isEnabled;
    _listener = AppLifecycleListener(
      onPause: () {
        if (widget.lockService.isEnabled) {
          setState(() => _isLocked = true);
        }
      },
      onResume: () {
        setState(() {});
      },
    );
    widget.lockNowSignal?.addListener(_onLockNowSignal);
  }

  @override
  void didUpdateWidget(LockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockNowSignal != widget.lockNowSignal) {
      oldWidget.lockNowSignal?.removeListener(_onLockNowSignal);
      widget.lockNowSignal?.addListener(_onLockNowSignal);
    }
  }

  void _onLockNowSignal() {
    if (!mounted) {
      return;
    }
    setState(() => _isLocked = true);
  }

  @override
  void dispose() {
    widget.lockNowSignal?.removeListener(_onLockNowSignal);
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return LockScreen(
        lockService: widget.lockService,
        onUnlocked: () => setState(() => _isLocked = false),
        onForgotPin: () => showForgotPinSheet(
          context,
          onReset: widget.onReset,
        ),
      );
    }
    return widget.child;
  }
}

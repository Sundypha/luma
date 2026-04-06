import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:luma/features/lock/forgot_pin_sheet.dart';
import 'package:luma/features/lock/lock_screen.dart';
import 'package:luma/features/lock/lock_service.dart';

bool get _backgroundLockSupported =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Shows [LockScreen] when the app should be locked (cold start or lifecycle).
///
/// Background/resume locking uses [AppLifecycleListener] (`onPause` and
/// `onHide` on mobile) and is only applied on **Android and iOS**. Other
/// platforms are out of product scope.
///
/// When [onBeforeLock] is provided, it runs immediately before the gate locks
/// (lifecycle or [lockNowSignal]) so the root [Navigator] can pop overlay
/// routes — otherwise [LockScreen] can sit under a pushed route (e.g. settings).
class LockGate extends StatefulWidget {
  const LockGate({
    super.key,
    required this.lockService,
    required this.child,
    required this.onReset,
    this.lockNowSignal,
    this.onBeforeLock,
  });

  final LockService lockService;
  final Widget child;
  final VoidCallback onReset;
  final ValueListenable<int>? lockNowSignal;

  /// Pops pushed routes on the app root navigator before showing [LockScreen].
  final VoidCallback? onBeforeLock;

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
        if (_backgroundLockSupported) {
          _lockIfEnabled();
        }
      },
      onHide: () {
        if (_backgroundLockSupported) {
          _lockIfEnabled();
        }
      },
      onResume: () {
        setState(() {});
      },
    );
    widget.lockNowSignal?.addListener(_onLockNowSignal);
  }

  void _lockIfEnabled() {
    if (!mounted) {
      return;
    }
    if (!widget.lockService.isEnabled) {
      return;
    }
    widget.onBeforeLock?.call();
    setState(() => _isLocked = true);
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
    if (!widget.lockService.isEnabled) {
      return;
    }
    widget.onBeforeLock?.call();
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

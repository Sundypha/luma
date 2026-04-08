import 'package:flutter/foundation.dart';

import 'package:luma/features/lock/lock_service.dart';

/// Drives PIN verification and biometric unlock for [LockScreen].
class LockViewModel extends ChangeNotifier {
  LockViewModel({required this.lockService});

  final LockService lockService;

  bool isLoading = false;
  bool hasError = false;
  /// True after a failed PIN attempt; UI maps to localized "Incorrect PIN".
  bool wrongPin = false;
  int attemptCount = 0;

  Future<void> verifyPin(
    String pin, {
    required VoidCallback onUnlocked,
  }) async {
    isLoading = true;
    notifyListeners();
    final ok = await lockService.verifyPin(pin);
    isLoading = false;
    if (ok) {
      hasError = false;
      wrongPin = false;
      notifyListeners();
      onUnlocked();
    } else {
      hasError = true;
      wrongPin = true;
      attemptCount += 1;
      notifyListeners();
    }
  }

  Future<void> authenticateBiometric({
    required VoidCallback onUnlocked,
    required String localizedReason,
  }) async {
    isLoading = true;
    notifyListeners();
    final ok = await lockService.authenticateWithBiometrics(
      localizedReason,
    );
    isLoading = false;
    if (ok) {
      hasError = false;
      wrongPin = false;
      notifyListeners();
      onUnlocked();
    } else {
      hasError = true;
      notifyListeners();
    }
  }

  void clearError() {
    hasError = false;
    wrongPin = false;
    isLoading = false;
    notifyListeners();
  }
}

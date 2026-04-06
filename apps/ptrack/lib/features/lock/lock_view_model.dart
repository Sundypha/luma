import 'package:flutter/foundation.dart';

import 'package:luma/features/lock/lock_service.dart';

/// Drives PIN verification and biometric unlock for [LockScreen].
class LockViewModel extends ChangeNotifier {
  LockViewModel({required this.lockService});

  final LockService lockService;

  bool isLoading = false;
  bool hasError = false;
  String? errorMessage;
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
      errorMessage = null;
      notifyListeners();
      onUnlocked();
    } else {
      hasError = true;
      errorMessage = 'Incorrect PIN';
      attemptCount += 1;
      notifyListeners();
    }
  }

  Future<void> authenticateBiometric({
    required VoidCallback onUnlocked,
  }) async {
    isLoading = true;
    notifyListeners();
    final ok = await lockService.authenticateWithBiometrics(
      'Authenticate to unlock Luma',
    );
    isLoading = false;
    if (ok) {
      hasError = false;
      errorMessage = null;
      notifyListeners();
      onUnlocked();
    } else {
      hasError = true;
      errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    hasError = false;
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}

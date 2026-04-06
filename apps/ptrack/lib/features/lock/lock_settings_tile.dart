import 'package:flutter/material.dart';

import 'package:luma/features/lock/lock_service.dart';
import 'package:luma/features/lock/lock_settings_screen.dart';

/// Drawer settings entry for app lock and biometrics.
class LockSettingsTile extends StatelessWidget {
  const LockSettingsTile({
    super.key,
    required this.lockService,
    required this.onReset,
    required this.onLockNow,
  });

  final LockService lockService;
  final VoidCallback onReset;
  final VoidCallback onLockNow;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lock_outlined),
      title: const Text('Privacy & Security'),
      subtitle: lockService.isEnabled
          ? const Text('App lock is on')
          : const Text(
              'Lock with PIN or biometrics when returning from background',
            ),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => LockSettingsScreen(
              lockService: lockService,
              onReset: onReset,
              onLockNow: onLockNow,
            ),
          ),
        );
      },
    );
  }
}

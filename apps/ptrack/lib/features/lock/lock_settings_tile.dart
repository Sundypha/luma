import 'package:flutter/material.dart';

import 'package:luma/features/lock/lock_service.dart';
import 'package:luma/features/lock/lock_settings_screen.dart';
import 'package:luma/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.lock_outlined),
      title: Text(l10n.lockPrivacySecurityTile),
      subtitle: lockService.isEnabled
          ? Text(l10n.lockPrivacySecurityOnSubtitle)
          : Text(l10n.lockPrivacySecurityOffSubtitle),
      onTap: () {
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

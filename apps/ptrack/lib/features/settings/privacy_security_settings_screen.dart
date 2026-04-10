import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../../l10n/app_localizations.dart';
import '../backup/data_settings_screen.dart';
import '../lock/lock_service.dart';
import '../lock/lock_settings_tile.dart';

class PrivacySecuritySettingsScreen extends StatelessWidget {
  const PrivacySecuritySettingsScreen({
    super.key,
    required this.lockService,
    required this.onReset,
    required this.onLockNow,
    required this.repository,
    required this.calendar,
  });

  final LockService lockService;
  final VoidCallback onReset;
  final VoidCallback onLockNow;
  final PeriodRepository repository;
  final PeriodCalendarContext calendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lockPrivacySecurityTile)),
      body: ListView(
        children: [
          LockSettingsTile(
            lockService: lockService,
            onReset: onReset,
            onLockNow: onLockNow,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l10n.dataSettingsTitle),
            subtitle: Text(l10n.settingsMenuDataBackupSubtitle),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => DataSettingsScreen(
                    repository: repository,
                    calendar: calendar,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

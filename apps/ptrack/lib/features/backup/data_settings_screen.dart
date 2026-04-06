import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import 'export_wizard_screen.dart';

/// Entry point for backup and restore (export wired; import in a later plan).
class DataSettingsScreen extends StatelessWidget {
  const DataSettingsScreen({super.key, required this.repository});

  final PeriodRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export Backup'),
            subtitle: const Text('Save your data as a .luma file'),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ExportWizardScreen(
                    service: ExportService(repository.database),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore data from a .luma file'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Auto-backups'),
            subtitle: const Text('Snapshots created before each import'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

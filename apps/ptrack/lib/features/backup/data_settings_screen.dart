import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../../l10n/app_localizations.dart';
import '../pdf_export/pdf_export_screen.dart';
import 'export_wizard_screen.dart';
import 'import_screen.dart';

/// Entry point for backup and restore (export and import).
class DataSettingsScreen extends StatelessWidget {
  const DataSettingsScreen({
    super.key,
    required this.repository,
    required this.calendar,
  });

  final PeriodRepository repository;
  final PeriodCalendarContext calendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataSettingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(l10n.dataExportTitle),
            subtitle: Text(l10n.dataExportSubtitle),
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
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(l10n.pdfExportTitle),
            subtitle: Text(l10n.pdfExportSubtitle),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PdfExportScreen(
                    repository: repository,
                    calendar: calendar,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.dataImportTitle),
            subtitle: Text(l10n.dataImportSubtitle),
            onTap: () {
              final db = repository.database;
              final backup = BackupService(db);
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ImportScreen(
                    importService: ImportService(
                      db,
                      calendar: calendar,
                      backupService: backup,
                    ),
                    db: db,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: Text(l10n.dataAutoBackupsTitle),
            subtitle: Text(l10n.dataAutoBackupsSubtitle),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

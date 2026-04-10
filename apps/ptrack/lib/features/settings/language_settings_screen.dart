import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_language_settings.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsMenuLanguageTitle)),
      body: ListView(
        children: const [
          AppLanguageSettingsSection(showSectionHeading: false),
        ],
      ),
    );
  }
}

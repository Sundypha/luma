import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats a UTC export timestamp for display using the active UI locale.
String formatBackupExportedAt(BuildContext context, DateTime exportedAtUtc) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).add_jm().format(exportedAtUtc.toLocal());
}

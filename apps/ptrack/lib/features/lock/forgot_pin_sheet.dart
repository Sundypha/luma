import 'package:flutter/material.dart';

import 'package:luma/l10n/app_localizations.dart';

/// Honest destructive reset flow: no hidden recovery channel (LOCK-03).
Future<void> showForgotPinSheet(
  BuildContext context, {
  required VoidCallback onReset,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colorScheme = theme.colorScheme;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final l10n = AppLocalizations.of(sheetContext);

      return Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.forgotPinTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.forgotPinBody,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.importCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onReset();
                    },
                    child: Text(l10n.forgotPinEraseCta),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';

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

      return Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Forgot your PIN?',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'There is no way to recover a forgotten PIN without erasing your data.\n\n'
              'Before resetting, export your data from Data settings so you can restore it afterwards.\n\n'
              'Resetting will erase all period and symptom history from this device.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Cancel'),
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
                    child: const Text('Erase all data and reset'),
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

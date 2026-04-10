import 'package:flutter/material.dart';

import 'package:luma/l10n/app_localizations.dart';

/// Numeric keypad with a dot display for PIN entry.
///
/// When [showExpectedLength] is `true` (default), exactly [pinLength] dots are
/// shown — filled for entered digits, hollow for remaining — and the keypad
/// auto-submits when the PIN is full (if [submitOnComplete] is also `true`).
///
/// When [showExpectedLength] is `false`, only filled dots are rendered so the
/// total expected length is never revealed. A submit button appears on the
/// keypad and is enabled once the user has entered at least [minLength] digits.
/// [submitOnComplete] is ignored in this mode.
class PinEntryWidget extends StatefulWidget {
  const PinEntryWidget({
    super.key,
    required this.pinLength,
    required this.onSubmit,
    this.minLength,
    this.onChanged,
    this.errorText,
    this.submitOnComplete = true,
    this.showExpectedLength = true,
  }) : assert(
          minLength == null || minLength <= pinLength,
          'minLength must be <= pinLength',
        );

  /// Maximum number of digits accepted. Also the fixed dot count when
  /// [showExpectedLength] is `true`.
  final int pinLength;

  /// Minimum digits required before the submit button is enabled.
  /// Defaults to [pinLength] when [showExpectedLength] is `true` (backward
  /// compatible) and to `1` when [showExpectedLength] is `false`.
  final int? minLength;

  final void Function(String pin) onSubmit;
  final void Function(String current)? onChanged;
  final String? errorText;

  /// Auto-submit when [pinLength] digits are entered. Only has an effect when
  /// [showExpectedLength] is `true`.
  final bool submitOnComplete;

  /// When `false`, only filled dots are shown (no hollow placeholders), and a
  /// submit button is always displayed instead of auto-submitting.
  final bool showExpectedLength;

  @override
  State<PinEntryWidget> createState() => _PinEntryWidgetState();
}

class _PinEntryWidgetState extends State<PinEntryWidget> {
  String _current = '';

  int get _effectiveMinLength {
    if (widget.minLength != null) return widget.minLength!;
    return widget.showExpectedLength ? widget.pinLength : 1;
  }

  bool get _canSubmit => _current.length >= _effectiveMinLength;

  void _append(String digit) {
    if (_current.length >= widget.pinLength) return;
    setState(() => _current += digit);
    widget.onChanged?.call(_current);
    if (widget.showExpectedLength &&
        widget.submitOnComplete &&
        _current.length == widget.pinLength) {
      widget.onSubmit(_current);
    }
  }

  void _backspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
    widget.onChanged?.call(_current);
  }

  void _submit() {
    if (_canSubmit) widget.onSubmit(_current);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    // Dot row: fixed count when showing expected length, growing otherwise.
    final dotCount =
        widget.showExpectedLength ? widget.pinLength : _current.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(dotCount, (i) {
              final filled = i < _current.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  filled ? Icons.circle : Icons.circle_outlined,
                  size: 14,
                  color: filled
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.6),
                ),
              );
            }),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        _keypadRow(l10n, ['1', '2', '3']),
        _keypadRow(l10n, ['4', '5', '6']),
        _keypadRow(l10n, ['7', '8', '9']),
        _keypadRow(l10n, [
          _KeypadAction.backspace,
          '0',
          // Show submit button when: (a) showExpectedLength is false, or
          // (b) submitOnComplete is false (caller wants manual submit).
          if (!widget.showExpectedLength || !widget.submitOnComplete)
            _KeypadAction.submit
          else
            _KeypadAction.spacer,
        ]),
      ],
    );
  }

  Widget _keypadRow(AppLocalizations l10n, List<Object> cells) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cells.map((cell) {
          return SizedBox(
            width: 72,
            height: 52,
            child: switch (cell) {
              String d => Center(
                  child: TextButton(
                    onPressed: () => _append(d),
                    child: Text(d, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              _KeypadAction.backspace => IconButton(
                  onPressed: _backspace,
                  icon: const Icon(Icons.backspace_outlined),
                  tooltip: l10n.commonBackspace,
                ),
              _KeypadAction.submit => IconButton(
                  onPressed: _canSubmit ? _submit : null,
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: l10n.commonSubmit,
                ),
              _KeypadAction.spacer => const SizedBox.shrink(),
              _ => const SizedBox.shrink(),
            },
          );
        }).toList(),
      ),
    );
  }
}

enum _KeypadAction { backspace, submit, spacer }

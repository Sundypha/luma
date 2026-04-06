import 'package:flutter/material.dart';

/// Numeric keypad with a dot display for PIN entry.
class PinEntryWidget extends StatefulWidget {
  const PinEntryWidget({
    super.key,
    required this.pinLength,
    required this.onSubmit,
    this.onChanged,
    this.errorText,
    this.submitOnComplete = true,
  });

  final int pinLength;
  final void Function(String pin) onSubmit;
  final void Function(String current)? onChanged;
  final String? errorText;
  final bool submitOnComplete;

  @override
  State<PinEntryWidget> createState() => _PinEntryWidgetState();
}

class _PinEntryWidgetState extends State<PinEntryWidget> {
  String _current = '';

  void _append(String digit) {
    if (_current.length >= widget.pinLength) {
      return;
    }
    setState(() {
      _current += digit;
    });
    widget.onChanged?.call(_current);
    if (_current.length == widget.pinLength && widget.submitOnComplete) {
      widget.onSubmit(_current);
    }
  }

  void _backspace() {
    if (_current.isEmpty) {
      return;
    }
    setState(() {
      _current = _current.substring(0, _current.length - 1);
    });
    widget.onChanged?.call(_current);
  }

  void _submit() {
    if (_current.length == widget.pinLength) {
      widget.onSubmit(_current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pinLength, (i) {
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
        _keypadRow(['1', '2', '3']),
        _keypadRow(['4', '5', '6']),
        _keypadRow(['7', '8', '9']),
        _keypadRow([
          _KeypadAction.backspace,
          '0',
          if (!widget.submitOnComplete)
            _KeypadAction.submit
          else
            _KeypadAction.spacer,
        ]),
      ],
    );
  }

  Widget _keypadRow(List<Object> cells) {
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
                  tooltip: 'Backspace',
                ),
              _KeypadAction.submit => IconButton(
                  onPressed:
                      _current.length == widget.pinLength ? _submit : null,
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Submit',
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

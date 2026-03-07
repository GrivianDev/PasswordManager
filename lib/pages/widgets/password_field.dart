import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget to display a password either obscured as dots or visible as text.
///
/// - [password]: The password string to display (nullable).
class PasswordField extends StatefulWidget {
  final String? password;

  const PasswordField({super.key, required this.password});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  /// Copies password to the clipboard.
  Future<void> _copyClicked() async {
    if (widget.password == null) return;
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final Color bgColor = Theme.of(context).colorScheme.primary;

    await Clipboard.setData(ClipboardData(text: widget.password!));

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: bgColor,
        content: Text('Copied password to clipboard'),
      ),
    );
  }

  Widget get obscuredDots => Wrap(
        spacing: 3,
        runSpacing: 4,
        children: List.generate(
          widget.password!.length,
          (_) => Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.password == null || widget.password!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'No password set',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _obscured
              ? obscuredDots
              : SelectableText(
                  widget.password!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        ),
        Center(
          child: IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboad',
            onPressed: _copyClicked
          ),
        ),
        Center(
          child: IconButton(
            icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
            tooltip: _obscured ? 'Show password' : 'Hide password',
            onPressed: () {
              setState(() => _obscured = !_obscured);
            },
          ),
        ),
      ],
    );
  }
}

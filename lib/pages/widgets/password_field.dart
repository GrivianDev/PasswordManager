import 'package:flutter/material.dart';

/// Widget to display a password either obscured as dots or visible as text.
///
/// Shows a message if no password is set. Includes a toggle button
/// to switch between obscured and visible password display.
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

import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// Displays a confirmation dialog with a text input field and returns the entered value.
/// Supports live validation of the input as the user types.
///
/// **Parameters:**
/// - [context] – Build context for showing the dialog.
/// - [title] – Dialog title.
/// - [description] – Description or instructions displayed above the input field.
/// - [labelText] – Optional label for the text field.
/// - [validator] – Optional function called whenever the input changes.
///   - Should return `null` if the input is valid.
///   - Should return an error message string if invalid.
///
/// **Behavior:**
/// - The confirm button is only accepted if:
///   1. The input is **not empty**, and
///   2. [validator] returns `null` (or is not provided).
/// - Pressing Enter will also confirm if the input is valid.
///
/// **Returns:**
/// - The entered string if the user confirmed with valid input.
/// - `null` if the dialog was cancelled.
Future<String?> getUserInputDialog({
  required BuildContext context,
  required String title,
  required String description,
  String? labelText,
  String? Function(String input)? validator,
}) async {
  String? userInput;
  String currentInput = '';
  String? errorText;

  await Notify.dialog(
    context: context,
    type: NotificationType.confirmDialog,
    title: title,
    content: StatefulBuilder(
      builder: (context, setState) {
        return SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(description),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: TextField(
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      currentInput = value;
                      errorText = validator?.call(currentInput);
                    });
                  },
                  onSubmitted: (value) {
                    currentInput = value;
                    final String? error = validator?.call(currentInput);
                    if (error == null && currentInput.isNotEmpty) {
                      userInput = currentInput;
                      Navigator.pop(context);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: labelText,
                    errorText: errorText,
                    errorMaxLines: 10,
                    constraints: const BoxConstraints(maxWidth: 100, maxHeight: 80.0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
    onConfirm: () {
      final error = validator?.call(currentInput);
      if (error == null && currentInput.isNotEmpty) {
        userInput = currentInput;
        Navigator.pop(context);
      }
    },
  );

  return userInput;
}
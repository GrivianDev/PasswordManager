import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// Shows a dialog requiring the user to type a specific input to confirm an action.
///
/// Supports only [NotificationType.confirmDialog] and [NotificationType.deleteDialog] presets.
/// Returns `true` if the user input matches [expectedInput] and confirms, otherwise `false`.
///
/// **Parameters:**
/// - [context]: The build context to show the dialog in.
/// - [type]: The type of dialog to show (confirm or delete).
/// - [title]: The dialog title text.
/// - [description]: A descriptive message shown above the input field.
/// - [expectedInput]: The exact string the user must type to confirm.
Future<bool> typedConfirmDialog(BuildContext context, NotificationType type, {required String title, required String description, required String expectedInput}) async {
  if (type != NotificationType.confirmDialog && type != NotificationType.deleteDialog) {
    throw Exception('Dialog type $type is not supported for the typedConfirmDialog function');
  }

  String currentInput = '';
  bool success = false;

  await Notify.dialog(
    context: context,
    type: type,
    title: title,
    content: SizedBox(
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: TextField(
              onChanged: (value) => currentInput = value,
              decoration: InputDecoration(
                constraints: const BoxConstraints(maxWidth: 100),
                hintText: 'Enter "$expectedInput"',
              ),
            ),
          ),
        ],
      ),
    ),
    onConfirm: () async {
      if (currentInput != expectedInput) return;
      success = true;
      Navigator.pop(context);
    },
  );

  return success;
}
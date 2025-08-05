import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

Future<String?> getUserInputDialog({
  required BuildContext context,
  required String title,
  required String description,
  String? labelText,
  String? initialValue,
  String? Function(String input)? validator,
}) async {
  String? userInput;
  String currentInput = initialValue?.trim() ?? ''; // TODO: Implement correct prefill in textfield
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
                    currentInput = value.trim();
                    setState(() {
                      errorText = validator?.call(currentInput);
                    });
                  },
                  onSubmitted: (value) {
                    currentInput = value.trim();
                    final String? error = validator?.call(currentInput);
                    if (error == null && currentInput.isNotEmpty) {
                      userInput = currentInput;
                      Navigator.pop(context);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: labelText,
                    errorText: errorText,
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
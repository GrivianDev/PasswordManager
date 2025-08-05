import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

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
      child: ListView(
        shrinkWrap: true,
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
                constraints: const BoxConstraints(maxWidth: 100, maxHeight: 60.0),
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
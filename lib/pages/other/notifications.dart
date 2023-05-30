import 'package:flutter/material.dart';

enum NotificationType {
  error,
  notification,
  confirmDialog,
  deleteDialog;
}

final class Notify {
  static void showLoading({required BuildContext context}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static Future<void> dialog({required BuildContext context, required NotificationType type, String? title, Widget? content, void Function()? onConfirm}) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title != null ? Text(
          title ?? 'Notification',
          style: TextStyle(
            fontWeight: Theme.of(context).textTheme.headlineLarge!.fontWeight,
            fontSize: Theme.of(context).textTheme.headlineLarge!.fontSize,
            color: type == NotificationType.error ? Colors.red : Theme.of(context).textTheme.headlineLarge!.color,
          ),
        ) : null,
        content: content,
        actionsAlignment: (type == NotificationType.confirmDialog ||
                type == NotificationType.deleteDialog)
            ? MainAxisAlignment.end
            : MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                (type == NotificationType.confirmDialog ||
                        type == NotificationType.deleteDialog)
                    ? 'Cancel'
                    : 'Return',
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          if (type == NotificationType.confirmDialog ||
              type == NotificationType.deleteDialog)
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      type == NotificationType.confirmDialog
                          ? Theme.of(context).colorScheme.primary
                          : Colors.red),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    type == NotificationType.confirmDialog
                        ? "Confirm"
                        : "DELETE",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

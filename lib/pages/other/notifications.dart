import 'package:flutter/material.dart';

/// Enum defining wich type of dialog preset should be used by the [Notify.dialog] method.
enum NotificationType {
  error,
  notification,
  confirmDialog,
  deleteDialog;
}

/// Class that uses a standard template for all notifications. The [dialog] method can be used
/// to show dialogs in an easy and short way.
final class Notify {

  /// Lays a non dissmissable loading widget above the current page.
  /// Needs to be popped manually in the following code.
  static void showLoading({required BuildContext context}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Can display a few standard dialogs while still considering the current appdesign. The [type] property defines wich standard
  /// template should be displayed. See [NotificationType] for further info. If the dialog is a confirm or delete dialog, then
  /// a function can be provided in [onConfirm].
  static Future<void> dialog(
      {required BuildContext context,
      required NotificationType type,
      String? title,
      Widget? content,
      void Function()? onConfirm}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title != null
            ? Text(
                title,
                style: TextStyle(
                  fontWeight:
                      Theme.of(context).textTheme.headlineLarge!.fontWeight,
                  fontSize: Theme.of(context).textTheme.headlineLarge!.fontSize,
                  color: type == NotificationType.error
                      ? Colors.red
                      : Theme.of(context).textTheme.headlineLarge!.color,
                ),
              )
            : null,
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

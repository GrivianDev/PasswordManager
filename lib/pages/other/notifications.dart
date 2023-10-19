import 'package:flutter/material.dart';

/// Enum defining which type of dialog preset should be used by the [Notify.dialog] method.
enum NotificationType {
  error,
  notification,
  confirmDialog,
  deleteDialog;
}

/// Class that uses a standard template for all notifications. The [dialog] method can be used
/// to show dialogs in an easy and short way.
final class Notify {
  /// Lays a non dismissible loading widget above the current page.
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

  /// Can display a few standard dialogs while still considering the current app-design. The [type] property defines which standard
  /// template should be displayed. See [NotificationType] for further info. If the dialog is a confirm or delete dialog, then
  /// a function can be provided in [onConfirm]. [beforeReturn] is called before the user exits the dialog in any way.
  static Future<void> dialog({
    required BuildContext context,
    required NotificationType type,
    String? title,
    Widget? content,
    void Function()? beforeReturn,
    void Function()? onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => _CustomDialog(
        type: type,
        title: title,
        content: content,
        beforeReturn: beforeReturn,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _CustomDialog extends StatelessWidget {
  const _CustomDialog({Key? key, required this.type, this.title, this.content, this.beforeReturn, this.onConfirm}) : super(key: key);

  final NotificationType type;
  final String? title;
  final Widget? content;
  final void Function()? beforeReturn;
  final void Function()? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (beforeReturn != null) beforeReturn!();
            Navigator.pop(context);
          },
          child: Container(
            color: Colors.transparent,
          ),
        ),
        AlertDialog(
          title: title != null
              ? Text(
                  title!,
                  style: TextStyle(
                    fontWeight: Theme.of(context).textTheme.headlineLarge!.fontWeight,
                    fontSize: Theme.of(context).textTheme.headlineLarge!.fontSize,
                    color: type == NotificationType.error ? Colors.red : Theme.of(context).textTheme.headlineLarge!.color,
                    overflow: TextOverflow.clip,
                  ),
                )
              : null,
          content: content,
          actionsAlignment:
              (type == NotificationType.confirmDialog || type == NotificationType.deleteDialog) ? MainAxisAlignment.end : MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                if (beforeReturn != null) beforeReturn!();
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                child: Text(
                  (type == NotificationType.confirmDialog || type == NotificationType.deleteDialog) ? 'Cancel' : 'Return',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.displaySmall?.fontSize,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (type == NotificationType.confirmDialog || type == NotificationType.deleteDialog)
              ElevatedButton(
                onPressed: onConfirm,
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(type == NotificationType.confirmDialog ? Theme.of(context).colorScheme.primary : Colors.red),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
                  child: Text(
                    type == NotificationType.confirmDialog ? "Confirm" : "DELETE",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.displaySmall?.fontSize,
                      overflow: TextOverflow.ellipsis,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

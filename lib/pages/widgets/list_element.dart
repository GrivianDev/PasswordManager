import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/pages/widgets/hoverbuilder.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/persistence.dart';
import 'package:passwordmanager/pages//other/notifications.dart';
import 'package:passwordmanager/pages/account_display_page.dart';

/// An element in the account list. The Widget itself is clickable wich navigates to the [AccountDisplayPage] of the stored [Account] instance.
/// Hovewer, this widget also provides the option to copy the password of the stored account to the clipboard or delete the account.
class ListElement extends StatelessWidget {
  // The _isSearchResult property states if an additional widget (the search result widget) needs to be popped in addition to the loading screen when saving.
  const ListElement({super.key, required Account account}) : _account = account;

  final Account _account;

  /// Returns a preview of the email in the following format: testing@example.com => t...g@example.com, but only
  /// if there was a valid email fomatting criteria.
  String? _mailPreview() {
    if (_account.email?.contains('@') == true) {
      String show = String.fromCharCode(_account.email!.codeUnitAt(0));
      show = '$show...';
      int remainsIndex = _account.email!.indexOf('@') - 1;
      if (remainsIndex < 0) return null;
      return '$show${_account.email!.substring(remainsIndex)}';
    }
    return null;
  }

  /// Asynchronous method to save the fact that the account has been deleted.
  /// Displays a snackbar if succeded.
  Future<void> _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase database = LocalDatabase();

    try {
      Notify.showLoading(context: context);
      await database.save();
    } catch (e) {
      navigator.pop();
      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Could not save changes!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
      database.notifyAll();
      return;
    }
    database.notifyAll();
    navigator.pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        content: const Row(
          children: [
            Text('Saved changes'),
            Padding(
              padding: EdgeInsets.only(left: 5.0),
              child: Icon(
                Icons.sync,
                size: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Copies password to the clipboard.
  Future<void> _copyClicked(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _account.password!));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text('Copied password of "${_account.name}" to clipboard'),
      ),
    );
  }

  /// Displays a dialog to avoid accidentally deleting accounts. If autosaving is active
  /// then the [_save] method is called.
  Future<void> _deleteClicked(BuildContext context) async {
    await Notify.dialog(
      context: context,
      title: 'Are you sure?',
      type: NotificationType.deleteDialog,
      content: Text(
        'Are you sure that you want to delete all information about your "${_account.name}" account?\nAction can not be undone!',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onConfirm: () async {
        final LocalDatabase database = LocalDatabase();
        Navigator.pop(context);
        database.removeAccount(_account, notify: false);
        if (context.read<Settings>().isAutoSaving) {
          await _save(context);
        } else {
          database.source?.claimHasUnsavedChanges();
          database.notifyAll();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: HoverBuilder(
        builder: (isHovered) => ElevatedButton(
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) => states.contains(MaterialState.hovered) ? Colors.blue : null,
            ),
            shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            backgroundColor: WidgetStatePropertyAll<Color>(Theme.of(context).primaryColor),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: Settings.isWindows ? 0.0 : 5.0),
                        child: Text(
                          _account.name ?? '<no-name>',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                    ),
                    if (isHovered)
                      Expanded(
                        child: Text(
                          isHovered ? _mailPreview() ?? '' : '',
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const Spacer(),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _copyClicked(context),
                    icon: Icon(
                      Icons.copy,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteClicked(context),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountDisplay(
                  account: _account,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

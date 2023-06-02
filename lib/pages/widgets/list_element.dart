import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/pages//other/notifications.dart';
import 'package:passwordmanager/pages/account_display_page.dart';

/// An element in the account list. The Widget itself is clickable wich navigates to the [AccountDisplayPage] of the stored [Account] instance.
/// Hovewer, this widget also provides the option to copy the password of the stored account to the clipboard or delete the account.
class ListElement extends StatelessWidget {
  // The _isSearchResult property states if an additional widget (the search result widget) needs to be popped in addition to the loading screen when saving.
  const ListElement(
      {Key? key, required Account account, bool isSearchResult = false})
      : _account = account,
        _isSearchResult = isSearchResult,
        super(key: key);

  final Account _account;
  final bool _isSearchResult;

  /// Asynchronous method to save the fact that the account has been deleted.
  /// Displays a snackbar if succeded.
  void _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final Color backgroundColor = Theme.of(context).colorScheme.primary;

    try {
      Notify.showLoading(context: context);
      await context.read<LocalDatabase>().save();
    } catch (e) {
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error: Could not save',
        content: Text(
          'Consider using a different save file.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
      navigator.pop();
      if (_isSearchResult) navigator.pop();
      return;
    }
    navigator.pop();
    if (_isSearchResult) navigator.pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        backgroundColor: backgroundColor,
        content: const Row(
          children: [
            Text(
              'Saved changes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
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

  void _copyClicked(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _account.password));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          'Copied password of "${_account.name}" to clipboard',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Displays a dialog to avoid accidentally deleting accounts. If autosaving is active
  /// then the [_save] method is called.
  void _deleteClicked(BuildContext context) {
    Notify.dialog(
      context: context,
      title: 'Are you sure?',
      type: NotificationType.deleteDialog,
      content: Text(
        'Are you sure that you want to delete all information about your "${_account.name}" account ?\nAction can not be undone!',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onConfirm: () {
        Navigator.pop(context);
        context.read<LocalDatabase>().removeAccount(_account);
        if (context.read<Settings>().isAutoSaving) {
          _save(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: ElevatedButton(
        style: ButtonStyle(
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              return states.contains(MaterialState.hovered)
                  ? Colors.blueAccent.shade100
                  : null;
            },
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
          backgroundColor:
              MaterialStateProperty.all<Color>(Theme.of(context).primaryColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _account.name,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _copyClicked(context),
              icon: Icon(
                Icons.copy,
                color: Theme.of(context).highlightColor,
              ),
            ),
            if(Settings.isWindows) IconButton(
              onPressed: () => _deleteClicked(context),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
          ],
        ),
        onPressed: () {
          if (_isSearchResult) Navigator.pop(context);
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
    );
  }
}

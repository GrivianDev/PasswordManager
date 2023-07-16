import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/clipboard_timer.dart';
import 'package:passwordmanager/pages/widgets/hoverbuilder.dart';
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

  /// Returns a preview of the email in the following format: testing@example.com => t...g@example.com, but only
  /// if there was a valid email fomatting criteria.
  String? _mailPreview() {
    if (_account.email.contains('@')) {
      String show = String.fromCharCode(_account.email.codeUnitAt(0));
      show = '$show...';
      int remainsIndex = _account.email.indexOf('@') - 1;
      if (remainsIndex < 0) return null;
      return '$show${_account.email.substring(remainsIndex)}';
    }
    return null;
  }

  /// Asynchronous method to save the fact that the account has been deleted.
  /// Displays a snackbar if succeded.
  Future<void> _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger =
        ScaffoldMessenger.of(context);
    final Color backgroundColor = Theme.of(context).colorScheme.primary;
    final LocalDatabase database = LocalDatabase();

    try {
      Notify.showLoading(context: context);
      await database.save();
    } catch (e) {
      navigator.pop();
      if (_isSearchResult) navigator.pop();

      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Could not save changes!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
      database.notifyListeners();
      return;
    }
    database.notifyListeners();
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

  /// Copies password for 30 seconds to the clipboard and clears it afterwards.
  Future<void> _copyClicked(BuildContext context) async {
    await ClipboardTimer.timed(text: _account.password, duration: const Duration(seconds: 30));

    if(!context.mounted) return;
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
      onConfirm: () async {
        final LocalDatabase database = LocalDatabase();
        Navigator.pop(context);
        database.removeAccount(_account, notify: false);
        if (context.read<Settings>().isAutoSaving) {
          await _save(context);
        } else {
          database.notifyListeners();
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
              (Set<MaterialState> states) {
                return states.contains(MaterialState.hovered)
                    ? Colors.blue
                    : null;
              },
            ),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            backgroundColor: MaterialStateProperty.all<Color>(
                Theme.of(context).primaryColor),
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
                          _account.name,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if(isHovered) Expanded(
                      child: Text(
                        isHovered ? _mailPreview() ?? '' : '',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(child: Container(),),
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
                  if (Settings.isWindows || context.read<Settings>().isOnlineModeEnabled)
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
      ),
    );
  }
}

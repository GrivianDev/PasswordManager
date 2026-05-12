import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/pages/flows/app_flows.dart';
import 'package:passwordmanager/pages/flows/typed_confirmation_dialog.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/pages/accounts/account_detail_page.dart';

class AccountListElement extends StatelessWidget {
  const AccountListElement({super.key, required Account account}) : _account = account;

  final Account _account;

  Future<void> _save(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase database = context.read();

    return runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        await database.save();

        scaffoldMessenger.showSnackBar(const SnackBar(
          duration: Duration(seconds: 2),
          content: Wrap(
            spacing: 5,
            children: [
              Icon(
                Icons.sync,
                size: 15,
                color: Colors.white,
              ),
              Text('Saved changes'),
            ],
          ),
        ));
      } finally {
        navigator.pop();
      }
    });
  }

  /// Copies password to the clipboard.
  Future<void> _copyClicked(BuildContext context) async {
    if (_account.password == null) return;
    await Clipboard.setData(ClipboardData(text: _account.password!));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text('Copied password of "${_account.name}" to clipboard'),
    ));
  }

  // If autosaving is active then the [_save] method is called.
  Future<void> _deleteClicked(BuildContext context) async {
    final LocalDatabase database = context.read();

    final bool doDelete = await typedConfirmDialog(
      context,
      NotificationType.deleteDialog,
      title: 'Are you sure?',
      description: 'Are you sure that you want to delete all information about your '
          '${(_account.name?.isNotEmpty ?? false) ? '"${_account.name}"' : 'unnamed'} account?\n'
          'Action can not be undone!',
      expectedInput: 'DELETE',
    );

    if (!doDelete || !context.mounted) return;

    database.removeAccount(_account.id);
    if (context.read<AppState>().autosaving.value) {
      await _save(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? mail = mailPreview(_account.email ?? '');

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      title: Text(_account.name ?? '<no-name>', style: Theme.of(context).textTheme.displaySmall),
      subtitle: mail != null ? Text(mail, style: Theme.of(context).listTileTheme.subtitleTextStyle!.copyWith(overflow: TextOverflow.ellipsis)) : null,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AccountDetailPage(account: _account))),
      tileColor: Theme.of(context).scaffoldBackgroundColor,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
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
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

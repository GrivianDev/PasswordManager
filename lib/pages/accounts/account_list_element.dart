import 'package:ethercrypt/engine/account.dart';
import 'package:ethercrypt/engine/db/local_database.dart';
import 'package:ethercrypt/engine/other/util.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/pages/accounts/account_detail_page.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/flows/typed_confirmation_dialog.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/other/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AccountListElement extends StatelessWidget {
  const AccountListElement({super.key, required Account account}) : _account = account;

  final Account _account;

  Future<void> _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase database = context.read();

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        await database.save();

        scaffoldMessenger.showSnackBar(
          SnackBarUtils.message('Saved changes', icon: Icons.sync),
        );
      } finally {
        navigator.pop();
      }
    });
  }

  /// Copies password to the clipboard.
  Future<void> _copyClicked(BuildContext context) {
    if (_account.password == null) return Future.value();

    return runAppFlow(context, () async {
      final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
      await Clipboard.setData(ClipboardData(text: _account.password!));

      scaffoldMessenger.showSnackBar(
        SnackBarUtils.message('Copied password of "${_account.name}" to clipboard'),
      );
    });
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

    await runAppFlow(context, () async {
      database.removeAccount(_account.id);
      if (context.read<AppState>().autosaving.value) {
        await _save(context);
      }
    });
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

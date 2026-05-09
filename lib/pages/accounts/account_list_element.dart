import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/pages/flows/app_flows.dart';
import 'package:passwordmanager/pages/flows/typed_confirmation_dialog.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/pages/widgets/hoverbuilder.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: HoverBuilder(
        builder: (isHovered) => ElevatedButton(
          style: ButtonStyle(
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
                        padding: EdgeInsets.only(top: Platform.isWindows || Platform.isLinux ? 0.0 : 5.0),
                        child: Text(
                          _account.name ?? '<no-name>',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                    ),
                    if (isHovered)
                      Expanded(
                        child: Text(
                          isHovered ? mailPreview(_account.email ?? '') ?? '' : '',
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
                      color: Colors.redAccent,
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
                builder: (context) => AccountDetailPage(
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

import 'dart:async';

import 'package:ethercrypt/engine/account.dart';
import 'package:ethercrypt/engine/db/local_database.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/pages/accounts/twofactor/two_factor_display.dart';
import 'package:ethercrypt/pages/accounts/twofactor/two_factor_edit_page.dart';
import 'package:ethercrypt/pages/accounts/twofactor/two_factor_setup.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/flows/typed_confirmation_dialog.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/other/snackbar_util.dart';
import 'package:ethercrypt/pages/widgets/default_page_body.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TwoFactorManagePage extends StatelessWidget {
  const TwoFactorManagePage({super.key, required this.account});

  final Account account;

  Future<void> _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase database = context.read();

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        await database.save();
      } finally {
        navigator.pop();
      }

      scaffoldMessenger.showSnackBar(
        SnackBarUtils.message('Saved changes', icon: Icons.sync),
      );
    });
  }

  Future<void> _deleteClicked(BuildContext context) async {
    final LocalDatabase database = context.read();
    final AppState appState = context.read();

    final bool doDelete = await typedConfirmDialog(
      context,
      NotificationType.deleteDialog,
      title: 'Are you sure?',
      description: 'Are you sure that you want to delete 2FA information about your "${account.name}" account?\nAction can not be undone!',
      expectedInput: 'DELETE',
    );

    if (!doDelete || !context.mounted) return;

    await runAppFlow(context, () async {
      account.twoFactorSecret = null;
      database.replaceAccount(account.id, account);
      if (appState.autosaving.value) {
        await _save(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('2FA')),
      body: DefaultPageBody(
        child: Consumer<LocalDatabase>(builder: (context, database, child) {
          if (account.twoFactorSecret != null) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: TwoFactorDisplayPage(
                    key: ValueKey(account.twoFactorSecret),
                    twoFactorSecret: account.twoFactorSecret!,
                  ),
                ),
                Positioned(
                  bottom: 164,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () async => await _deleteClicked(context),
                    heroTag: 'deleteFAB',
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.delete_outline),
                  ),
                ),
                Positioned(
                  bottom: 90, // stacked higher than the other two
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'shareQR',
                    onPressed: () async => await Notify.dialog(
                      context: context,
                      type: NotificationType.notification,
                      title: '2FA Setup QR Code',
                      content: SizedBox(
                        width: 250,
                        height: 300,
                        child: Column(
                          spacing: 15,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Scan to get these codes in another authenticator app.',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(10.0),
                                child: QrImageView(
                                  data: account.twoFactorSecret!.getAuthUrl(),
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: const Icon(Icons.qr_code),
                  ),
                ),
                Positioned(
                  bottom: 16, // place it above the first FAB
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TwoFactorEditPage(
                          title: 'Edit 2FA information',
                          account: account,
                        ),
                      ),
                    ),
                    heroTag: 'editFAB',
                    child: const Icon(Icons.edit),
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: TwoFactorSetupPage(
                account: account,
              ),
            );
          }
        }),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:passwordmanager/pages/flows/typed_confirmation_dialog.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/pages/two_factor_edit_page.dart';
import 'package:passwordmanager/pages/widgets/two_factor_create_subpage.dart';
import 'package:passwordmanager/pages/widgets/two_factor_display_subpage.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

class TwoFactorManagePage extends StatelessWidget {
  const TwoFactorManagePage({super.key, required this.account});

  final Account account;

  /// Asynchronous method to persist changes.
  /// Displays a snackbar if succeeded.
  Future<void> _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase database = context.read();

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
        content: Text(e.toString()),
      );
      return;
    }
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

  /// Displays a dialog to avoid accidentally deleting 2FA info. If autosaving is active
  /// then the [_save] method is called.
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

    account.twoFactorSecret = null;
    database.replaceAccount(account.id, account);
    if (appState.autosaving.value) {
      await _save(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('2FA')),
      body: Consumer<LocalDatabase>(builder: (context, database, child) {
        if (account.twoFactorSecret != null) {
          return Stack(
            children: [
              TwoFactorDisplaySubpage(
                key: ValueKey(account.twoFactorSecret),
                twoFactorSecret: account.twoFactorSecret!,
              ),
              Positioned(
                bottom: 164,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () async => await _deleteClicked(context),
                  heroTag: 'deleteFAB',
                  backgroundColor: Colors.red,
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 90, // stacked higher than the other two
                right: 16,
                child: FloatingActionButton(
                  heroTag: "shareQR",
                  onPressed: () async => await Notify.dialog(
                      context: context,
                      type: NotificationType.notification,
                      title: '2FA Setup QR Code',
                      content: SizedBox(
                        width: 225,
                        height: 225,
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Container(
                              color: Colors.white,
                              padding: EdgeInsets.all(10.0),
                              child: QrImageView(
                                data: account.twoFactorSecret!.getAuthUrl(),
                                // The data you want to encode
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )),
                  child: const Icon(
                    Icons.qr_code,
                    color: Colors.white,
                  ),
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
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        } else {
          return TwoFactorCreateSubpage(
            account: account,
          );
        }
      }),
    );
  }
}

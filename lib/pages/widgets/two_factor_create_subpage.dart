import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/two_factor_token.dart';
import 'package:passwordmanager/pages/qr_scanner_page.dart';
import 'package:passwordmanager/pages/two_factor_edit_page.dart';
import 'package:passwordmanager/pages//other/notifications.dart';

class TwoFactorCreateSubpage extends StatelessWidget {
  const TwoFactorCreateSubpage({super.key, required this.account});

  final Account account;

  Future<void> _getQRCode(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase db = context.read();
    final AppState appState = context.read();

    final String? code = await navigator.push(
      MaterialPageRoute(
        builder: (context) => QrScannerPage(),
      ),
    );

    if (code == null) return;

    try {
      if (!context.mounted) return;
      Notify.showLoading(context: context);
      account.twoFactorSecret = TOTPSecret.fromUri(code);
      db.replaceAccount(account.id, account); // This trivial replacement is just to notify listeners

      if (appState.autosaving.value) {
        await db.save();
      }
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

  @override
  Widget build(BuildContext context) {
    return DefaultPageBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Easily generate your 2FA codes with built-in support for Time-based One-Time Passwords (TOTP), the most widely used standard.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (Platform.isAndroid || Platform.isIOS) ...[
            const SizedBox(height: 25.0),
            ElevatedButton(
              onPressed: () => _getQRCode(context),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: 10.0),
                        child: Text('Scan QR-Code'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 25.0),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TwoFactorEditPage(
                  title: 'Setup 2FA',
                  account: account,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_alt_outlined),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text('Enter setup key'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

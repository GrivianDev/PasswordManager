import 'dart:io';

import 'package:ethercrypt/engine/account.dart';
import 'package:ethercrypt/engine/db/local_database.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/two_factor_token.dart';
import 'package:ethercrypt/pages//other/notifications.dart';
import 'package:ethercrypt/pages/accounts/twofactor/two_factor_edit_page.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/widgets/qr_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TwoFactorSetupPage extends StatelessWidget {
  const TwoFactorSetupPage({super.key, required this.account});

  final Account account;

  Future<void> _getQRCode(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase db = context.read();
    final AppState appState = context.read();

    final String? code = await navigator.push(
      MaterialPageRoute(
        builder: (context) => const QrScannerPage(),
      ),
    );

    if (code == null || !context.mounted) return;

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        account.twoFactorSecret = TOTPSecret.fromUri(code);
        db.replaceAccount(account.id, account); // This trivial replacement is just to notify listeners

        if (appState.autosaving.value) {
          await db.save();
        }
      } finally {
        navigator.pop();
      }
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 25,
        children: [
          Text(
            'Easily generate your 2FA codes with built-in support for Time-based One-Time Passwords (TOTP), the most widely used standard.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (Platform.isAndroid || Platform.isIOS) ...[
            ElevatedButton(
              onPressed: () => _getQRCode(context),
              child: const Padding(
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
            child: const Padding(
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

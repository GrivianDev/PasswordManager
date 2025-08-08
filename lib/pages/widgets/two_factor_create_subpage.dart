import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/two_factor_token.dart';
import 'package:passwordmanager/pages/qr_scanner_page.dart';
import 'package:passwordmanager/pages/two_factor_edit_page.dart';

class TwoFactorCreateSubpage extends StatelessWidget {
  const TwoFactorCreateSubpage({super.key, required this.account});

  final Account account;

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
          if (Platform.isAndroid || Platform.isIOS)
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QrScannerPage(
                    onScan: (String code) {
                      account.twoFactorSecret = TOTPSecret.fromUri(code);
                      final LocalDatabase db = context.read();
                      db.replaceAccount(account.id, account); // This trivial replacement is just to notify listeners
                    },
                  ),
                ),
              ),
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

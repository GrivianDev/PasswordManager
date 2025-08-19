import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/two_factor_manage_page.dart';
import 'package:passwordmanager/pages/widgets/password_field.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/pages/editing_page.dart';

/// Simple widget for displaying all data of an [Account]. Can navigate to the [EditPage] for editing
/// the displayed account or to [TwoFactorManagePage] to add / edit the 2FA setup.
class AccountDisplay extends StatelessWidget {
  const AccountDisplay({super.key, required Account account, bool accessedThroughSearch = false}) : _account = account;

  final Account _account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LocalDatabase>(
          builder: (context, database, child) => Text(_account.name ?? '<no-name>'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditingPage(
              title: 'Edit account',
              account: _account,
            ),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 90),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Consumer<LocalDatabase>(
          builder: (context, database, child) => SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectableDisplay(description: 'Tag:', text: _account.tag ?? ''),
                _SelectableDisplay(description: 'Info:', text: _account.info ?? ''),
                _SelectableDisplay(description: 'E-mail:', text: _account.email ?? ''),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password:', style: Theme.of(context).textTheme.displayMedium),
                    PasswordField(password: _account.password),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TwoFactorManagePage(
                        account: _account,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_account.twoFactorSecret == null ? Icons.add_moderator : Icons.security),
                      SizedBox(width: 10),
                      Text(_account.twoFactorSecret == null ? 'Add 2FA' : 'Show 2FA'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableDisplay extends StatelessWidget {
  const _SelectableDisplay({required String text, required this.description}) : _text = text;

  final String description;
  final String _text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(description, style: Theme.of(context).textTheme.displayMedium),
        SelectableText(_text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

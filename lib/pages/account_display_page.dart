import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/pages/editing_page.dart';

/// Simple widget for displaying all data of an [Accout]. Can navigate to the [EditPage] for editing the displayed account (Only on windows).
class AccountDisplay extends StatelessWidget {
  const AccountDisplay(
      {Key? key, required Account account, bool accessedThroughSearch = false})
      : _account = account,
        super(key: key);

  final Account _account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).primaryColor,
        title: Consumer<LocalDatabase>(
          builder: (context, database, child) => Text(
            _account.name,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
      ),
      floatingActionButton: Settings.isWindows ? FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
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
      ) : null,
      body: Stack(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
          ),
          Container(
            margin: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(20.0),
              ),
              color: Theme.of(context).colorScheme.background,
            ),
            child: SingleChildScrollView(
              child: Consumer<LocalDatabase>(
                builder: (context, database, child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableDisplay(text: 'Tag:\n${_account.tag}'),
                    SelectableDisplay(text: 'Info:\n${_account.info}'),
                    SelectableDisplay(text: 'E-mail:\n${_account.email}'),
                    SelectableDisplay(text: 'Password:\n${_account.password}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectableDisplay extends StatelessWidget {
  const SelectableDisplay({Key? key, required String text}) : _text = text, super(key: key);

  final String _text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: SelectableText(
        _text,
      ),
    );
  }
}

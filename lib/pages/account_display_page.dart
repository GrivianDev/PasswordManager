import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/pages/editing_page.dart';
import 'package:passwordmanager/engine/implementation/account.dart';

class AccountDisplay extends StatelessWidget {
  const AccountDisplay(
      {Key? key, required Account account, bool accessedThroughSearch = false})
      : _account = account,
        _accessedThroughSearch = accessedThroughSearch,
        super(key: key);

  final Account _account;
  final bool _accessedThroughSearch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), onPressed: () {
            if(_accessedThroughSearch) Navigator.pop(context);
            Navigator.pop(context);
        },
        ),
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).primaryColor,
        title: Consumer<LocalDatabase>(
          builder: (context, database, child) => Text(
            _account.name,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
      ),
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
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: SelectableText(
                        'Tag:\n${_account.tag}',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: SelectableText(
                        'Info:\n${_account.info}',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: SelectableText(
                        'E-mail:\n${_account.email}',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: SelectableText(
                        'Password:\n${_account.password}',
                      ),
                    ),
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

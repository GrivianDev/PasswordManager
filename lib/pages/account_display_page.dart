import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/editing_page.dart';

import '../engine/implementation/account.dart';

class AccountDisplay extends StatefulWidget {
  const AccountDisplay({Key? key, required Account account})
      : _account = account,
        super(key: key);

  final Account _account;

  @override
  State<AccountDisplay> createState() => _AccountDisplayState();
}

class _AccountDisplayState extends State<AccountDisplay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          widget._account.name,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.background,
        child: Icon(
          Icons.edit,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditingPage(
              title: 'Edit account',
              account: widget._account,
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
            margin: const EdgeInsets.symmetric(horizontal: 15.0),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(20.0),
              ),
              color: Theme.of(context).colorScheme.background,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: SelectableText(
                      'Tag:\n${widget._account.tag}',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: SelectableText(
                      'Info:\n${widget._account.tag}',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: SelectableText(
                      'E-mail:\n${widget._account.tag}',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: SelectableText(
                      'Password:\n${widget._account.tag}',
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

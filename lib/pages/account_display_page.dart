import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/pages/widgets/hoverbuilder.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/pages/editing_page.dart';

/// Simple widget for displaying all data of an [Accout]. Can navigate to the [EditPage] for editing the displayed account (Only on windows).
class AccountDisplay extends StatelessWidget {
  const AccountDisplay({Key? key, required Account account, bool accessedThroughSearch = false})
      : _account = account,
        super(key: key);

  final Account _account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LocalDatabase>(
          builder: (context, database, child) => Text(_account.name),
        ),
      ),
      floatingActionButton: Settings.isWindows || context.read<Settings>().isOnlineModeEnabled
          ? FloatingActionButton(
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
            )
          : null,
      body: Container(
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
                SelectableDisplay(description: 'Tag:', text: _account.tag),
                SelectableDisplay(description: 'Info:', text: _account.info),
                SelectableDisplay(description: 'E-mail:', text: _account.email),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15.0, top: 25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text('Password:', style: Theme.of(context).textTheme.displayMedium),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10.0, bottom: 25.0),
                        child: HoverBuilder(
                          builder: (isHovered) => isHovered
                              ? SelectableText(
                                  _account.password,
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              : ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 6.0,
                                    sigmaY: 6.0,
                                  ),
                                  child: SelectableText(
                                    _account.password,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                        ),
                      ),
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

class SelectableDisplay extends StatelessWidget {
  const SelectableDisplay({Key? key, required String text, required this.description})
      : _text = text,
        super(key: key);

  final String description;
  final String _text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: Theme.of(context).textTheme.displayMedium),
          SelectableText(_text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

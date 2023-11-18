import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/pages/widgets/list_element.dart';

/// The ListView displaying all [Account] instances based on the tag and order in the alphabet.
/// "Relativly" expensive because changes need to call the [_buildTagTile] everytime the database adds,
/// edits or removes accounts.
class AccountListView extends StatelessWidget {
  //Needs to be not const. Otherwise [_builTagTile] will not be called as needed.
  AccountListView({Key? key}) : super(key: key);

  List<Widget> _buildTagTile(BuildContext context, String tag) {
    List<Account> accountsOfTag = context.read<LocalDatabase>().getAccountsWithTag(tag);
    List<Widget> children = List.of(accountsOfTag.isNotEmpty
        ? [
            Row(
              children: [
                const Expanded(child: Divider(thickness: 1.5)),
                Expanded(
                  child: Text(
                    tag,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                const Expanded(child: Divider(thickness: 1.5)),
              ],
            ),
          ]
        : []);
    for (Account acc in accountsOfTag) {
      children.add(ListElement(account: acc));
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalDatabase>(
      builder: (context, database, child) => ListView.builder(
        itemCount: database.tags.length,
        itemBuilder: (context, index) => ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _buildTagTile(
            context,
            database.tags.elementAt(index),
          ),
        ),
      ),
    );
  }
}

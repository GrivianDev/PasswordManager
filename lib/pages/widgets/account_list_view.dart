import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/pages/widgets/list_element.dart';

/// The ListView displaying all [Account] instances based on the tag and order in the alphabet.
/// "Relativly" expensive because changes need to call the [_buildTiles] everytime the database adds,
/// edits or removes accounts.
class AccountListView extends StatelessWidget {
  const AccountListView({Key? key, this.searchTag, this.searchQuery}) : super(key: key);
  final String? searchTag;
  final String? searchQuery;

  /// Builds Widget tiles based on search cirteria.
  List<Widget> _buildTiles(BuildContext context) {
    String? searchTag = this.searchTag;
    String? searchQuery = this.searchQuery;
    if (searchQuery == null && searchTag == null) {
      searchQuery = '';
    }

    final LocalDatabase database = LocalDatabase();
    final Iterable<String> tags = searchQuery != null ? database.tags : database.tags.where((element) => element.contains(searchTag!));
    final List<Widget> result = [];

    for (String tag in tags) {
      List<Account> accounts = database.getAccountsWithTag(tag);
      if (searchQuery != null) {
        if (searchQuery.isNotEmpty) {
          accounts = accounts
              .where((element) =>
                  element.name.toLowerCase().contains(searchQuery!) |
                  element.info.toLowerCase().contains(searchQuery) |
                  element.email.toLowerCase().contains(searchQuery))
              .toList();
        }
      }

      if (accounts.isNotEmpty) {
        result.add(
          Row(children: [
            const Expanded(child: Divider(thickness: 1.5)),
            Expanded(
              child: Text(
                tag,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            const Expanded(child: Divider(thickness: 1.5)),
          ]),
        );
        result.addAll(accounts.map((acc) => ListElement(account: acc)));
      }
    }

    if (result.isEmpty) {
      return [
        const Center(
          child: Icon(
            Icons.no_accounts,
            size: 50.0,
          ),
        ),
      ];
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: _buildTiles(context),
    );
  }
}

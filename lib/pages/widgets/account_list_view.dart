import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/pages/widgets/list_element.dart';

/// The ListView displaying all [Account] instances based on the tag and order in the alphabet.
/// "Relativly" expensive because changes need to call the [_buildTiles] everytime the database adds,
/// edits or removes accounts.
class AccountListView extends StatelessWidget {
  const AccountListView({super.key, this.searchTag, this.searchQuery, required this.queryCaseInsensitiveSearch});
  final String? searchTag;
  final String? searchQuery;
  final bool queryCaseInsensitiveSearch;

  bool _matchesQuery(Account acc, String query) {
    return _contains(acc.name, query) ||
        _contains(acc.info, query) ||
        _contains(acc.email, query);
  }

  bool _contains(String? source, String query) {
    if (source == null) return false;
    return queryCaseInsensitiveSearch
        ? source.toLowerCase().contains(query)
        : source.contains(query);
  }

  Widget _buildTagHeader(BuildContext context, String tag) {
    return Row(children: [
      const Expanded(child: Divider(thickness: 1.5)),
      Expanded(
        child: Text(
          tag,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      const Expanded(child: Divider(thickness: 1.5)),
    ]);
  }

  /// Builds Widget tiles based on search cirteria.
  List<Widget> _buildTiles(BuildContext context) {
    final LocalDatabase database = context.read();
    final List<Widget> result = [];

    final String? tagFilter = searchTag;
    final String? query = queryCaseInsensitiveSearch ? searchQuery?.toLowerCase() : searchQuery;

    // If filtering by tag
    final Iterable<String> matchingTags = tagFilter == null ? database.tags : database.tags.where((element) => element.contains(tagFilter));
    final List<String?> tagsToIterate = [...matchingTags, null]; // Include non tagged accounts last

    for (String? tag in tagsToIterate) {
      late final Iterable<Account> accounts;
      if (query != null && query.isNotEmpty) {
        // search account details
        accounts = database.getAccountsWithTag(tag).where((acc) => _matchesQuery(acc, query));
      } else {
        accounts = database.getAccountsWithTag(tag);
      }

      if (accounts.isEmpty) continue;

      result.add(_buildTagHeader(context, tag ?? '<no-tag>'));
      result.addAll(accounts.map((acc) => ListElement(account: acc)));
    }

    // If no accounts present make return a placeholder widget
    if (result.isEmpty) {
      result.add(const Center(
        child: Icon(
          Icons.no_accounts,
          size: 50.0,
        ),
      ));
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

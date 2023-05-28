import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/pages/widgets/list_element.dart';
import 'package:passwordmanager/pages/widgets/navbar.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/pages/editing_page.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/implementation/account.dart';

class ManagePage extends StatelessWidget {
  const ManagePage({super.key, required this.title});

  final String title;

  void _search(BuildContext context, String string) {
    List<Account> list = LocalDatabase()
        .accounts
        .where((element) =>
            element.name.contains(string) |
            element.tag.contains(string) |
            element.info.contains(string) |
            element.email.contains(string) |
            element.password.contains(string))
        .toList();

    List<ListElement> listElements = List.empty(growable: true);
    for (var element in list) {
      listElements.add(ListElement(
        account: element,
        isSearchResult: true,
      ));
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search results for "$string":',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: listElements,
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'Return',
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTagTile(BuildContext context, String tag) {
    List<Account> accountsOfTag =
        context.read<LocalDatabase>().getAccountsWithTag(tag);
    List<Widget> children = List.of(accountsOfTag.isNotEmpty
        ? [
            Row(
              children: [
                const Expanded(child: Divider(thickness: 2)),
                Expanded(
                  child: Text(
                    tag,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Expanded(child: Divider(thickness: 2)),
              ],
            ),
          ]
        : []);
    for (Account acc in accountsOfTag) {
      children.add(ListElement(account: acc));
    }
    return children;
  }

  Future<void> _save(BuildContext context) async {
    try {
      if (!context.mounted) return;
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      await context.read<LocalDatabase>().save();
    } on ArgumentError catch (_) {
    } finally {
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const NavBar(),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: Scaffold.of(context).openEndDrawer,
              ),
            ),
          ),
        ],
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(title, style: Theme.of(context).textTheme.headlineLarge),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditingPage(
              title: 'Create account',
            ),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.background,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 85.0),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search',
                        ),
                        onSubmitted: (string) => _search(context, string),
                      ),
                    ),
                    Consumer<Settings>(
                      builder: (context, settings, child) => settings
                              .isAutoSaving
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.only(left: 15.0),
                              child: ElevatedButton(
                                onPressed: () => _save(context),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(right: 10.0),
                                        child: Icon(
                                          Icons.save,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Save',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.fontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Consumer<LocalDatabase>(
                  builder: (context, database, child) => ListView.builder(
                    itemCount: database.tags.length,
                    itemBuilder: (context, index) => ListView(
                      shrinkWrap: true,
                      children: _buildTagTile(
                          context, database.tags.elementAt(index)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

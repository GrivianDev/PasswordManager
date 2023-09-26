import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/source.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/pages/widgets/list_element.dart';
import 'package:passwordmanager/pages/widgets/account_list_view.dart';
import 'package:passwordmanager/pages/widgets/navbar.dart';
import 'package:passwordmanager/pages/editing_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// The main core page of this project. The widget provides four main fuctionalites:
/// * A Searchbar to search for specific [Account] instances that contain the keyword.
/// * An [AccountListView] to display all accounts in a scrollable way.
/// * Button for saving changes (Only on windows).
/// * Button for adding a new [Account] (Only on windows).
class ManagePage extends StatelessWidget {
  const ManagePage({super.key, required this.title});

  final String title;

  /// Case insensetive search for accounts. A widget is displayed with the found accounts.
  void _search(BuildContext context, String string) {
    if (string.isEmpty) return;
    string = string.toLowerCase();
    List<Account> list = LocalDatabase()
        .accounts
        .where((element) =>
            element.name.toLowerCase().contains(string) |
            element.tag.toLowerCase().contains(string) |
            element.info.toLowerCase().contains(string) |
            element.email.toLowerCase().contains(string) |
            element.password.toLowerCase().contains(string))
        .toList();

    List<Widget> listElements = List.empty(growable: true);
    for (Account acc in list) {
      listElements.add(
        ListElement(
          account: acc,
          isSearchResult: true,
        ),
      );
    }

    int count = listElements.length;
    if (listElements.isEmpty) {
      listElements.add(
        const Center(
          child: Icon(
            Icons.no_accounts,
            size: 50.0,
          ),
        ),
      );
    }

    Notify.dialog(
      context: context,
      type: NotificationType.notification,
      title: '$count result(s) for "$string":',
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: listElements,
        ),
      ),
    );
  }

  /// Asynchronous method to save the fact that changes happened.
  /// Note: Can only be accessed through the button that is only visible when autosaving is not activated.
  /// Displays a snackbar if succeeded.
  Future<void> _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final Color backgroundColor = Theme.of(context).colorScheme.primary;

    try {
      Notify.showLoading(context: context);
      await LocalDatabase().save();
    } catch (e) {
      navigator.pop();
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Could not save changes!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
      return;
    }
    navigator.pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        backgroundColor: backgroundColor,
        content: const Row(
          children: [
            Text(
              'Saved changes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 5.0),
              child: Icon(
                Icons.sync,
                size: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Asynchronous method to display some info of the current file or storage.
  Future<void> _showDetails(BuildContext context) async {
    final LocalDatabase database = LocalDatabase();
    final Settings settings = context.read<Settings>();
    final Source? source = LocalDatabase().source;

    await Notify.dialog(
      context: context,
      type: NotificationType.notification,
      title: 'Details ${settings.isOnlineModeEnabled ? '(Cloud storage)' : '(Local file)'}',
      content: Text(
        'Name: "${source?.name ?? 'none'}"\nAccounts: ${database.accounts.length}/${LocalDatabase.maxCapacity}\nTags: ${database.tags.length}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        endDrawer: const NavBar(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: IconButton(
                icon: const Icon(Icons.sticky_note_2_outlined),
                onPressed: () => _showDetails(context),
              ),
            ),
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
          title: Text(title),
        ),
        floatingActionButton: Settings.isWindows || context.read<Settings>().isOnlineModeEnabled
            ? FloatingActionButton(
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
              )
            : null,
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: SizedBox(
                    height: 60.0,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: false,
                            decoration: const InputDecoration(
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Icon(Icons.search),
                              ),
                              hintText: 'Search',
                            ),
                            onSubmitted: (string) => _search(context, string),
                          ),
                        ),
                        if (Settings.isWindows || context.read<Settings>().isOnlineModeEnabled)
                          Consumer<Settings>(
                            builder: (context, settings, child) => settings.isAutoSaving
                                ? Container()
                                : Padding(
                                    padding: const EdgeInsets.only(left: 15.0),
                                    child: ElevatedButton(
                                      onPressed: () => _save(context),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(right: 10.0),
                                              child: Icon(
                                                context.read<Settings>().isOnlineModeEnabled ? Icons.sync : Icons.save,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'Save',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: Theme.of(context).textTheme.displaySmall?.fontSize,
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
                ),
                Expanded(
                  flex: 4,
                  child: AccountListView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

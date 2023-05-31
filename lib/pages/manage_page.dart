import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/widgets/account_list_view.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/pages/widgets/list_element.dart';
import 'package:passwordmanager/pages/widgets/navbar.dart';
import 'package:passwordmanager/pages/editing_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

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
    for (Account acc in list) {
      listElements.add(
        ListElement(
          account: acc,
          isSearchResult: true,
        ),
      );
    }

    Notify.dialog(
      context: context,
      type: NotificationType.notification,
      title: 'Search results for "$string":',
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: listElements,
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final Color backgroundColor = Theme.of(context).colorScheme.primary;

    try {
      Notify.showLoading(context: context);
      await context.read<LocalDatabase>().save();
    } catch (e) {
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(
          'Could not save changes! Consider using a different save file.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
      navigator.pop();
      return;
    }
    navigator.pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
                                            padding:
                                                EdgeInsets.only(right: 10.0),
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

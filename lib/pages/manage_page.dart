import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/settings.dart';
import 'package:passwordmanager/engine/persistence/source.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/pages/widgets/account_list_view.dart';
import 'package:passwordmanager/pages/widgets/navbar.dart';
import 'package:passwordmanager/pages/editing_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// The main core page of this project. The widget provides four main functionalities:
/// * A Searchbar to search for specific [Account] instances that contain the keyword.
/// * An [AccountListView] to display all accounts in a scrollable way.
/// * Button for saving changes (Only on windows).
/// * Button for adding a new [Account] (Only on windows).
class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  String? searchQuery;
  String? tagQuery;

  /// Case insensitive search for accounts. A widget is displayed with the found accounts.
  void _search(BuildContext context, String string) {
    setState(() {
      searchQuery = string.isNotEmpty ? string.toLowerCase() : null;
      tagQuery = null;
    });
  }

  /// Case insensitive search for tags. A widget is displayed with the found accounts.
  void _searchTag(BuildContext context, String string) {
    setState(() {
      tagQuery = string.isNotEmpty ? string : null;
      searchQuery = null;
    });
  }

  /// Asynchronous method to save the fact that changes happened.
  /// Note: Can only be accessed through the button that is only visible when autosaving is not activated.
  /// Displays a snackbar if succeeded.
  Future<void> _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase database = LocalDatabase();

    try {
      Notify.showLoading(context: context);
      await LocalDatabase().save();
    } catch (e) {
      navigator.pop();
      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Could not save changes!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
      database.notifyAll();
      return;
    }
    database.notifyAll();
    navigator.pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        content: const Row(
          children: [
            Text('Saved changes'),
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
    final Source source = database.source!;

    await Notify.dialog(
      context: context,
      type: NotificationType.notification,
      title: 'Details ${source.usesFirestoreCloud ? '(Cloud storage)' : '(Local file)'}',
      content: Text(
        'Name: "${source.name}"\nStorage version: ${source.accessorVersion ?? 'Not specified'}\nAccounts: ${database.accounts.length}/${LocalDatabase.maxCapacity}\nTags: ${database.tags.length}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ),
          ],
          title: const Text('Your accounts'),
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
        body: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            color: Theme.of(context).colorScheme.surface,
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
                          child: _CustomAutocomplete(
                            onSwitchTrueFunction: _searchTag,
                            onSwitchFalseFunction: _search,
                          ),
                        ),
                        Consumer<Settings>(
                          builder: (context, settings, child) {
                            return settings.isAutoSaving
                                ? Container()
                                : Consumer<LocalDatabase>(
                                    builder: (context, localDb, child) => Padding(
                                      padding: const EdgeInsets.only(left: 15.0),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _save(context),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 10.0),
                                                    child: Icon(
                                                      localDb.source?.usesFirestoreCloud == true ? Icons.sync : Icons.save,
                                                    ),
                                                  ),
                                                  Text('Save'),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (localDb.source?.hasUnsavedChanges == true)
                                            Positioned(
                                              right: -4,
                                              top: -4,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.orange, width: 2),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Consumer<LocalDatabase>(
                    builder: (context, database, child) => AccountListView(searchQuery: searchQuery, searchTag: tagQuery),
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

/// Small container for storing the name and tag of an account inside the [_CustomAutocomplete] widget or just the tag.
/// Necessary for the switch between normal and tag search.
class _TwoValueContainer<T> {
  final T first;
  final T second;

  _TwoValueContainer(this.first, this.second);
}

class _CustomAutocomplete extends StatefulWidget {
  const _CustomAutocomplete({
    required this.onSwitchTrueFunction,
    required this.onSwitchFalseFunction,
  });

  final void Function(BuildContext context, String key) onSwitchTrueFunction;
  final void Function(BuildContext context, String key) onSwitchFalseFunction;

  @override
  State<_CustomAutocomplete> createState() => _CustomAutocompleteState();
}

/// Customized Autocomplete Textfield that supports searching for a specific [Account] or for an general tag.
/// Allows switching between both modes.
class _CustomAutocompleteState extends State<_CustomAutocomplete> {
  bool _active = false;
  String? _searchingWithQuery;
  Iterable<_TwoValueContainer<String>> _lastOptions = [];

  void _execute(String string) {
    if (_active) {
      widget.onSwitchTrueFunction(context, string);
    } else {
      widget.onSwitchFalseFunction(context, string);
    }
  }

  /// Asynchronous and case insensitive search for options to display
  Future<Iterable<_TwoValueContainer<String>>> _searchForOptions(String value) async {
    final LocalDatabase database = LocalDatabase();
    final searchValue = value.toLowerCase();
    if (!_active) {
      return database.accounts
          .where((element) =>
              (element.name?.toLowerCase().contains(searchValue) ?? false) ||
              (element.info?.toLowerCase().contains(searchValue) ?? false) ||
              (element.email?.toLowerCase().contains(searchValue) ?? false))
          .take(10)
          .map((e) => _TwoValueContainer(e.name ?? '<no-name>', e.tag));
    }
    return database.tags.where((e) => e.toLowerCase().contains(searchValue)).take(10).map((e) => _TwoValueContainer(e, ''));
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<_TwoValueContainer<String>>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        _searchingWithQuery = textEditingValue.text;
        if (textEditingValue.text.isEmpty) return const Iterable<_TwoValueContainer<String>>.empty();

        final Iterable<_TwoValueContainer<String>> options = await _searchForOptions(textEditingValue.text);
        if (_searchingWithQuery != textEditingValue.text) {
          return _lastOptions; // throw away result if newer query is running
        }
        _lastOptions = options;
        return options;
      },
      displayStringForOption: (e) => e.first,
      onSelected: (e) => _execute(e.first),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0, right: 40, bottom: 215),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  spreadRadius: 3,
                  blurRadius: 3,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Material(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemBuilder: (context, index) => ListTile(
                    tileColor: Theme.of(context).primaryColor,
                    leading: Icon(_active ? Icons.sell : Icons.person),
                    title: Text(
                      options.elementAt(index).first,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    subtitle: !_active
                        ? Text(
                            options.elementAt(index).second,
                            style: const TextStyle(
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : null,
                    onTap: () => onSelected(options.elementAt(index)),
                  ),
                  itemCount: options.length,
                ),
              ),
            ),
          ),
        ),
      ),
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: false,
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Icon(Icons.search),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: IconButton(
              tooltip: 'Toggle tag search',
              onPressed: () => setState(() {
                _active = !_active;
                controller.clear();
                _execute('');
              }),
              icon: Icon(_active ? Icons.sell : Icons.sell_outlined),
            ),
          ),
          hintText: _active ? 'Search tag' : 'Search',
        ),
        onChanged: (string) => _execute(string),
      ),
    );
  }
}

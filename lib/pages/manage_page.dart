import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/persistence/source.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/pages/widgets/account_list_view.dart';
import 'package:passwordmanager/pages/widgets/manage_page_navbar.dart';
import 'package:passwordmanager/pages/editing_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

import '../engine/db/accessors/accessor_registry.dart';

class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  String? searchQuery;
  String? tagQuery;

  /// Case insensitive search for accounts. A widget is displayed with the found accounts.
  void _searchAccountDetails(String string) {
    setState(() {
      searchQuery = string.isNotEmpty ? string : null;
      tagQuery = null;
    });
  }

  /// Case insensitive search for tags. A widget is displayed with the found accounts.
  void _searchTag(String string) {
    setState(() {
      tagQuery = string.isNotEmpty ? string : null;
      searchQuery = null;
    });
  }

  /// Asynchronous method to save the fact that changes happened.
  /// Note: Can only be accessed through the button that is only visible when autosaving is not activated.
  Future<void> _save() async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase database = context.read();

    try {
      Notify.showLoading(context: context);
      await database.save();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Could not save changes!',
        content: Text(e.toString()),
      );
      return;
    }
    navigator.pop();

    scaffoldMessenger.showSnackBar(SnackBar(
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
    ));
  }

  Future<void> _askToMigrate() async {
    final NavigatorState navigator = Navigator.of(context);
    final LocalDatabase database = context.read();
    final String currentVersion = database.source?.accessorVersion ?? 'not-specified';

    bool migrate = false;
    await Notify.dialog(
      context: context,
      type: NotificationType.confirmDialog,
      title: 'Outdated storage!',
      content: Text(
        'Your current storage version is "$currentVersion", but the most recent version is "${DataAccessorRegistry.latestVersion}". Do you wish to upgrade?\n',
      ),
      onConfirm: () {
        migrate = true;
        Navigator.pop(context);
      }
    );

    if (!migrate) return;

    try {
      if (!mounted) return;
      Notify.showLoading(context: context);
      await database.source?.upgradeSource();
      setState(() {}); // Rebuild
      navigator.pop();
      if (!mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.notification,
        title: 'Successfully upgraded storage!',
        content: Text('All new features and are now available.'),
      );
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Could not migrate!',
        content: Text(e.toString()),
      );
    }
  }

  Future<void> _showDetails() async {
    final LocalDatabase database = context.read();
    final Source source = database.source!;

    String type = 'Unknown';
    if (source.usesLocalFile) {
      type = 'Local file';
    } else if (source.usesFirestoreCloud) {
      type = 'Firestore cloud document';
    }

    return Notify.dialog(
      context: context,
      type: NotificationType.notification,
      title: 'Details',
      content: Text(
        'Type: $type\nName: "${source.displayName}"\nStorage version: ${source.accessorVersion ?? 'Not specified'}\nAccounts: ${database.accounts.length}/${LocalDatabase.maxCapacity}\nTags: ${database.tags.length}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        endDrawer: const ManagePageNavbar(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            if (context.read<LocalDatabase>().source?.accessorVersion != DataAccessorRegistry.latestVersion)
              Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: IconButton(
                  icon: const Icon(Icons.warning_amber_rounded , color: Colors.orange),
                  onPressed: _askToMigrate,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: IconButton(
                icon: const Icon(Icons.sticky_note_2_outlined),
                onPressed: _showDetails,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: SizedBox(
                    height: 60.0,
                    child: Row(
                      children: [
                        Expanded(
                          child: _CustomAutocomplete(
                            onSwitchTrue: _searchTag,
                            onSwitchFalse: _searchAccountDetails,
                          ),
                        ),
                        Consumer<AppState>(
                          builder: (context, appstate, child) {
                            return appstate.autosaving.value
                                ? Container()
                                : Consumer<LocalDatabase>(
                                    builder: (context, localDb, child) => Padding(
                                      padding: const EdgeInsets.only(left: 15.0),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ElevatedButton(
                                            onPressed: _save,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 10.0),
                                                    child: Icon(
                                                      localDb.source?.usesLocalFile == false ? Icons.sync : Icons.save_rounded,
                                                    ),
                                                  ),
                                                  Text('Save'),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (localDb.hasUnsavedChanges)
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
                    builder: (context, database, child) => AccountListView(
                      searchTag: tagQuery,
                      searchQuery: searchQuery,
                      queryCaseInsensitiveSearch: true,
                    ),
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
    required this.onSwitchTrue,
    required this.onSwitchFalse,
  });

  final void Function(String key) onSwitchTrue;
  final void Function(String key) onSwitchFalse;

  @override
  State<_CustomAutocomplete> createState() => _CustomAutocompleteState();
}

/// Customized Autocomplete Textfield that supports searching for a specific [Account] or for an general tag.
/// Allows switching between both modes.
class _CustomAutocompleteState extends State<_CustomAutocomplete> {
  bool _switch = false;
  String? _searchingWithQuery;
  Iterable<_TwoValueContainer<String>> _lastOptions = [];

  void _execute(String string) {
    if (_switch) {
      widget.onSwitchTrue(string);
    } else {
      widget.onSwitchFalse(string);
    }
  }

  /// Asynchronous and case insensitive search for options to display
  Future<Iterable<_TwoValueContainer<String>>> _searchForOptions(String value) async {
    final LocalDatabase database = context.read();
    final String searchValue = value.toLowerCase();
    if (!_switch) {
      return database.accounts
          .where((acc) =>
              (acc.name?.toLowerCase().contains(searchValue) ?? false) ||
              (acc.info?.toLowerCase().contains(searchValue) ?? false) ||
              (acc.email?.toLowerCase().contains(searchValue) ?? false))
          .take(10)
          .map((e) => _TwoValueContainer(e.name ?? '<no-name>', e.tag ?? '<no-tag>'));
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
                    leading: Icon(_switch ? Icons.sell : Icons.person),
                    title: Text(
                      options.elementAt(index).first,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    subtitle: !_switch
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
                _switch = !_switch;
                controller.clear();
                _execute('');
              }),
              icon: Icon(_switch ? Icons.sell : Icons.sell_outlined),
            ),
          ),
          hintText: _switch ? 'Search tag' : 'Search',
        ),
        onChanged: (string) => _execute(string),
      ),
    );
  }
}

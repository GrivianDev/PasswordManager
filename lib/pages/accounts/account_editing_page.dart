import 'package:ethercrypt/engine/account.dart';
import 'package:ethercrypt/engine/db/local_database.dart';
import 'package:ethercrypt/engine/other/safety.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/widgets/default_page_body.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The EditingPage is used for editing AND creating [Account] instances despite it beeing named "EditingPage".
class AccountEditingPage extends StatefulWidget {
  const AccountEditingPage({super.key, required this.title, Account? account}) : _account = account;

  final String title;
  final Account? _account;

  @override
  State<AccountEditingPage> createState() => _AccountEditingPageState();
}

/// State that stores all data with controllers. Changes can only be applied if something has indeed changed at least once.
class _AccountEditingPageState extends State<AccountEditingPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _tagController;
  late final TextEditingController _infoController;
  late final TextEditingController _emailController;
  late final TextEditingController _pwController;

  /// Asynchronous method to save the fact that the account has been edited or added.
  /// Note: this method is executes even if autosaving is not active. Changes are
  /// only persisted if autosiaving is active.
  /// Displays a snackbar if succeded.
  Future<void> _save() async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase database = context.read();

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        if (widget._account == null) {
          // Create new
          database.addAccount(
            Account(
              name: _nameController.text.isEmpty ? null : _nameController.text,
              tag: _tagController.text.isEmpty ? null : _tagController.text,
              info: _infoController.text.isEmpty ? null : _infoController.text,
              email: _emailController.text.isEmpty ? null : _emailController.text,
              password: _pwController.text.isEmpty ? null : _pwController.text,
            ),
          );
        } else {
          // Update existing
          widget._account!.name = _nameController.text.isEmpty ? null : _nameController.text;
          widget._account!.tag = _tagController.text.isEmpty ? null : _tagController.text;
          widget._account!.info = _infoController.text.isEmpty ? null : _infoController.text;
          widget._account!.email = _emailController.text.isEmpty ? null : _emailController.text;
          widget._account!.password = _pwController.text.isEmpty ? null : _pwController.text;
          database.replaceAccount(widget._account!.id, widget._account!);
        }

        if (context.read<AppState>().autosaving.value) {
          await database.save();
          scaffoldMessenger.showSnackBar(const SnackBar(
            duration: Duration(seconds: 2),
            content: Wrap(
              spacing: 5,
              children: [
                Icon(
                  Icons.sync,
                  size: 15,
                  color: Colors.white,
                ),
                Text('Saved changes'),
              ],
            ),
          ));
        }
      } finally {
        navigator.pop();
      }
      navigator.pop();
    });
  }

  List<DropdownMenuEntry<String>> _collectEmailSuggestions() {
    final Set<String> emails = context.read<LocalDatabase>().accounts.where((a) => a.email != null).map((a) => a.email!).toSet();
    return emails.map((e) => DropdownMenuEntry(value: e, label: e, leadingIcon: const Icon(Icons.email))).toList();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget._account?.name ?? '');
    _tagController = TextEditingController(text: widget._account?.tag ?? '');
    _infoController = TextEditingController(text: widget._account?.info ?? '');
    _emailController = TextEditingController(text: widget._account?.email ?? '');
    _pwController = TextEditingController(text: widget._account?.password ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _infoController.dispose();
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: DefaultPageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            spacing: 25,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              DropdownMenu<String>(
                enableSearch: true,
                enableFilter: true,
                requestFocusOnTap: true,
                width: double.infinity,
                menuHeight: 250,
                label: const Text('Tag'),
                controller: _tagController,
                dropdownMenuEntries: context.read<LocalDatabase>().tags.map((t) => DropdownMenuEntry(value: t, label: t, leadingIcon: const Icon(Icons.sell))).toList(),
              ),
              TextField(
                controller: _infoController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Info',
                ),
              ),
              DropdownMenu<String>(
                enableSearch: true,
                enableFilter: true,
                requestFocusOnTap: true,
                width: double.infinity,
                menuHeight: 250,
                label: const Text('Email'),
                controller: _emailController,
                dropdownMenuEntries: _collectEmailSuggestions(),
              ),
              TextField(
                controller: _pwController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: IconButton(
                      onPressed: () {
                        final AppState appstate = context.read();
                        _pwController.text = SafetyAnalyser.generatePassword(
                          min: appstate.pwGenMinCharacters.value,
                          max: appstate.pwGenMaxCharacters.value,
                          useLetters: appstate.pwGenUseLetters.value,
                          useNumbers: appstate.pwGenUseNumbers.value,
                          useSpecialChars: appstate.pwGenUseSpecialChars.value,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 5.0),
                    child: Icon(
                      Icons.check,
                      size: 40,
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

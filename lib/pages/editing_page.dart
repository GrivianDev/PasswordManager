import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/safety.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// A Stateful widget that provides the option to edit account templates.
/// Note: The EditingPage is used for creating AND editing [Account] instances despite it beeing named "EditingPage".
class EditingPage extends StatefulWidget {
  const EditingPage({Key? key, required this.title, Account? account})
      : _account = account,
        super(key: key);

  final String title;
  final Account? _account;

  @override
  State<EditingPage> createState() => _EditingPageState();
}

/// State that stores all data with controllers. Changes can only be applied if something has indeed changed at least once.
class _EditingPageState extends State<EditingPage> {
  late bool _changes;
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
    final Color backgroundColor = Theme.of(context).colorScheme.primary;
    final LocalDatabase database = LocalDatabase();

    bool success = _confirmChanges();
    if (success && context.read<Settings>().isAutoSaving) {
      try {
        Notify.showLoading(context: context);
        await context.read<LocalDatabase>().save();
      } catch (e) {
        if(!context.mounted) return;
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
    } else {
      database.source?.claimHasUnsavedChanges();
    }
    if (success) navigator.pop();
  }

  /// Returns true if and only if all criteria is met. Uses the [_isInvalidInput] method to verify:
  /// * [LocalDataBase] does allow a new account when trying to add another.
  /// * Input contain no dissallowed characters.
  bool _confirmChanges() {
    final LocalDatabase dataBase = LocalDatabase();
    bool valid = !_isInvalidInput();
    try {
      if (valid) {
        if (widget._account == null) {
          dataBase.addAccount(
            Account(
              name: _nameController.text,
              tag: _tagController.text,
              info: _infoController.text,
              email: _emailController.text,
              password: _pwController.text,
            ),
          );
        } else {
          String oldTag = widget._account!.tag;
          widget._account?.setName = _nameController.text;
          widget._account?.setTag = _tagController.text;
          widget._account?.setInfo = _infoController.text;
          widget._account?.setEmail = _emailController.text;
          widget._account?.setPassword = _pwController.text;
          dataBase.callEditOf(oldTag, widget._account!);
        }
      } else {
        throw Exception(
            'Consider using a different character instead of ${LocalDatabase.disallowedCharacter}.\nThis chracter is used for formatting so try to avoid it.');
      }
    } catch (e) {
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
      return false;
    }
    return true;
  }

  bool _isInvalidInput() {
    if (_nameController.text.contains(LocalDatabase.disallowedCharacter) ||
        _tagController.text.contains(LocalDatabase.disallowedCharacter) ||
        _infoController.text.contains(LocalDatabase.disallowedCharacter) ||
        _emailController.text.contains(LocalDatabase.disallowedCharacter) ||
        _pwController.text.contains(LocalDatabase.disallowedCharacter)) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    _changes = false;
    _nameController = TextEditingController(text: widget._account != null ? widget._account?.name : '');
    _tagController = TextEditingController(text: widget._account != null ? widget._account?.tag : '');
    _infoController = TextEditingController(text: widget._account != null ? widget._account?.info : '');
    _emailController = TextEditingController(text: widget._account != null ? widget._account?.email : '');
    _pwController = TextEditingController(text: widget._account != null ? widget._account?.password : '');
    super.initState();
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
      body: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.background,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                  child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                      onChanged: (string) => !_changes
                          ? setState(() {
                              _changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _tagController,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Tag',
                      ),
                      onChanged: (string) => !_changes
                          ? setState(() {
                              _changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      maxLength: 250,
                      controller: _infoController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'Info',
                      ),
                      onChanged: (string) => !_changes
                          ? setState(() {
                              _changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      maxLength: 50,
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      onChanged: (string) => !_changes
                          ? setState(() {
                              _changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      maxLength: 50,
                      controller: _pwController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: IconButton(
                            onPressed: () => {
                              _pwController.text = SafetyAnalyser().generateSavePassword(context),
                              setState(() {
                                _changes = true;
                              }),
                            },
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                      ),
                      onChanged: (string) => !_changes
                          ? setState(() {
                              _changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 10),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(_changes ? Theme.of(context).colorScheme.primary : Colors.blueGrey),
                        ),
                        onPressed: _changes ? _save : null,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 5.0),
                          child: Icon(
                            Icons.check,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/implementation/account.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

class EditingPage extends StatefulWidget {
  const EditingPage({Key? key, required this.title, Account? account})
      : _account = account,
        super(key: key);

  final String title;
  final Account? _account;

  @override
  State<EditingPage> createState() => _EditingPageState();
}

class _EditingPageState extends State<EditingPage> {
  Account? _account;
  late bool changes;
  late TextEditingController _nameController;
  late TextEditingController _tagController;
  late TextEditingController _infoController;
  late TextEditingController _emailController;
  late TextEditingController _pwController;

  Future<void> _save() async {
    bool success = _confirmChanges();
    if (success && context.read<Settings>().isAutoSaving) {
      try {
        Notify.showLoading(context: context);
        await context.read<LocalDatabase>().save();
      } catch (e) {
        await Notify.dialog(
          context: context,
          type: NotificationType.error,
          title: 'Error: Could not save',
        );
      } finally {
        if (context.mounted) Navigator.pop(context);
      }
    }
    if (success && context.mounted) Navigator.pop(context);
  }

  bool _confirmChanges() {
    LocalDatabase dataBase = LocalDatabase();
    bool valid = !_isInvalidInput();
    if (valid) {
      if (_account == null) {
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
        String oldTag = _account!.tag;
        _account?.setName = _nameController.text;
        _account?.setTag = _tagController.text;
        _account?.setInfo = _infoController.text;
        _account?.setEmail = _emailController.text;
        _account?.setPassword = _pwController.text;
        dataBase.callEditOf(oldTag, _account!);
      }
    } else {
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Contains disallowed character',
        content: Text(
          'Consider using a different character instead of ${LocalDatabase.disallowedCharacter}.\nThis chracter is used for formatting so try to avoid it.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return valid;
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
    _account = widget._account;
    changes = false;
    _nameController =
        TextEditingController(text: _account != null ? _account?.name : '');
    _tagController =
        TextEditingController(text: _account != null ? _account?.tag : '');
    _infoController =
        TextEditingController(text: _account != null ? _account?.info : '');
    _emailController =
        TextEditingController(text: _account != null ? _account?.email : '');
    _pwController =
        TextEditingController(text: _account != null ? _account?.password : '');
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
        elevation: 0.0,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).primaryColor,
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                      onChanged: (string) => !changes
                          ? setState(() {
                              changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Tag',
                      ),
                      onChanged: (string) => !changes
                          ? setState(() {
                              changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _infoController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'Info',
                      ),
                      onChanged: (string) => !changes
                          ? setState(() {
                              changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      onChanged: (string) => !changes
                          ? setState(() {
                              changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: _pwController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      onChanged: (string) => !changes
                          ? setState(() {
                              changes = true;
                            })
                          : null,
                    ),
                    const SizedBox(height: 25),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                              changes
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.blueGrey),
                        ),
                        onPressed: changes ? _save : null,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 25.0, vertical: 5.0),
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

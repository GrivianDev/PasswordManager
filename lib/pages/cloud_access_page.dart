import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/source.dart';
import 'package:passwordmanager/pages/manage_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/engine/safety_analyser.dart';

/// Page that is used to access firebase cloud via the [FirebaseConnector]. Can verify your access
/// to a certain storage or create a new storage.
class CloudAccessPage extends StatefulWidget {
  const CloudAccessPage({Key? key, required this.login}) : super(key: key);

  final bool login;

  @override
  State<CloudAccessPage> createState() => _CloudAccessPageState();
}

/// State checking that name and passwords can only be submitted if the text input is not empty.
class _CloudAccessPageState extends State<CloudAccessPage> {
  late bool _isObscured;
  late bool _canSubmit;
  late TextEditingController _nameController;
  late TextEditingController _pwController;

  /// Asynchronous method to create an access a storage:
  /// * Login:
  /// * Tests if storage name exists
  /// * Verifys entered password
  Future<void> submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final FirebaseConnector connector = context.read<FirebaseConnector>();
    final LocalDatabase database = LocalDatabase();
    final Settings settings = context.read<Settings>();

    Notify.showLoading(context: context);
    try {
      if (widget.login) {
        // Login logic ---------------------------
        final bool exists = await connector.docExists(_nameController.text);
        if (!exists) {
          throw Exception(
              'Storage with the name "${_nameController.text}" does not exist');
        }
        final bool verify = await connector.verifyPassword(
          name: _nameController.text,
          password: _pwController.text,
        );
        if (!verify) throw Exception('Wrong password');
        database.setSource(Source(connector: connector), _pwController.text);
        await database.load();
        await settings.setLastOpenedCloudDoc(_nameController.text);
        navigator.pop();
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const ManagePage(title: 'Your accounts'),
          ),
        );
      } else {
        // Create logic ---------------------------
        final bool exists = await connector.docExists(_nameController.text);
        if (exists) {
          throw Exception(
              'Storage with the name "${_nameController.text}" already exists');
        }
        database.setSource(Source(connector: connector), _pwController.text);
        await connector.createDocument(
          name: _nameController.text,
          hash: database.doubleHash!,
          data: database.cipher!,
        );
        await settings.setLastOpenedCloudDoc(_nameController.text);
        navigator.pop();
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const ManagePage(title: 'Your accounts'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      navigator.pop();
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
      database.clear(notify: false);
    }
  }

  /// Building method for a small indicator on how strong the users password is.
  Column buildPasswordStrengthIndictator(BuildContext context) {
    final double rating =
        SafetyAnalyser.rateSafety(password: _pwController.text);
    String text = 'Weak';
    if (rating > 0.5) {
      text = 'Decent';
    }
    if (rating > 0.85) {
      text = 'Strong';
    }
    return Column(
      children: [
        Text(
          'Password strength:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(
          width: 250,
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120.0,
                height: 20.0,
                child: LinearProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).primaryColor,
                  value: rating,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    _isObscured = true;
    _canSubmit = false;
    _nameController = TextEditingController(
        text: widget.login ? context.read<Settings>().lastOpenedCloudDoc : '');
    _pwController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.login ? 'Access storage' : 'Register storage',
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.background,
        ),
        padding: const EdgeInsets.all(35.0),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    TextField(
                      maxLength: 32,
                      autofocus: (context
                                  .read<Settings>()
                                  .lastOpenedCloudDoc
                                  .isEmpty &&
                              widget.login) ||
                          !widget.login,
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Storage name',
                      ),
                      onChanged: (string) => setState(() {
                        _canSubmit = _nameController.text.isNotEmpty &&
                            _pwController.text.isNotEmpty;
                      }),
                    ),
                    TextField(
                      obscureText: _isObscured,
                      maxLength: 32,
                      autofocus: context
                              .read<Settings>()
                              .lastOpenedCloudDoc
                              .isNotEmpty &&
                          widget.login,
                      controller: _pwController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Icon(Icons.key),
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _isObscured = !_isObscured;
                              });
                            },
                            icon: Icon(_isObscured
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                      ),
                      onChanged: (string) => setState(() {
                        _canSubmit = _nameController.text.isNotEmpty &&
                            _pwController.text.isNotEmpty;
                      }),
                      onSubmitted: (string) => _canSubmit ? submit() : null,
                    ),
                    if (!widget.login) buildPasswordStrengthIndictator(context),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: TextButton(
                          onPressed: () => _canSubmit ? submit() : null,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              widget.login ? 'SUBMIT' : 'CREATE',
                              style: TextStyle(
                                color: _canSubmit
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.blueGrey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

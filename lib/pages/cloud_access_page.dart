import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/source.dart';
import 'package:passwordmanager/pages/manage_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/engine/safety.dart';

/// Page that is used to access firebase cloud via the [FirebaseConnector]. Can verify your access
/// to a certain storage or create a new storage. Caches recently entered storage names.
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
  late List<String> _suggestions;
  late TextEditingController _nameController;
  late TextEditingController _pwController;

  /// Asynchronous method to create an access a storage:
  /// * Login:
  /// * Tests if storage name exists
  /// * Verifys entered password
  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final FirebaseConnector connector = context.read<FirebaseConnector>();
    final LocalDatabase database = LocalDatabase();
    final Settings settings = context.read<Settings>();

    Notify.showLoading(context: context);
    try {
      if (widget.login) {
        // Login logic ---------------------------
        await Guardian.failIfAccessDenied(() async {
          final bool exists = await connector.docExists(_nameController.text);
          if (!exists) {
            throw Exception('Storage with the name "${_nameController.text}" does not exist');
          }
          final bool verify = await connector.verifyPassword(
            name: _nameController.text,
            password: _pwController.text,
          );
          if (!verify) {
            Guardian.callAccessFailed('Wrong password');
          }
          database.setSource(Source(connector: connector), _pwController.text);
          await database.load();
          await settings.setLastOpenedCloudDoc(_nameController.text);
          navigator.pop();
          navigator.push(
            MaterialPageRoute(
              builder: (context) => const ManagePage(title: 'Your accounts'),
            ),
          );
        });
      } else {
        // Create logic ---------------------------
        final bool exists = await connector.docExists(_nameController.text);
        if (exists) {
          throw Exception('Storage with the name "${_nameController.text}" already exists');
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
      database.clear(notify: false);
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
  Column _buildPasswordStrengthIndictator(BuildContext context) {
    final double rating = SafetyAnalyser().rateSafety(password: _pwController.text);
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
          style: Theme.of(context).textTheme.displaySmall,
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
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
                      overflow: Theme.of(context).textTheme.displaySmall!.overflow,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Callback workaround because calling setState in the initState method breaks flutter
  void _checkCanSubmitCallback() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _canSubmit = _nameController.text.isNotEmpty && _pwController.text.isNotEmpty;
      });
    });
  }

  @override
  void initState() {
    _isObscured = true;
    _canSubmit = false;
    _suggestions = context.read<Settings>().lastOpenedCloudDocs;
    _nameController = TextEditingController();
    _pwController = TextEditingController();
    _nameController.addListener(_checkCanSubmitCallback);
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pwController.dispose();
    _nameController.removeListener(_checkCanSubmitCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    children: [
                      if (widget.login && _suggestions.isNotEmpty) ...[
                        DropdownMenu<String>(
                          enableSearch: true,
                          requestFocusOnTap: true,
                          width: MediaQuery.of(context).size.width - 50,
                          dropdownMenuEntries: _suggestions
                              .map(
                                (e) => DropdownMenuEntry(
                                  value: e,
                                  label: e,
                                  labelWidget: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Row(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(right: 5.0),
                                          child: Icon(Icons.history),
                                        ),
                                        Expanded(child: Text(e)),
                                        IconButton(
                                          onPressed: () async {
                                            await context.read<Settings>().removeLastOpenedCloudDocEntry(e);
                                            setState(() {
                                              _suggestions.remove(e);
                                            });
                                          },
                                          icon: const Icon(Icons.close),
                                        ),
                                      ],
                                    ),
                                  ),
                                  style: ButtonStyle(
                                    textStyle: MaterialStateProperty.all<TextStyle?>(Theme.of(context).textTheme.displaySmall),
                                    backgroundColor: MaterialStateProperty.all<Color?>(Theme.of(context).primaryColor),
                                  ),
                                ),
                              )
                              .toList(),
                          initialSelection: _suggestions.first,
                          controller: _nameController,
                          menuStyle: MenuStyle(
                            elevation: MaterialStateProperty.all<double?>(5),
                            shape: MaterialStateProperty.all<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0))),
                          ),
                          label: const Text(
                            'Storage name',
                            style: TextStyle(overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _ListeningText(
                              controller: _nameController,
                              buildText: (string) => '${string.length}/32',
                            ),
                          ),
                        ),
                      ],
                      if (!widget.login || _suggestions.isEmpty)
                        TextField(
                          controller: _nameController,
                          maxLength: 32,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Storage name',
                          ),
                        ),
                      TextField(
                        obscureText: _isObscured,
                        maxLength: 32,
                        autofocus: _suggestions.isNotEmpty && widget.login,
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
                              icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                            ),
                          ),
                        ),
                        onChanged: (string) => setState(() {
                          _canSubmit = _nameController.text.isNotEmpty && _pwController.text.isNotEmpty;
                        }),
                        onSubmitted: (string) => _canSubmit ? _submit : null,
                      ),
                      if (!widget.login) _buildPasswordStrengthIndictator(context),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: TextButton(
                            onPressed: _canSubmit ? _submit : null,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                widget.login ? 'SUBMIT' : 'CREATE',
                                style: TextStyle(
                                  color: _canSubmit ? null : Colors.blueGrey,
                                  fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
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
      ),
    );
  }
}

/// Small widget for having a text display that listens to changes of a TextEditingController.
class _ListeningText extends StatefulWidget {
  const _ListeningText({Key? key, required TextEditingController controller, required String Function(String) buildText})
      : _buildText = buildText,
        _controller = controller,
        super(key: key);

  final TextEditingController _controller;
  final String Function(String) _buildText;

  @override
  State<_ListeningText> createState() => _ListeningTextState();
}

class _ListeningTextState extends State<_ListeningText> {
  late String _old = '';

  void _update() {
    setState(() {
      if (widget._controller.text.length > 32) {
        widget._controller.text = _old;
      } else {
        _old = widget._controller.text;
      }
    });
  }

  @override
  void initState() {
    widget._controller.addListener(_update);
    super.initState();
  }

  @override
  void dispose() {
    widget._controller.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        widget._buildText(widget._controller.text),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

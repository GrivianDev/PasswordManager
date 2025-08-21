import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/engine/two_factor_token.dart';
import 'package:passwordmanager/pages/other/base32_input_formatter.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

class TwoFactorEditPage extends StatefulWidget {
  const TwoFactorEditPage({super.key, required this.title, required this.account});

  final String title;
  final Account account;

  @override
  State<TwoFactorEditPage> createState() => _TwoFactorEditPageState();
}

class _TwoFactorEditPageState extends State<TwoFactorEditPage> {
  late final TextEditingController _secretController;
  late final TextEditingController _issuerController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _periodController;
  late final TextEditingController _digitController;

  late String _selectedAlgorithm;
  bool _isUnusualSecret = false;
  bool _changes = false;

  /// Asynchronous method to persist changes.
  /// Displays a snackbar if succeeded.
  Future<void> _save(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final LocalDatabase database = context.read();

    try {
      Notify.showLoading(context: context);
      await database.save();
    } catch (e) {
      navigator.pop();
      if (!context.mounted) return;
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

  /// Callback that inserts the new / edited account into the database.
  /// Calls [_save] if autosaving is enabled.
  Future<void> _confirmClicked() async {
    final NavigatorState navigator = Navigator.of(context);
    final LocalDatabase database = context.read();

    try {
      widget.account.twoFactorSecret = TOTPSecret(
        issuer: _issuerController.text,
        accountName: _accountNameController.text,
        secret: _secretController.text.replaceAll(' ', ''),
        algorithm: _selectedAlgorithm,
        period: int.parse(_periodController.text),
        digits: int.parse(_digitController.text),
      );
      database.replaceAccount(widget.account.id, widget.account);
    } catch (e) {
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(e.toString()),
      );
      return;
    }

    if (context.read<AppState>().autosaving.value) {
      await _save(context);
    }
    navigator.pop();
  }

  @override
  void initState() {
    super.initState();
    final TOTPSecret? secret = widget.account.twoFactorSecret;
    if (secret != null) {
      _isUnusualSecret = secret.unpaddedSecret.length % 8 != 0;
    }
    _accountNameController = TextEditingController(text: secret?.accountName ?? widget.account.name ?? 'unnamed');
    _secretController = TextEditingController(text: secret != null ? Base32InputFormatter.formatBase32(secret.unpaddedSecret) : '');
    _issuerController = TextEditingController(text: secret?.issuer ?? 'unnamed');
    _periodController = TextEditingController(text: secret?.period.toString() ?? TOTPSecret.defaultPeriod.toString());
    _digitController = TextEditingController(text: secret?.digits.toString() ?? TOTPSecret.defaultDigit.toString());
    _selectedAlgorithm = secret?.algorithm ?? TOTPSecret.defaultAlgorithm;
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _secretController.dispose();
    _issuerController.dispose();
    _periodController.dispose();
    _digitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: DefaultPageBody(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(25),
          child: Column(
            spacing: 20.0,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                inputFormatters: [Base32InputFormatter()],
                controller: _secretController,
                decoration: InputDecoration(
                  suffixIcon: _isUnusualSecret ? Padding(
                    padding: EdgeInsets.only(right: 5.0),
                    child: Tooltip(
                      showDuration: Duration(seconds: 5),
                      message: 'Secret is not a multiple of 8 characters. It works here, but may be incompatible for export into some authenticator apps.',
                      textStyle: TextStyle(color: Colors.orange),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                    ),
                  ) : null,
                  labelText: 'Setup Key (Secret)',
                ),
                onSubmitted: (_) => _confirmClicked(),
                onChanged: (string) {
                  setState(() {
                    _isUnusualSecret = _secretController.text.replaceAll(' ', '').length % 8 != 0;
                    _changes = true;
                  });
                },
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'Advanced Settings',
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.displayMedium!.fontSize,
                        overflow: Theme.of(context).textTheme.displayMedium!.overflow,
                      ),
                    ),
                    subtitle: const Text(
                      'Only change this if you know what you are doing or your provider explicitly tells you to specify these parameters.',
                      style: TextStyle(fontSize: 14, color: Colors.orange),
                    ),
                    childrenPadding: EdgeInsets.all(20.0),
                    expandedAlignment: Alignment.center,
                    children: [
                      TextField(
                        controller: _accountNameController,
                        decoration: const InputDecoration(
                          labelText: 'Account Name',
                        ),
                        onChanged: (_) {
                          if (!_changes) {
                            setState(() {
                              _changes = true;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 15.0),
                      TextField(
                        controller: _issuerController,
                        decoration: const InputDecoration(
                          labelText: 'Issuer',
                        ),
                        onChanged: (_) {
                          if (!_changes) {
                            setState(() {
                              _changes = true;
                            });
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        child: Divider(thickness: 1.5),
                      ),
                      TextField(
                        controller: _periodController,
                        decoration: const InputDecoration(
                          labelText: 'Period (seconds)',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) {
                          if (!_changes) {
                            setState(() {
                              _changes = true;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 15.0),
                      TextField(
                        controller: _digitController,
                        decoration: const InputDecoration(
                          labelText: 'Digits',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) {
                          if (!_changes) {
                            setState(() {
                              _changes = true;
                            });
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        child: Divider(thickness: 1.5),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedAlgorithm,
                        decoration: const InputDecoration(
                          labelText: 'Algorithm',
                        ),
                        items: TOTPSecret.allowedAlgorithms.map((algo) {
                          return DropdownMenuItem(
                            value: algo,
                            child: Text(algo),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null && value != _selectedAlgorithm) {
                            setState(() {
                              _selectedAlgorithm = value;
                              _changes = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25.0),
              ElevatedButton(
                style: !_changes || _secretController.text.isEmpty
                    ? ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll<Color>(Colors.blueGrey),
                      )
                    : null,
                onPressed: _changes && _secretController.text.isNotEmpty ? _confirmClicked : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.0),
                  child: Icon(Icons.check, size: 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

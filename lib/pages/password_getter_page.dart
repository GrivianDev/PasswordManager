import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/safety.dart';
import 'package:passwordmanager/pages/widgets/password_strength_indicator.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';

/// Widget that provides a password upon being popped. The user is asked to type in a password that
/// the is used to encrypt data.
class PasswordGetterPage extends StatefulWidget {
  const PasswordGetterPage({super.key, required this.path, required this.title, this.showPwStrengthIndicator = false});

  final String title;
  final String? path;
  final bool showPwStrengthIndicator;

  @override
  State<PasswordGetterPage> createState() => _PasswordGetterPageState();
}

/// State checking that passwords can only be submitted if the text input is not empty.
class _PasswordGetterPageState extends State<PasswordGetterPage> {
  late bool _isObscured;
  late bool _canSubmit;
  late double _rating;
  late TextEditingController _pwController;

  @override
  void initState() {
    super.initState();
    _isObscured = true;
    _canSubmit = false;
    _rating = 0.0;
    _pwController = TextEditingController();
  }

  @override
  void dispose() {
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          DefaultPageBody(
            child: Column(
              spacing: 20,
              children: [
                if (widget.path != null)
                  Text(
                    widget.path!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                TextField(
                  obscureText: _isObscured,
                  maxLength: 128,
                  autofocus: true,
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
                        icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),
                  onChanged: (string) {
                    final double newRating = SafetyAnalyser.rateSafety(password: _pwController.text);
                    setState(() {
                      _canSubmit = _pwController.text.isNotEmpty;
                      _rating = newRating;
                    });
                  },
                  onSubmitted: (string) => _canSubmit ? Navigator.pop(context, string) : null,
                ),
                if (widget.showPwStrengthIndicator) PasswordStrengthIndicator(rating: _rating),
              ],
            ),
          ),
          Positioned(
            bottom: 25,
            right: 25,
            child: TextButton(
              onPressed: () => _canSubmit ? Navigator.pop(context, _pwController.text) : null,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'SUBMIT',
                  style: TextStyle(
                    color: _canSubmit ? null : Colors.blueGrey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

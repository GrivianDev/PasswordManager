import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/safety.dart';

/// Widget that provides a password upon being popped. The user is asked to type in a password that
/// the is used to encrypt data.
class PasswordGetterPage extends StatefulWidget {
  const PasswordGetterPage({super.key, required this.path, required this.title, this.showIndicator = false});

  final String title;
  final String? path;
  final bool showIndicator;

  @override
  State<PasswordGetterPage> createState() => _PasswordGetterPageState();
}

/// State checking that passwords can only be submitted if the text input is not empty.
class _PasswordGetterPageState extends State<PasswordGetterPage> {
  late bool _isObscured;
  late bool _canSubmit;
  late double _rating;
  late TextEditingController _pwController;

  /// Building method for a small indicator on how strong the users password is.
  Column _buildPasswordStrengthIndictator(BuildContext context) {
    String text = 'Weak';
    if (_rating > 0.5) {
      text = 'Decent';
    }
    if (_rating > 0.85) {
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: _rating),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10.0),
                    );
                  },
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

  @override
  void initState() {
    _isObscured = true;
    _canSubmit = false;
    _rating = 0.0;
    _pwController = TextEditingController();
    super.initState();
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
        title: Text(
          widget.title,
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
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    children: [
                      Text(
                        widget.path ?? '',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(
                        height: 10.0,
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
                              icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                            ),
                          ),
                        ),
                        onChanged: (string) {
                          final double newRating = SafetyAnalyser().rateSafety(password: _pwController.text);
                          setState(() {
                            _canSubmit = _pwController.text.isNotEmpty;
                            _rating = newRating;
                          });
                        },
                        onSubmitted: (string) => _canSubmit ? Navigator.pop(context, string) : null,
                      ),
                      if (widget.showIndicator) _buildPasswordStrengthIndictator(context),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: TextButton(
                            onPressed: () => _canSubmit ? Navigator.pop(context, _pwController.text) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'SUBMIT',
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

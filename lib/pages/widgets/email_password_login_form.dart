import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/widgets/obscured_text_field.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/other/safety.dart';
import 'package:passwordmanager/pages/widgets/password_strength_indicator.dart';

/// Page for login or registration.
class EmailPasswordLoginForm extends StatefulWidget {
  const EmailPasswordLoginForm({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    this.initialLoginMode = true,
    this.initialEmail,
  });

  final void Function(String, String) onLogin;
  final void Function(String, String) onSignUp;
  final bool initialLoginMode;
  final String? initialEmail;

  @override
  State<EmailPasswordLoginForm> createState() => _EmailPasswordLoginFormState();
}

class _EmailPasswordLoginFormState extends State<EmailPasswordLoginForm> {
  late final TextEditingController _emailController;
  late final TextEditingController _pwController;
  String? _emailFieldErrortext;
  double _rating = 0.0;
  bool _canSubmit = false;
  bool _loginMode = false;

  void _onSubmit() {
    if (_loginMode) {
      widget.onLogin(_emailController.text, _pwController.text);
    } else {
      widget.onSignUp(_emailController.text, _pwController.text);
    }
  }

  @override
  void initState() {
    super.initState();
    _loginMode = widget.initialLoginMode;
    _emailController = TextEditingController(text: widget.initialEmail);
    _pwController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: _emailFieldErrortext,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 5.0),
              child: Icon(Icons.email),
            ),
          ),
          onChanged: (value) {
            final bool isValid = isValidEmail(_emailController.text);
            setState(() {
              _emailFieldErrortext = isValid ? null : 'Not a valid email';
              _canSubmit = _pwController.text.isNotEmpty && isValid;
            });
          },
        ),
        ObscuredTextField(
          label: 'Password',
          controller: _pwController,
          onChanged: (string) {
            final double newRating = SafetyAnalyser.rateSafety(password: _pwController.text);
            setState(() {
              _canSubmit = _pwController.text.isNotEmpty && isValidEmail(_emailController.text);
              _rating = newRating;
            });
          },
          onSubmitted: (string) => _canSubmit ? _onSubmit() : null,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: !_loginMode ? PasswordStrengthIndicator(rating: _rating) : const SizedBox.shrink(),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: Row(
            key: ValueKey(_loginMode),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _loginMode ? 'No account?' : 'Already have an account?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _loginMode = !_loginMode;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    _loginMode ? 'Sign up' : 'Login',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: TextButton(
            onPressed: () => _canSubmit ? _onSubmit() : null,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _loginMode ? 'Login' : 'Sign up',
                style: TextStyle(
                  color: _canSubmit ? null : Colors.blueGrey,
                  fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

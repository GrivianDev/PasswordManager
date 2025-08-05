import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/api/firebase/firebase.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/engine/safety.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/pages/widgets/password_strength_indicator.dart';

class FirebaseLoginPage extends StatefulWidget {
  const FirebaseLoginPage({super.key, required this.loginMode});

  final bool loginMode;

  @override
  State<FirebaseLoginPage> createState() => _FirebaseLoginPageState();
}

class _FirebaseLoginPageState extends State<FirebaseLoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _pwController;
  String? _emailFieldErrortext;
  double _rating = 0.0;
  bool _canSubmit = false;
  bool _isObscured = true;
  bool _loginMode = true;

  Future<void> _onSubmit() async {
    final NavigatorState navigator = Navigator.of(context);
    final Firestore firestoreService = context.read();

    try {
      Notify.showLoading(context: context);
      if (_loginMode) {
        await firestoreService.auth.login(_emailController.text, _pwController.text);
      } else {
        await firestoreService.auth.signUp(_emailController.text, _pwController.text);
      }
      navigator.pop();
      navigator.pop(true);
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(e.toString()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    String? initialEmail;
    try {
      final AppState appState = context.read();
      initialEmail = appState.firebaseAuthLastUserEmail.value;
    } catch (_) {}
    _loginMode = widget.loginMode;
    _emailController = TextEditingController(text: initialEmail);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_loginMode ? 'Login to Firebase' : 'Register at Firebase'),
      ),
      body: Stack(
        children: [
          DefaultPageBody(
            child: Column(
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
                TextField(
                  obscureText: _isObscured,
                  maxLength: 128,
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
                      _canSubmit = _pwController.text.isNotEmpty && isValidEmail(_emailController.text);
                      _rating = newRating;
                    });
                  },
                  onSubmitted: (string) => _canSubmit ? _onSubmit() : null,
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: !_loginMode ? PasswordStrengthIndicator(rating: _rating) : const SizedBox.shrink(),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
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
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 25,
            right: 25,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: TextButton(
                onPressed: () => _canSubmit ? _onSubmit() : null,
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
    );
  }
}
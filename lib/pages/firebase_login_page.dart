import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/api/firebase/firebase.dart';
import 'package:passwordmanager/pages/firebase_cloud_access_page.dart';
import 'package:passwordmanager/pages/other/reusable_things.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/engine/safety.dart';

import 'other/notifications.dart';

class FirebaseLoginPage extends StatefulWidget {
  const FirebaseLoginPage({super.key, required this.loginMode});

  final bool loginMode;

  @override
  State<FirebaseLoginPage> createState() => _FirebaseLoginPageState();
}

class _FirebaseLoginPageState extends State<FirebaseLoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _pwController;
  String? _emailFieldErrortext;
  double _rating = 0.0;
  bool _canSubmit = false;
  bool _isObscured = true;

  Future<void> _onSubmit() async {
    final NavigatorState navigator = Navigator.of(context);
    try {
      Notify.showLoading(context: context);
      if (widget.loginMode) {
        await Firestore.instance.auth.login(_emailController.text, _pwController.text);
      } else {
        await Firestore.instance.auth.signUp(_emailController.text, _pwController.text);
      }
      navigator.pop();
      navigator.pop(true);
    } catch (e) {
      navigator.pop();
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

    _emailController = TextEditingController();
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
        title: Text(widget.loginMode ? 'Login to Firebase' : 'Register at Firebase'),
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
                        icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                  ),
                  onChanged: (string) {
                    final double newRating = SafetyAnalyser().rateSafety(password: _pwController.text);
                    setState(() {
                      _canSubmit = _pwController.text.isNotEmpty && _emailFieldErrortext == null;
                      _rating = newRating;
                    });
                  },
                  onSubmitted: (string) => _canSubmit ? _onSubmit() : null,
                ),
                if (!widget.loginMode) buildPasswordStrengthIndictator(context, _rating),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.loginMode ? 'No account?' : 'Already have an account?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          createSlideRoute(
                            FirebaseLoginPage(loginMode: !widget.loginMode),
                            reverse: !widget.loginMode,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(widget.loginMode ? 'Sign up' : 'Login'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 25,
            right: 25,
            child: Align(
              alignment: Alignment.bottomRight,
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
          ),
        ],
      ),
    );
  }
}

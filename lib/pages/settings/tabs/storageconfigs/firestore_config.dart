import 'package:ethercrypt/engine/app_exception.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ethercrypt/engine/api/firebase/firebase_user.dart';
import 'package:ethercrypt/engine/api/firebase/firestore.dart';
import 'package:ethercrypt/engine/other/util.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/flows/typed_confirmation_dialog.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/widgets/email_password_login_form.dart';

class FirestoreConfig extends StatefulWidget {
  const FirestoreConfig({super.key});

  @override
  State<FirestoreConfig> createState() => _FirestoreConfigState();
}

class _FirestoreConfigState extends State<FirestoreConfig> {
  late final TextEditingController _projectIdController;
  late final TextEditingController _apiKeyController;

  Future<void> _handleSaveConfig() {
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final Firestore firestore = context.read();
    final AppState appState = context.read();

    return runAppFlow(context, () async {
      final String projectId = _projectIdController.text.trim();
      final String apiKey = _apiKeyController.text.trim();
      firestore.configure(projectId, apiKey);
      appState.firebaseProjectId.value = projectId;
      appState.firebaseApiKey.value = apiKey;
      await appState.save();

      scaffoldMessenger.showSnackBar(const SnackBar(
        duration: Duration(seconds: 2),
        content: Wrap(
          spacing: 5,
          children: [
            Icon(
              Icons.settings,
              size: 15,
              color: Colors.white,
            ),
            Text('Saved configuration'),
          ],
        ),
      ));
    });
  }

  Future<void> _handleLogin(String email, String password) {
    final Firestore firestore = context.read();
    final NavigatorState navigator = Navigator.of(context);

    return runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        await firestore.auth.login(email, password);
      } catch (e, s) {
        throw AppException(
          'Login failed',
          debugContext: 'Firebase Authentication',
          cause: e,
          stackTrace: s,
        );
      } finally {
        navigator.pop();
      }
    });
  }

  Future<void> _handleSignUp(String email, String password) {
    final Firestore firestore = context.read();
    final NavigatorState navigator = Navigator.of(context);

    return runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        await firestore.auth.signUp(email, password);
      } catch (e, s) {
        throw AppException(
          'Signing up failed',
          debugContext: 'Firebase Authentication',
          cause: e,
          stackTrace: s,
        );
      } finally {
        navigator.pop();
      }
    });
  }

  void _handleLogout() {
    final Firestore firestore = context.read();
    firestore.auth.logout();
  }

  Future<void> _handleDeleteUser() async {
    final Firestore firestore = context.read();
    final NavigatorState navigator = Navigator.of(context);

    final bool doDelete = await typedConfirmDialog(
      context,
      NotificationType.deleteDialog,
      title: 'Are you sure?',
      description: 'Are you sure that you want to delete your "${firestore.auth.user!.email}" account from Cloud Firestore?\nAction can not be undone!',
      expectedInput: 'DELETE',
    );

    if (!doDelete || !mounted) return;
    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        await firestore.auth.deleteAccount();
      } catch (e, s) {
        throw AppException(
          'Deleting user failed',
          debugContext: 'Firebase Authentication',
          cause: e,
          stackTrace: s,
        );
      } finally {
        navigator.pop();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    final AppState appState = context.read();
    _projectIdController = TextEditingController(text: appState.firebaseProjectId.value);
    _apiKeyController = TextEditingController(text: appState.firebaseApiKey.value);
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Firestore firestore = context.read();

    return Column(
      spacing: 15,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _projectIdController,
          decoration: const InputDecoration(
            labelText: 'Project ID',
          ),
        ),
        TextField(
          controller: _apiKeyController,
          decoration: const InputDecoration(
            labelText: 'API Key',
          ),
        ),
        ElevatedButton(
          onPressed: _handleSaveConfig,
          child: const Text('Apply configuration'),
        ),
        StreamBuilder<FirebaseUser?>(
          stream: context.read<Firestore>().auth.authChanges,
          initialData: context.read<Firestore>().auth.user,
          builder: (context, snapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                if (firestore.isConfigValid) ...[
                  const Divider(),
                  Text(
                    'Authentication',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  if (!snapshot.hasData)
                    EmailPasswordLoginForm(
                      onLogin: _handleLogin,
                      onSignUp: _handleSignUp,
                      initialEmail: context.read<AppState>().firebaseAuthLastUserEmail.value,
                    ),
                  if (snapshot.hasData) ...[
                    Text(
                      'Logged in as ${mailPreview(snapshot.data!.email)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Wrap(
                      children: [
                        TextButton.icon(
                          onPressed: _handleLogout,
                          label: const Text('Logout'),
                          icon: const Icon(Icons.logout),
                          style: const ButtonStyle(
                            foregroundColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
                            iconColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _handleDeleteUser,
                          label: const Text('Delete user'),
                          icon: const Icon(Icons.delete_outline),
                          style: const ButtonStyle(
                            foregroundColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
                            iconColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/api/firebase/firebase.dart';
import 'package:passwordmanager/engine/api/online_providers.dart';
import 'package:passwordmanager/pages/firebase_login_page.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/engine/other/util.dart';

class OnlineProviderSelectPage extends StatefulWidget {
  const OnlineProviderSelectPage({super.key});

  @override
  State<OnlineProviderSelectPage> createState() => _OnlineProviderSelectPageState();
}

class _OnlineProviderSelectPageState extends State<OnlineProviderSelectPage> {
  late final Future<void> _firestoreReAuthFuture;

  Future<void> _firestoreReauthenticate() async {
    final Firestore firestoreService = context.read();
    if (firestoreService.deactivated) return; // Exit if firestore was not configured

    try {
      if (firestoreService.auth.isUserLoggedIn) return;
      await firestoreService.auth.loginWithRefreshToken();
    } catch (_) {}
  }


  Future<void> _firestoreSelected() async {
    final NavigatorState navigator = Navigator.of(context);
    final Firestore firestoreService = context.read();

    bool? success = true;
    if (!firestoreService.auth.isUserLoggedIn) {
      success = await navigator.push(
        MaterialPageRoute(builder: (context) => FirebaseLoginPage(loginMode: true)),
      );
    }
    if (success == true) {
      navigator.pop(LoginResult(OnlineProvidertype.firestore, loggedIn: firestoreService.auth.isUserLoggedIn));
    }
  }

  Future<void> _firestoreLogout() async {
    final NavigatorState navigator = Navigator.of(context);
    final Firestore firestoreService = context.read();

    try {
      Notify.showLoading(context: context);
      await firestoreService.auth.logout();
      setState(() {}); // Rebuild
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(e.toString()),
      );
      return;
    }
    navigator.pop();
  }

  @override
  void initState() {
    super.initState();
    _firestoreReAuthFuture = _firestoreReauthenticate();
  }

  @override
  Widget build(BuildContext context) {
    final Firestore firestoreService = context.read();

    return Scaffold(
      appBar: AppBar(
        title: Text('Select your provider'),
      ),
      body: DefaultPageBody(
        child: Column(
          children: [
            Column(
              spacing: 5.0,
              children: [
                ElevatedButton(
                  onPressed: !firestoreService.deactivated ? _firestoreSelected : null,
                  style: firestoreService.deactivated ? ButtonStyle(backgroundColor: WidgetStatePropertyAll<Color>(Colors.blueGrey)) : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10.0,
                    children: [
                      Icon(Icons.storage_rounded),
                      Flexible(child: Text('Cloud Firestore${firestoreService.deactivated ? ' (deactivated)' : ''}')),
                    ],
                  ),
                ),
                FutureBuilder<void>(future: _firestoreReAuthFuture, builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (firestoreService.auth.isUserLoggedIn) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Text(
                                'Logged in as ${mailPreview(firestoreService.auth.user!.email)}',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _firestoreLogout,
                            tooltip: 'Logout',
                            icon: Icon(
                              Icons.logout,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  } else {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                      ),
                    );
                  }
                }),
              ],
            )
          ],
        ),
      ),
    );
  }
}

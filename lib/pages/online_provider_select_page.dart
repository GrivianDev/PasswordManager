import 'package:flutter/material.dart';
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
  Future<void> _firestoreSelected() async {
    final NavigatorState navigator = Navigator.of(context);

    Notify.showLoading(context: context);
    bool? success = true;
    try {
      await Firestore.instance.auth.loginWithRefreshToken();
    } catch (e) {
      // Manual login
      success = await navigator.push(
        MaterialPageRoute(builder: (context) => FirebaseLoginPage(loginMode: true)),
      );
    }
    navigator.pop();

    if (success == true) {
      navigator.pop(LoginResult(OnlineProvidertype.firestore, loggedIn: Firestore.instance.auth.isUserLoggedIn));
    }
  }

  Future<void> _firestoreLogout() async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      Notify.showLoading(context: context);
      await Firestore.instance.auth.logout();
      setState(() {}); // Rebuild
    } catch (e) {
      if (!mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(e.toString()),
      );
    } finally {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select your sync option'),
      ),
      body: DefaultPageBody(
        child: Column(
          children: [
            Column(
              children: [
                ElevatedButton(
                  onPressed: _firestoreSelected,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10.0,
                    children: [
                      Icon(Icons.storage_rounded),
                      Flexible(child: Text('Cloud Firestore')),
                    ],
                  ),
                ),
                if (Firestore.instance.auth.isUserLoggedIn)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Text(
                            'Logged in as ${mailPreview(Firestore.instance.auth.user!.email)}',
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
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

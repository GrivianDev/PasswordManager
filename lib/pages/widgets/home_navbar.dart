import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/pages/settings_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

class HomeNavBar extends StatelessWidget {
  const HomeNavBar({super.key});

  Future<void> _clearAppData(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

    bool doClear = false;
    await Notify.dialog(
      context: context,
      type: NotificationType.confirmDialog,
      title: 'Proceed?',
        content: Text('This will reset all cached app settings. While it will not delete any secure files or online data, '
            'it will log you out of all connected providers when closing this app.'),
        onConfirm: () {
        doClear = true;
        navigator.pop();
      }
    );

    if (!doClear) return;

    try {
      if (!context.mounted) return;
      Notify.showLoading(context: context);
      final AppState appState = context.read();
      await appState.clearAllData();
    } catch (e) {
      navigator.pop();
      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Could not clear data',
      );
      return;
    }
    navigator.pop();
    scaffoldMessenger.showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 1500),
      content: const Row(
        children: [
          Text('Successfully cleared data'),
          Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: Icon(
              Icons.auto_awesome,
              size: 15,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text(
            'Options',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const Divider(),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.settings),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        'Settings',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          TextButton(
            onPressed: () => _clearAppData(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.cleaning_services),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        'Clear app data',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

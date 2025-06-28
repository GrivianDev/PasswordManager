import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/engine/persistence.dart';
import 'package:passwordmanager/pages/settings_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// Simplified navigation bar for the [HomePage]. The only options are to change the current theme and go online.
class HomeNavBar extends StatelessWidget {
  const HomeNavBar({super.key});

  /// Logs in the app into the firebase cloud or does the logout logic.
  Future<void> _changeOnlineMode(BuildContext context, bool enabled) async {
    final FirebaseConnector connector = context.read<FirebaseConnector>();
    final Settings settings = context.read<Settings>();
    try {
      if (enabled) {
        await connector.login();
      } else {
        connector.logout();
      }
      settings.setOnlineMode(enabled);
    } catch (e) {
      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Switch.adaptive(
                value: context.watch<Settings>().isOnlineModeEnabled,
                onChanged: (enabled) => !FirebaseConnector.deactivated ? _changeOnlineMode(context, enabled) : null,
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text(
                    context.read<Settings>().isOnlineModeEnabled ? 'Online' : 'Offline',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Icon(context.read<Settings>().isOnlineModeEnabled ? Icons.cloud_sync : Icons.cloud_off),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/pages/settings_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// Simplified navigation bar for the [HomePage]. The only options are to change the current theme and go online.
class HomeNavBar extends StatelessWidget {
  const HomeNavBar({Key? key}) : super(key: key);

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
          style: Theme.of(context).textTheme.displaySmall,
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
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Divider(color: Colors.grey),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.bodyMedium!.fontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.grey),
          Row(
            children: [
              Switch.adaptive(
                value: context.watch<Settings>().isOnlineModeEnabled,
                onChanged: (enabled) => !FirebaseConnector.deactivated
                    ? _changeOnlineMode(context, enabled)
                    : null,
              ),
              Expanded(
                child: Text(
                  context.read<Settings>().isOnlineModeEnabled
                      ? 'Online'
                      : 'Offline',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Icon(context.read<Settings>().isOnlineModeEnabled
                  ? Icons.cloud_sync
                  : Icons.cloud_off),
            ],
          ),
        ],
      ),
    );
  }
}

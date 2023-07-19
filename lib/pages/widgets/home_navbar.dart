import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/engine/persistance.dart';
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
          style: Theme
              .of(context)
              .textTheme
              .bodySmall,
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
          Row(
            children: [
              // This doesnt need to active watch the settings property because a theme change will trigger an automatic rebuild
              // since the MaterialApp is already watching the theme.
              Switch.adaptive(
                value: context.read<Settings>().isLightMode,
                onChanged: (enabled) {
                  context.read<Settings>().setLightMode(enabled);
                },
              ),
              Expanded(
                child: Text(
                  context.read<Settings>().isLightMode
                      ? 'Light theme'
                      : 'Dark theme',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          Row(
            children: [
              Switch.adaptive(
                value: context.watch<Settings>().isOnlineModeEnabled,
                onChanged: (enabled) => !FirebaseConnector.deactivated ? _changeOnlineMode(context, enabled) : null,
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

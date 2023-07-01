import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/manage_page.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/local_database.dart';

/// Navbar that gives more options, in particular the option to activate and deactivate autosaving (Is deactivated on windows).
/// Also this widget is the only option to exit the [ManagePage]. External tries to exit the page for example
/// through the Android back button are suppressed. You have to explicitly leave the page through clicking logout.
class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

  /// Exits the [ManagePage] and completly wipes the database by calling [LocalDatabase.clear].
  void _exit(BuildContext context) {
    LocalDatabase().clear();
    Navigator.pop(context);
    Navigator.pop(context);
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
                onChanged: (value) {
                  context.read<Settings>().setLightMode(value);
                },
              ),
              Expanded(
                child: Text(
                  context.read<Settings>().isLightMode
                      ? 'Light Mode'
                      : 'Dark Mode',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          if(Settings.isWindows) ... [
            Row(
              children: [
                // This watches the isAutoSaving property because it is not rebuild otherwise.
                Switch.adaptive(
                  value: context.watch<Settings>().isAutoSaving,
                  onChanged: (value) {
                    context.read<Settings>().setAutoSaving(value);
                  },
                ),
                Expanded(
                  child: Text(
                    context.read<Settings>().isAutoSaving
                        ? 'Autosaving'
                        : 'Manual saving',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
          const Divider(color: Colors.grey),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: IconButton(
              iconSize: 35.0,
              onPressed: () => _exit(context),
              icon: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

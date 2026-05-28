import 'package:ethercrypt/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';

class VaultsMasterViewNavbar extends StatelessWidget {
  const VaultsMasterViewNavbar({super.key});

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
        ],
      ),
    );
  }
}

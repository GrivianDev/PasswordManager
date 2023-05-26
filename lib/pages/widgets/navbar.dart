import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/pages/themes.dart';
import 'package:passwordmanager/engine/local_database.dart';

class NavBar extends StatelessWidget {
  NavBar({Key? key}) : super(key: key);

  void exit(BuildContext context) {
    LocalDataBase().clear();
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
          Divider(color: Theme.of(context).colorScheme.background),
          Row(
            children: [
              Switch.adaptive(
                value: Settings.isLightMode(),
                onChanged: (value) {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(value);
                },
              ),
              Text(Settings.isLightMode() ? 'Light Mode' : 'Dark Mode'),
            ],
          ),
          Divider(color: Theme.of(context).colorScheme.background),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: IconButton(
              iconSize: 35.0,
              onPressed: () => exit(context),
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

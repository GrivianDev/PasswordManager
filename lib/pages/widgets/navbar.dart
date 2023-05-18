import 'package:flutter/material.dart';

import 'package:passwordmanager/engine/persistance.dart';
import 'package:provider/provider.dart';

import '../themes.dart';

class NavBar extends StatelessWidget {
  NavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Divider(color: Theme.of(context).colorScheme.background,),
          Row(
            children: [
              Switch.adaptive(
                value: Settings.isLightMode(),
                onChanged: (value) {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(value);
                },
              ),
              Text(
                  Settings.isLightMode() ? 'Light Mode' : 'Dark Mode'
              ),
            ],
          )
        ],
      ),
    );
  }
}

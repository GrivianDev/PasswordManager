import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/local_database.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

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
          Divider(color: Theme.of(context).colorScheme.background),
          Row(
            children: [
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
          Divider(color: Theme.of(context).colorScheme.background),
          Row(
            children: [
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
          Divider(color: Theme.of(context).colorScheme.background),
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

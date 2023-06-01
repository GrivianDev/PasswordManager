import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistance.dart';

/// Simplified navigation bar for the [HomePage]. The only option is to change the current theme.
class HomeNavBar extends StatelessWidget {
  const HomeNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
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
                      ? 'Light Mode'
                      : 'Dark Mode',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

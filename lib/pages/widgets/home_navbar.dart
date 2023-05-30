import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistance.dart';

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

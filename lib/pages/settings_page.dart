import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistence.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.background,
        ),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: <Widget>[
            Row(
              children: [
                // This doesn't need to actively watch the settings property because a theme change will trigger an automatic rebuild
                // since the MaterialApp is already watching the theme.
                Switch.adaptive(
                  value: context.read<Settings>().isLightMode,
                  onChanged: (value) => context.read<Settings>().setLightMode(value),
                ),
                Flexible(
                  child: Text(
                    context.read<Settings>().isLightMode ? 'Light theme' : 'Dark theme',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                // This watches the isAutoSaving property because it is not rebuild otherwise.
                Switch.adaptive(
                  value: context.watch<Settings>().isAutoSaving,
                  onChanged: (value) => context.read<Settings>().setAutoSaving(value),
                ),
                Flexible(
                  child: Text(
                    context.read<Settings>().isAutoSaving ? 'Autosaving' : 'Manual saving',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              'Password generation:',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Row(
              children: [
                Checkbox.adaptive(
                  value: context.watch<Settings>().useLettersEnabled,
                  onChanged: (value) => context.read<Settings>().setUseLetters(value ?? true),
                ),
                Flexible(
                  child: Text(
                    'Use letters',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox.adaptive(
                  value: context.watch<Settings>().useNumbersEnabled,
                  onChanged: (value) => context.read<Settings>().setUseNumbers(value ?? true),
                ),
                Flexible(
                  child: Text(
                    'Use numbers',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox.adaptive(
                  value: context.watch<Settings>().useSpecialCharsEnabled,
                  onChanged: (value) => context.read<Settings>().setUseSpecialChars(value ?? true),
                ),
                Flexible(
                  child: Text(
                    'Use special characters',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

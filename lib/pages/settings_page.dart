import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _saving = false; // Flag do avoid race conditions / multiple frequent save callbacks

  Future<void> saveSettings() async {
    final AppState appState = context.read();

    _saving = true;
    try {
      await appState.save();
    } catch (_) {
      if (!mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Something went wrong!',
        content: Text('Could not save current app settings.'),
      );
    }
    _saving = false;
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: DefaultPageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Row(
              children: [
                // This doesn't need to actively watch the settings property because a theme change will trigger an automatic rebuild
                // since the MaterialApp is already watching the theme.
                Switch.adaptive(
                  value: appState.darkMode.value,
                  onChanged: (value) {
                    if (_saving) return;
                    appState.darkMode.value = value;
                    saveSettings();
                  },
                ),
                Flexible(
                  child: Text(
                    appState.darkMode.value ? 'Dark theme' : 'Light theme',
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
                  value: appState.autosaving.value,
                  onChanged: (value) {
                    if (_saving) return;
                    appState.autosaving.value = value;
                    saveSettings();
                  },
                ),
                Flexible(
                  child: Text(
                    appState.autosaving.value ? 'Autosaving' : 'Manual saving',
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
                  value: appState.pwGenUseLetters.value,
                  onChanged: (value) {
                    if (_saving) return;
                    appState.pwGenUseLetters.value = value!;
                    saveSettings();
                  },
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
                  value: appState.pwGenUseNumbers.value,
                  onChanged: (value) {
                    if (_saving) return;
                    appState.pwGenUseNumbers.value = value!;
                    saveSettings();
                  },
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
                  value: appState.pwGenUseSpecialChars.value,
                  onChanged: (value) {
                    if (_saving) return;
                    appState.pwGenUseSpecialChars.value = value!;
                    saveSettings();
                  },
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
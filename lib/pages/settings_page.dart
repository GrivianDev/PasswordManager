import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/pages/flows/user_input_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _saving = false; // Flag do avoid race conditions / multiple frequent save callbacks

  Future<void> _saveSettings() async {
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Row(
                spacing: 10,
                children: [
                  // This doesn't need to actively watch the settings property because a theme change will trigger an automatic rebuild
                  // since the MaterialApp is already watching the theme.
                  Switch.adaptive(
                    value: appState.darkMode.value,
                    onChanged: (value) {
                      if (_saving) return;
                      appState.darkMode.value = value;
                      _saveSettings();
                    },
                  ),
                  Flexible(
                    child: Text(
                      appState.darkMode.value ? 'Dark theme' : 'Light theme',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                spacing: 10,
                children: [
                  // This watches the isAutoSaving property because it is not rebuild otherwise.
                  Switch.adaptive(
                    value: appState.autosaving.value,
                    onChanged: (value) {
                      if (_saving) return;
                      appState.autosaving.value = value;
                      _saveSettings();
                    },
                  ),
                  Flexible(
                    child: Text(
                      appState.autosaving.value ? 'Autosaving' : 'Manual saving',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Text(
                'Password generation',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Password length: ${appState.pwGenMinCharacters.value} - ${appState.pwGenMaxCharacters.value}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              RangeSlider(
                values: RangeValues(
                  appState.pwGenMinCharacters.value.toDouble(),
                  appState.pwGenMaxCharacters.value.toDouble(),
                ),
                min: 8,
                max: 100,                
                onChanged: (range) {
                  if (_saving) return;
                  appState.pwGenMinCharacters.value = range.start.toInt();
                  appState.pwGenMaxCharacters.value = range.end.toInt();
                  _saveSettings();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox.adaptive(
                    value: appState.pwGenUseLetters.value,
                    onChanged: (value) {
                      if (_saving) return;
                      appState.pwGenUseLetters.value = value!;
                      _saveSettings();
                    },
                  ),
                  Flexible(
                    child: Text(
                      'Use letters',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                      _saveSettings();
                    },
                  ),
                  Flexible(
                    child: Text(
                      'Use numbers',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                      _saveSettings();
                    },
                  ),
                  Flexible(
                    child: Text(
                      'Use special characters',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                spacing: 10,
                children: [
                  Text(
                    'NTP Server',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Tooltip(
                    message: 'Used to synchronize time for more accurate 2FA code generation.',
                    child: Icon(Icons.help_outline, size: 18),
                  ),
                ],
              ),
              Row(
                spacing: 10,
                children: [
                  Flexible(
                    child: Text(
                      appState.ntpTimeSyncServer.value ?? 'Not configured',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final AppState appState = context.read();
                      String? input = await getUserInputDialog(
                        context: context,
                        title: 'Enter new NTP server',
                        labelText: 'NTP Server',
                        hintText: 'time.example.com',
                        allowEmptyInput: true,
                      );
                      if (input == null) return;
                      appState.ntpTimeSyncServer.value = input.isEmpty ? null : input;
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
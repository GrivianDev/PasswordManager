import 'dart:io';

import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GeneralSettings extends StatefulWidget {
  const GeneralSettings({super.key});

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  Future<void> _clearAppData() async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

    bool doClear = false;
    await Notify.dialog(
      context: context,
      type: NotificationType.confirmDialog,
      title: 'Proceed?',
      content: const Text('This will reset all cached app settings. While it will not delete any secure files or online data, '
          'it will log you out of all connected providers when closing this app.'),
      onConfirm: () {
        doClear = true;
        navigator.pop();
      },
    );

    if (!doClear) return;

    if (!mounted) return;
    await runAppFlow(context, () async {
      final AppState appState = context.read();
      await appState.clearAllData();
      if (Platform.isAndroid || Platform.isIOS) {
        await FilePicker.clearTemporaryFiles();
      }

      scaffoldMessenger.showSnackBar(const SnackBar(
        duration: Duration(seconds: 2),
        content: Wrap(
          spacing: 5,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 15,
              color: Colors.white,
            ),
            Text('Successfully cleared data'),
          ],
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch(); // trigger rebuild on change

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        Row(
          spacing: 10,
          children: [
            Switch.adaptive(
              value: appState.darkMode.value,
              onChanged: (value) {
                runAppFlow(context, () async {
                  appState.darkMode.value = value;
                  await appState.save();
                });
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
        Text(
          'Vault editing',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        Row(
          spacing: 10,
          children: [
            Switch.adaptive(
              value: appState.autosaving.value,
              onChanged: (value) {
                runAppFlow(context, () async {
                  appState.autosaving.value = value;
                  await appState.save();
                });
              },
            ),
            Flexible(
              child: Text(
                appState.autosaving.value ? 'Autosave enabled' : 'Autosave disabled',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const Divider(),
        TextButton(
          onPressed: _clearAppData,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              spacing: 15,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cleaning_services),
                Flexible(
                  child: Text(
                    'Clear app data',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

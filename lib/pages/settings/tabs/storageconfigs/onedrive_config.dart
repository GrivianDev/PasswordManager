import 'package:ethercrypt/engine/api/onedrive/onedrive.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_provider.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/other/storage_type_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OneDriveConfig extends StatefulWidget {
  const OneDriveConfig({super.key});

  @override
  State<OneDriveConfig> createState() => _OneDriveConfigState();
}

class _OneDriveConfigState extends State<OneDriveConfig> {
  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch();

    return Column(
      spacing: 15,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox.adaptive(
              value: appState.oneDriveEnabled.value,
              onChanged: (value) {
                final StorageProvider storageProvider = context.read();
                runAppFlow(context, () async {
                  appState.oneDriveEnabled.value = value!;
                  await appState.save();
                  storageProvider.load(StorageType.OneDrive);
                });
              },
            ),
            const Flexible(child: Text('Enable option')),
          ],
        ),
        StreamBuilder(
          stream: context.read<OneDrive>().auth.sessionChanges,
          initialData: context.read<OneDrive>().auth.session,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  const Text('OneDrive connected'),
                  TextButton.icon(
                    icon: const Icon(Icons.remove_circle_outline),
                    style: const ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
                      iconColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
                    ),
                    onPressed: () {
                      final NavigatorState navigator = Navigator.of(context);
                      runAppFlow(context, () async {
                        Notify.showLoading(context: context);
                        try {
                          context.read<OneDrive>().auth.revokeAccess();
                        } finally {
                          navigator.pop();
                        }
                      });
                    },
                    label: const Text('Revoke access'),
                  ),
                ],
              );
            } else {
              return ElevatedButton.icon(
                icon: Icon(StorageType.Dropbox.icon),
                onPressed: () {
                  final NavigatorState navigator = Navigator.of(context);
                  runAppFlow(context, () async {
                    try {
                      Notify.showLoading(context: context);
                      await context.read<OneDrive>().auth.authorize();
                    } finally {
                      navigator.pop();
                    }
                  });
                },
                label: const Text('Connect OneDrive'),
              );
            }
          },
        ),
      ],
    );
  }
}

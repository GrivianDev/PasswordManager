import 'package:ethercrypt/engine/api/googledrive/google_drive.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/other/storage_type_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GoogeDriveConfig extends StatefulWidget {
  const GoogeDriveConfig({super.key});

  @override
  State<GoogeDriveConfig> createState() => _GoogeDriveConfigState();
}

class _GoogeDriveConfigState extends State<GoogeDriveConfig> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<GoogleDrive>().auth.sessionChanges,
      initialData: context.read<GoogleDrive>().auth.session,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              const Text('Google Drive connected'),
              TextButton.icon(
                icon: const Icon(Icons.remove_circle_outline),
                style: const ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
                  iconColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
                ),
                onPressed: () {
                  runAppFlow(context, () {
                    context.read<GoogleDrive>().auth.revokeAccess();
                  });
                },
                label: const Text('Revoke access'),
              ),
            ],
          );
        } else {
          return ElevatedButton.icon(
            icon: Icon(StorageType.GoogleDrive.icon),
            onPressed: () {
              final NavigatorState navigator = Navigator.of(context);
              runAppFlow(context, () async {
                try {
                  Notify.showLoading(context: context);
                  await context.read<GoogleDrive>().auth.authorize();
                } finally {
                  navigator.pop();
                }
              });
            },
            label: const Text('Connect Google Drive'),
          );
        }
      },
    );
  }
}

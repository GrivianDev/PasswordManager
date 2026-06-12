import 'package:ethercrypt/engine/api/dropbox/dropbox.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/other/storage_type_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DropboxConfig extends StatefulWidget {
  const DropboxConfig({super.key});

  @override
  State<DropboxConfig> createState() => _DropboxConfigState();
}

class _DropboxConfigState extends State<DropboxConfig> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<Dropbox>().auth.sessionChanges,
      initialData: context.read<Dropbox>().auth.session,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              const Text('Dropbox connected'),
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
                      await context.read<Dropbox>().auth.revokeAccess();
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
                  await context.read<Dropbox>().auth.authorize();
                } finally {
                  navigator.pop();
                }
              });
            },
            label: const Text('Connect Drobox'),
          );
        }
      },
    );
  }
}
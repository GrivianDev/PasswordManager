import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_provider.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/engine/other/util.dart';
import 'package:ethercrypt/pages/flows/user_input_dialog.dart';
import 'package:ethercrypt/pages/settings/settings_page.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/engine/db/local_database.dart';

class AccountMasterViewNavbar extends StatelessWidget {
  const AccountMasterViewNavbar({super.key});

  Future<void> _exit(BuildContext context) async {
    final LocalDatabase database = context.read();

    if (database.hasUnsavedChanges) {
      await Notify.dialog(
        context: context,
        type: NotificationType.confirmDialog,
        title: 'Unsaved changes!',
        content: const Text('Do you really want to quit without saving? Unsaved changes will be lost.'),
        onConfirm: () {
          database.clear();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } else {
      database.clear();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final LocalDatabase database = context.read();

    final String? newPassword = await getUserInputDialog(
      context: context,
      title: 'Enter new password',
      labelText: 'Password',
      obscured: true,
      allowEmptyInput: false,
    );

    if (newPassword == null || !context.mounted) return;

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        database.source!.changePassword(newPassword);
        await database.save();
      } finally {
        navigator.pop();
      }

      if (!context.mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.notification,
        title: 'Successfully changed password!',
        content: const Text('Accessing this storage again will now require the new password.'),
      );
    });
  }

  Future<void> _storeBackup(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final LocalDatabase database = context.read();
    final StorageController controller = context.read<StorageProvider>().controller(StorageType.LocalFilesystem);

    await runAppFlow(context, () async {
      String? freeFileName;
      try {
        Notify.showLoading(context: context);
        final String storageLocation = await controller.getUserStorageLocation();
        freeFileName = await findAvailableFilename(storageLocation, '${database.source!.file.name}.x');
        await controller.repository.create(
          name: getBasename(freeFileName),
          location: storageLocation,
          initialData: await database.asFormattedData,
        );
        controller.load();
      } finally {
        navigator.pop();
      }

      if (!context.mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.notification,
        title: 'Successfully saved backup!',
        content: Text('Your backup has been stored locally as "$freeFileName".'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text(
            'Options',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const Divider(),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.settings),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        'Settings',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          TextButton(
            onPressed: () => _storeBackup(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_download_outlined),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        'Save backup',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          TextButton(
            onPressed: () => _changePassword(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.key_rounded),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        'Change password',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: IconButton(
              tooltip: 'Exit',
              iconSize: 35.0,
              onPressed: () => _exit(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

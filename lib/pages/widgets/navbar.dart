import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:passwordmanager/pages/upload_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/manage_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/engine/local_database.dart';

/// Navbar that gives more options, in particular the option to activate and deactivate autosaving (Is deactivated mobile offlinemode).
/// Also this widget is the only option to exit the [ManagePage]. External tries to exit the page for example
/// through the Android back button are suppressed. You have to explicitly leave the page through clicking logout.
/// Additional option in offlinemode is to upload current data.
/// Onlinemode also allows backup saves and deletion of cloud storage.
class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

  /// Exits the [ManagePage] and completly wipes the database by calling [LocalDatabase.clear].
  void _exit(BuildContext context) {
    LocalDatabase().clear();
    if(context.read<Settings>().isOnlineModeEnabled) Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
  }

  /// Forever deletes current storage from firebase cloud and wipes database by calling [LocalDatabase.clear].
  /// Does nothing if deletion fails.
  void _deleteStorage(BuildContext context) {
    Notify.dialog(
      context: context,
      type: NotificationType.deleteDialog,
      title: 'Are you sure?',
      content: Text(
        'Do you really want to wipe all data of cloud storage? Action cannot be undone!',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onConfirm: () async {
        NavigatorState navigator = Navigator.of(context);
        FirebaseConnector connector = context.read<FirebaseConnector>();

        try {
          navigator.pop();
          Notify.showLoading(context: context);
          await connector.deleteDocument();
          LocalDatabase().clear();
          navigator.pop();
          navigator.pop();
          navigator.pop();
          navigator.pop();
        } catch(e) {
          navigator.pop();
          navigator.pop();
        }
      }
    );
  }

  /// Saves a backup of the currently loaded accounts in the selected file.
  /// Allows overwriting files.
  Future<void> _storeBackup(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      String? path = await FilePicker.platform.saveFile(
        lockParentWindow: true,
        fileName: 'backup.x',
        dialogTitle: 'Save your data',
        type: FileType.custom,
        allowedExtensions: ['x'],
      );
      if(path == null) return;

      navigator.pop();
      File file = File(path!);
      if (!file.path.endsWith('.x')) {
        throw Exception('File extension is not supported');
      }
      await file.create(recursive: true);
      await file.writeAsString(LocalDatabase().cipher!);
      if(!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.notification,
        title: 'Successfully saved backup',
        content: Text(
          'Saved file under:\n${file.path}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    } catch(e) {
      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                onChanged: (value) {
                  context.read<Settings>().setLightMode(value);
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
          if (Settings.isWindows ||
              context.read<Settings>().isOnlineModeEnabled) ...[
            const Divider(color: Colors.grey),
            Row(
              children: [
                // This watches the isAutoSaving property because it is not rebuild otherwise.
                Switch.adaptive(
                  value: context.watch<Settings>().isAutoSaving,
                  onChanged: (value) {
                    context.read<Settings>().setAutoSaving(value);
                  },
                ),
                Expanded(
                  child: Text(
                    context.read<Settings>().isAutoSaving
                        ? 'Autosaving'
                        : 'Manual saving',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
          if (Settings.isWindows &&
              context.read<Settings>().isOnlineModeEnabled) ...[
            const Divider(color: Colors.grey),
            TextButton(
              onPressed: () => _storeBackup(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_download_outlined),
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Text(
                        'Save backup',
                        style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.bodyMedium!.fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!context.read<Settings>().isOnlineModeEnabled) ...[
            const Divider(color: Colors.grey),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const UploadPage())),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload),
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Text(
                        'Upload data',
                        style: TextStyle(
                          fontSize:
                          Theme.of(context).textTheme.bodyMedium!.fontSize,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Divider(color: Colors.grey),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: IconButton(
              iconSize: 35.0,
              onPressed: () => _exit(context),
              icon: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
            ),
          ),
          if (context.read<Settings>().isOnlineModeEnabled) ...[
            const Divider(color: Colors.grey),
            TextButton(
              onLongPress: () => _deleteStorage(context),
              onPressed: null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 35.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.bodyMedium!.fontSize,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

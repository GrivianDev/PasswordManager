import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/home_page.dart';
import 'package:passwordmanager/pages/settings_page.dart';
import 'package:passwordmanager/pages/upload_page.dart';
import 'package:passwordmanager/pages/manage_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/engine/local_database.dart';

/// Navbar that gives more options, in particular the option to activate and deactivate autosaving (Is not visible in mobile offlinemode).
/// Also this widget is the only option to exit the [ManagePage]. External tries to exit the page for example
/// through the Android back button are suppressed. You have to explicitly leave the page through clicking logout.
/// Additional option in offlinemode is to upload current data.
/// Onlinemode also allows backup saves and deletion of cloud storage.
class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

  /// Exits the [ManagePage] and completly wipes the database by calling [LocalDatabase.clear].
  void _exit(BuildContext context) {
    final LocalDatabase database = LocalDatabase();

    if (database.source!.hasUnsavedChanges) {
      Notify.dialog(
        context: context,
        type: NotificationType.confirmDialog,
        title: 'Unsaved changes!',
        content: Text(
          'Do you really want to quit without saving? Unsaved changes will be lost.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onConfirm: () {
          database.clear();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const HomePage(title: 'Home'),
            ),
            (route) => false,
          );
        },
      );
    } else {
      database.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomePage(title: 'Home'),
        ),
        (route) => false,
      );
    }
  }

  /// Forever deletes current storage from firebase cloud and wipes database by calling [LocalDatabase.clear].
  /// Does nothing if deletion fails.
  Future<void> _deleteStorage(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    await Notify.dialog(
      context: context,
      type: NotificationType.deleteDialog,
      title: 'Are you sure?',
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Do you really want to wipe all data of this cloud storage? Action cannot be undone!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  constraints: BoxConstraints(maxWidth: 100, maxHeight: 60.0),
                  hintText: 'Enter "DELETE"',
                ),
              ),
            ),
          ],
        ),
      ),
      beforeReturn: () => controller.dispose(),
      onConfirm: () async {
        if (controller.text != 'DELETE') return;
        controller.dispose();
        final NavigatorState navigator = Navigator.of(context);
        final FirebaseConnector connector = context.read<FirebaseConnector>();

        try {
          Notify.showLoading(context: context);
          await connector.deleteDocument();
          LocalDatabase().clear();
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const HomePage(title: 'Home'),
            ),
            (route) => false,
          );
        } catch (e) {
          navigator.pop();
          navigator.pop();
          navigator.pop();
        }
      },
    );
  }

  /// Saves a backup of the currently loaded accounts into the selected file or the designated directory on mobile.
  /// Allows overwriting files.
  Future<void> _storeBackup(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      String? path;
      if(Settings.isWindows) {
        path = await FilePicker.platform.saveFile(
          lockParentWindow: true,
          fileName: 'backup.x',
          dialogTitle: 'Save your data',
          type: FileType.custom,
          allowedExtensions: ['x'],
        );
      } else {
        final Directory? dir = await getExternalStorageDirectory();
        if(dir == null) throw Exception('Could not receive storage directory');
        path = '${dir.path}${Platform.pathSeparator}${LocalDatabase().source?.name}-backup';
        if(!path.endsWith('.x')) {
          path += '.x';
        }
      }

      if (path == null) return;

      navigator.pop();
      File file = File(path);
      if (!file.path.endsWith('.x')) {
        throw Exception('File extension is not supported');
      }

      if (!context.mounted) return;
      Notify.showLoading(context: context);
      bool? error;
      try {
        await file.create(recursive: true);
        await file.writeAsString(LocalDatabase().cipher!);
      } catch(e) {
        error = true;
      }
      navigator.pop();
      if(error ?? false) throw Exception('Could not save backup');

      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.notification,
        title: 'Successfully saved backup',
        content: Text(
          'Saved file under:\n${file.path}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    } catch (e) {
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
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.settings),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        'Settings',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (context.read<Settings>().isOnlineModeEnabled) ...[
            const Divider(),
            TextButton(
              onPressed: () => _storeBackup(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_download_outlined),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.0),
                        child: Text(
                          'Save backup',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!context.read<Settings>().isOnlineModeEnabled) ...[
            const Divider(),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const UploadPage())),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_upload),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.0),
                        child: Text(
                          'Upload data',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (context.read<Settings>().isOnlineModeEnabled) ...[
            const Divider(),
            TextButton(
              onPressed: () async => _deleteStorage(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 30.0,
                    ),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.0),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: IconButton(
              tooltip: "Exit",
              iconSize: 35.0,
              onPressed: () => _exit(context),
              icon: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

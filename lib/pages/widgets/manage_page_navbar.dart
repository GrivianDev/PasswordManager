import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:passwordmanager/engine/api/firebase/firebase.dart';
import 'package:passwordmanager/engine/api/online_providers.dart';
import 'package:passwordmanager/engine/persistence/connector/persistence_connector.dart';
import 'package:passwordmanager/pages/online_provider_select_page.dart';
import 'package:passwordmanager/pages/password_getter_page.dart';
import 'package:passwordmanager/pages/home_page.dart';
import 'package:passwordmanager/pages/settings_page.dart';
import 'package:passwordmanager/pages/manage_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/persistence/connector/firebase_connector.dart';

/// Navbar that gives more options, in particular the option to activate and deactivate autosaving.
/// Also this widget is the only option to exit the [ManagePage]. External tries to exit the page for example
/// through the Android back button are suppressed. You have to explicitly leave the page through clicking logout.
/// Additional option when using local files is to upload current data.
/// Online ser also allows backup saves.
class ManagePageNavbar extends StatelessWidget {
  const ManagePageNavbar({super.key});

  /// Exits the [ManagePage] and completly wipes the database by calling [LocalDatabase.clear].
  Future<void> _exit(BuildContext context) async {
    final LocalDatabase database = context.read();

    void cleaDatabaseAndGoBack() {
      database.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
        (route) => false,
      );
    }

    if (database.hasUnsavedChanges) {
      await Notify.dialog(
        context: context,
        type: NotificationType.confirmDialog,
        title: 'Unsaved changes!',
        content: Text('Do you really want to quit without saving? Unsaved changes will be lost.'),
        onConfirm: cleaDatabaseAndGoBack,
      );
    } else {
      cleaDatabaseAndGoBack();
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final LocalDatabase database = context.read();

    try {
      final String? newPassword = await navigator.push(MaterialPageRoute(
        builder: (context) => PasswordGetterPage(
          path: null,
          title: 'Enter new password',
          showPwStrengthIndicator: true,
        ),
      ));

      if (newPassword == null) return;
      if (!context.mounted) return;

      Notify.showLoading(context: context);
      database.source!.changePassword(newPassword);
      await database.save();
      navigator.pop();
      if (!context.mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.notification,
        title: 'Successfully changed password!',
        content: Text('Accessing this storage again will now require the new password.'),
      );
    } catch (e) {
      navigator.pop();
      if (!context.mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(e.toString()),
      );
    }
  }

  Future<void> _uploadFile(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final LocalDatabase database = context.read();
    final Firestore firestoreService = context.read();

    try {
      final LoginResult? result = await navigator.push(MaterialPageRoute(
        builder: (context) => OnlineProviderSelectPage(),
      ));

      if (result == null) return;

      if (!context.mounted) return;
      Notify.showLoading(context: context);
      late final PersistenceConnector connector;
      final String uploadName = database.source!.displayName!;
      if (result.type == OnlineProvidertype.firestore) {
        connector = FirebaseConnector(
          cloudDocId: '',
          cloudDocName: uploadName,
          firestoreServiceRef: firestoreService,
        );
      } else {
        throw Exception('This online provider is not supported for uploading.');
      }
      await connector.create(await database.formattedData);
      navigator.pop();
      if (!context.mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.notification,
        title: 'Upload success!',
        content: Text('"$uploadName" has been uploaded.\nPlease note: Changes made in this session will not '
            'affect the uploaded file unless you re-upload it. To work with the uploaded version, go back to the home page and select it from there.'),
      );
    } catch (e) {
      navigator.pop();
      if (!context.mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(e.toString()),
      );
    }
  }

  /// Saves a backup of the currently loaded accounts into the selected file or the designated directory on mobile.
  /// Allows overwriting files.
  Future<void> _storeBackup(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final LocalDatabase database = context.read();

    try {
      String? path;
      if (Platform.isWindows || Platform.isLinux) {
        path = await FilePicker.platform.saveFile(
          lockParentWindow: true,
          fileName: '${database.source!.displayName}-backup.x',
          dialogTitle: 'Save your data',
          type: FileType.custom,
          allowedExtensions: ['x'],
        );
      } else {
        final Directory? dir = await getExternalStorageDirectory();
        if (dir == null) throw Exception('Could not receive storage directory');
        path = '${dir.path}${Platform.pathSeparator}${database.source!.displayName}-backup.x';
      }

      if (path == null) return;

      File file = File(path);
      if (!file.path.endsWith('.x')) {
        throw Exception('File extension is not supported');
      }

      if (!context.mounted) return;
      Notify.showLoading(context: context);
      bool error = false;
      try {
        await file.create(recursive: true);
        await file.writeAsString(await database.formattedData);
      } catch (e) {
        error = true;
      }
      navigator.pop();
      if (error) throw Exception('Could not save backup');

      navigator.pop();
      if (!context.mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.notification,
        title: 'Successfully saved backup',
        content: Text('Saved file under:\n${file.path}'),
      );
    } catch (e) {
      navigator.pop();
      if (!context.mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(e.toString()),
      );
    }
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
          if (context.read<LocalDatabase>().source?.usesLocalFile == false) ...[
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
          ],
          if (context.read<LocalDatabase>().source?.usesLocalFile == true) ...[
            const Divider(),
            TextButton(
              onPressed: () => _uploadFile(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_upload),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.0),
                        child: Text(
                          'Upload data',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

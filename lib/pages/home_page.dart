import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/persistence/connector/file_connector.dart';
import 'package:passwordmanager/engine/selection_result.dart';
import 'package:passwordmanager/pages/firebase_cloud_access_page.dart';
import 'package:passwordmanager/pages/firebase_login_page.dart';
import 'package:passwordmanager/pages/manage_page.dart';
import 'package:passwordmanager/pages/mobile_file_selection_page.dart';
import 'package:passwordmanager/pages/other/reusable_things.dart';
import 'package:passwordmanager/pages/password_getter_page.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/pages/desktop_file_selection_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/settings.dart';
import 'package:passwordmanager/pages/widgets/home_navbar.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/engine/persistence/source.dart';

import '../engine/api/firebase/firebase.dart';
import '../engine/persistence/connector/firebase_connector.dart';

/// The entry point of the application.
/// Can display the current version information and provides options for:
/// * Offline: Locally select / create save files
/// * Online: Online select of files
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});

  final String title;

  Future<void> _selectLocally(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final LocalDatabase database = LocalDatabase();

    FileSelectionResult? fileResult;
    try {
      if (Settings.isWindows) {
        // Use desktop file selection
        fileResult = await navigator.push(
          MaterialPageRoute(
            builder: (contex) => DesktopFileSelectionPage(),
          ),
        );
      } else {
        // use mobile file selection for files in specifc directory
        final Directory? dir = await getExternalStorageDirectory();
        if (dir == null) throw Exception('Could not receive storage directory');
        fileResult = await navigator.push(
          MaterialPageRoute(
            builder: (contex) => MobileFileSelectionPage(dir: dir),
          ),
        );
      }

      if (fileResult == null) return;

      String? pw = await navigator.push(
        MaterialPageRoute(
          builder: (contex) => PasswordGetterPage(
            path: shortenPath(fileResult!.file.path),
            title: '${fileResult.isNewlyCreated ? 'Creating new' : 'Enter password for'} storage',
            showIndicator: fileResult.isNewlyCreated,
          ),
        ),
      );

      if (pw == null) return;

      try {
        if (!context.mounted) return;
        Notify.showLoading(context: context);
        database.setSource(Source(FileConnector(file: fileResult.file)));
        if (fileResult.isNewlyCreated) {
          await database.source!.initialiseNewSource(password: pw);
        } else {
          await database.load(password: pw);
        }
      } catch (e) {
        navigator.pop();
        rethrow;
      }
      navigator.pop();

      navigator.push(
        MaterialPageRoute(builder: (contex) => ManagePage()),
      );
    } catch (e) {
      database.clear(notify: false);
      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
  }

  Future<void> _selectOnline(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final LocalDatabase database = LocalDatabase();

    try {
      Notify.showLoading(context: context);
      try {
        await Firestore.instance.auth.loginWithRefreshToken();
      } catch (e) {
        await navigator.push(
          MaterialPageRoute(builder: (context) => FirebaseLoginPage(loginMode: true)),
        );
      }
      navigator.pop();

      FirestoreSelectionResult? result;
      if (Firestore.instance.auth.isUserLoggedIn) {
        result = await navigator.push(
          MaterialPageRoute(builder: (context) => FirebaseCloudAccessPage()),
        );
      }

      if (result == null) return;

      String? pw = await navigator.push(
        MaterialPageRoute(
          builder: (contex) => PasswordGetterPage(
            path: null,
            title: '${result!.isNewlyCreated ? 'Creating new' : 'Enter password for'} storage',
            showIndicator: result.isNewlyCreated,
          ),
        ),
      );

      if (pw == null) return;

      try {
        Notify.showLoading(context: context);
        database.setSource(Source(FirebaseConnector(cloudDocId: result.documentId, cloudDocName: result.documentName)));
        if (result.isNewlyCreated) {
          await database.source!.initialiseNewSource(password: pw);
        } else {
          await database.load(password: pw);
        }
      } catch (e) {
        navigator.pop();
        database.clear(notify: false);
        rethrow;
      }
      navigator.pop();

      navigator.push(
        MaterialPageRoute(builder: (contex) => ManagePage()),
      );
  } catch (e) {
      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const HomeNavBar(),
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => displayInfoDialog(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ),
        ],
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 5.0),
              child: Icon(Settings.isWindows ? Icons.desktop_windows_outlined : Icons.phone_android_outlined),
            ),
          ],
        ),
      ),
      body: DefaultPageBody(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            SizedBox(
              width: 560,
              height: 120,
              child: context.read<Settings>().isLightMode ? SvgPicture.asset('assets/lightLogo.svg') : SvgPicture.asset('assets/darkLogo.svg'),
            ),
            Text(
              'Access your encrypted save file:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 225),
              child: ElevatedButton(
                onPressed: () => _selectLocally(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.search_rounded),
                    const SizedBox(width: 10),
                    Flexible(child: Text('Load from local file')),
                  ],
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 225),
              child: ElevatedButton(
                onPressed: () => _selectOnline(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud),
                    const SizedBox(width: 10),
                    Flexible(child: Text('Connect to cloud')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

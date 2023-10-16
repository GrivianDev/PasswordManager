import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:passwordmanager/pages/help_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/pages/widgets/home_navbar.dart';
import 'package:passwordmanager/pages/widgets/offline_subpage.dart';
import 'package:passwordmanager/pages/widgets/online_subpage.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// The entry point of the application where cloud or offline mode can be swapped between.
/// Can display the current version information and provides options for:
/// * Offline: Searching a save file
/// * Offline: Reopening the last save file (only on Windows)
/// * Offline: Creating a new save file (only on Windows)
/// * Online: Access storage data
/// * Online: Create new storage
class HomePage extends StatelessWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  /// Displays the current app information such as the version number.
  /// Additionally shows a link to the github repository.
  Future<void> _displayInfo(BuildContext context) async {
    final PackageInfo info = await PackageInfo.fromPlatform();

    if (!context.mounted) return;
    Notify.dialog(
      context: context,
      type: NotificationType.notification,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 560,
              height: 80,
              child: context.read<Settings>().isLightMode ? SvgPicture.asset('assets/lightLogo.svg') : SvgPicture.asset('assets/darkLogo.svg'),
            ),
            Text(
              'Version: ${info.version}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: TextButton(
                onPressed: () async => await launchUrl(Uri.parse('https://github.com/grievous110/PasswordManager/tree/main')),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.code),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text(
                          'View code',
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  showLicensePage(
                    context: context,
                    applicationName: 'Ethercrypt',
                    applicationIcon: const Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Icon(Icons.shield_outlined),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copyright),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text(
                          'Licenses',
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5.0, bottom: 25),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HelpPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.help_outline),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Text(
                          'Help',
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'created by:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Joel Lutz',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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
              onPressed: () => _displayInfo(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: Scaffold.of(context).openEndDrawer,
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
      body: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.background,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Consumer<Settings>(
                    builder: (context, settings, child) => settings.isOnlineModeEnabled ? const OnlinePage() : const OfflinePage(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
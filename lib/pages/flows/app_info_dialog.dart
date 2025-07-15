import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/settings.dart';
import 'package:passwordmanager/pages/help_page.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// Displays the current app information such as the version number.
/// Additionally shows a link to the github repository.
Future<void> displayInfoDialog(BuildContext context) async {
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
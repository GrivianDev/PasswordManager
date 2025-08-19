import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// Displays the current app information such as the version number.
/// Additionally shows a link to the github repository.
Future<void> displayInfoDialog(BuildContext context) async {
  final PackageInfo info = await PackageInfo.fromPlatform();

  if (!context.mounted) return;
  Notify.dialog(
    context: context,
    type: NotificationType.notification,
    content: Column(
      spacing: 10.0,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 560,
          height: 80,
          child: context.read<AppState>().darkMode.value ? SvgPicture.asset('assets/darkLogo.svg') : SvgPicture.asset('assets/lightLogo.svg'),
        ),
        Text(
          'Version: ${info.version}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Column(
          children: [
            TextButton(
              onPressed: () async => await launchUrl(Uri.parse('https://github.com/grievous110/PasswordManager/tree/main')),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.code),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Text('View code'),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
                      child: Text('Licenses'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(
          'created by:\nJoel Lutz',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
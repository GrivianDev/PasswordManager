import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Displays the current app information such as the version number.
/// Additionally shows a link to the github repository.
Future<void> displayInfoDialog(BuildContext context) async {
  final PackageInfo info = await PackageInfo.fromPlatform();

  if (!context.mounted) return;
  showAdaptiveDialog(
    context: context,
    builder: (context) {
      return Theme(
        data: Theme.of(context).copyWith(
          listTileTheme: Theme.of(context).listTileTheme.copyWith(shape: const ContinuousRectangleBorder(),),
        ),
        child: AboutDialog.adaptive(
          applicationVersion: info.version,
          applicationIcon: const Icon(
            Icons.shield_outlined,
            size: 45,
          ),
          children: [
            const SizedBox(height: 15),
            TextButton(
              onPressed: () async => await launchUrl(Uri.parse('https://github.com/GrivianDev/PasswordManager')),
              child: const Wrap(
                spacing: 5,
                children: [
                  Icon(Icons.open_in_new),
                  Text('View code'),
                ],
              ),
            ),
            const Divider(),
          ],
        ),
      );
    },
  );
}

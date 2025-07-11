import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/settings.dart';
import 'package:passwordmanager/pages/help_page.dart';
import 'notifications.dart';

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

/// Building method for a small indicator on how strong the users password is.
Column buildPasswordStrengthIndictator(BuildContext context, double rating) {
  String text = 'Weak';
  if (rating > 0.5) {
    text = 'Decent';
  }
  if (rating > 0.85) {
    text = 'Strong';
  }
  return Column(
    children: [
      Text(
        'Password strength:',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      SizedBox(
        width: 250,
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120.0,
              height: 20.0,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: rating),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10.0),
                  );
                },
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: Theme.of(context).textTheme.displaySmall!.fontSize,
                    overflow: Theme.of(context).textTheme.displaySmall!.overflow,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<String?> getUserDefinedFilenameViaDialog(BuildContext context, String path) async {
  String? storageName;
  String? errorText;
  String currentInput = '';

  // Helper function for checking if file with name already exists
  bool nameExists() {
    final File fileCheck = File('$path${Platform.pathSeparator}$currentInput.x');
    return fileCheck.existsSync();
  }

  await Notify.dialog(
    context: context,
    type: NotificationType.confirmDialog,
    title: 'Name your new storage',
    content: StatefulBuilder(
      builder: (context, setState) {
        return SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'What name do you want for your storage?',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: TextField(
                  autofocus: true,
                  onChanged: (value) {
                    currentInput = value.trim();
                    setState(() {
                      if (currentInput.isEmpty) {
                        errorText = null;
                      } else if (nameExists()) {
                        errorText = 'A file with this name already exists';
                      } else {
                        errorText = null;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: errorText,
                    constraints: const BoxConstraints(maxWidth: 100, maxHeight: 80.0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
    onConfirm: () {
      if (currentInput.isNotEmpty && !nameExists()) {
        storageName = currentInput;
        Navigator.pop(context);
      }
    },
  );
  return storageName;
}

Route createSlideRoute(Widget page, {bool reverse = false}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // right-to-left
      const end = Offset.zero;
      const reverseBegin = Offset(-1.0, 0.0); // left-to-right

      final tween = Tween<Offset>(
        begin: reverse ? reverseBegin : begin,
        end: end,
      ).chain(CurveTween(curve: Curves.easeInOut));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

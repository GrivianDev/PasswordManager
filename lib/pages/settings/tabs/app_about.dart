import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/updates/app_version.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppAbout extends StatelessWidget {
  const AppAbout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: SvgPicture.asset('assets/appIcon.svg'),
        ),
        Text(
          'Ethercrypt ${context.read<AppVersion>().version}',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        Text(
          'A simple and secure open-source app to store your passwords and account details.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Built by Joel Lutz',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.open_in_new),
          title: const Text('View source code'),
          onTap: () {
            runAppFlow(context, () async {
              if (!await launchUrl(Uri.parse('https://github.com/GrivianDev/PasswordManager'))) {
                throw AppException('Failed to open url');
              }
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Licenses'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      listTileTheme: Theme.of(context).listTileTheme.copyWith(shape: const ContinuousRectangleBorder()),
                    ),
                    child: const LicensePage(),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

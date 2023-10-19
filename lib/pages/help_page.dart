import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.background,
        ),
        child: ListView(
          padding: const EdgeInsets.all(25.0),
          children: const [
            HelpTile(
              title: 'How to use',
              children: [
                TextSpan(
                  text:
                      'This password manager operates on the principle of selecting a single, robust password for encrypting your sensitive data. It is '
                      'advisable to settle for a strong password comprising a mix of uppercase and lowercase letters, numbers, and special characters, all while '
                      'ensuring it remains memorable. It is crucial to bear in mind that once this password is lost, there is no recourse for recovering your accounts, '
                      'as there are no password reset or similar features available. ',
                ),
                TextSpan(
                  text: 'Avoid loosing your password!\n\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(
                  text: 'Your data is organized into "',
                ),
                TextSpan(
                  text: 'Accounts',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(
                  text: '", each containing a name, a sorting tag, a general information field, an email, and a password field. '
                      'These can be conveniently created, modified, or removed to suit your preferences. Additionally, a case-insensitive search feature '
                      'is available to facilitate swift account retrieval.\n\n',
                ),
                TextSpan(
                  text:
                      'Should you decide to use a cloud storage, then you have the option to download backups accessible even without an internet connection. '
                      'On the other hand, if you possess a local file, you can upload its data to a cloud storage by specifying a name that has not yet been used.',
                ),
              ],
            ),
            Divider(),
            HelpTile(
              title: 'Modes explained',
              children: [
                TextSpan(
                  text: 'The current operational mode is denoted by the slider positioned within the options panel situated on the homepage.\n\n',
                ),
                TextSpan(
                  text: 'Offline mode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' allows users to choose a local file for secure data storage, making it ideal for keeping information safe without needing '
                      'an internet connection. Nonetheless, there are certain limitations to consider: this mode lacks the ability to synchronize data '
                      'between devices. For exchanging files, you must connect your mobile device to your desktop and manually transfer the file. '
                      'Alternatively, you can opt to select your file from Google Drive on your mobile device as an alternative solution.\n\n',
                ),
                TextSpan(
                  text: 'Online mode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ' enables effortless synchronization between Android and Windows devices via a Firebase Cloudstore database. Once a user creates '
                      'a designated storage, this data becomes accessible and editable across all devices using this application. It is crucial to note that you should, '
                      'at the very least, note down the name of the created storage, as this identifier is essential for access, in addition to the password. '
                      'The necessity for an internet connection in this mode is self-explanatory.',
                ),
              ],
            ),
            Divider(),
            HelpTile(
              title: 'Security',
              children: [
                TextSpan(
                  text:
                      'The encryption technique used is AES-256, whereby the cryptographic key is generated through hashing the provided UTF-8 encoded password '
                      'with the SHA-256 algorithm. Regarding the the cloud storage, access is exclusively permitted to this application through strict security rules.\n\n',
                ),
                TextSpan(
                  text: 'Is my data safe in the cloud storage?\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'Certainly! The only elements stored include the chosen storage name, the encrypted data, and the additionally hashed value of '
                      'the cryptographic key employed in the encryption process. The hash value serves exclusively to authenticate access to this '
                      'storage. The hash itself is useless for decrypting the stored data.\n\n',
                ),
                TextSpan(
                  text: 'Not convinced?\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: 'If you remain unconvinced, you have the option to create a customized version of this application using Flutter, coupled  '
                      'with your personal Firebase Cloud Storage integration. The code, along with a brief guide on creating the necessary authentication '
                      'file, can be located within the GitHub repository.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HelpTile extends StatelessWidget {
  const HelpTile({Key? key, required this.title, required this.children}) : super(key: key);

  final String title;
  final List<InlineSpan> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.displayMedium!.fontSize,
              overflow: Theme.of(context).textTheme.displayMedium!.overflow,
            ),
          ),
          expandedAlignment: Alignment.centerLeft,
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

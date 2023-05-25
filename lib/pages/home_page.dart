import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/manage_page.dart';
import 'package:passwordmanager/pages/password_getter_page.dart';
import 'package:passwordmanager/pages/widgets/home_navbar.dart';

import '../engine/implementation/account.dart';
import '../engine/local_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late LocalDataBase _database;

  @override
  void initState() {
    _database = LocalDataBase();
  }

  Future<void> selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select your save file',
      type: FileType.custom,
      allowedExtensions: ['x'],
      allowMultiple: false,
    );

    if (result != null) {
      File file = File(result.files.single.path ?? '');
      print(file.path);

      if (!context.mounted) return;
      String? pw = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordGetterPage(
            path: file.path,
            title: 'Enter password',
          ),
        ),
      );

      /*_database.addAccount(Account(name: 'Fortnite'));
      _database.addAccount(Account(name: 'Diablo'));
      _database.addAccount(Account(name: 'League'));
      _database.addAccount(Account(name: 'Dumb and dumber'));
      _database.addAccount(Account(name: 'gaaaaaaahd'));
      _database.setSource(file, 'test');
      _database.save();*/

      if (pw == null) return;
      print(pw);

      _database.setSource(file, pw);
      await _database.load();

      //sleep(Duration(seconds: 1));

      if (_database.accounts.isEmpty && file.lengthSync() > 0) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Wrong password!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      'Return',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ManagePage(title: 'Your accounts'),
          ),
        );
      }
    }
  }

  Future<void> createFile() async {
    String? path = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select directory for save file');

    if (path != null) {
      File file;
      Random rand = Random.secure();
      int tries = 1000;
      do {
        int random = rand.nextInt(10000) + 1000;
        file = File('$path${Platform.pathSeparator}save-$random.x');
        tries--;
      } while (file.existsSync() && tries > 0);

      if (!context.mounted) return;
      String? pw = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordGetterPage(
            path: file.path,
            title: 'Set password for new file',
          ),
        ),
      );

      if (pw == null) return;
      print(pw);

      _database.setSource(file, pw);

      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManagePage(title: 'Your accounts'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: HomeNavBar(),
      appBar: AppBar(
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        actions: [
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
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(widget.title,
            style: Theme.of(context).textTheme.headlineLarge),
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
                  padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Select your save file:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(
                            height: 15.0,
                          ),
                          ElevatedButton(
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                              ),
                            ),
                            onPressed: selectFile,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: Icon(
                                Icons.search,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(
                        height: 50,
                      ),
                      Column(
                        children: [
                          Text(
                            'No save file?',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: createFile,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                'Create a new one',
                                style: TextStyle(
                                    fontSize: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.fontSize,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/selection_result.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/pages/widgets/file_element.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/pages/flows/user_input_dialog.dart';
import 'package:path_provider/path_provider.dart';

/// Page that displays all available .x files in the apps directory on mobile.
/// Also allows selection of external files adn creation of new ones.
class MobileFileSelectionPage extends StatefulWidget {
  const MobileFileSelectionPage({super.key, required this.dir});

  final Directory dir;

  @override
  State<MobileFileSelectionPage> createState() => _MobileFileSelectionPageState();
}

class _MobileFileSelectionPageState extends State<MobileFileSelectionPage> {
  late Future<List<File>> _fileList;

  /// Future for intern futurebuilder
  Future<List<File>> _receiveFuture() async {
    final List<FileSystemEntity> list = await widget.dir.list().toList();
    return list.whereType<File>().where((e) => e.statSync().type == FileSystemEntityType.file).where((e) => e.path.endsWith('.x')).toList();
  }

  /// Tries to select a save file by using the platform specific filepicker.
  /// Files are cached and copied into the app directory afterwards. Clears cache after.
  /// If file was already present then a dialog is shown to determine if method should overwrite said file.
  /// Cases an error is thrown:
  /// * The file extension is NOT ".x"
  /// * An unknown error occurred
  Future<void> _mobileFileSelection() async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      // Mobile version always returns the cached version of picked file
      Notify.showLoading(context: context);
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        lockParentWindow: true,
        dialogTitle: 'Select your save file',
        type: FileType.any,
        //allowedExtensions: ['x'],
        allowMultiple: false,
      );

      if (result == null) {
        navigator.pop();
        return;
      }

      final File extrernalFile = File(result.files.single.path ?? '');
      final File targetFile = File('${widget.dir.path}${Platform.pathSeparator}${extractFilenameFromPath(extrernalFile.path)}');

      if (!extrernalFile.path.endsWith('.x')) {
        throw Exception('File extension is not supported');
      }

      if (await targetFile.exists()) {
        bool allowOverwrite = false;
        if(!mounted) return;
        await Notify.dialog(
            context: context,
            type: NotificationType.confirmDialog,
            title: 'File already exists',
            content: Text('Allow overwriting of current file?'),
            onConfirm: () {
              allowOverwrite = true;
              Navigator.pop(context);
            });
        if (!allowOverwrite) return;
      }

      await extrernalFile.copy(targetFile.path);
      // Clear up tmp files. This is nessecary cause android might cache file selections, if now the file
      // has been changed and reselected, then the cached unchanged variant will be used instead, which is not desired.
      await FilePicker.platform.clearTemporaryFiles();

      navigator.pop(); // Pop loading widget
      navigator.pop(FileSelectionResult(file: targetFile, isNewlyCreated: false));
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(e.toString()),
      );
    }
  }

  /// Returns a new not existing save file in the selected directory.
  /// Cases an error is thrown:
  /// * An unknown error occurred
  Future<void> _mobileCreateFile() async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      String? path = (await getExternalStorageDirectory())?.path;
      if (path == null) return;

      // Get user file name wish
      if (!mounted) return;
      String? storageName = await getUserInputDialog(
          context: context,
          title: 'Name your new storage',
          description: 'What name do you want for your storage?',
          labelText: 'Name',
          validator: (value) {
            final File fileCheck = File('$path${Platform.pathSeparator}$value.x');
            if (fileCheck.existsSync()) {
              return 'File with this name already exists!';
            } else if (!isValidFilename(value)) {
              return 'Discouraged filename!';
            }
            return null;
          }
      );

      if (storageName == null || storageName.isEmpty) return;

      final File file = File('$path${Platform.pathSeparator}$storageName.x');
      navigator.pop(FileSelectionResult(file: file, isNewlyCreated: true));
    } catch (e) {
      if (!mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(e.toString()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fileList = _receiveFuture();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select file'),
      ),
      body: DefaultPageBody(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              Text(
                shortenPath(widget.dir.path, parentsToShow: 0),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              FutureBuilder<List<File>>(
                future: _fileList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.data!.isEmpty) {
                      return Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.find_in_page_outlined,
                                size: 50.0,
                              ),
                              Text(
                                'Seems like there are no files yet...',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Expanded(
                        child: ListView.separated(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) => FileWidget(
                            file: snapshot.data!.elementAt(index),
                            onClicked: (e) => Navigator.of(context).pop(FileSelectionResult(file: e, isNewlyCreated: false)),
                            onDelete: () => setState(() {
                              _fileList = _receiveFuture();
                            }),
                          ),
                          separatorBuilder: (context, index) => const SizedBox(height: 15.0),
                        ),
                      );
                    }
                  } else if (snapshot.hasError) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          'Error while loading files!',
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                            overflow: Theme.of(context).textTheme.bodyMedium?.overflow,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
              SizedBox(
                height: 60.0,
                width: MediaQuery.of(context).size.width,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: _mobileFileSelection,
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        'Select other',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 60.0,
                width: MediaQuery.of(context).size.width,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: _mobileCreateFile,
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        'Create new',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

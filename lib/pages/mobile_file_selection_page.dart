import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/widgets/file_element.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/engine/reference.dart';

/// Page that displays all available .x files in the apps directory on mobile.
/// Also allows selection of external files.
class MobileFileSelectionPage extends StatefulWidget {
  const MobileFileSelectionPage({super.key, required Directory dir}) : _dir = dir;

  final Directory _dir;

  @override
  State<MobileFileSelectionPage> createState() => _MobileFileSelectionPageState();
}

class _MobileFileSelectionPageState extends State<MobileFileSelectionPage> {
  late Future<List<Reference<File>>> _fileList;

  /// Future for intern futurebuilder
  Future<List<Reference<File>>> _receiveFuture() async {
    final List<FileSystemEntity> list = await widget._dir.list().toList();
    return list.whereType<File>().where((e) => e.path.endsWith('.x')).map((e) => Reference<File>(value: e)).toList();
  }

  /// Tries to select a save file by using the platform specific filepicker.
  /// Files are cached and copied into a permanent directory afterwards. Clears cache after.
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

      final File cacheFile = File(result.files.single.path ?? '');
      final File file = File('${widget._dir.path}${Platform.pathSeparator}${cacheFile.path.split(Platform.pathSeparator).last}');

      if (!cacheFile.path.endsWith('.x')) {
        throw Exception('File extension is not supported');
      }

      if (await file.exists()) {
        bool? allow;
        if (!context.mounted) return;
        await Notify.dialog(
            context: context,
            type: NotificationType.confirmDialog,
            title: 'File already exists',
            content: Text(
              'Allow overwriting of current file?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onConfirm: () {
              allow = true;
              Navigator.of(context).pop();
            });
        if (!(allow ?? false)) return;
      }

      if (!context.mounted) return;
      try {
        await cacheFile.copy(file.path);
        await FilePicker.platform.clearTemporaryFiles();
      } catch (e) {
        //precaution
      }

      navigator.pop();
      navigator.pop(file);
    } catch (e) {
      await FilePicker.platform.clearTemporaryFiles();
      navigator.pop();
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
  void initState() {
    _fileList = _receiveFuture();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select file',
          style: Theme.of(context).appBarTheme.titleTextStyle,
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
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              Text(
                '...${Platform.pathSeparator}${widget._dir.path.split(Platform.pathSeparator).last}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              FutureBuilder<List<Reference<File>>>(
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
                              Text('Seems like there are no files yet...', style: TextStyle(color: Colors.grey),)
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Expanded(
                        child: ListView.separated(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) => FileWidget(
                            reference: snapshot.data!.elementAt(index),
                            onClicked: (e) => Navigator.of(context).pop(e),
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
                    onPressed: () => _mobileFileSelection(),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text('Select other'),
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

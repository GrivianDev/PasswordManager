import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/selection_result.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/pages/flows/user_input_dialog.dart';

class DesktopFileSelectionPage extends StatelessWidget {
  const DesktopFileSelectionPage({super.key});

  /// Returns the last opened save file to the parent widget, but only if it exists.
  void _openLast(BuildContext context) {
    final File file = File(context.read<AppState>().lastOpenedFilePath.value!);
    if (file.existsSync()) {
      Navigator.pop(context, FileSelectionResult(file: file, isNewlyCreated: false));
    } else {
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text('File does not exist.'),
      );
    }
  }

  /// Returns an existing save file by using the platform specific filepicker.
  /// Cases an error occurs:
  /// * The file extension is NOT ".x"
  /// * An unknown error occurred
  Future<void> _selectFile(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        lockParentWindow: true,
        dialogTitle: 'Select your save file',
        type: FileType.any,
        //allowedExtensions: ['x'],
        allowMultiple: false,
      );

      if (result == null) return;
      final File file = File(result.files.single.path ?? '');

      if (!file.path.endsWith('.x')) {
        throw Exception('File extension is not supported');
      }

      navigator.pop(FileSelectionResult(file: file, isNewlyCreated: false));
    } catch (e) {
      if (!context.mounted) return;
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
  Future<void> _createFile(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);

    try {
      String? path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select directory for save file',
        lockParentWindow: true,
      );

      if (path == null) return;

      // Get user file name wish
      if (!context.mounted) return;
      String? storageName = await getUserInputDialog(
          context: context,
          title: 'Name your new storage',
          description: 'What name do you want for your storage?',
          labelText: 'Name',
          validator: (value) {
            final File fileCheck = File('$path${Platform.pathSeparator}$value.x');
            if (fileCheck.existsSync()) {
              return 'File with this name already exists!';
            }
            return null;
          }
      );

      if (storageName == null || storageName.isEmpty) return;

      final File file = File('$path${Platform.pathSeparator}$storageName.x');

      navigator.pop(FileSelectionResult(file: file, isNewlyCreated: true));
    } catch (e) {
      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(e.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select file'),
      ),
      body: Stack(
        children: [
          DefaultPageBody(
            child: Column(
              spacing: 35,
              children: [
                Column(
                  children: [
                    Text(
                      'Select your save file:',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 15.0),
                    ElevatedButton(
                      onPressed: () => _selectFile(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 2.5),
                        child: Icon(
                          Icons.search,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
                if (context.read<AppState>().lastOpenedFilePath.value != null)
                  TextButton(
                    onPressed: () => _openLast(context),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        'Open last: ${shortenPath(context.read<AppState>().lastOpenedFilePath.value!)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20)
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 25,
            right: 25,
            child: Column(
              children: [
                Text(
                  'No save file?',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                TextButton(
                  onPressed: () => _createFile(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                        'Create a new one',
                        style: TextStyle(fontSize: 20)
                    ),
                  ),
                ),
              ],
            )
          ),
        ],
      ),
    );
  }
}

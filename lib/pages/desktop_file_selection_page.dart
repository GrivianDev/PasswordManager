import 'dart:io';
import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/selection_result.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:passwordmanager/engine/persistence.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

import 'other/reusable_things.dart';

class DesktopFileSelectionPage extends StatelessWidget {
  const DesktopFileSelectionPage({super.key});

  /// Returns the last opened save file through the [Settings.lastOpenedPath] property.
  void _openLast(BuildContext context) {
    final File file = File(context.read<Settings>().lastOpenedPath);
    if (file.existsSync()) {
      Navigator.of(context).pop(FileSelectionResult(file: file, isNewlyCreated: false));
    } else {
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(
          'File does not exist.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
  }

  /// Returns an existing save file by using the platform specific filepicker.
  /// Cases an error is thrown:
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
        content: Text(
          e.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
      String? storageName = await getUserDefinedFilenameViaDialog(context, path);

      if (storageName == null) return;

      final File file = File('$path${Platform.pathSeparator}$storageName.x');

      if (file.existsSync()) { // Sanity check
        throw Exception('This file already exists!');
      }

      navigator.pop(FileSelectionResult(file: file, isNewlyCreated: true));
    } catch (e) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select file',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: DefaultPageBody(
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
            if (context.read<Settings>().lastOpenedPath.isNotEmpty)
            TextButton(
              onPressed: () => _openLast(context),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'Open last: ${shortenPath(context.read<Settings>().lastOpenedPath)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    overflow: Theme.of(context).textTheme.bodySmall!.overflow,
                  ),
                ),
              ),
            ),
            Column(
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
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/pages/flows/typed_confirmation_dialog.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// Widget that displays a local file with options to rename or delete it.
///
/// Shows the file name, size in bytes, and provides buttons for inline renaming
/// or deleting the file. Renaming validates for uniqueness and discouraged filenames.
/// Deletion requires user confirmation.
///
/// - [file]: The file to display.
/// - [onClicked]: Callback when the file tile is tapped (if not renaming).
/// - [onDelete]: Callback after successful deletion.
class FileWidget extends StatefulWidget {
  const FileWidget({super.key, required this.file, required this.onClicked, required this.onDelete});

  final File file;
  final void Function(File) onClicked;
  final void Function() onDelete;

  @override
  State<FileWidget> createState() => _FileWidgetState();
}

class _FileWidgetState extends State<FileWidget> {
  late File _file;
  late TextEditingController _renameController;
  late String _currentName;
  String? _inputErrorText;
  bool _renaming = false;

  /// Asynchronously renames the file if the new name is valid and not empty.
  /// Cancels rename if the name is unchanged or invalid.
  /// Throws an error dialog if renaming fails.
  ///
  /// - [newName]: The new name to rename the file to.
  Future<void> _rename(String newName) async {
    if (newName.trim().isEmpty || newName == _currentName || _inputErrorText != null) {
      // Invalid / irrelevant input -> Return and deactivate rename mode
      setState(() {
        _renaming = false;
        _renameController.text = _currentName; // Reset to previous value
      });
      return;
    }

    try {
      final File newFile = File('${_file.parent.path}${Platform.pathSeparator}$newName.x');

      if (newFile.existsSync()) throw Exception(); // Sanity check

      _file = await _file.rename(newFile.path);
      // Set new name
      setState(() {
        _renaming = false;
        _currentName = newName; // Set to new value
      });
    } catch (e) {
      if (!mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text('Could not rename file'),
      );
    }
  }

  /// Prompts the user to confirm file deletion.
  /// Deletes the file if confirmed, showing a loading indicator.
  /// Calls the [onDelete] callback after successful deletion.
  Future<void> _deleteFileClicked() async {
    final NavigatorState navigator = Navigator.of(context);

    final bool doDelete = await typedConfirmDialog(
      context,
      NotificationType.deleteDialog,
      title: 'Are you sure?',
      description: 'Are you sure that you want to delete "${shortenPath(_file.path)}"?\nAction can not be undone!',
      expectedInput: 'DELETE',
    );

    if (!doDelete) return;

    if (!mounted) return;
    Notify.showLoading(context: context);

    try {
      await _file.delete();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text('Could not delete file'),
      );
      return;
    }

    navigator.pop();
    widget.onDelete();
  }

  @override
  void initState() {
    super.initState();
    _file = widget.file;
    _currentName = getBasename(extractFilenameFromPath(_file.path));
    _renameController = TextEditingController(text: _currentName);
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        onTap: () => !_renaming ? widget.onClicked(_file) : null,
        leading: const Icon(
          Icons.file_open_outlined,
          size: 40.0,
        ),
        title: !_renaming
            ? Text(
                extractFilenameFromPath(_file.path),
                style: Theme.of(context).textTheme.displayMedium,
              )
            : Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: TextField(
                  controller: _renameController,
                  autofocus: true,
                  onSubmitted: (value) => _rename(value),
                  decoration: InputDecoration(
                    errorText: _inputErrorText,
                    errorMaxLines: 10,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
                  ),
                  onChanged: (value) => setState(() {
                    final File file = File('${_file.parent.path}${Platform.pathSeparator}$value.x');
                    if (file.existsSync() && value != _currentName) {
                      _inputErrorText = 'File with this name already exists!';
                    } else if(!isValidFilename(value)) {
                      _inputErrorText = 'Discouraged filename!';
                    } else {
                      _inputErrorText = null;
                    }
                  }),
                  onTapOutside: (value) => setState(() {
                    _renaming = false;
                    _inputErrorText = null;
                    _renameController.text = _currentName; // Reset to previous value
                  }),
                ),
              ),
        subtitle: Text(
          '${_file.lengthSync()} bytes',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        trailing: !_renaming ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => setState(() {
                _renaming = true;
              }),
              icon: const Icon(
                Icons.edit,
                size: 30.0,
              ),
            ),
            IconButton(
              onPressed: _deleteFileClicked,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 35.0,
              ),
            ),
          ],
        ) : null,
      ),
    );
  }
}

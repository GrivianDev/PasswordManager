import 'dart:io';
import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

/// Widget that represents a local file. Allows deletion and renaming of file.
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
  late bool _renaming;
  late TextEditingController _renameController;
  late String _currentName;

  /// Asynchronous method to rename the file. Does nothing if provided name is empty or only consists of whitespaces.
  /// Purposefully fails if file with new name already exists.
  Future<void> _rename(String newName) async {
    try {
      if (newName.trim().isNotEmpty && newName != _currentName) {
        final int lastSeperator = _file.path.lastIndexOf(Platform.pathSeparator);
        final String relativePath = _file.path.substring(0, lastSeperator + 1);
        if (File('$relativePath$newName.x').existsSync()) throw Exception();
        _file = await _file.rename('$relativePath$newName.x');

        setState(() {
          _renaming = false;
          _currentName = newName;
        });
      } else {
        setState(() {
          _renaming = false;
          _renameController.text = _currentName;
        });
      }
    } catch (e) {
      if (!context.mounted) return;
      Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occurred!',
        content: Text(
          'Could not rename file',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
  }

  /// After user allows deletion file is deleted and [afterDelete] callback is executed.
  Future<void> _deleteFileClicked() async {
    bool? delete;
    await Notify.dialog(
        context: context,
        type: NotificationType.deleteDialog,
        title: 'Are you sure?',
        content: Text(
          'Are you sure that you want to delete "${shortenPath(_file.path)}"?\nAction can not be undone!',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onConfirm: () {
          delete = true;
          Navigator.of(context).pop();
        });
    if (delete ?? false) {
      if (!context.mounted) return;
      Notify.showLoading(context: context);
      await _file.delete();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      widget.onDelete();
    }
  }

  @override
  void initState() {
    _file = widget.file;
    _renaming = false;
    final String wholeName = _file.path.split(Platform.pathSeparator).last;
    _currentName = wholeName.substring(0, wholeName.lastIndexOf('.'));
    _renameController = TextEditingController(text: _currentName);
    super.initState();
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
                _file.path.split(Platform.pathSeparator).last,
                style: Theme.of(context).textTheme.displayMedium,
              )
            : Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: TextField(
                  controller: _renameController,
                  autofocus: true,
                  onSubmitted: (value) => _rename(value),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 15.0),
                  ),
                  onTapOutside: (value) => setState(() {
                    _renaming = false;
                    _renameController.text = _currentName;
                  }),
                ),
              ),
        subtitle: Text(
          '${_file.lengthSync()} bytes',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_renaming)
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
              onPressed: () => !_renaming ? _deleteFileClicked() : null,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 35.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

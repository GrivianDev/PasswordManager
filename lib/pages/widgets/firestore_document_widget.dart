import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/api/firebase/firebase.dart';
import 'package:passwordmanager/pages/flows/typed_confirmation_dialog.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

class FirestoreDocumentWidget extends StatefulWidget {
  const FirestoreDocumentWidget({super.key, required this.documentId, required this.documentName, required this.onClicked, required this.afterDelete});

  final String documentId;
  final String documentName;
  final void Function() onClicked;
  final void Function() afterDelete;

  @override
  State<FirestoreDocumentWidget> createState() => _FirestoreDocumentWidgetState();
}

class _FirestoreDocumentWidgetState extends State<FirestoreDocumentWidget> {
  late TextEditingController _renameController;
  late String _currentDocumentName;
  String? _inputErrorText;
  bool _renaming = false;

  Future<void> _renameStorage(String newName) async {
    if (newName.trim().isEmpty || newName == _currentDocumentName || _inputErrorText != null) {
      // Invalid / irrelevant input -> Return and deactivate rename mode
      setState(() {
        _renaming = false;
        _inputErrorText = null;
        _renameController.text = _currentDocumentName; // Reset to previous value
      });
      return;
    }

    try {
      final Firestore firestore = context.read();
      await firestore.updateDocument('${firestore.userVaultPath}/${widget.documentId}', {'name': newName});
      setState(() {
        _renaming = false;
        _currentDocumentName = newName;
      });
    } catch (e) {
      if (!mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(e.toString()),
      );
    }
  }

  Future<void> _deleteStorage() async {
    final NavigatorState navigator = Navigator.of(context);

    final bool doDelete = await typedConfirmDialog(
      context,
      NotificationType.deleteDialog,
      title: 'Are you sure?',
      description: 'Do you really want to wipe all data of this cloud storage "${widget.documentName}"? Action cannot be undone!',
      expectedInput: 'DELETE',
    );

    if (!doDelete) return;

    try {
      if (!mounted) return;
      Notify.showLoading(context: context);
      final Firestore firestore = context.read();
      await firestore.deleteDocument('${firestore.userVaultPath}/${widget.documentId}');
      widget.afterDelete();
      navigator.pop();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.error,
        title: 'Error occured!',
        content: Text(e.toString()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _currentDocumentName = widget.documentName;
    _renameController = TextEditingController(text: _currentDocumentName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        onTap: !_renaming ? widget.onClicked : null,
        leading: const Icon(
          Icons.cloud_circle,
          size: 40.0,
        ),
        title: !_renaming ? Text(
          _currentDocumentName,
          style: Theme.of(context).textTheme.displayMedium,
        ) : Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: TextField(
            controller: _renameController,
            autofocus: true,
            onSubmitted: (value) => _renameStorage(value),
            decoration: InputDecoration(
              errorText: _inputErrorText,
              errorMaxLines: 10,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15.0),
            ),
            onChanged: (value) => setState(() {
              if(!isValidFilename(value)) {
                _inputErrorText = 'Discouraged storage name!';
              } else {
                _inputErrorText = null;
              }
            }),
            onTapOutside: (value) => setState(() {
              _renaming = false;
              _inputErrorText = null;
              _renameController.text = _currentDocumentName;
            }),
          ),
        ),
        subtitle: Text(
          'ID: ${widget.documentId}',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 12),
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
              onPressed: _deleteStorage,
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

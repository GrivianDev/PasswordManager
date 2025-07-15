import 'package:flutter/material.dart';
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
      await Firestore.instance.deleteDocument('${Firestore.instance.userVaultPath}/${widget.documentId}');
      navigator.pop();
      widget.afterDelete();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        onTap: widget.onClicked,
        leading: const Icon(
          Icons.cloud_circle,
          size: 40.0,
        ),
        title: Text(
          widget.documentName,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        subtitle: Text(
          'ID: ${widget.documentId}',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 12),
        ),
        trailing: IconButton(
          onPressed: _deleteStorage,
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 35.0,
          ),
        ),
      ),
    );
  }
}

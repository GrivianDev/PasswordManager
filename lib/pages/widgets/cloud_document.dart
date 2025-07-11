import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/api/firebase/firebase.dart';

import '../other/notifications.dart';

class CloudDocument extends StatefulWidget {
  const CloudDocument({super.key, required this.documentId, required this.documentName, required this.onClicked, required this.afterDelete});

  final String documentId;
  final String documentName;
  final void Function(String) onClicked;
  final void Function() afterDelete;

  @override
  State<CloudDocument> createState() => _CloudDocumentState();
}

class _CloudDocumentState extends State<CloudDocument> {
  Future<void> _deleteStorageDialog(BuildContext context) async {
    String input = '';

    await Notify.dialog(
      context: context,
      type: NotificationType.deleteDialog,
      title: 'Are you sure?',
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Do you really want to wipe all data of this cloud storage "${widget.documentName}"? Action cannot be undone!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: TextField(
                onChanged: (value) => input = value.trim(),
                decoration: const InputDecoration(
                  constraints: BoxConstraints(maxWidth: 100, maxHeight: 60.0),
                  hintText: 'Enter "DELETE"',
                ),
              ),
            ),
          ],
        ),
      ),
      onConfirm: () async {
        if (input != 'DELETE') return;
        final NavigatorState navigator = Navigator.of(context);

        try {
          Notify.showLoading(context: context);
          await Firestore.instance.deleteDocument('${Firestore.instance.userVaultPath}/${widget.documentId}');
          widget.afterDelete();
        } catch (e) {
          await Notify.dialog(
            context: context,
            type: NotificationType.error,
            title: 'Error occured!',
            content: Text(
              e.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        navigator.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        onTap: () => widget.onClicked(widget.documentName),
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
          onPressed: () => _deleteStorageDialog(context),
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

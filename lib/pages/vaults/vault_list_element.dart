import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/other/file_utility.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/persistence/source.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_controller.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_provider.dart';
import 'package:passwordmanager/pages/accounts/accounts_master_view.dart';
import 'package:passwordmanager/pages/flows/app_flows.dart';
import 'package:passwordmanager/pages/flows/typed_confirmation_dialog.dart';
import 'package:passwordmanager/pages/flows/user_input_dialog.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/pages/vaults/vault_create_page.dart';

class VaultListElement extends StatelessWidget {
  const VaultListElement({super.key, required this.vault});

  final StorageFile vault;

  Future<void> _accessStorage(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final StorageProvider provider = context.read();

    final String? passwordInput = await getUserInputDialog(
      context: context,
      title: 'Enter password for "${vault.name}"',
      labelText: 'Password',
      obscured: true,
      allowEmptyInput: false,
    );

    if (passwordInput == null || !context.mounted) return;

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        final StorageController controller = provider.controller(vault.type);
        final LocalDatabase database = context.read();

        database.clear();
        await database.loadFromSource(Source(
          controller.repository,
          file: vault,
          password: passwordInput,
        ));
      } finally {
        navigator.pop();
      }
      navigator.push(MaterialPageRoute(builder: (context) => const AccountsMasterView()));
    });
  }

  Future<String?> _validateNameInput(String input, StorageController controller) async {
    try {
      if (input.isEmpty) return 'Cannot be empty';
      if (!isValidFilename(input)) return 'Discouraged vault name';
      final String location = await controller.getUserStorageLocation();
      if (await controller.repository.nameExists(name: input, location: location)) return 'Name already exists';
    } catch (_) {
      return 'Error occured';
    }
    return null;
  }

  Future<void> _renameStorage(BuildContext context) async {
    final StorageController controller = context.read<StorageProvider>().controller(vault.type);

    final String? newName = await getUserInputDialog(
      context: context,
      title: 'Rename storage',
      labelText: 'New name',
      validator: (value) => _validateNameInput(value, controller),
    );

    if (newName == null || !context.mounted) return;

    await runAppFlow(context, () async {
      await controller.repository.rename(vault, newName);
      controller.load();
    });
  }

  Future<void> _storeBackup(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final StorageController controller = context.read<StorageProvider>().controller(vault.type);

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        final String content = await controller.repository.read(vault);
        final String? resultPath = await saveFileExternal(filename: '${vault.name}.x', content: content);
        if (resultPath == null) return;

        scaffoldMessenger.showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Wrap(
            spacing: 5,
            children: [
              const Icon(
                Icons.download_done,
                size: 15,
                color: Colors.white,
              ),
              Text('Saved "${vault.name}" as local file'),
            ],
          ),
        ));
      } finally {
        navigator.pop();
      }
    });
  }

  Future<void> _deleteVault(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    final StorageController controller = context.read<StorageProvider>().controller(vault.type);

    final bool doDelete = await typedConfirmDialog(
      context,
      NotificationType.deleteDialog,
      title: 'Are you sure?',
      description: 'Are you sure that you want to delete "${vault.name}"?\nAction can not be undone!',
      expectedInput: 'DELETE',
    );

    if (!doDelete || !context.mounted) return;

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        await controller.repository.delete(vault);
        controller.load();

        scaffoldMessenger.showSnackBar(SnackBar(
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
          content: Wrap(
            spacing: 5,
            children: [
              const Icon(
                Icons.delete,
                size: 15,
                color: Colors.white,
              ),
              Text('Deleted "${vault.name}"'),
            ],
          ),
        ));
      } finally {
        navigator.pop();
      }
    });
  }

  void _morePressed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(25),
            children: [
              Text('Vault: "${vault.name}"'),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  final NavigatorState navigator = Navigator.of(context);
                  _renameStorage(navigator.context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move),
                title: const Text('Copy to storage'),
                onTap: () {
                  final NavigatorState navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => VaultCreatePage(sourceFile: vault),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export backup'),
                onTap: () {
                  final NavigatorState navigator = Navigator.of(context);
                  navigator.pop();
                  _storeBackup(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  final NavigatorState navigator = Navigator.of(context);
                  navigator.pop();
                  _deleteVault(navigator.context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFileMetadata() {
    final List<String> parts = [];

    if (vault.byteSize != null) {
      parts.add(formatBytes(vault.byteSize!));
    }
    if (vault.lastModified != null) {
      parts.add('Modified ${timeAgo(vault.lastModified!)}');
    }
    return parts.join(' • ');
  }

  IconData _iconForStorageType() {
    switch (vault.type) {
      case StorageType.LocalFilesystem:
        return Icons.storage;
      case StorageType.Dropbox:
        return Icons.shelves;
      case StorageType.OneDrive:
        return Icons.cloud;
      case StorageType.GoogleDrive:
        return Icons.add_to_drive;
      case StorageType.CloudFirestore:
        return Icons.whatshot;
    }
  }

  String _storageTypeLabel() {
    switch (vault.type) {
      case StorageType.LocalFilesystem:
        return 'Local File System';
      case StorageType.Dropbox:
        return 'Dropbox';
      case StorageType.OneDrive:
        return 'OneDrive';
      case StorageType.GoogleDrive:
        return 'Google Drive';
      case StorageType.CloudFirestore:
        return 'Cloud Firestore';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lock),
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '${vault.name}  '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Tooltip(
                message: _storageTypeLabel(),
                child: Icon(_iconForStorageType(), size: 16),
              ),
            ),
          ],
        ),
      ),
      tileColor: Theme.of(context).scaffoldBackgroundColor,
      subtitle: Text(_formatFileMetadata()),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _morePressed(context),
      ),
      onTap: () => _accessStorage(context),
    );
  }
}

import 'package:ethercrypt/engine/db/local_database.dart';
import 'package:ethercrypt/engine/other/file_utility.dart';
import 'package:ethercrypt/engine/other/util.dart';
import 'package:ethercrypt/engine/persistence/source.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_provider.dart';
import 'package:ethercrypt/pages/accounts/accounts_master_view.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/flows/typed_confirmation_dialog.dart';
import 'package:ethercrypt/pages/flows/user_input_dialog.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/other/snackbar_util.dart';
import 'package:ethercrypt/pages/other/storage_type_ui.dart';
import 'package:ethercrypt/pages/vaults/vault_create_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          controller,
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
      return 'Error occurred';
    }
    return null;
  }

  Future<void> _renameStorage(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final StorageController controller = context.read<StorageProvider>().controller(vault.type);

    final String? newName = await getUserInputDialog(
      context: context,
      title: 'Rename storage',
      labelText: 'New name',
      initialValue: vault.name,
      validator: (value) => _validateNameInput(value, controller),
    );

    if (newName == null || !context.mounted) return;

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        StorageFile renamed = await controller.repository.rename(vault, newName);
        controller.applyFileUpdate(vault, renamed);
      } finally {
        navigator.pop();
      }
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
        final String? resultPath = await saveFileContentExternal(
          dialogTitle: 'Save backup',
          filename: '${vault.name}.x',
          content: content,
        );
        if (resultPath == null) return;

        scaffoldMessenger.showSnackBar(
          SnackBarUtils.message('Saved "${vault.name}" as local file', icon: Icons.download_done),
        );
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
        controller.applyFileUpdate(vault, null);

        scaffoldMessenger.showSnackBar(SnackBarUtils.message(
          'Deleted "${vault.name}"',
          backgroundColor: Colors.redAccent,
          icon: Icons.delete,
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
                  navigator.pop();
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
                message: vault.type.label,
                child: Icon(vault.type.icon, size: 16),
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

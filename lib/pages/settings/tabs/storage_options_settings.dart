import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_provider.dart';
import 'package:ethercrypt/pages/other/storage_type_ui.dart';
import 'package:ethercrypt/pages/settings/tabs/storageconfigs/firestore_config.dart';
import 'package:ethercrypt/pages/settings/tabs/storageconfigs/googe_drive_config.dart';
import 'package:ethercrypt/pages/settings/tabs/storageconfigs/local_file_system_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StorageOptionsSettings extends StatefulWidget {
  const StorageOptionsSettings({super.key});

  @override
  State<StorageOptionsSettings> createState() => _StorageOptionsSettingsState();
}

class _StorageOptionsSettingsState extends State<StorageOptionsSettings> {
  StorageType _selectedStorageType = StorageType.LocalFilesystem;

  final Map<StorageType, Widget Function()> configBuilder = {
    StorageType.LocalFilesystem: () => const LocalFileSystemConfig(),
    StorageType.GoogleDrive: () => const GoogeDriveConfig(),
    StorageType.CloudFirestore: () => const FirestoreConfig(),
  };

  Widget _storageCard(StorageType type, IconData icon, String title) {
    final StorageProvider provider = context.read();
    final StorageController controller = provider.controller(type);
    final bool isConfigured = controller.isConfigured;
    final bool requiresAuth = controller.requiresAuth;

    return Card(
      child: SizedBox(
        width: 250,
        child: ListTile(
          tileColor: Theme.of(context).scaffoldBackgroundColor,
          selectedTileColor: Theme.of(context).scaffoldBackgroundColor,
          selected: _selectedStorageType == type,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(
            !isConfigured
                ? 'Not configured'
                : requiresAuth
                    ? 'Not authenticated'
                    : 'Configured',
            style: isConfigured && !requiresAuth ? Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14, color: Colors.green) : null,
          ),
          onTap: () {
            setState(() {
              _selectedStorageType = type;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<StorageProvider>(
          builder: (context, provider, child) {
            return Wrap(
              children: StorageType.values.where((type) => context.read<StorageProvider>().isAvailable(type)).map((type) => _storageCard(type, type.icon, type.label)).toList(),
            );
          },
        ),
        const Divider(),
        Text('Configuration', style: Theme.of(context).textTheme.headlineLarge),
        configBuilder[_selectedStorageType]!(),
      ],
    );
  }
}

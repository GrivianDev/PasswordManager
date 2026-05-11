import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';
import 'package:passwordmanager/pages/vaults/vault_list_element.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_provider.dart';

class VaultListView extends StatelessWidget {
  const VaultListView({super.key});

  @override
  Widget build(BuildContext context) {
    final StorageProvider storageProvider = context.watch();
    final List<StorageFile> files = storageProvider.allFiles;

    if (files.isEmpty && !storageProvider.isLoadingAny) {
      return const Center(
        child: FittedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.grey,
                size: 56,
              ),
              Text(
                'Your vault collection is empty',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      clipBehavior: Clip.hardEdge,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(25, 25, 25, 150),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final StorageFile file = files[index];
          return VaultListElement(vault: file);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 15),
      ),
    );
  }
}

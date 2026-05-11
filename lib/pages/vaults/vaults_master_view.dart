import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:passwordmanager/engine/other/file_utility.dart';
import 'package:passwordmanager/engine/app_exception.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_controller.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_provider.dart';
import 'package:passwordmanager/pages/flows/app_flows.dart';
import 'package:passwordmanager/pages/vaults/vault_create_page.dart';
import 'package:passwordmanager/pages/vaults/vault_list_view.dart';
import 'package:passwordmanager/pages/vaults/vault_load_statusbar.dart';
import 'package:passwordmanager/pages/widgets/morphing_fab.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/pages/flows/app_info_dialog.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/pages/vaults/vaults_master_view_navbar.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

class VaultsMasterView extends StatelessWidget {
  const VaultsMasterView({super.key});

  Future<void> _selectFromFileSystem(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final StorageController controller = context.read<StorageProvider>().controller(StorageType.LocalFilesystem);

    await runAppFlow(context, () async {
      File? externalFile;
      try {
        Notify.showLoading(context: context);
        externalFile = await pickExternalFile(dialogTitle: 'Select your vault file');
      } finally {
        navigator.pop();
      }

      if (externalFile == null) return;
      if (!externalFile.path.endsWith('.x')) {
        throw AppException('File extension is not supported');
      }

      final String targetDir = await controller.getUserStorageLocation();
      final String fileName = await findAvailableFilename(targetDir, extractFilenameFromPath(externalFile.path));
      final File targetFile = File('$targetDir${Platform.pathSeparator}$fileName');

      await externalFile.copy(targetFile.path);
      controller.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: MorphingFab(
        toggledIconScale: 1.2,
        options: [
          FabOption(
            label: 'Import vault',
            icon: Icons.save_alt_outlined,
            onPressed: () => _selectFromFileSystem(context),
          ),
          FabOption(
            label: 'Create vault',
            icon: Icons.add_circle_outline_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VaultCreatePage(),
                ),
              );
            },
          ),
        ],
      ),
      endDrawer: const VaultsMasterViewNavbar(),
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => displayInfoDialog(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ),
        ],
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 40,
              ),
              context.watch<AppState>().darkMode.value ? SvgPicture.asset('assets/darkLogo.svg') : SvgPicture.asset('assets/lightLogo.svg'),
            ],
          ),
        ),
      ),
      body: const DefaultPageBody(
        child: Column(
          children: [
            VaultStatusBar(),
            Expanded(child: VaultListView()),
          ],
        ),
      ),
    );
  }
}

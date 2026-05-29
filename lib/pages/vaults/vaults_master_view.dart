import 'dart:io';

import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/other/file_utility.dart';
import 'package:ethercrypt/engine/other/util.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_provider.dart';
import 'package:ethercrypt/engine/updates/update_service.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/other/snackbar_util.dart';
import 'package:ethercrypt/pages/settings/settings_page.dart';
import 'package:ethercrypt/pages/vaults/vault_create_page.dart';
import 'package:ethercrypt/pages/vaults/vault_list_view.dart';
import 'package:ethercrypt/pages/vaults/vault_load_statusbar.dart';
import 'package:ethercrypt/pages/vaults/vaults_master_view_navbar.dart';
import 'package:ethercrypt/pages/widgets/default_page_body.dart';
import 'package:ethercrypt/pages/widgets/morphing_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class VaultsMasterView extends StatelessWidget {
  const VaultsMasterView({super.key});

  Future<void> _selectFromFileSystem(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
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

      scaffoldMessenger.showSnackBar(
        SnackBarUtils.message('Imported as "$fileName"', icon: Icons.download_done),
      );
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
          Consumer<UpdateService>(
            builder: (context, updater, child) {
              if (updater.hasUpdateAvailable) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Stack(
                    children: [
                      Tooltip(
                        message: 'Version ${updater.updateInfo.latestVersion ?? '?'} available',
                        child: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(initalTab: SettingsTab.updates),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
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

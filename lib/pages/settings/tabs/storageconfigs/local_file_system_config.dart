import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/engine/persistence/storage/controller/local_file_controller.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_provider.dart';
import 'package:passwordmanager/pages/flows/app_flows.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

class LocalFileSystemConfig extends StatefulWidget {
  const LocalFileSystemConfig({super.key});

  @override
  State<LocalFileSystemConfig> createState() => _LocalFileSystemConfigState();
}

class _LocalFileSystemConfigState extends State<LocalFileSystemConfig> {
  late final TextEditingController _storagePathController;

  Future<void> _changeStoragePathViaDirectoryPicker() async {
    final NavigatorState navigator = Navigator.of(context);
    final AppState appState = context.read();
    final StorageProvider storageProvider = context.read();

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        String? path = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select directory for vaults',
          lockParentWindow: true,
        );

        if (path == null || !mounted) return;
        appState.localSystemStorageLocation.value = path;
        await appState.save();
        storageProvider.load(StorageType.LocalFilesystem);
        _storagePathController.text = path;

        if (!mounted) return;
      } finally {
        navigator.pop();
      }
    });
  }

  Future<void> _changeStoragePathManually() async {
    final AppState appState = context.read();
    final StorageProvider storageProvider = context.read();

    await runAppFlow(context, () async {
      appState.localSystemStorageLocation.value = _storagePathController.text;
      await appState.save();
      storageProvider.load(StorageType.LocalFilesystem);
    });
  }

  @override
  void initState() {
    super.initState();

    final AppState appState = context.read();
    _storagePathController = TextEditingController(text: appState.localSystemStorageLocation.value);
  }

  @override
  void dispose() {
    _storagePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        TextField(
          controller: _storagePathController,
          decoration: InputDecoration(
            labelText: 'Storage path',
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: IconButton(
                onPressed: _changeStoragePathViaDirectoryPicker,
                icon: const Icon(Icons.folder_open),
              ),
            ),
          ),
          onSubmitted: (value) => _changeStoragePathManually(),
        ),
        if (appState.localSystemStorageLocation.value.isEmpty)
          FutureBuilder(
            future: context.read<LocalFileController>().getUserStorageLocation(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  'Using default path: ${snapshot.data}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              return Container();
            },
          ),
      ],
    );
  }
}

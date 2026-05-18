import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ethercrypt/engine/other/file_utility.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/updates/downloader.dart';
import 'package:ethercrypt/engine/updates/update_asset.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/engine/other/util.dart';
import 'package:ethercrypt/engine/updates/app_version.dart';
import 'package:ethercrypt/engine/updates/update_service.dart';

class UpdateSettings extends StatelessWidget {
  const UpdateSettings({super.key});

  Future<UpdateAsset?> _showAssetPickerDialog(BuildContext context, List<UpdateAsset> assets) {
    // TODO: Before asset picker, pull most recent assets forcefully to gurantee best selection
    final List<UpdateAsset> sortedAssets = [...assets]..sort((a, b) {
        final aSupported = RuntimeRules.supports(a.type);
        final bSupported = RuntimeRules.supports(b.type);

        if (aSupported == bSupported) return 0;
        return aSupported ? -1 : 1; // supported first
      });

    return showDialog<UpdateAsset>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose installer'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: sortedAssets.map((asset) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(
                    asset.fileName,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(fontFamily: 'monospace'),
                  ),
                  subtitle: RuntimeRules.supports(asset.type) ? const Text('(Recommended)') : null,
                  onTap: () => Navigator.of(context).pop(asset),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _performDownload(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final UpdateService updateService = context.read();
    final UpdateAsset? asset = await _showAssetPickerDialog(context, updateService.updateInfo.assets);
    if (asset == null || !context.mounted) return;

    final Directory tmpDir = await getTemporaryDirectory();
    final File tmpFile = File('${tmpDir.path}${Platform.pathSeparator}${asset.fileName}');
    final Downloader downloader = Downloader();

    if (!context.mounted) return;
    Future<void> dialogFuture = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<DownloadProgress>(
          valueListenable: downloader.progress,
          builder: (context, progress, child) {
            return AlertDialog(
              title: Text(progress.finished ? 'Download complete' : 'Downloading update'),
              content: Column(
                spacing: 10,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.fileName),
                  LinearProgressIndicator(
                    value: progress.hasKnownSize ? progress.progress : null,
                    backgroundColor: Colors.blueGrey,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${formatBytes(progress.downloadedBytes)} / ${formatBytes(progress.totalBytes)}'),
                      Text('${formatBytes(progress.bytesPerSecond.toInt())}/s'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await downloader.cancel();
                    navigator.pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: progress.finished
                      ? () async {
                          String? resultPath;
                          try {
                            Notify.showLoading(context: context);
                            resultPath = await saveFileExternal(
                              dialogTitle: 'Save update',
                              filename: asset.fileName,
                              sourceFile: tmpFile,
                            );
                          } finally {
                            navigator.pop();
                          }

                          if (!context.mounted || resultPath == null) return;

                          navigator.pop();

                          Notify.dialog(
                            context: context,
                            type: NotificationType.notification,
                            title: 'Update ready',
                            content: const Text(
                              'The update was saved successfully. '
                              'Please close the application and open the downloaded file.',
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    'Save',
                    style: progress.finished ? null : const TextStyle(color: Colors.blueGrey),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    await downloader.startDownload(
      Uri.parse(asset.downloadUrl),
      tmpFile,
    );

    await dialogFuture;
    downloader.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updater, child) {
        final UpdateInfo info = updater.updateInfo;

        return Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Keep your application up to date with the latest features and security patches'),
            Row(
              children: [
                Consumer<AppState>(
                  builder: (context, appState, child) => Checkbox.adaptive(
                    value: appState.updateAutoCheck.value,
                    onChanged: (value) {
                      runAppFlow(context, () async {
                        appState.updateAutoCheck.value = value!;
                        await appState.save();
                      });
                    },
                  ),
                ),
                Flexible(
                  child: Text(
                    'Automatically check for updates',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  spacing: 20,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current version: ${context.read<AppVersion>().version}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 15,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              updater.hasUpdateAvailable ? Icons.update_rounded : Icons.check_circle_outline,
                              color: updater.hasUpdateAvailable ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                updater.hasUpdateAvailable ? 'Update available (${info.latestVersion ?? '?'})' : 'You are up to date',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (info.lastCheck != null)
                                Text(
                                  'Last checked: ${timeAgo(updater.updateInfo.lastCheck!)}',
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey),
                                ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: updater.isChecking ? null : () => updater.checkForUpdates(force: true),
                            icon: updater.isChecking
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(updater.isChecking ? 'Checking...' : 'Check for updates'),
                          ),
                        ],
                      ),
                    ),
                    if (updater.hasUpdateAvailable)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _performDownload(context),
                          icon: const Icon(Icons.download),
                          label: const Text('Download now'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:ethercrypt/engine/updates/update_asset.dart';
import 'package:flutter/foundation.dart';

final class UpdateInfo {
  final String? latestVersion;
  final DateTime? lastCheck;
  final List<UpdateAsset> assets;

  const UpdateInfo({
    this.latestVersion,
    this.lastCheck,
    this.assets = const [],
  });
}

abstract class UpdateService with ChangeNotifier {
  UpdateInfo get updateInfo;

  bool get isChecking;

  bool get hasUpdateAvailable;

  void scheduleNextCheck();

  Future<void> checkForUpdates({bool force = false});
}

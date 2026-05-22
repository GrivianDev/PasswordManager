import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';
import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/updates/update_asset.dart';
import 'package:ethercrypt/engine/api/http_client.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/updates/app_version.dart';
import 'package:ethercrypt/engine/updates/update_service.dart';

class GitHubUpdateService extends UpdateService {
  final AppState _appState;
  final AppVersion appVersion;
  final String owner;
  final String repo;
  final Uri _githubReleasesUrl;

  UpdateInfo _updateInfo = const UpdateInfo();
  Timer? _timer;
  bool _isChecking = false;

  final Duration checkInterval;

  GitHubUpdateService({
    required AppState appState,
    required this.appVersion,
    required this.owner,
    required this.repo,
    this.checkInterval = const Duration(hours: 24),
  })  : _appState = appState,
        _githubReleasesUrl = Uri.https('api.github.com', '/repos/$owner/$repo/releases/latest') {
    final DateTime? lastCheck = _appState.updateLastCheckTime.value > 0 ? DateTime.fromMillisecondsSinceEpoch(_appState.updateLastCheckTime.value, isUtc: true) : null;
    _updateInfo = UpdateInfo(latestVersion: _appState.updateLatestKnownVersion.value, lastCheck: lastCheck);
  }

  @override
  UpdateInfo get updateInfo => _updateInfo;

  @override
  bool get isChecking => _isChecking;

  @override
  bool get hasUpdateAvailable {
    final String? latest = _updateInfo.latestVersion;
    if (latest == null) return false;

    return Version.parse(latest) > Version.parse(appVersion.version);
  }

  bool _shouldCheck() {
    if (_appState.updateLastCheckTime.value <= 0) return true;
    if (!_appState.updateAutoCheck.value) return false;

    final DateTime lastCheck = DateTime.fromMillisecondsSinceEpoch(
      _appState.updateLastCheckTime.value,
      isUtc: true,
    );

    return DateTime.now().difference(lastCheck) > checkInterval;
  }

  @override
  void scheduleNextCheck() {
    _timer?.cancel();

    final DateTime last = DateTime.fromMillisecondsSinceEpoch(
      _appState.updateLastCheckTime.value,
      isUtc: true,
    );

    final DateTime next = last.add(checkInterval);
    final Duration delay = next.difference(DateTime.now());

    _timer = Timer(delay.isNegative ? Duration.zero : delay, () async {
      await checkForUpdates();
      scheduleNextCheck();
    });
  }

  @override
  Future<void> checkForUpdates({bool force = false}) async {
    if (!_shouldCheck() && !force) return;

    _isChecking = true;
    notifyListeners();

    try {
      final result = await _fetchFromGithub();
      if (result != null) {
        _updateInfo = result;
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  DistributionType? _inferTypeFromFileName(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.exe')) return DistributionType.windowsExe;
    if (lower.endsWith('.appimage')) return DistributionType.linuxAppImage;
    if (lower.endsWith('.deb')) return DistributionType.linuxDeb;
    if (lower.endsWith('.apk')) return DistributionType.androidApk;
    return null;
  }

  UpdateAsset? _parseAsset(Map<String, dynamic> assetJson) {
    final String name = assetJson['name'] ?? '';
    final String url = assetJson['browser_download_url'] ?? '';

    final DistributionType? type = _inferTypeFromFileName(name);

    if (type == null) return null;

    return UpdateAsset(
      type: type,
      downloadUrl: url,
      fileName: name,
    );
  }

  Future<UpdateInfo?> _fetchFromGithub() async {
    final httpClient = LoggingHttpClient();
    try {
      final http.Response response = await httpClient.get(
        _githubReleasesUrl,
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final String? tag = data['tag_name'];
      if (tag == null) return null;

      final String version = tag.startsWith('v') ? tag.substring(1) : tag;

      List<UpdateAsset> updateAssets = [];

      final assetsJson = (data['assets'] as List<dynamic>? ?? []);
      for (final raw in assetsJson) {
        final UpdateAsset? asset = _parseAsset(raw as Map<String, dynamic>);
        if (asset != null) {
          updateAssets.add(asset);
        }
      }

      _appState.updateLastCheckTime.value = DateTime.timestamp().millisecondsSinceEpoch;
      _appState.updateLatestKnownVersion.value = version;
      await _appState.save();

      return UpdateInfo(
        latestVersion: version,
        lastCheck: DateTime.now(),
        assets: updateAssets,
      );
    } catch (e, s) {
      throw AppException(
        'Failed to fetch update info from GitHub',
        debugContext: 'GitHub Update Service',
        cause: e,
        stackTrace: s,
      );
    } finally {
      httpClient.close();
    }
  }
}

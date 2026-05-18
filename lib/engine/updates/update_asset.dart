import 'dart:io';

enum DistributionType {
  windowsExe,
  windowsMsix,
  androidApk,
  linuxDeb,
  linuxAppImage,
}

class RuntimeRules {
  static List<DistributionType> preference() {
    if (Platform.isWindows) {
      return [
        DistributionType.windowsMsix,
        DistributionType.windowsExe,
      ];
    }

    if (Platform.isLinux) {
      return [
        DistributionType.linuxAppImage,
        DistributionType.linuxDeb,
      ];
    }

    if (Platform.isAndroid) {
      return [
        DistributionType.androidApk,
      ];
    }

    return [];
  }

  static bool supports(DistributionType type) {
    return preference().contains(type);
  }
}

final class UpdateAsset {
  final DistributionType type;
  final String downloadUrl;
  final String fileName;

  const UpdateAsset({
    required this.type,
    required this.downloadUrl,
    required this.fileName,
  });
}
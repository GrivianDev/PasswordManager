class VersionUtils {
  static int compare(String version, String otherVersion) {
    final List<int> aParts = _parse(version);
    final List<int> bParts = _parse(otherVersion);

    final int maxLength = aParts.length > bParts.length ? aParts.length : bParts.length;

    for (int i = 0; i < maxLength; i++) {
      final int aValue = i < aParts.length ? aParts[i] : 0;
      final int bValue = i < bParts.length ? bParts[i] : 0;

      if (aValue != bValue) {
        return aValue.compareTo(bValue);
      }
    }

    return 0;
  }

  static bool isGreater(String version, String otherVersion) => compare(version, otherVersion) > 0;

  static bool isLess(String version, String otherVersion) => compare(version, otherVersion) < 0;

  static bool isEqual(String version, String otherVersion) => compare(version, otherVersion) == 0;

  static List<int> _parse(String version) {
    return version.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }
}

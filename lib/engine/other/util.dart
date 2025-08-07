import 'dart:io';

/// Shortens a full file path to show only the last [parentsToShow] parent folders and the file.
/// The result is returned in the format: `.../parent1/.../filename`
///
/// [parentsToShow] defines how many parent segments to show before the file name.
///  - 0 shows only the file: `.../filename`
///  - 1 shows one parent:   `.../parent/filename`
///  - 2 shows two parents:  `.../grandparent/parent/filename`
///  - and so on...
///
/// Example:
///  - Input:  '/users/docs/reports/report.pdf', parentsToShow: 2
///  - Output: '.../docs/reports/report.pdf'
String shortenPath(String fullPath, {int parentsToShow = 1}) {
  final List<String> parts = fullPath.split(Platform.pathSeparator);

  if (parts.isEmpty) return fullPath;

  final int parentsStart = (parts.length - 1 - parentsToShow).clamp(0, parts.length - 1);
  final List<String> selectedParts = parts.sublist(parentsStart);
  return '...${Platform.pathSeparator}${selectedParts.join(Platform.pathSeparator)}';
}

/// Extracts the filename from a full file path (cross-platform).
String extractFilenameFromPath(String path) {
  final List<String> parts = path.split(Platform.pathSeparator);
  return parts.isEmpty ? '' : parts.last;
}

/// Extracts the basename (filename without extension).
/// If no dot exists, returns the full filename.
String getBasename(String filename) {
  final int dotIndex = filename.lastIndexOf('.');
  if (dotIndex <= 0) return filename; // Either no dot or dot is first char
  return filename.substring(0, dotIndex);
}

/// Checks if a filename contains only valid characters.
///
/// [name]: The filename to validate (without path).
/// [crossPlatformSafe]: If true, enforces rules that are safe across all platforms.
///                      If false, checks only against the current platform rules.
///
/// Returns true if the filename is valid, false otherwise.
bool isValidFilename(String name, {bool crossPlatformSafe = true}) {
  if (name.isEmpty || name == '.' || name == '..') return false;

  // Reserved Windows device names
  const Set<String> reservedNames = {
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
  };

  // Disallowed characters (Unicode control characters 0x00–0x1F)
  final RegExp controlChars = RegExp(r'[\x00-\x1F]');
  final RegExp invalidCharsWindows = RegExp(r'[<>:"/\\|?*]');
  final RegExp invalidCharsCrossPlatform = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
  final RegExp endsWithDotOrSpace = RegExp(r'[. ]$');

  final String baseName = getBasename(name);

  if (crossPlatformSafe) {
    // Cross-platform strict rules
    if (invalidCharsCrossPlatform.hasMatch(name)) return false;
    if (reservedNames.contains(baseName.toUpperCase())) return false;
    if (endsWithDotOrSpace.hasMatch(name)) return false;
    return true;
  }

  // Platform-specific rules
  if (Platform.isWindows) {
    if (invalidCharsWindows.hasMatch(name)) return false;
    if (controlChars.hasMatch(name)) return false;
    if (reservedNames.contains(baseName.toUpperCase())) return false;
    if (endsWithDotOrSpace.hasMatch(name)) return false;
  } else if (Platform.isMacOS || Platform.isIOS) {
    if (controlChars.hasMatch(name)) return false;
    if (name.contains(':')) return false;
  } else if (Platform.isLinux || Platform.isAndroid) {
    if (controlChars.hasMatch(name)) return false;
    if (name.contains('/')) return false;
  } else {
    // Unknown platform: default to cross-platform rules
    if (invalidCharsCrossPlatform.hasMatch(name)) return false;
    if (reservedNames.contains(baseName.toUpperCase())) return false;
    if (endsWithDotOrSpace.hasMatch(name)) return false;
  }

  return true;
}

/// This function uses a basic regular expression to verify that the input is a valid email address:
/// - Contains exactly one `@` character
/// - Has non-whitespace characters before and after the `@`
/// - Has at least one `.` in the domain part (after the `@`)
///
/// Note: This is a lightweight check and does not fully validate all RFC-compliant
/// email formats, but is sufficient for most practical use cases.
///
/// Returns `true` if the email matches the pattern, `false` otherwise.
bool isValidEmail(String email) {
  final RegExp simpleEmailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return simpleEmailRegex.hasMatch(email);
}

/// Returns a preview of the email in the following format: testing@example.com => t...g@example.com.
/// Returns null if input was not a valid email.
String? mailPreview(String email) {
  if (isValidEmail(email)) {
    String show = String.fromCharCode(email.codeUnitAt(0));
    show = '$show...';
    int remainsIndex = email.indexOf('@') - 1;
    if (remainsIndex < 0) return null;
    return '$show${email.substring(remainsIndex)}';
  }
  return null;
}
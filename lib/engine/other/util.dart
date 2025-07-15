import 'dart:io';

String shortenPath(String fullPath) {
  final segments = fullPath.split(Platform.pathSeparator);

  if (segments.length >= 2) {
    final parent = segments[segments.length - 2];
    final file = segments.last;
    return '...${Platform.pathSeparator}$parent${Platform.pathSeparator}$file';
  } else if (segments.length == 1) {
    return '...${Platform.pathSeparator}${segments.first}';
  } else {
    return fullPath;
  }
}

bool isValidEmail(String email) {
  final RegExp simpleEmailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return simpleEmailRegex.hasMatch(email);
}

/// Returns a preview of the email in the following format: testing@example.com => t...g@example.com, but only
/// if there was a valid email fomatting criteria.
String? mailPreview(String email) {
  if (email.contains('@') == true) {
    String show = String.fromCharCode(email.codeUnitAt(0));
    show = '$show...';
    int remainsIndex = email.indexOf('@') - 1;
    if (remainsIndex < 0) return null;
    return '$show${email.substring(remainsIndex)}';
  }
  return null;
}
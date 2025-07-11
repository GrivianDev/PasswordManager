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
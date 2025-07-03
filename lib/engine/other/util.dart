import 'dart:io';

String shortenPath(String fullPath) {
  final cleaned = fullPath.replaceAll('\\', '/'); // Normalize just in case
  final segments = cleaned.split('/');

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
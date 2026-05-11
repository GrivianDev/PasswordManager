import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

Future<File?> pickExternalFile({String? dialogTitle}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    // Clear up tmp files. This is nessecary cause android might cache file selections, if now the file
    // has been changed and reselected, then the cached unchanged variant will be used instead, which is not desired.
    await FilePicker.clearTemporaryFiles();
  }

  final FilePickerResult? result = await FilePicker.pickFiles(
    lockParentWindow: true,
    dialogTitle: dialogTitle,
    type: FileType.any,
    allowMultiple: false,
  );

  if (result == null) {
    return null;
  }

  final String? path = result.files.single.path;
  return path != null ? File(path) : null;
}

Future<String?> saveFileExternal({String? dialogTitle, required String filename, required String content}) async {
  final Directory tempDir = await getTemporaryDirectory();
  final File tempFile = File('${tempDir.path}${Platform.pathSeparator}$filename');

  await tempFile.writeAsString(content, encoding: utf8);

  if (Platform.isAndroid || Platform.isIOS) {
    return FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: tempFile.path,
        fileName: filename,
      ),
    );
  } else {
    final String? outputPath = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: filename,
      lockParentWindow: true,
    );

    if (outputPath != null) {
      await tempFile.copy(outputPath);
      return tempFile.path;
    }
  }
  return null;
}

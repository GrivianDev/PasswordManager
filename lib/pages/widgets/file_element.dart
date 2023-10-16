import 'dart:io';
import 'package:flutter/material.dart';

class FileWidget extends StatelessWidget {
  const FileWidget({Key? key, required this.file, required this.onClicked}) : super(key: key);

  final File file;
  final void Function(File) onClicked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 100,
      child: Expanded(
        child: ElevatedButton(
          onPressed: () => onClicked(file),

          child: Row(
            children: [
              const Icon(Icons.file_open),
              Text(
                file.path.split('/').last,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ],
          ),
        ),
      )
    );
  }
}

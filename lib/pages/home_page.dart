import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:passwordmanager/engine/encryption.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? crypt;
  final TextEditingController _pwInputController = TextEditingController();
  final TextEditingController _txtInputController = TextEditingController();

  void encrypt() {
    setState(() {
      Encryption.getAccountsFromString('string');
    });
  }

  void decrypt() {
    setState(() {
      crypt = Encryption.decrypt(_txtInputController.text, _pwInputController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineMedium
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 45.0),
              child: FloatingActionButton.extended(
                onPressed: encrypt,
                icon:  const Icon(
                  Icons.key,
                  size: 40,
                ),
                label: const Text(
                    'Encrypt',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 45.0),
              child: FloatingActionButton.extended(
                onPressed: decrypt,
                icon:  const Icon(
                  Icons.key_off,
                  size: 40,
                ),
                label: const Text(
                  'Decrypt',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0, left: 20.0, right: 20.0),
              child: TextField(
                maxLength: 32,
                controller: _pwInputController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 45.0, left: 20.0, right: 20.0),
              child: TextField(
                controller: _txtInputController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Input',
                ),
              ),
            ),
            SelectableText(
              crypt ?? 'No text',
            )
          ],
        ),
      ),
    );
  }
}
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:passwordmanager/engine/encryption.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/themes.dart';
import 'package:passwordmanager/pages/widgets/list_element.dart';
import 'package:provider/provider.dart';

import '../engine/account.dart';
import '../engine/manager.dart';
import '../engine/persistance.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Manager _manager = Manager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Switch.adaptive(
              value: Settings.isLightMode(),
              onChanged: (value) {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
              },
            ),
          )
        ],
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(widget.title,
            style: Theme.of(context).textTheme.headlineLarge),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
              color: Theme.of(context).colorScheme.background,
            ),
            child: ListView.builder(
              itemCount: _manager.accountCount(),
              itemBuilder: (context, index) {
                return ListElement(
                  account: _manager.getAccountAt(index) ?? Account(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

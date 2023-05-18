import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:passwordmanager/engine/encryption.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/themes.dart';
import 'package:passwordmanager/pages/widgets/list_element.dart';
import 'package:passwordmanager/pages/widgets/navbar.dart';
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
      endDrawer: NavBar(),
      appBar: AppBar(
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ),
        ],
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(widget.title,
            style: Theme.of(context).textTheme.headlineLarge),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {},
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.background,
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(
                  left: 10.0, right: 10.0, top: 20.0, bottom: 10.0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                  ),
                  hintText: 'Search',
                ),
              ),
            ),
            Expanded(
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
      ),
    );
  }
}

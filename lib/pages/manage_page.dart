import 'package:flutter/material.dart';

import 'package:passwordmanager/pages/widgets/list_element.dart';
import 'package:passwordmanager/pages/widgets/navbar.dart';
import 'package:passwordmanager/engine/local_database.dart';

import 'editing_page.dart';

class ManagePage extends StatefulWidget {
  const ManagePage({super.key, required this.title});

  final String title;

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  final LocalDataBase _database = LocalDataBase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: NavBar(),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: Scaffold.of(context).openEndDrawer,
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditingPage(
              title: 'Create account',
            ),
          ),
        ),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 85.0),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 10.0),
                                child: Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: ListView.builder(
                  itemCount: _database.accounts.length,
                  itemBuilder: (context, index) => ListElement(
                    account: _database.accounts.elementAt(index),
                    parent: this,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

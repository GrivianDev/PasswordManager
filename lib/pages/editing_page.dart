import 'package:flutter/material.dart';

import 'package:passwordmanager/engine/implementation/account.dart';

class EditingPage extends StatefulWidget {
  const EditingPage({Key? key, required this.title, Account? account}) : _account = account, super(key: key);

  final String title;
  final Account? _account;

  @override
  State<EditingPage> createState() => _EditingPageState();
}

class _EditingPageState extends State<EditingPage> {
  Account? _account;
  late bool changes;
  late TextEditingController _nameController;
  late TextEditingController _tagController;
  late TextEditingController _infoController;
  late TextEditingController _emailController;
  late TextEditingController _pwController;

  void confirmChanges() {

  }

  @override
  void initState() {
    _account = widget._account;
    changes = false;
    _nameController = TextEditingController(text: _account != null ? _account?.name : '');
    _tagController = TextEditingController(text: _account != null ? _account?.tag : '');
    _infoController = TextEditingController(text: _account != null ? _account?.info : '');
    _emailController = TextEditingController(text: _account != null ? _account?.email : '');
    _pwController = TextEditingController(text: _account != null ? _account?.password : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _infoController.dispose();
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(widget.title),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.background,
        ),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              onChanged: (string) => setState(() {
                changes = true;
              }),
            ),
            const SizedBox(height: 25,),
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Tag',
              ),
              onChanged: (string) => setState(() {
                changes = true;
              }),
            ),
            const SizedBox(height: 25,),
            TextField(
              controller: _infoController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Info',
              ),
              onChanged: (string) => setState(() {
                changes = true;
              }),
            ),
            const SizedBox(height: 25,),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              onChanged: (string) => setState(() {
                changes = true;
              }),
            ),
            const SizedBox(height: 25,),
            TextField(
              controller: _pwController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              onChanged: (string) => setState(() {
                changes = true;
              }),
            ),
            const SizedBox(height: 25,),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<
                        RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(changes ? Theme.of(context).colorScheme.primary : Colors.blueGrey),
                  ),
                  onPressed: changes ? confirmChanges : null,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 5.0),
                    child: Icon(
                      Icons.check,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
              ),
            )
          ],
        ),
      ),
    );
  }
}

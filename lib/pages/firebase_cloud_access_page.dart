import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/api/firebase/firebase.dart';
import 'package:passwordmanager/engine/selection_result.dart';
import 'package:passwordmanager/pages/widgets/cloud_document.dart';
import 'other/notifications.dart';

class FirebaseCloudAccessPage extends StatefulWidget {
  const FirebaseCloudAccessPage({super.key});

  @override
  State<FirebaseCloudAccessPage> createState() => _FirebaseCloudAccessPageState();
}

class _FirebaseCloudAccessPageState extends State<FirebaseCloudAccessPage> {
  late Future<List<CloudDocument>> _listDocuments;

  Future<List<CloudDocument>> _getListDocumentsFuture() async {
    final List<Map<String, dynamic>> documents = await Firestore.instance.getCollection(
        Firestore.instance.userVaultPath,
        fieldMask: ['name']
    );

    final List<CloudDocument> docWidgets = [];
    for (final Map<String, dynamic> doc in documents) {
      final String documentId = doc['name'].split('/').last;
      final String documentName = doc['fields']?['name']?['stringValue'] ?? '<no-name>';
      docWidgets.add(CloudDocument(
          documentId: documentId,
          documentName: documentName,
          onClicked: (value) {
            Navigator.pop(context, FirestoreSelectionResult(documentId, documentName, false));
          },
          afterDelete: () => setState(() {
            _listDocuments = _getListDocumentsFuture();
          })
      ));
    }
    return docWidgets;
  }

  Future<void> _createNew() async {
    String? storageName;
    String currentInput = '';

    await Notify.dialog(
      context: context,
      type: NotificationType.confirmDialog,
      title: 'Name your new storage',
      content: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'What name do you want for your storage?',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: TextField(
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        currentInput = value.trim();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Name',
                      constraints: const BoxConstraints(maxWidth: 100, maxHeight: 80.0),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      onConfirm: () {
        if (currentInput.isNotEmpty) {
          storageName = currentInput;
          Navigator.pop(context);
        }
      },
    );

    if (storageName != null) {
      Navigator.pop(context, FirestoreSelectionResult('', storageName!, true));
    }
  }

  @override
  void initState() {
    super.initState();
    _listDocuments = _getListDocumentsFuture();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select cloud document',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              onPressed: () async {
                await Firestore.instance.auth.logout();
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.logout,
                color: Colors.red,
              ),
              tooltip: 'Logout',
            ),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              FutureBuilder<List<CloudDocument>>(
                future: _listDocuments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            'Error while loading documents: ${snapshot.error.toString()}',
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                              overflow: Theme.of(context).textTheme.bodyMedium?.overflow,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      );
                    } else {
                      if (snapshot.hasData && snapshot.data!.length > 0) {
                        return Expanded(
                          child: ListView.separated(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) => snapshot.data![index],
                            separatorBuilder: (context, index) => const SizedBox(height: 15.0),
                          ),
                        );
                      } else {
                        return Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  size: 50.0,
                                ),
                                Text(
                                  'Seems like there are no documents yet...',
                                  style: TextStyle(color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    return const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
              SizedBox(
                height: 60.0,
                width: MediaQuery.of(context).size.width,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: _createNew,
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text('Create new'),
                    ),
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

import 'package:flutter/material.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/api/firebase/firebase.dart';
import 'package:passwordmanager/engine/selection_result.dart';
import 'package:passwordmanager/pages/flows/user_input_dialog.dart';
import 'package:passwordmanager/pages/widgets/firestore_document_widget.dart';

class FirebaseCloudAccessPage extends StatefulWidget {
  const FirebaseCloudAccessPage({super.key});

  @override
  State<FirebaseCloudAccessPage> createState() => _FirebaseCloudAccessPageState();
}

class _FirebaseCloudAccessPageState extends State<FirebaseCloudAccessPage> {
  late Future<List<FirestoreDocumentWidget>> _listDocuments;

  Future<List<FirestoreDocumentWidget>> _getListDocumentsFuture() async {
    final Firestore firestoreService = context.read();
    final List<Map<String, dynamic>> documents = await firestoreService.getCollection(
        firestoreService.userVaultPath,
        fieldMask: ['name']
    );

    final List<FirestoreDocumentWidget> docWidgets = [];
    for (final Map<String, dynamic> doc in documents) {
      final String documentId = doc['name'].split('/').last;
      final String documentName = doc['fields']?['name']?['stringValue'] ?? '<no-name>';
      docWidgets.add(FirestoreDocumentWidget(
          documentId: documentId,
          documentName: documentName,
          onClicked: () {
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
    final NavigatorState navigator = Navigator.of(context);

    final String? storageName = await getUserInputDialog(
      context: context,
      title: 'Name your new storage',
      labelText: 'Name',
      description: 'What name do you want for your storage?',
      validator: (value) {
        if (!isValidFilename(value)) {
          return 'Discouraged storage name!';
        }
        return null;
      }
    );

    if (storageName == null || storageName.isEmpty) return;

    navigator.pop(FirestoreSelectionResult('', storageName, true));
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
        title: Text('Select cloud document'),
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
              FutureBuilder<List<FirestoreDocumentWidget>>(
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
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
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
                                  textAlign: TextAlign.center,
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
                      child: Text(
                        'Create new',
                        style: TextStyle(fontSize: 20),
                      ),
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

import 'package:ethercrypt/engine/api/firebase/firestore.dart';
import 'package:ethercrypt/engine/api/firebase/firestore_query.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';

class FirestoreRepository implements StorageRepository {
  final Firestore firestore;

  FirestoreRepository(this.firestore);

  String _fullyQualifiedPath(StorageFile file) => '${file.location}/${file.id}';

  @override
  Future<List<StorageFile>> findAll({String? location}) async {
    final String actualLocation = location ?? '';
    final List<FirestoreDocument>? docs = await firestore.getCollection(
      actualLocation,
      fieldMask: ['name'],
    );
    return docs?.map((doc) {
          final String documentId = doc.name.split('/').last;
          final String documentName = doc.fields['name'] ?? '<no-name>';
          return StorageFile(
            id: documentId,
            location: actualLocation,
            name: documentName,
            type: StorageType.CloudFirestore,
            lastModified: doc.updateTime,
          );
        }).toList() ??
        [];
  }

  @override
  Future<StorageFile> create({required String name, String? location, String? initialData}) async {
    final FirestoreDocument newDoc = await firestore.createDocument(
      location!,
      {
        'name': name,
        'data': initialData ?? '',
      },
    );
    final String documentId = newDoc.name.split('/').last;
    return StorageFile(
      id: documentId,
      location: location,
      name: name,
      type: StorageType.CloudFirestore,
      byteSize: initialData?.length,
      lastModified: newDoc.createTime,
    );
  }

  @override
  Future<bool> exists(StorageFile file) async {
    final FirestoreDocument? doc = await firestore.getDocument(_fullyQualifiedPath(file), fieldMask: []);
    return doc != null;
  }

  @override
  Future<bool> nameExists({required String name, String? location}) async {
    final FirestoreQuery query = FirestoreQuery(location ?? '/').select(List.empty()).whereEqualTo('name', name);
    final List<FirestoreDocument> matches = await firestore.query(query);
    return matches.isNotEmpty;
  }

  @override
  Future<StorageFile> rename(StorageFile file, String newName) async {
    final FirestoreDocument updatedDoc = await firestore.updateDocument(
      _fullyQualifiedPath(file),
      {'name': newName},
    );
    return StorageFile(
      id: file.id,
      location: file.location,
      name: newName,
      type: StorageType.CloudFirestore,
      byteSize: file.byteSize,
      lastModified: updatedDoc.updateTime,
    );
  }

  @override
  Future<String> read(StorageFile file) async {
    final FirestoreDocument? doc = await firestore.getDocument(
      _fullyQualifiedPath(file),
      fieldMask: ['data'],
    );
    return doc!.fields['data'] as String;
  }

  @override
  Future<StorageFile> update(StorageFile file, String data) async {
    final FirestoreDocument updatedDoc = await firestore.updateDocument(
      _fullyQualifiedPath(file),
      {'data': data},
    );
    return StorageFile(
      id: file.id,
      location: file.location,
      name: file.name,
      type: StorageType.CloudFirestore,
      byteSize: data.length,
      lastModified: updatedDoc.updateTime,
    );
  }

  @override
  Future<void> delete(StorageFile file) => firestore.deleteDocument(_fullyQualifiedPath(file));
}

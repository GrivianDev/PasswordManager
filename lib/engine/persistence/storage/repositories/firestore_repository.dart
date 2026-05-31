import 'package:ethercrypt/engine/api/firebase/firestore.dart';
import 'package:ethercrypt/engine/api/firebase/firestore_query.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_conflict_exception.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_repository.dart';

class FirestoreRepository implements StorageRepository {
  final Firestore firestore;

  FirestoreRepository(this.firestore);

  String _fullyQualifiedPath(StorageFile file) => '${file.location}/${file.id}';

  StorageFile _fromDoc(FirestoreDocument doc, String location) {
    final String documentId = doc.name.split('/').last;
    final String documentName = doc.fields['name'] ?? '<no-name>';
    final int? size = doc.fields['size'];

    return StorageFile(
      id: documentId,
      location: location,
      name: documentName,
      type: StorageType.CloudFirestore,
      revision: doc.updateTime.toUtc().toIso8601String(),
      byteSize: size,
      lastModified: doc.updateTime,
    );
  }

  @override
  Future<List<StorageFile>> findAll({String? location}) async {
    final String actualLocation = location ?? '';
    final List<FirestoreDocument>? docs = await firestore.getCollection(
      actualLocation,
      fieldMask: ['name', 'size'],
    );
    return docs?.map((doc) => _fromDoc(doc, actualLocation)).toList() ?? [];
  }

  @override
  Future<StorageFile> create({required String name, String? location, String? initialData}) async {
    final FirestoreDocument newDoc = await firestore.createDocument(
      location!,
      {
        'name': name,
        'size': initialData?.length ?? 0,
        'data': initialData ?? '',
      },
    );
    return _fromDoc(newDoc, location);
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
    try {
      final FirestoreDocument updatedDoc = await firestore.writeDocument(
        _fullyQualifiedPath(file),
        {'name': newName},
        updateMask: ['name'],
        precondition: FirestorePrecondition.updateTime(DateTime.parse(file.revision)),
      );
      return _fromDoc(updatedDoc, file.location);
    } on FirestoreApiException catch (e) {
      if (e.status == 'FAILED_PRECONDITION') throw const StorageConflictException();
      rethrow;
    }
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
    try {
      final FirestoreDocument updatedDoc = await firestore.writeDocument(
        _fullyQualifiedPath(file),
        {'size': data.length, 'data': data},
        updateMask: ['size', 'data'],
        precondition: FirestorePrecondition.updateTime(DateTime.parse(file.revision)),
      );
      return _fromDoc(updatedDoc, file.location);
    } on FirestoreApiException catch (e) {
      if (e.status == 'FAILED_PRECONDITION') throw const StorageConflictException();
      rethrow;
    }
  }

  @override
  Future<void> delete(StorageFile file) => firestore.deleteDocument(_fullyQualifiedPath(file));
}

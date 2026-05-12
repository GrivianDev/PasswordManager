import 'package:ethercrypt/engine/api/firebase/firestore_codec.dart';

class FirestoreQuery {
  final String collectionPath;

  final String? collectionParentPath;
  final String collectionId;

  final List<String> _select = [];
  final List<Map<String, dynamic>> _filters = [];

  FirestoreQuery(this.collectionPath)
      : collectionParentPath = _extractParentPath(collectionPath),
        collectionId = _extractCollectionId(collectionPath);

  static String _extractCollectionId(String path) {
    final List<String> segments = path.split('/');
    if (segments.isEmpty) throw ArgumentError('Invalid collection path');

    return segments.last;
  }

  static String? _extractParentPath(String path) {
    final List<String> segments = path.split('/');
    if (segments.length <= 1) return null;

    return segments.sublist(0, segments.length - 1).join('/');
  }

  FirestoreQuery select(List<String> fields) {
    _select.clear();
    _select.addAll(fields.isNotEmpty ? fields : ['__name__']);
    return this;
  }

  FirestoreQuery whereEqualTo(
    String field,
    dynamic value,
  ) {
    _filters.add({
      'fieldFilter': {
        'field': {
          'fieldPath': field,
        },
        'op': 'EQUAL',
        'value': FirestoreCodec.encodeValue(value),
      }
    });

    return this;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> structuredQuery = {
      'from': [
        {'collectionId': collectionId}
      ],
    };

    if (_filters.isNotEmpty) {
      structuredQuery['where'] = _filters.length == 1
          ? _filters.first
          : {
              'compositeFilter': {
                'op': 'AND',
                'filters': _filters,
              }
            };
    }

    if (_select.isNotEmpty) {
      structuredQuery['select'] = {
        'fields': _select.map((field) => {'fieldPath': field}).toList(),
      };
    }

    return {
      'structuredQuery': structuredQuery,
    };
  }
}

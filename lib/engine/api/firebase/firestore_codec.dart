final class FirestoreCodec {
  static const String docName = 'name';
  static const String docCreateTime = 'createTime';
  static const String docUpdateTime = 'updateTime';

  static const String nullValue = 'nullValue';
  static const String stringValue = 'stringValue';
  static const String booleanValue = 'booleanValue';
  static const String integerValue = 'integerValue';
  static const String doubleValue = 'doubleValue';
  static const String timestampValue = 'timestampValue';
  static const String mapValue = 'mapValue';
  static const String arrayValue = 'arrayValue';

  static const String fields = 'fields';
  static const String values = 'values';

  static Map<String, dynamic> encodeDocumentFields(Map<String, dynamic> docFields) {
    return docFields.map((key, value) => MapEntry(key, encodeValue(value)));
  }

  static Map<String, dynamic> decodeDocumentFields(Map<String, dynamic> docFields) {
    return docFields.map((key, value) =>  MapEntry(key, decodeValue(value)));
  }

  // Firestores field format
  static Map<String, dynamic> encodeValue(dynamic value) {
    if (value == null) return {nullValue: null};
    if (value is String) return {stringValue: value};
    if (value is bool) return {booleanValue: value};
    if (value is int) return {integerValue: value.toString()};
    if (value is double) return {doubleValue: value};
    if (value is DateTime) return {timestampValue: value.toUtc().toIso8601String()};
    if (value is Map) {
      return {
        mapValue: {fields: value.map((key, value) => MapEntry(key, encodeValue(value)))}
      };
    }
    if (value is List) {
      return {
        arrayValue: {values: value.map(encodeValue).toList()}
      };
    }
    throw Exception('Unsupported Firestore type: ${value.runtimeType}');
  }

  static dynamic decodeValue(Map<String, dynamic> value) {
    if (value.containsKey(nullValue)) return null;
    if (value.containsKey(stringValue)) return value[stringValue] as String;
    if (value.containsKey(booleanValue)) return value[booleanValue] as bool;
    if (value.containsKey(integerValue)) return int.parse(value[integerValue]);
    if (value.containsKey(doubleValue)) return (value[doubleValue] as num).toDouble();
    if (value.containsKey(timestampValue)) return DateTime.parse(value[timestampValue]);
    if (value.containsKey(mapValue)) {
      final f = value[mapValue][fields] as Map<String, dynamic>?;
      if (f == null) return <String, dynamic>{};
      return f.map((key, value) => MapEntry(key, decodeValue(value)));
    }
    if (value.containsKey(arrayValue)) {
      final a = value[arrayValue][values] as List?;
      if (a == null) return <dynamic>[];
      return a.map((e) => decodeValue(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Unknown Firestore value type: $value');
  }
}

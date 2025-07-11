import 'package:passwordmanager/engine/db/accessors/version/accessor_v0.dart';
import 'package:passwordmanager/engine/db/accessors/version/accessor_v1.dart';
import 'package:passwordmanager/engine/db/accessors/accessor.dart';

class DataAccessorRegistry {
  static const String latestVersion = 'v1';

  static final Map<String, DataAccessor Function()> factories = {
    'v0': () => DataAccessorV0(),
    'v1': () => DataAccessorV1(),
  };

  static DataAccessor create(String version) {
    final factory = factories[version];
    if (factory == null) throw Exception("Unknown or unsupported accessor version: $version");
    return factory();
  }
}

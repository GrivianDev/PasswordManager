import 'package:ethercrypt/engine/db/accessors/version/accessor_v0.dart';
import 'package:ethercrypt/engine/db/accessors/version/accessor_v1.dart';
import 'package:ethercrypt/engine/db/accessors/accessor.dart';

/// Registry for getting different versions of [DataAccessor] implementations.
class DataAccessorRegistry {
  static const String latestVersion = 'v1';

  static final Map<String, DataAccessor Function()> _factories = {
    'v0': () => DataAccessorV0(),
    'v1': () => DataAccessorV1(),
  };

  /// Creates a [DataAccessor] instance matching the specified [version].
  static DataAccessor create(String version) {
    final factory = _factories[version];
    if (factory == null) throw Exception('Unknown or unsupported accessor version: $version');
    return factory();
  }
}

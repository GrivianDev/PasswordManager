import 'package:passwordmanager/engine/db/database_content.dart';

/// Abstract base class defining the interface for data access and encryption.
///
/// Implementations must provide methods to:
/// - get the data format/version
/// - define the encryption password
/// - load and decrypt data
/// - encrypt and format data
abstract class DataAccessor {
  /// Returns the data format version string used by this accessor.
  String get version;

  /// Sets the password to use for encryption and decryption.
  ///
  /// This must be called before any load or encrypt operations.
  void setPassword(String password);

  /// Loads encrypted data from map, decrypts it.
  Future<DatabaseContent> unpack(Map<String, String> properties);

  /// Encrypts data and returns it including metadata.
  Future<Map<String, String>> pack(DatabaseContent dbContent);
}

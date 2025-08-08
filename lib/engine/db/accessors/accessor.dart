
import 'package:passwordmanager/engine/db/local_database.dart';

/// Abstract base class defining the interface for data access and encryption.
///
/// Used by the [Source] class to handle encrypted data storage and retrieval.
///
/// Implementations must provide methods to:
/// - get the data format/version,
/// - define the encryption password,
/// - load and decrypt data into a target database,
/// - encrypt and format data from a source database.
abstract class DataAccessor {
  /// Returns the data format version string used by this accessor.
  String get version;

  /// Sets the password to use for encryption and decryption.
  ///
  /// This must be called before any load or encrypt operations.
  void definePassword(String password);

  /// Loads encrypted data from [properties], decrypts it,
  /// and populates [targetDatabase] with the decrypted content.
  ///
  /// Throws on failure or invalid password.
  Future<void> loadAndDecrypt(LocalDatabase targetDatabase, Map<String, String> properties);

  /// Encrypts data from [sourceDatabase] and returns it as a formatted string.
  ///
  /// The format is determined by the implementation and includes metadata if needed.
  Future<String> encryptAndFormat(LocalDatabase sourceDatabase);
}
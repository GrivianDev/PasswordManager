abstract class PersistenceConnector {
  String get name;

  /// Returns true if the connector is ready to be used (e.g., file exists, user is logged in)
  Future<bool> get isAvailable;

  /// Loads the formatted, encrypted data string from the source
  Future<String> load();

  /// Saves a new version of the formatted, encrypted data string
  Future<void> save(String formattedData);

  /// Creates a new document or file with the given content (may be the same as save)
  Future<void> create(String formattedData);

  /// Optionally invalidates the session or state (e.g., logout, cache clear)
  Future<void> delete();
}
// Class for constants and things pulled from environment
final class AppConfig {
  static const googleDriveClientId = String.fromEnvironment('GOOGLE_DRIVE_CLIENT_ID');
  static const googleDriveClientSecret = String.fromEnvironment('GOOGLE_DRIVE_CLIENT_SECRET');
  
  static const dropboxAppKey = String.fromEnvironment('DROPBOX_APP_KEY');
}
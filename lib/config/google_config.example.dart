/// TEMPLATE — copy to google_config.dart and fill in your values.
///
/// This file IS committed to git (it contains no secrets).
/// google_config.dart is in .gitignore and must NOT be committed.
///
/// Setup steps:
/// 1. Create a Google Cloud project at https://console.cloud.google.com
/// 2. Enable the Google Drive API.
/// 3. Create OAuth 2.0 credentials:
///      Android : "Android" client → supply your SHA-1 fingerprint and package name
///      iOS     : "iOS" client → supply your bundle ID
///      Windows : "Desktop app" client → download the JSON; read client_id from it
/// 4. Copy this file to lib/config/google_config.dart and fill in the values below.
///
/// Android SHA-1 (debug):
///   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
///           -storepass android -keypass android
///
/// Required scopes: https://www.googleapis.com/auth/drive.file
/// (drive.file scope only accesses files created by this app — minimal footprint)

// ignore_for_file: constant_identifier_names

library;

/// Google OAuth client IDs.
/// Leave a field empty ('') for platforms you do not support.
abstract final class GoogleConfig {
  /// Android OAuth client ID (from google-services.json → oauth_client[0].client_id)
  static const String androidClientId = 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';

  /// iOS OAuth client ID (from GoogleService-Info.plist → CLIENT_ID)
  static const String iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  /// Windows / desktop OAuth client ID (from the downloaded JSON file).
  /// On Windows the user must paste their own Client ID in Settings if this is empty.
  static const String windowsClientId = '';

  /// Required Drive scope — do NOT change to a broader scope.
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/drive.file',
  ];
}

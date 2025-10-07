// lib/app_keys.dart
class AppKeys {
  // Stream API key for tutorial mode (public). You can also pass via --dart-define.
  static const String streamApiKey = String.fromEnvironment(
    'r9mn4fsbzhub',
    defaultValue: 'r9mn4fsbzhub',
  );
  // Replace with your APN provider name from Stream Dashboard
  static const String iosPushProviderName = 'niwner_notification';

  // Replace with your FCM provider name from Stream Dashboard
  static const String androidPushProviderName = 'niwner_notification';

  // Backend base URL for token endpoint
  // Note: On Android emulator, 'localhost' should be '10.0.2.2'.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8181',
  );

  // Dev-only: Backend Bearer token for calling the token endpoint (if required)
  // Leave empty if your backend endpoint doesn't require Authorization in dev.
  static const String backendBearerToken = String.fromEnvironment(
    'BACKEND_BEARER_TOKEN',
    defaultValue: '',
  );
}

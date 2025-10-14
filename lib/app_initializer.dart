// lib/app_initializer.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';

import 'app_keys.dart';
import 'tutorial_user.dart';
import 'firebase_options.dart';
import 'services/token_service.dart';
import 'dev_manual_auth.dart';

class AppInitializer {
  static const _storedUserKey = 'loggedInUserId';

  /// Get the stored user from secure storage
  static Future<TutorialUser?> getStoredUser() async {
    const storage = FlutterSecureStorage();
    final userId = await storage.read(key: _storedUserKey);
    
    if (userId == null) {
      return null;
    }

    try {
      return TutorialUser.users.firstWhere(
        (user) => user.user.id == userId,
      );
    } catch (e) {
      // User not found in hardcoded list
      return null;
    }
  }

  /// Store user ID in secure storage
  static Future<void> storeUser(TutorialUser tutorialUser) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _storedUserKey, value: tutorialUser.user.id);
  }

  static Future<void> storeUserId(String userId) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _storedUserKey, value: userId);
  }

  /// Clear stored user data
  static Future<void> clearStoredUser() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: _storedUserKey);
  }

  /// Initialize StreamVideo + Firebase (for push). Pull userId/name/token from backend.
  static Future<StreamVideo> init(TutorialUser tutorialUser) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Dev manual override
    if (ManualAuth.enabled) {
      final m = ManualAuth.current();
      final manualUser = User.regular(
        userId: m.userId,
        name: m.name,
      );
      await storeUserId(m.userId);
      return createClient(
        user: manualUser,
        apiKey: m.apiKey,
        userToken: m.token,
        attachPushManager: false,
      );
    }

    // Tutorial tokens flow (use tokens from tutorial_user.dart if provided)
    if ((tutorialUser.token ?? '').isNotEmpty) {
      final apiKey = AppKeys.streamApiKey;
      if (apiKey.isEmpty) {
        throw Exception('STREAM_API_KEY is empty. Set AppKeys.streamApiKey or pass --dart-define=STREAM_API_KEY=...');
      }
      await storeUserId(tutorialUser.user.id);
      return createClient(
        user: tutorialUser.user,
        apiKey: apiKey,
        userToken: tutorialUser.token!,
      );
    }

    // Backend flow
    const storage = FlutterSecureStorage();
    final appAccessToken = await storage.read(key: 'app_access_token');
    final auth = await TokenService.fetchStreamAuth(accessToken: appAccessToken);

    final userForToken = User.regular(
      userId: auth.userId,
      name: auth.fullName ?? tutorialUser.user.name,
      image: tutorialUser.user.image,
    );
    await storeUserId(auth.userId);
    return createClient(user: userForToken, apiKey: auth.apiKey, userToken: auth.token);
  }

  /// Create a configured StreamVideo client for the provided user.
  static StreamVideo createClient({
    required User user,
    required String apiKey,
    required String userToken,
    bool attachPushManager = true,
  }) {
    return StreamVideo(
      apiKey,
      user: user,
      userToken: userToken,
      options: const StreamVideoOptions(
        keepConnectionsAliveWhenInBackground: true,
      ),
      pushNotificationManagerProvider: attachPushManager
          ? StreamVideoPushNotificationManager.create(
              iosPushProvider: const StreamVideoPushProvider.apn(
                name: AppKeys.iosPushProviderName,
              ),
              androidPushProvider: const StreamVideoPushProvider.firebase(
                name: AppKeys.androidPushProviderName,
              ),
              pushParams: const StreamVideoPushParams(
                appName: 'Stream Video Call',
                ios: IOSParams(iconName: 'IconMask'),
              ),
              registerApnDeviceToken: true,
            )
          : null,
    )..connect();
  }
}

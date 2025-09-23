// lib/firebase_background_handler.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';

import 'app_initializer.dart';
import 'app_keys.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
  }

  try {
    final tutorialUser = await AppInitializer.getStoredUser();
    if (tutorialUser == null) {
      if (kDebugMode) {
        print('No stored user found for background message');
      }
      return;
    }

    final streamVideo = StreamVideo(
      AppKeys.streamApiKey,
      user: tutorialUser.user,
      userToken: tutorialUser.token ?? '',
      options: const StreamVideoOptions(
        keepConnectionsAliveWhenInBackground: true,
      ),
      pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
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
      ),
    )..connect();

    final declineSubscription = streamVideo.observeCallDeclinedCallKitEvent();
    streamVideo.disposeAfterResolvingRinging(
      disposingCallback: () => declineSubscription?.cancel(),
    );

    await StreamVideo.instance.handleRingingFlowNotifications(message.data);
  } catch (e, stack) {
    if (kDebugMode) {
      print('Error handling background message: $e');
      print('Stack trace: $stack');
    }
  }
}

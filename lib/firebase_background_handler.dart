import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'app_initializer.dart';
import 'firebase_options.dart';
import 'services/token_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
  }

  try {
    // Production: fetch a fresh Stream user token from backend and build user from it.
    final auth = await TokenService.fetchStreamAuth();

    final user = User.regular(
      userId: auth.userId,
      name: auth.fullName ?? auth.userId,
    );

    final client = AppInitializer.createClient(
      user: user,
      apiKey: auth.apiKey,
      userToken: auth.token,
    );

    // Ensure cleanup after resolving ringing flow
    final declineSub = client.observeCallDeclinedCallKitEvent();
    client.disposeAfterResolvingRinging(
      disposingCallback: () => declineSub?.cancel(),
    );

    await StreamVideo.instance.handleRingingFlowNotifications(message.data);
  } catch (e, st) {
    if (kDebugMode) {
      print('Background handler error: $e');
      print(st);
    }
  }
}

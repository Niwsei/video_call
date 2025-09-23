// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'app.dart';
import 'app_initializer.dart';
import 'firebase_background_handler.dart';
import 'tutorial_user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final currentUser = TutorialUser.user3();
  final StreamVideo client = await AppInitializer.init(currentUser);
  await AppInitializer.storeUser(currentUser);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(MyApp(client: client));
}

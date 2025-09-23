// lib/app.dart
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'home_page.dart';

class MyApp extends StatelessWidget {
  final StreamVideo client;

  const MyApp({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stream Video Call',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomePage(client: client),
    );
  }
}

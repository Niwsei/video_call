# Stream Video Project Setup Guide

This project ships with placeholder credentials so the demo can compile. Replace them with real values before shipping or testing in production.

## Stream Video API
- Update `lib/app_keys.dart:4` with the real Stream API key from the Stream dashboard.
- Reuse the same key everywhere: update `_firebaseMessagingBackgroundHandler` in `lib/home_page.dart:911` and reference the key via `AppKeys.streamApiKey` in `lib/main.dart` instead of hard-coding it.

## Push Notification Providers
- Stream push requires provider names that match your dashboard configuration.
- Replace `AppKeys.iosPushProviderName` and `AppKeys.androidPushProviderName` in `lib/app_keys.dart:7` and `:10` with the provider IDs you created on Stream.

## Firebase Configuration
- Run `flutterfire configure` or copy real Firebase configs into `lib/firebase_options.dart`.
- Ensure the generated `google-services.json` is placed in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
- For web builds, add a `firebase-messaging-sw.js` service worker and set the VAPID key if you enable browser push.

## User Tokens
- Tokens in `lib/tutorial_user.dart` and `lib/constants.dart` are sample JWTs and will expire quickly.
- Implement a secure backend endpoint (or Cloud Function) that calls Stream's server SDK to mint user tokens on demand.
- Update the app to fetch tokens from that backend instead of storing them in source control.

## Background Handling
- Complete the TODO section in `lib/firebase_background_handler.dart:17` with logic to call `StreamVideo.instance.handleRingingFlowNotifications(message.data)` after initializing Firebase.
- Mirror the same configuration inside `_firebaseMessagingBackgroundHandler` in `lib/home_page.dart:904` and ensure it uses the real Stream API key and provider names.

## Platform Checks
- Android: verify required permissions remain in `android/app/src/main/AndroidManifest.xml` and that `build.gradle.kts` has the correct applicationId.
- iOS: update bundle identifier, enable Push Notifications, Background Modes, and upload the APNs authentication key/certificate in Stream dashboard.

## Final Verification
1. Run `flutter pub get`.
2. Build and run on a physical device (Android/iOS) to test ringing, notifications, and call flow end-to-end.

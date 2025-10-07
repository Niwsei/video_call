// สคริปต์ตรวจสอบว่าไฟล์ Firebase config ตรงกันหรือไม่
// Run: dart check_firebase_config.dart

import 'dart:io';
import 'dart:convert';

void main() {
  print('========================================');
  print('🔍 CHECKING FIREBASE CONFIGURATION');
  print('========================================\n');

  // อ่าน firebase_options.dart
  final optionsFile = File('lib/firebase_options.dart');
  if (!optionsFile.existsSync()) {
    print('❌ firebase_options.dart not found!');
    return;
  }

  final optionsContent = optionsFile.readAsStringSync();

  // Extract projectId from firebase_options.dart
  final projectIdMatch = RegExp(r"projectId:\s*'([^']+)'").firstMatch(optionsContent);
  final messagingSenderIdMatch = RegExp(r"messagingSenderId:\s*'([^']+)'").firstMatch(optionsContent);

  if (projectIdMatch == null || messagingSenderIdMatch == null) {
    print('❌ Could not extract project info from firebase_options.dart');
    return;
  }

  final expectedProjectId = projectIdMatch.group(1)!;
  final expectedMessagingSenderId = messagingSenderIdMatch.group(1)!;

  print('📋 Expected Configuration (from firebase_options.dart):');
  print('   Project ID: $expectedProjectId');
  print('   Messaging Sender ID: $expectedMessagingSenderId\n');

  // ตรวจสอบ Android
  print('📱 Checking Android (google-services.json):');
  final androidFile = File('android/app/google-services.json');

  if (!androidFile.existsSync()) {
    print('   ❌ File not found!\n');
  } else {
    try {
      final androidContent = jsonDecode(androidFile.readAsStringSync());
      final androidProjectId = androidContent['project_info']['project_id'];
      final androidProjectNumber = androidContent['project_info']['project_number'];

      print('   Project ID: $androidProjectId');
      print('   Project Number: $androidProjectNumber');

      if (androidProjectId == expectedProjectId &&
          androidProjectNumber == expectedMessagingSenderId) {
        print('   ✅ Android configuration is CORRECT!\n');
      } else {
        print('   ❌ Android configuration MISMATCH!');
        print('   Expected Project ID: $expectedProjectId');
        print('   Expected Project Number: $expectedMessagingSenderId\n');
      }
    } catch (e) {
      print('   ❌ Error reading file: $e\n');
    }
  }

  // ตรวจสอบ iOS (แค่ check ว่ามีไฟล์และ format ถูกต้องหรือไม่)
  print('🍎 Checking iOS (GoogleService-Info.plist):');
  final iosFile = File('ios/Runner/GoogleService-Info.plist');

  if (!iosFile.existsSync()) {
    print('   ❌ File not found!\n');
  } else {
    final iosContent = iosFile.readAsStringSync();

    // Check if it's XML format (plist) or JSON
    if (iosContent.trimLeft().startsWith('<?xml') || iosContent.trimLeft().startsWith('<plist')) {
      print('   ✅ File format is correct (XML/plist)');

      // Try to extract PROJECT_ID
      final projectIdMatch = RegExp(r'<key>PROJECT_ID</key>\s*<string>([^<]+)</string>').firstMatch(iosContent);
      final gcmSenderIdMatch = RegExp(r'<key>GCM_SENDER_ID</key>\s*<string>([^<]+)</string>').firstMatch(iosContent);

      if (projectIdMatch != null && gcmSenderIdMatch != null) {
        final iosProjectId = projectIdMatch.group(1)!;
        final iosGcmSenderId = gcmSenderIdMatch.group(1)!;

        print('   Project ID: $iosProjectId');
        print('   GCM Sender ID: $iosGcmSenderId');

        if (iosProjectId == expectedProjectId &&
            iosGcmSenderId == expectedMessagingSenderId) {
          print('   ✅ iOS configuration is CORRECT!\n');
        } else {
          print('   ❌ iOS configuration MISMATCH!');
          print('   Expected Project ID: $expectedProjectId');
          print('   Expected GCM Sender ID: $expectedMessagingSenderId\n');
        }
      } else {
        print('   ⚠️  Could not extract project info from plist\n');
      }
    } else if (iosContent.trimLeft().startsWith('{')) {
      print('   ❌ File format is WRONG! It\'s JSON, should be XML/plist');
      print('   👉 Please download GoogleService-Info.plist from Firebase Console\n');

      // ถ้าเป็น JSON ลอง parse ดู
      try {
        final iosJson = jsonDecode(iosContent);
        final iosProjectId = iosJson['project_info']['project_id'];
        print('   Current Project ID in file: $iosProjectId');
        print('   This file is using the wrong Firebase project!\n');
      } catch (e) {
        print('   Error parsing JSON: $e\n');
      }
    } else {
      print('   ❌ Unknown file format!\n');
    }
  }

  print('========================================');
  print('📝 SUMMARY');
  print('========================================');
  print('Expected Firebase Project: $expectedProjectId');
  print('Expected Project Number: $expectedMessagingSenderId');
  print('\n💡 If configurations don\'t match:');
  print('1. Go to Firebase Console: https://console.firebase.google.com/');
  print('2. Select project: $expectedProjectId');
  print('3. Download google-services.json for Android');
  print('4. Download GoogleService-Info.plist for iOS');
  print('5. Replace the files in your project');
  print('6. Run: flutter clean && flutter pub get');
  print('========================================');
}

# 📱 คู่มือสร้าง Video Call App ตั้งแต่ต้น

## สารบัญ

1. [STEP 1: สร้าง Stream Account](#step-1-สร้าง-stream-account)
2. [STEP 2: สร้างและ Config Firebase](#step-2-สร้างและ-config-firebase)
3. [STEP 3: เชื่อม Firebase กับ Stream](#step-3-เชื่อม-firebase-กับ-stream)
4. [STEP 4: สร้าง Backend (Token Generator)](#step-4-สร้าง-backend-token-generator)
5. [STEP 5: สร้าง Flutter App](#step-5-สร้าง-flutter-app)
6. [STEP 6: Config Flutter App](#step-6-config-flutter-app)
7. [STEP 7: เขียน Code - Initialize](#step-7-เขียน-code---initialize)
8. [STEP 8: เขียน Code - Make Call](#step-8-เขียน-code---make-call)
9. [STEP 9: เขียน Code - Receive Call](#step-9-เขียน-code---receive-call)
10. [STEP 10: Test ทั้งระบบ](#step-10-test-ทั้งระบบ)

---

# STEP 1: สร้าง Stream Account

## จุดประสงค์
สร้างบัญชี Stream และได้ API Key + API Secret สำหรับการเชื่อมต่อ

## ขั้นตอน

### 1.1 สมัครบัญชี
1. เปิด https://getstream.io/
2. คลิก **"Sign Up"** หรือ **"Get Started Free"**
3. กรอกข้อมูล:
   - Email
   - Password
   - ชื่อบริษัท/โปรเจค (เช่น "MyVideoApp")
4. ยืนยัน Email

### 1.2 สร้าง App
1. Login เข้า Dashboard: https://dashboard.getstream.io/
2. ถ้ายังไม่มี app → คลิก **"Create App"**
3. เลือก **"Video & Audio"** (ไม่ใช่ Chat)
4. ตั้งชื่อ App (เช่น "My Video Call App")
5. เลือก Region:
   - **ถ้าใช้ในเอเชีย:** Singapore
   - **ถ้าใช้ในอเมริกา:** US East
6. คลิก **"Create App"**

### 1.3 ดู API Credentials
1. ไปที่ **Dashboard → Settings → General**
2. จะเห็น:
   ```
   API Key:     r9mn4fsbzhub
   API Secret:  [คลิก "Show" เพื่อดู]
   ```
3. **บันทึกทั้ง 2 ค่าไว้** (จะใช้ใน Backend)

## ผลลัพธ์ที่ได้
- ✅ API Key (สำหรับ App)
- ✅ API Secret (สำหรับ Backend)

## เช็คว่าสำเร็จ
- เห็น Dashboard ของ Stream
- เห็น API Key และ API Secret

---

# STEP 2: สร้างและ Config Firebase

## จุดประสงค์
สร้าง Firebase Project เพื่อใช้ส่ง Push Notifications

## ขั้นตอน

### 2.1 สร้าง Firebase Project
1. เปิด https://console.firebase.google.com/
2. คลิก **"Add project"** หรือ **"Create a project"**
3. ตั้งชื่อโปรเจค (เช่น "notificationforlailaolab")
4. เปิด/ปิด Google Analytics (แนะนำปิดถ้าไม่ใช้)
5. คลิก **"Create project"**
6. รอ 1-2 นาที

### 2.2 เพิ่ม Android App
1. ใน Firebase Console → คลิก **Android icon** (รูป Android)
2. กรอกข้อมูล:
   ```
   Android package name: com.example.myvideoapp
   App nickname: MyVideoApp (Android)
   Debug signing certificate: [ไม่ต้องกรอก]
   ```
3. คลิก **"Register app"**
4. **Download `google-services.json`**
5. บันทึกไฟล์ไว้ (จะใช้ใน Step 6)

### 2.3 เพิ่ม iOS App
1. คลิก **iOS icon** (รูป Apple)
2. กรอกข้อมูล:
   ```
   iOS bundle ID: com.example.myvideoapp
   App nickname: MyVideoApp (iOS)
   App Store ID: [ไม่ต้องกรอก]
   ```
3. คลิก **"Register app"**
4. **Download `GoogleService-Info.plist`**
5. บันทึกไฟล์ไว้ (จะใช้ใน Step 6)

### 2.4 Enable Cloud Messaging
1. ไปที่ **Project Settings** (ไอคอนเฟือง)
2. เลือกแท็บ **"Cloud Messaging"**
3. ถ้าเห็น **"Cloud Messaging API (Legacy) - Disabled"**:
   - คลิก **"⋮"** (3 จุด)
   - เลือก **"Manage API in Google Cloud Console"**
   - คลิก **"Enable"**
4. กลับมาที่ Firebase Console
5. จะเห็น **"Server key"** (ยาวประมาณ 150 ตัวอักษร)
6. **Copy Server Key ไว้** (จะใช้ใน Step 3)

## ผลลัพธ์ที่ได้
- ✅ Firebase Project
- ✅ `google-services.json` (Android)
- ✅ `GoogleService-Info.plist` (iOS)
- ✅ FCM Server Key

## เช็คว่าสำเร็จ
- เห็น Firebase Project ใน Console
- มีไฟล์ `google-services.json` และ `GoogleService-Info.plist`
- เห็น Server Key ใน Cloud Messaging settings

---

# STEP 3: เชื่อม Firebase กับ Stream

## จุดประสงค์
Config Stream ให้ส่ง Push Notifications ผ่าน Firebase

## ขั้นตอน

### 3.1 เปิด Push Notifications Settings
1. ไปที่ Stream Dashboard: https://dashboard.getstream.io/
2. เลือก App ที่สร้างไว้
3. เมนูซ้ายมือ → **"Video & Audio"** → **"Push Notifications"**

### 3.2 เพิ่ม Firebase Provider
1. คลิก **"Add Configuration"** หรือ **"New Push Provider"**
2. เลือก **"Firebase Cloud Messaging (FCM)"**
3. กรอกข้อมูล:
   ```
   Name: niwner_notification
   Description: Firebase push for video calls
   ```
4. วาง **FCM Server Key** (จาก Step 2.4)
5. คลิก **"Save"**

### 3.3 เพิ่ม APNs Provider (สำหรับ iOS)
1. คลิก **"Add Configuration"** อีกครั้ง
2. เลือก **"Apple Push Notification Service (APNs)"**
3. กรอกข้อมูล:
   ```
   Name: niwner_notification
   Auth Method: Token (แนะนำ) หรือ Certificate
   ```
4. Upload APNs Token หรือ Certificate จาก Apple Developer
5. คลิก **"Save"**

> **หมายเหตุ:** ถ้ายังไม่มี APNs Certificate สามารถข้ามไปก่อน แล้วกลับมาทำทีหลัง

## ผลลัพธ์ที่ได้
- ✅ Firebase Provider ชื่อ "niwner_notification" ใน Stream
- ✅ APNs Provider ชื่อ "niwner_notification" ใน Stream (iOS)

## เช็คว่าสำเร็จ
- เห็น Provider ใน Push Notifications page
- Status เป็น **"Active"** (สีเขียว)

---

# STEP 4: สร้าง Backend (Token Generator)

## จุดประสงค์
สร้าง Backend API เพื่อ Generate User Token สำหรับ Authentication

## เหตุผลที่ต้องมี Backend
- **ห้ามเก็บ API Secret ใน App!** (เพราะ decompile ได้)
- Backend จะ generate token ให้ user ด้วย API Secret
- Token นี้มี expiration time (ปลอดภัย)

## ขั้นตอน

### 4.1 สร้าง Node.js Project
```bash
mkdir video-call-backend
cd video-call-backend
npm init -y
```

### 4.2 ติดตั้ง Dependencies
```bash
npm install express dotenv jsonwebtoken cors
npm install --save-dev typescript @types/node @types/express ts-node
```

### 4.3 สร้าง TypeScript Config
สร้างไฟล์ `tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true
  }
}
```

### 4.4 สร้างไฟล์ `.env`
สร้างไฟล์ `.env` ที่ root:
```env
PORT=8181
STREAM_API_KEY=r9mn4fsbzhub
STREAM_API_SECRET=your_api_secret_from_step_1
TOKEN_TTL_SECONDS=86400
```

> **⚠️ สำคัญ:** แทนที่ `STREAM_API_SECRET` ด้วยค่าจริงจาก Stream Dashboard (Step 1.3)

### 4.5 สร้าง Token Generator
สร้างไฟล์ `src/controllers/streamController.ts`:
```typescript
import jwt from 'jsonwebtoken';

const STREAM_API_SECRET = process.env.STREAM_API_SECRET!;
const STREAM_API_KEY = process.env.STREAM_API_KEY!;
const TOKEN_TTL = Number(process.env.TOKEN_TTL_SECONDS) || 3600;

export const generateStreamToken = (req: any, res: any) => {
  try {
    // ดึง userId จาก request (จาก JWT token ของ app)
    const userId = req.user?.userId || req.body?.userId;

    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    // สร้าง Stream token
    const issuedAt = Math.floor(Date.now() / 1000);
    const expiresAt = issuedAt + TOKEN_TTL;

    const token = jwt.sign(
      {
        user_id: userId,
        validity_in_seconds: TOKEN_TTL,
        iat: issuedAt,
        exp: expiresAt,
      },
      STREAM_API_SECRET,
      { algorithm: 'HS256' }
    );

    console.log(`✅ Generated token for user: ${userId}`);

    return res.json({
      apiKey: STREAM_API_KEY,
      userId: userId,
      token: token,
      expiresAt: expiresAt,
    });
  } catch (error) {
    console.error('❌ Error generating token:', error);
    return res.status(500).json({ error: 'Failed to generate token' });
  }
};
```

### 4.6 สร้าง Router
สร้างไฟล์ `src/routes/streamRoutes.ts`:
```typescript
import { Router } from 'express';
import { generateStreamToken } from '../controllers/streamController';

const router = Router();

// API สำหรับ generate token
router.post('/callStreams', generateStreamToken);

export default router;
```

### 4.7 สร้าง Server
สร้างไฟล์ `src/index.ts`:
```typescript
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import streamRoutes from './routes/streamRoutes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8181;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/v1/api', streamRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Server is running' });
});

// Start server
app.listen(PORT, () => {
  console.log('========================================');
  console.log(`✅ Server is running on port ${PORT}`);
  console.log(`📍 Generate Token: POST http://localhost:${PORT}/v1/api/callStreams`);
  console.log('========================================');
});
```

### 4.8 เพิ่ม Scripts ใน `package.json`
แก้ไขไฟล์ `package.json`:
```json
{
  "scripts": {
    "dev": "ts-node src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  }
}
```

### 4.9 รัน Backend
```bash
npm run dev
```

ควรเห็น:
```
========================================
✅ Server is running on port 8181
📍 Generate Token: POST http://localhost:8181/v1/api/callStreams
========================================
```

## ผลลัพธ์ที่ได้
- ✅ Backend API ที่รันที่ `http://localhost:8181`
- ✅ Endpoint `/v1/api/callStreams` สำหรับ generate token

## เช็คว่าสำเร็จ

### Test 1: Health Check
```bash
curl http://localhost:8181/health
```

**ควรได้:**
```json
{"status":"OK","message":"Server is running"}
```

### Test 2: Generate Token
```bash
curl -X POST http://localhost:8181/v1/api/callStreams \
  -H "Content-Type: application/json" \
  -d '{"userId": "test-user-123"}'
```

**ควรได้:**
```json
{
  "apiKey": "r9mn4fsbzhub",
  "userId": "test-user-123",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": 1759899600
}
```

---

# STEP 5: สร้าง Flutter App

## จุดประสงค์
สร้าง Flutter project พร้อม dependencies ที่จำเป็น

## ขั้นตอน

### 5.1 สร้าง Project
```bash
flutter create my_video_app
cd my_video_app
```

### 5.2 เพิ่ม Dependencies
แก้ไขไฟล์ `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Stream Video SDK
  stream_video_flutter: ^1.5.1

  # Firebase
  firebase_core: ^3.10.0
  firebase_messaging: ^15.2.0

  # HTTP
  http: ^1.2.2

environment:
  sdk: '>=3.0.0 <4.0.0'
```

### 5.3 Install Dependencies
```bash
flutter pub get
```

### 5.4 Enable Platforms
```bash
# Enable Android
flutter config --enable-android

# Enable iOS (Mac only)
flutter config --enable-ios

# Enable Web
flutter config --enable-web
```

## ผลลัพธ์ที่ได้
- ✅ Flutter project พร้อม dependencies

## เช็คว่าสำเร็จ
```bash
flutter doctor
```

ควรเห็น:
```
✓ Flutter (Channel stable)
✓ Android toolchain
✓ Chrome - develop for the web
```

---

# STEP 6: Config Flutter App

## จุดประสงค์
Configure Firebase และ Permissions สำหรับ Android/iOS

## ขั้นตอน

### 6.1 Config Firebase สำหรับ Flutter

#### วิธีที่ 1: ใช้ FlutterFire CLI (แนะนำ)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Config Firebase
flutterfire configure
```

เลือก:
- Project: `notificationforlailaolab` (จาก Step 2)
- Platforms: Android, iOS, Web (เลือกตามต้องการ)

#### วิธีที่ 2: Manual Setup

**Android:**
1. Copy `google-services.json` (จาก Step 2.2)
2. วางที่ `android/app/google-services.json`

**iOS:**
1. Copy `GoogleService-Info.plist` (จาก Step 2.3)
2. วางที่ `ios/Runner/GoogleService-Info.plist`

### 6.2 Config Android

#### 6.2.1 แก้ `android/build.gradle`
```gradle
buildscript {
    dependencies {
        // เพิ่มบรรทัดนี้
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### 6.2.2 แก้ `android/app/build.gradle`
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

// เพิ่มบรรทัดนี้ (ท้ายสุดของไฟล์)
apply plugin: 'com.google.gms.google-services'

android {
    namespace = "com.example.myvideoapp"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.myvideoapp"
        minSdk = 24  // ✅ Stream ต้องการ 24+
        targetSdk = 34
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
}
```

#### 6.2.3 แก้ `android/app/src/main/AndroidManifest.xml`
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application
        android:label="my_video_app"
        android:icon="@mipmap/ic_launcher">

        <activity android:name=".MainActivity"
            android:launchMode="singleTop"
            android:showWhenLocked="true"
            android:turnScreenOn="true">
        </activity>

        <!-- Firebase Messaging Service -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT"/>
            </intent-filter>
        </service>
    </application>
</manifest>
```

### 6.3 Config iOS

#### 6.3.1 แก้ `ios/Runner/Info.plist`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- เพิ่มส่วนนี้ -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>voip</string>
        <string>remote-notification</string>
    </array>

    <!-- Camera และ Microphone -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access for video calls</string>

    <key>NSMicrophoneUsageDescription</key>
    <string>We need microphone access for video calls</string>

    <!-- Existing keys... -->
</dict>
</plist>
```

#### 6.3.2 เพิ่ม Push Notifications Capability
1. เปิด `ios/Runner.xcworkspace` ใน Xcode
2. เลือก Runner target
3. แท็บ **"Signing & Capabilities"**
4. คลิก **"+ Capability"**
5. เพิ่ม:
   - **Push Notifications**
   - **Background Modes** → เปิด Audio, VoIP, Remote notifications

### 6.4 Generate Firebase Options

สร้างไฟล์ `lib/firebase_options.dart`:
```bash
flutterfire configure
```

หรือสร้างเองจาก Firebase Console:
```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIza...',  // จาก google-services.json
    appId: '1:564...',
    messagingSenderId: '564591146605',
    projectId: 'notificationforlailaolab',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIza...',  // จาก GoogleService-Info.plist
    appId: '1:564...',
    messagingSenderId: '564591146605',
    projectId: 'notificationforlailaolab',
    iosBundleId: 'com.example.myvideoapp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIza...',
    appId: '1:564...',
    messagingSenderId: '564591146605',
    projectId: 'notificationforlailaolab',
  );
}
```

## ผลลัพธ์ที่ได้
- ✅ Firebase configured
- ✅ Permissions configured
- ✅ `firebase_options.dart` ready

## เช็คว่าสำเร็จ
```bash
flutter build apk --debug
```

ควร build สำเร็จไม่มี error

---

# STEP 7: เขียน Code - Initialize

## จุดประสงค์
Initialize Firebase และ Stream Video Client

## ขั้นตอน

### 7.1 สร้าง Background Handler
สร้างไฟล์ `lib/firebase_background_handler.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    print('🔔 Background notification: ${message.messageId}');
  }

  await StreamVideoPushNotificationManager.onBackgroundMessage(message);
}
```

### 7.2 สร้าง Stream Client Initializer
สร้างไฟล์ `lib/services/stream_service.dart`:
```dart
import 'package:stream_video_flutter/stream_video_flutter.dart';

class StreamService {
  static StreamVideo? _client;

  static Future<StreamVideo> initialize({
    required String apiKey,
    required String userId,
    required String userName,
    required String userToken,
  }) async {
    if (_client != null) {
      return _client!;
    }

    print('========================================');
    print('🔧 Initializing Stream Video Client');
    print('User ID: $userId');
    print('User Name: $userName');
    print('========================================');

    final user = User(id: userId, name: userName);

    _client = StreamVideo(
      apiKey,
      user: user,
      userToken: userToken,
      pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
        androidPushProvider: const StreamVideoPushProvider.firebase(
          name: 'niwner_notification',  // ต้องตรงกับ Stream Dashboard
        ),
        iosPushProvider: const StreamVideoPushProvider.apn(
          name: 'niwner_notification',
        ),
      ),
    );

    await _client!.connect();
    print('✅ Stream Video connected');

    return _client!;
  }

  static StreamVideo get client {
    if (_client == null) {
      throw Exception('StreamVideo not initialized');
    }
    return _client!;
  }

  static void dispose() {
    _client?.disconnect();
    _client = null;
  }
}
```

### 7.3 แก้ `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_background_handler.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Request notification permission
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Call App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
```

## ผลลัพธ์ที่ได้
- ✅ Firebase initialized
- ✅ Background handler registered
- ✅ Stream service ready

---

# STEP 8: เขียน Code - Make Call

## จุดประสงค์
สร้างหน้าจอหลักและฟังก์ชันโทรออก

## ขั้นตอน

### 8.1 สร้างหน้า Login
สร้างไฟล์ `lib/pages/login_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/stream_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userIdController = TextEditingController();
  final _userNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final userId = _userIdController.text.trim();
    final userName = _userNameController.text.trim();

    if (userId.isEmpty || userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter user ID and name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call backend to get token
      final response = await http.post(
        Uri.parse('http://localhost:8181/v1/api/callStreams'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get token');
      }

      final data = jsonDecode(response.body);
      final apiKey = data['apiKey'];
      final token = data['token'];

      // Initialize Stream
      await StreamService.initialize(
        apiKey: apiKey,
        userId: userId,
        userName: userName,
        userToken: token,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userNameController,
              decoration: const InputDecoration(
                labelText: 'User Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

### 8.2 สร้างหน้า Home (Caller)
สร้างไฟล์ `lib/pages/home_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/stream_service.dart';
import 'call_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _calleeIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _observeIncomingCalls();
  }

  void _observeIncomingCalls() {
    StreamService.client.state.incomingCall.listen((call) {
      if (call != null && mounted) {
        print('📞 Incoming call from: ${call.state.value.createdBy?.name}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallPage(call: call, isOutgoing: false),
          ),
        );
      }
    });
  }

  Future<void> _startCall({required bool isVideoCall}) async {
    final calleeId = _calleeIdController.text.trim();

    if (calleeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter callee ID')),
      );
      return;
    }

    try {
      print('========================================');
      print('📞 Starting call to: $calleeId');
      print('Video: $isVideoCall');
      print('========================================');

      final callId = const Uuid().v4();
      final call = StreamService.client.makeCall(
        callType: StreamCallType.defaultType(),
        id: callId,
      );

      await call.getOrCreate(
        memberIds: [calleeId],
        ringing: true,  // ✅ ส่ง push notification
      );

      await call.ring();

      print('✅ Call created and ringing');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallPage(call: call, isOutgoing: true),
          ),
        );
      }
    } catch (e) {
      print('❌ Failed to start call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = StreamService.client.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${currentUser.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your ID: ${currentUser.id}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _calleeIdController,
              decoration: const InputDecoration(
                labelText: 'Callee User ID',
                border: OutlineInputBorder(),
                hintText: 'Enter user ID to call',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _startCall(isVideoCall: false),
                  icon: const Icon(Icons.phone),
                  label: const Text('Audio Call'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _startCall(isVideoCall: true),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Video Call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _calleeIdController.dispose();
    super.dispose();
  }
}
```

## ผลลัพธ์ที่ได้
- ✅ Login page with backend integration
- ✅ Home page with call functionality
- ✅ Call creation with `ringing: true`

---

# STEP 9: เขียน Code - Receive Call

## จุดประสงค์
สร้างหน้าจอรับสายและจัดการ WebRTC connection

## ขั้นตอน

### 9.1 สร้างหน้า Call
สร้างไฟล์ `lib/pages/call_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class CallPage extends StatefulWidget {
  final Call call;
  final bool isOutgoing;

  const CallPage({
    super.key,
    required this.call,
    required this.isOutgoing,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  bool _isCallActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOutgoing) {
      // Caller: already rang in HomePage
      _waitForAccept();
    } else {
      // Callee: show ringing UI
      _showIncomingCallUI();
    }

    _observeCallState();
  }

  void _waitForAccept() {
    setState(() => _isCallActive = true);
    print('⏳ Waiting for callee to accept...');
  }

  void _showIncomingCallUI() {
    print('🔔 Showing incoming call UI');
  }

  void _observeCallState() {
    widget.call.state.listen((state) {
      print('Call state: ${state.status}');
      if (state.status == CallStatus.ended && mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _acceptCall() async {
    try {
      print('✅ Accepting call...');
      await widget.call.accept();
      setState(() => _isCallActive = true);
      print('✅ Call accepted');
    } catch (e) {
      print('❌ Failed to accept: $e');
    }
  }

  Future<void> _rejectCall() async {
    try {
      print('❌ Rejecting call...');
      await widget.call.reject();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ Failed to reject: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      print('📴 Ending call...');
      await widget.call.leave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ Failed to end call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCallActive && !widget.isOutgoing) {
      // Incoming call - show accept/reject buttons
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                widget.call.state.value.createdBy?.name ?? 'Unknown',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Incoming Call...',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 64),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: _rejectCall,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  FloatingActionButton(
                    onPressed: _acceptCall,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.call, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Active call - show video/audio UI
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamCallContainer(
        call: widget.call,
        callContentBuilder: (context, call, callState) {
          return StreamCallContent(
            call: call,
            callState: callState,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _endCall,
        backgroundColor: Colors.red,
        child: const Icon(Icons.call_end),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
```

## ผลลัพธ์ที่ได้
- ✅ Incoming call UI (Accept/Reject)
- ✅ Active call UI with video
- ✅ Call state management

---

# STEP 10: Test ทั้งระบบ

## จุดประสงค์
ทดสอบการโทรตั้งแต่ต้นจนจบ

## ขั้นตอน

### 10.1 เตรียม Backend
```bash
cd video-call-backend
npm run dev
```

ต้องเห็น:
```
✅ Server is running on port 8181
```

### 10.2 เตรียม Device/Emulator

#### Option 1: 2 Emulators/Simulators
```bash
# Terminal 1 - Android Emulator 1
flutter run -d emulator-5554

# Terminal 2 - Android Emulator 2
flutter run -d emulator-5556
```

#### Option 2: Chrome + Mobile
```bash
# Terminal 1 - Chrome (User A)
flutter run -d chrome

# Terminal 2 - Android Device (User B)
flutter run -d YOUR_DEVICE_ID
```

### 10.3 Login Users

**Device 1 (User A):**
```
User ID: user-a
User Name: Alice
```

**Device 2 (User B):**
```
User ID: user-b
User Name: Bob
```

### 10.4 ทดสอบการโทร

1. **ที่ Device 1 (Alice):**
   - กรอก Callee ID: `user-b`
   - กด **"Video Call"**

2. **ควรเห็นที่ Device 1:**
   ```
   ========================================
   📞 Starting call to: user-b
   Video: true
   ========================================
   ✅ Call created and ringing
   ```

3. **ควรเห็นที่ Device 2 (Bob):**
   - **Foreground:** หน้าจอ incoming call ปรากฏทันที
   - **Background:** Notification + CallKit/ConnectionService
   ```
   🔔 Background notification: ...
   📞 Incoming call from: Alice
   ```

4. **ที่ Device 2 (Bob):**
   - กด **Accept** (ปุ่มเขียว)

5. **ควรเห็น:**
   - Device 1: Video ของ Bob ปรากฏ
   - Device 2: Video ของ Alice ปรากฏ
   - ทั้งสองฝั่งได้ยินเสียงกัน

### 10.5 ตรวจสอบ Logs

#### Device 1 (Caller) Logs:
```
🔧 Initializing Stream Video Client
User ID: user-a
✅ Stream Video connected
📞 Starting call to: user-b
✅ Call created and ringing
Call state: active
```

#### Device 2 (Callee) Logs:
```
🔧 Initializing Stream Video Client
User ID: user-b
✅ Stream Video connected
🔔 Background notification: 0:123...
📞 Incoming call from: Alice
✅ Accepting call...
✅ Call accepted
Call state: active
```

#### Backend Logs:
```
✅ Generated token for user: user-a
✅ Generated token for user: user-b
```

#### Stream Dashboard:
1. ไปที่ https://dashboard.getstream.io/
2. เลือก App
3. ไปที่ **"Video & Audio"** → **"Logs"**
4. ควรเห็น:
   ```
   call.created
   call.ring
   push.sent
   call.accepted
   call.session.started
   ```

### 10.6 Test Scenarios

#### Scenario 1: Background Call
1. Device 2: กด Home (ส่งแอปไป background)
2. Device 1: โทรไปหา Device 2
3. **Expected:** Device 2 แสดง CallKit/ConnectionService UI

#### Scenario 2: App Terminated
1. Device 2: ปิดแอป (swipe away)
2. Device 1: โทรไปหา Device 2
3. **Expected:** Device 2 แสดง notification + wake up แอป

#### Scenario 3: Reject Call
1. Device 1: โทรไปหา Device 2
2. Device 2: กด **Reject**
3. **Expected:**
   - Device 2: กลับหน้า Home
   - Device 1: Call ends, กลับหน้า Home

#### Scenario 4: End Call
1. Device 1: โทรไปหา Device 2
2. Device 2: Accept
3. Device 1: กด **End Call**
4. **Expected:** ทั้งสองฝั่งกลับหน้า Home

## Checklist ทั้งหมด

### Backend
- [ ] Backend รันที่ port 8181
- [ ] Health check ผ่าน (`/health`)
- [ ] Generate token ได้ (`/v1/api/callStreams`)
- [ ] Token signature ถูกต้อง (ไม่มี "Token signature is invalid")

### Firebase
- [ ] Firebase project สร้างแล้ว
- [ ] `google-services.json` อยู่ใน `android/app/`
- [ ] `GoogleService-Info.plist` อยู่ใน `ios/Runner/`
- [ ] FCM Server Key config ใน Stream Dashboard

### Stream
- [ ] Stream app สร้างแล้ว
- [ ] Push Provider "niwner_notification" มี (Firebase + APNs)
- [ ] API Key และ API Secret ถูกต้อง

### Flutter App
- [ ] Dependencies ติดตั้งแล้ว (`flutter pub get`)
- [ ] Android permissions ครบ (AndroidManifest.xml)
- [ ] iOS capabilities ครบ (Info.plist, Xcode)
- [ ] Background handler registered (main.dart)

### Testing
- [ ] Login ได้ทั้ง 2 user
- [ ] FCM Token แสดงใน logs
- [ ] โทรจาก A → B ได้
- [ ] B ได้รับ notification (foreground/background)
- [ ] B กด Accept → เชื่อมต่อได้
- [ ] เห็น video และได้ยินเสียงกัน
- [ ] End call ได้
- [ ] Stream Dashboard มี logs

---

## 🎉 สำเร็จแล้ว!

ตอนนี้คุณมี Video Call App ที่สมบูรณ์:
- ✅ Backend สำหรับ generate token
- ✅ Firebase สำหรับ push notifications
- ✅ Stream Video SDK สำหรับ video calling
- ✅ Flutter App ที่โทรได้ทั้ง foreground และ background

---

## 📚 สิ่งที่ควรทำต่อ

### Security
- เพิ่ม Authentication (JWT) สำหรับ Backend API
- ไม่ hardcode credentials
- ใช้ environment variables

### Features
- เพิ่ม contact list
- เพิ่ม call history
- เพิ่ม group calls
- เพิ่ม screen sharing
- เพิ่ม chat during call

### Production
- Deploy backend ไปที่ cloud (AWS, GCP, Heroku)
- ใช้ HTTPS สำหรับ backend
- Config APNs certificate สำหรับ iOS production
- Test บน real devices มากขึ้น

---

## ❓ FAQ

### Q: Token หมดอายุทำยังไง?
**A:** Backend generate token ใหม่โดยอัตโนมัติเมื่อ login ใหม่

### Q: ถ้า Backend ไม่ online?
**A:** App จะ login ไม่ได้ (ต้องมี token)

### Q: iOS ไม่ได้รับ notification?
**A:**
1. ตรวจสอบ APNs certificate ใน Stream Dashboard
2. ตรวจสอบ Background Modes ใน Xcode
3. ทดสอบบน real device (simulator ไม่รับ push)

### Q: Android notification ไม่ขึ้น?
**A:**
1. ตรวจสอบ FCM Server Key ใน Stream Dashboard
2. ตรวจสอบ permissions ใน AndroidManifest.xml
3. ปิด Battery Optimization สำหรับ app

### Q: Stream Dashboard ไม่มี logs?
**A:** แสดงว่า token signature ผิด → ตรวจสอบ `STREAM_API_SECRET` ใน backend `.env`

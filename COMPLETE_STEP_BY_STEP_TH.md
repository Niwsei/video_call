# 📚 คู่มืออธิบายโค้ดทุกขั้นตอน - ตั้งแต่เริ่มต้นจนโทรได้

## สารบัญ

### ส่วนที่ 1: เริ่มต้น Application
- [ขั้นตอนที่ 1: เปิด App - main() function](#ขั้นตอนที่-1-เปิด-app---main-function)
- [ขั้นตอนที่ 2: Bootstrap App - _BootstrapApp](#ขั้นตอนที่-2-bootstrap-app---_bootstrapapp)
- [ขั้นตอนที่ 3: เริ่ม Initialize - _initialize()](#ขั้นตอนที่-3-เริ่ม-initialize---_initialize)
- [ขั้นตอนที่ 4: Get User Data - TutorialUser](#ขั้นตอนที่-4-get-user-data---tutorialuser)
- [ขั้นตอนที่ 5: Initialize App - AppInitializer](#ขั้นตอนที่-5-initialize-app---appinitializer)

### ส่วนที่ 2: Firebase และ Push Notifications
- [ขั้นตอนที่ 6: Initialize Firebase](#ขั้นตอนที่-6-initialize-firebase)
- [ขั้นตอนที่ 7: Register Background Handler](#ขั้นตอนที่-7-register-background-handler)
- [ขั้นตอนที่ 8: Request FCM Permission](#ขั้นตอนที่-8-request-fcm-permission)

### ส่วนที่ 3: Stream Video Client
- [ขั้นตอนที่ 9: Create Stream Client](#ขั้นตอนที่-9-create-stream-client)
- [ขั้นตอนที่ 10: Setup Push Notification Manager](#ขั้นตอนที่-10-setup-push-notification-manager)
- [ขั้นตอนที่ 11: Connect to Stream Backend](#ขั้นตอนที่-11-connect-to-stream-backend)
- [ขั้นตอนที่ 12: Register FCM Token with Stream](#ขั้นตอนที่-12-register-fcm-token-with-stream)

### ส่วนที่ 4: แสดง UI หลัก
- [ขั้นตอนที่ 13: แสดง MyApp Widget](#ขั้นตอนที่-13-แสดง-myapp-widget)
- [ขั้นตอนที่ 14: แสดง HomePage](#ขั้นตอนที่-14-แสดง-homepage)
- [ขั้นตอนที่ 15: Listen for Incoming Calls](#ขั้นตอนที่-15-listen-for-incoming-calls)
- [ขั้นตอนที่ 16: Monitor FCM Token](#ขั้นตอนที่-16-monitor-fcm-token)

### ส่วนที่ 5: การโทรออก (Caller - User A)
- [ขั้นตอนที่ 17: User กรอก Callee ID](#ขั้นตอนที่-17-user-กรอก-callee-id)
- [ขั้นตอนที่ 18: กดปุ่มโทร - _startCall()](#ขั้นตอนที่-18-กดปุ่มโทร---_startcall)
- [ขั้นตอนที่ 19: สร้าง Call ID](#ขั้นตอนที่-19-สร้าง-call-id)
- [ขั้นตอนที่ 20: makeCall()](#ขั้นตอนที่-20-makecall)
- [ขั้นตอนที่ 21: getOrCreate() - สร้าง Call ใน Server](#ขั้นตอนที่-21-getorcreate---สร้าง-call-ใน-server)
- [ขั้นตอนที่ 22: ring() - ส่ง Push Notification](#ขั้นตอนที่-22-ring---ส่ง-push-notification)
- [ขั้นตอนที่ 23: Navigate to CallScreen (Caller)](#ขั้นตอนที่-23-navigate-to-callscreen-caller)

### ส่วนที่ 6: Stream Backend Process
- [ขั้นตอนที่ 24: Stream รับ Request สร้าง Call](#ขั้นตอนที่-24-stream-รับ-request-สร้าง-call)
- [ขั้นตอนที่ 25: Stream Query User B Devices](#ขั้นตอนที่-25-stream-query-user-b-devices)
- [ขั้นตอนที่ 26: Stream Get Push Provider Config](#ขั้นตอนที่-26-stream-get-push-provider-config)
- [ขั้นตอนที่ 27: Stream สร้าง Notification Payload](#ขั้นตอนที่-27-stream-สร้าง-notification-payload)
- [ขั้นตอนที่ 28: Stream ส่งไป Firebase FCM](#ขั้นตอนที่-28-stream-ส่งไป-firebase-fcm)

### ส่วนที่ 7: Firebase ส่ง Notification
- [ขั้นตอนที่ 29: Firebase รับ Request จาก Stream](#ขั้นตอนที่-29-firebase-รับ-request-จาก-stream)
- [ขั้นตอนที่ 30: Firebase Route to User B Device](#ขั้นตอนที่-30-firebase-route-to-user-b-device)

### ส่วนที่ 8: การรับสาย (Callee - User B)
- [ขั้นตอนที่ 31: User B รับ Notification (Foreground)](#ขั้นตอนที่-31-user-b-รับ-notification-foreground)
- [ขั้นตอนที่ 32: User B รับ Notification (Background)](#ขั้นตอนที่-32-user-b-รับ-notification-background)
- [ขั้นตอนที่ 33: Stream SDK Parse Message](#ขั้นตอนที่-33-stream-sdk-parse-message)
- [ขั้นตอนที่ 34: Update IncomingCall Stream](#ขั้นตอนที่-34-update-incomingcall-stream)
- [ขั้นตอนที่ 35: Listener Trigger - Navigate to CallScreen](#ขั้นตอนที่-35-listener-trigger---navigate-to-callscreen)

### ส่วนที่ 9: CallScreen (Incoming Call UI)
- [ขั้นตอนที่ 36: แสดง Incoming Call UI](#ขั้นตอนที่-36-แสดง-incoming-call-ui)
- [ขั้นตอนที่ 37: User B กด Accept](#ขั้นตอนที่-37-user-b-กด-accept)
- [ขั้นตอนที่ 38: call.accept() - ส่ง Request](#ขั้นตอนที่-38-callaccept---ส่ง-request)
- [ขั้นตอนที่ 39: Stream Notify User A](#ขั้นตอนที่-39-stream-notify-user-a)

### ส่วนที่ 10: WebRTC Connection
- [ขั้นตอนที่ 40: User A สร้าง SDP Offer](#ขั้นตอนที่-40-user-a-สร้าง-sdp-offer)
- [ขั้นตอนที่ 41: ส่ง Offer ผ่าน Stream](#ขั้นตอนที่-41-ส่ง-offer-ผ่าน-stream)
- [ขั้นตอนที่ 42: User B รับ Offer](#ขั้นตอนที่-42-user-b-รับ-offer)
- [ขั้นตอนที่ 43: User B สร้าง SDP Answer](#ขั้นตอนที่-43-user-b-สร้าง-sdp-answer)
- [ขั้นตอนที่ 44: ส่ง Answer กลับ User A](#ขั้นตอนที่-44-ส่ง-answer-กลับ-user-a)
- [ขั้นตอนที่ 45: แลกเปลี่ยน ICE Candidates](#ขั้นตอนที่-45-แลกเปลี่ยน-ice-candidates)
- [ขั้นตอนที่ 46: WebRTC Connection Established](#ขั้นตอนที่-46-webrtc-connection-established)

### ส่วนที่ 11: Active Call
- [ขั้นตอนที่ 47: แสดง Active Call UI](#ขั้นตอนที่-47-แสดง-active-call-ui)
- [ขั้นตอนที่ 48: Audio/Video Streaming](#ขั้นตอนที่-48-audiovideo-streaming)
- [ขั้นตอนที่ 49: Monitor Call State](#ขั้นตอนที่-49-monitor-call-state)

### ส่วนที่ 12: จบการโทร
- [ขั้นตอนที่ 50: User กด End Call](#ขั้นตอนที่-50-user-กด-end-call)
- [ขั้นตอนที่ 51: call.leave() - Disconnect](#ขั้นตอนที่-51-callleave---disconnect)
- [ขั้นตอนที่ 52: Notify Participants](#ขั้นตอนที่-52-notify-participants)
- [ขั้นตอนที่ 53: Navigate กลับ HomePage](#ขั้นตอนที่-53-navigate-กลับ-homepage)

---

# ส่วนที่ 1: เริ่มต้น Application

---

## ขั้นตอนที่ 1: เปิด App - main() function

### ไฟล์: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
```

### อธิบาย:
- **`import`**: นำเข้า package หรือ library เพื่อใช้งาน
- **`package:flutter/material.dart`**:
  - Material Design widgets จาก Flutter framework
  - มี widgets พื้นฐาน เช่น `Text`, `Button`, `Scaffold`, `MaterialApp`
  - ต้อง import ทุกไฟล์ที่ใช้ Flutter widgets

---

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
```

### อธิบาย:
- **Firebase Cloud Messaging (FCM) package**
- ใช้สำหรับ:
  - รับ push notifications
  - Get FCM token
  - Handle foreground/background messages
- Version: `firebase_messaging: ^15.2.0` (จาก pubspec.yaml)

---

```dart
import 'package:stream_video_flutter/stream_video_flutter.dart';
```

### อธิบาย:
- **Stream Video Flutter SDK**
- ใช้สำหรับ:
  - Video/Audio calling
  - WebRTC connection
  - Push notification integration
  - Call management
- Version: `stream_video_flutter: ^1.5.1`

---

```dart
import 'app.dart';
import 'app_initializer.dart';
import 'firebase_background_handler.dart';
import 'tutorial_user.dart';
```

### อธิบาย:
- **Import ไฟล์ local** (ไฟล์ในโปรเจคเรา)
- **`app.dart`**: MyApp widget (main app widget)
- **`app_initializer.dart`**: Initialize Stream client
- **`firebase_background_handler.dart`**: Background notification handler
- **`tutorial_user.dart`**: User data (for manual auth mode)

---

```dart
Future<void> main() async {
```

### อธิบาย:
- **`main()`**: Entry point ของ Flutter app
  - Dart compiler เริ่มรันที่นี่
  - ทุก app ต้องมี `main()` function

- **`Future<void>`**:
  - `Future` = asynchronous operation (ทำงานแบบไม่ blocking)
  - `void` = ไม่ return ค่า
  - ต้องเป็น `Future` เพราะมี async operations (Firebase init)

- **`async`**:
  - ทำให้ function เป็น asynchronous
  - สามารถใช้ `await` ได้ภายใน function

**ตัวอย่างความต่าง:**
```dart
// Synchronous (blocking):
void main() {
  print('1');
  print('2');  // รอให้ 1 เสร็จก่อน
  print('3');  // รอให้ 2 เสร็จก่อน
}

// Asynchronous (non-blocking):
Future<void> main() async {
  print('1');
  await someAsyncOperation();  // รอให้เสร็จก่อนทำต่อ
  print('2');
}
```

---

```dart
  WidgetsFlutterBinding.ensureInitialized();
```

### อธิบาย:
- **ทำอะไร:**
  - Initialize Flutter engine
  - Setup binding ระหว่าง Flutter framework ↔ Native platform (Android/iOS)
  - จำเป็นก่อนใช้ native plugins ใน `main()`

- **ทำไมต้องเรียก:**
  - ปกติ `runApp()` จะเรียกให้อัตโนมัติ
  - แต่ถ้าต้องใช้ native plugins **ก่อน** `runApp()` → ต้องเรียกเอง
  - ตัวอย่าง plugins ที่ต้องเรียก:
    - `Firebase.initializeApp()`
    - `SharedPreferences.getInstance()`
    - `PathProvider.getApplicationDocumentsDirectory()`

- **Error ถ้าไม่เรียก:**
  ```
  ServicesBinding.defaultBinaryMessenger was accessed before the binding was initialized.
  ```

**Flow:**
```
WidgetsFlutterBinding.ensureInitialized()
    ↓
Binding created
    ↓
Native platform channel ready
    ↓
ใช้ native plugins ได้
```

---

```dart
  runApp(const _BootstrapApp());
}
```

### อธิบาย:

**`runApp(Widget app)`:**
- **ทำอะไร:**
  1. รับ root widget
  2. สร้าง widget tree
  3. Attach widget tree ไปที่หน้าจอ
  4. เริ่ม render UI

- **`const _BootstrapApp()`**:
  - สร้าง instance ของ `_BootstrapApp` widget
  - `const` = compile-time constant (optimize performance)
  - `_BootstrapApp` = private class (ขึ้นต้นด้วย `_`)

**Widget Tree:**
```
runApp(_BootstrapApp)
    ↓
_BootstrapApp (StatefulWidget)
    ↓
FutureBuilder (รอ initialization)
    ↓
MyApp (เมื่อ init เสร็จ)
    ↓
HomePage
```

---

## ขั้นตอนที่ 2: Bootstrap App - _BootstrapApp

```dart
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}
```

### อธิบาย:

**`StatefulWidget`:**
- Widget ที่มี state (ข้อมูลที่เปลี่ยนแปลงได้)
- เมื่อ state เปลี่ยน → rebuild UI
- ต้องมี `createState()` method

**`const _BootstrapApp()`:**
- Constructor แบบ const
- ไม่มี parameters
- `_` = private (ใช้ได้เฉพาะในไฟล์นี้)

**`createState()`:**
- สร้าง State object
- Return `_BootstrapAppState` instance
- เรียกครั้งเดียวตอนสร้าง widget

**ความต่างระหว่าง StatelessWidget vs StatefulWidget:**
```dart
// StatelessWidget (ไม่มี state):
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello');  // ไม่เปลี่ยนแปลง
  }
}

// StatefulWidget (มี state):
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int counter = 0;  // state

  @override
  Widget build(BuildContext context) {
    return Text('$counter');  // เปลี่ยนแปลงได้
  }
}
```

---

```dart
class _BootstrapAppState extends State<_BootstrapApp> {
  late Future<StreamVideo> _initFuture;
```

### อธิบาย:

**`State<_BootstrapApp>`:**
- State class สำหรับ `_BootstrapApp` widget
- มี lifecycle methods: `initState()`, `build()`, `dispose()`

**`late Future<StreamVideo> _initFuture;`:**
- **`late`**:
  - บอกว่าจะ initialize ทีหลัง (ไม่ใช่ตอนประกาศ)
  - ต้อง assign ค่าก่อนใช้
  - ถ้าใช้ก่อน assign → runtime error

- **`Future<StreamVideo>`**:
  - Async operation ที่จะ return `StreamVideo` object
  - `Future` = promise (จะได้ค่าในอนาคต)

- **`_initFuture`**:
  - Private variable (ขึ้นต้นด้วย `_`)
  - เก็บ Future ของ initialization process

**ตัวอย่างการใช้ `late`:**
```dart
// ไม่ใช้ late (error):
Future<int> myFuture;  // Error: must be initialized

// ใช้ late (OK):
late Future<int> myFuture;  // OK, จะ init ทีหลัง

// Initialize ใน initState:
@override
void initState() {
  super.initState();
  myFuture = Future.value(42);  // assign ค่า
}
```

---

```dart
  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }
```

### อธิบาย:

**`initState()`:**
- **Lifecycle method** ของ StatefulWidget
- เรียก **1 ครั้งเดียว** ตอนสร้าง State object
- ใช้สำหรับ:
  - Initialize variables
  - Subscribe to streams
  - Setup listeners
  - Start async operations

**`super.initState()`:**
- เรียก parent class's `initState()`
- **ต้องเรียกก่อน** ทำอะไร
- Dart requirement

**`_initFuture = _initialize();`:**
- เรียก `_initialize()` method
- Return `Future<StreamVideo>`
- Assign ให้ `_initFuture`

**Lifecycle order:**
```
1. Constructor (_BootstrapApp())
2. createState()
3. initState()  ← เรียกที่นี่
4. build()
5. (state changes → build() again)
6. dispose()
```

---

## ขั้นตอนที่ 3: เริ่ม Initialize - _initialize()

```dart
  Future<StreamVideo> _initialize() async {
    final currentUser = TutorialUser.user1();
```

### อธิบาย:

**`Future<StreamVideo> _initialize() async`:**
- Private method (ขึ้นต้นด้วย `_`)
- Return `Future<StreamVideo>`
- `async` = สามารถใช้ `await`

**`final currentUser = TutorialUser.user1();`:**
- **`final`**: constant reference (ไม่สามารถ reassign)
- **`TutorialUser.user1()`**: Static method
  - Return user data (userId, name, token)
  - สำหรับ manual auth mode (testing)

---

## ขั้นตอนที่ 4: Get User Data - TutorialUser

### ไฟล์: `lib/tutorial_user.dart`

```dart
class TutorialUser {
  final String apiKey;
  final String userId;
  final String name;
  final String token;

  const TutorialUser({
    required this.apiKey,
    required this.userId,
    required this.name,
    required this.token,
  });
```

### อธิบาย:

**Data class:**
- เก็บข้อมูล user
- มี 4 fields: apiKey, userId, name, token
- `final` = immutable (ไม่เปลี่ยนแปลง)
- `required` = ต้องระบุตอนสร้าง

---

```dart
  static TutorialUser user1() {
    // Check if using manual auth mode
    if (ManualAuth.enabled) {
      final selected = ManualAuth.current();
      return TutorialUser(
        apiKey: selected.apiKey,
        userId: selected.userId,
        name: selected.name,
        token: selected.token,
      );
    }
```

### อธิบาย:

**`static TutorialUser user1()`:**
- Static method = เรียกได้โดยไม่ต้องสร้าง instance
- `TutorialUser.user1()` แทน `TutorialUser().user1()`

**`ManualAuth.enabled`:**
- Check ว่าใช้ manual auth mode หรือไม่
- อ่านจาก compile-time constant:
  ```bash
  flutter run --dart-define=MANUAL_AUTH=true
  ```

**`ManualAuth.current()`:**
- Get user data จาก `dev_manual_auth.dart`
- ดึงค่า userA หรือ userB ตาม `MANUAL_AUTH_USER`

### ไฟล์: `lib/dev_manual_auth.dart`

```dart
class ManualAuth {
  static const bool enabled = bool.fromEnvironment('MANUAL_AUTH', defaultValue: false);
  static const String selected = String.fromEnvironment('MANUAL_AUTH_USER', defaultValue: 'A');

  static const ManualAuthUser userA = ManualAuthUser(
    apiKey: 'r9mn4fsbzhub',
    userId: '68da5610e8994916f01364b8',
    name: 'ຮືວ່າງ ວ່າງ',
    token: 'eyJhbGci...',
  );

  static const ManualAuthUser userB = ManualAuthUser(
    apiKey: 'r9mn4fsbzhub',
    userId: '68ad1babd03c44ef943bb6bb',
    name: 'tangiro kamado',
    token: 'eyJhbGci...',
  );

  static ManualAuthUser current() =>
      (selected.toUpperCase() == 'B') ? userB : userA;
}
```

### อธิบาย:

**`bool.fromEnvironment('MANUAL_AUTH')`:**
- อ่านค่าจาก compile-time constant
- ถ้า run ด้วย `--dart-define=MANUAL_AUTH=true` → enabled = true
- ถ้าไม่ระบุ → defaultValue = false

**`current()`:**
- ถ้า `MANUAL_AUTH_USER=B` → return userB
- ไม่งั้น → return userA

**Use case:**
```bash
# Terminal 1 (User A):
flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=A

# Terminal 2 (User B):
flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=B
```

---

กลับมาที่ `tutorial_user.dart`:

```dart
    // Otherwise, use backend mode
    const userId = '68ad1babd03c44ef943bb6bb';
    return TutorialUser(
      apiKey: kAppKeys.apiKey,
      userId: userId,
      name: 'tangiro kamado',
      token: '',  // Will fetch from backend
    );
  }
}
```

### อธิบาย:

**Backend mode:**
- ถ้าไม่ใช้ manual auth → ใช้ backend
- `token: ''` = empty (จะไป fetch จาก backend ทีหลัง)
- `kAppKeys.apiKey` = API key จาก config file

---

กลับมาที่ `main.dart`:

```dart
    try {
      final client = await AppInitializer.init(currentUser);
```

### อธิบาย:

**`try-catch` block:**
- Handle errors ที่อาจเกิดขึ้น
- ถ้า error → catch block ทำงาน

**`await AppInitializer.init(currentUser)`:**
- **`await`**: รอให้ async operation เสร็จ
- **`AppInitializer.init()`**: Initialize Stream client
- **`currentUser`**: ส่ง user data ไป

**ถ้าไม่ใช้ await:**
```dart
// ไม่ await (ผิด):
final client = AppInitializer.init(currentUser);
// client = Future<StreamVideo> (ยังไม่เสร็จ)

// ใช้ await (ถูก):
final client = await AppInitializer.init(currentUser);
// client = StreamVideo (เสร็จแล้ว)
```

---

## ขั้นตอนที่ 5: Initialize App - AppInitializer

### ไฟล์: `lib/app_initializer.dart`

```dart
class AppInitializer {
  static Future<StreamVideo> init(TutorialUser currentUser) async {
```

### อธิบาย:

**Static method:**
- เรียกได้โดยไม่ต้องสร้าง instance
- `AppInitializer.init()` แทน `AppInitializer().init()`

**Parameters:**
- `currentUser`: TutorialUser object (userId, name, token, apiKey)

---

```dart
    print('========================================');
    print('🚀 STARTING APP INITIALIZATION');
    print('User ID: ${currentUser.userId}');
    print('User Name: ${currentUser.name}');
    print('========================================');
```

### อธิบาย:

**Debug logging:**
- แสดงข้อมูลใน console
- ช่วย debug ว่าผ่านขั้นตอนไหนแล้ว
- `${variable}` = string interpolation

**Output ตัวอย่าง:**
```
========================================
🚀 STARTING APP INITIALIZATION
User ID: 68da5610e8994916f01364b8
User Name: ຮືວ່າງ ວ່າງ
========================================
```

---

## ขั้นตอนที่ 6: Initialize Firebase

```dart
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
```

### อธิบาย:

**`Firebase.initializeApp()`:**
- Initialize Firebase SDK
- **ต้องเรียกก่อน** ใช้ Firebase services
- `await` = รอให้เสร็จก่อนทำต่อ

**`DefaultFirebaseOptions.currentPlatform`:**
- เลือก Firebase config ตาม platform:
  - Android → `google-services.json`
  - iOS → `GoogleService-Info.plist`
  - Web → Firebase web config

**สิ่งที่เกิดขึ้น:**
1. อ่าน Firebase configuration
2. เชื่อมต่อ Firebase Backend
3. Setup Firebase services:
   - Firebase Messaging (FCM)
   - Firebase Analytics (ถ้าเปิด)
   - Firebase Crashlytics (ถ้าเปิด)

**Output:**
```
✅ Firebase initialized
```

---

## ขั้นตอนที่ 7: Register Background Handler

```dart
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('✅ Background message handler registered');
```

### อธิบาย:

**`FirebaseMessaging.onBackgroundMessage()`:**
- Register function สำหรับ handle background notifications
- เรียกเมื่อมี notification มาตอนแอป:
  - อยู่เบื้องหลัง (background)
  - ปิดอยู่ (terminated)

**`firebaseMessagingBackgroundHandler`:**
- Function ที่เราเขียนใน `firebase_background_handler.dart`
- ต้องเป็น **top-level function** (ไม่ใช่ method ใน class)

### ไฟล์: `lib/firebase_background_handler.dart`

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    print('========================================');
    print('🔔 BACKGROUND FCM MESSAGE RECEIVED');
    print('Message ID: ${message.messageId}');
    print('Message data: ${message.data}');
    print('========================================');
  }

  await StreamVideoPushNotificationManager.onBackgroundMessage(
    message,
    callDisplayHelper: CallDisplayHelper(),
  );
}
```

### อธิบาย:

**`@pragma('vm:entry-point')`:**
- บอก Dart compiler ว่า function นี้ถูกเรียกจาก native code
- ป้องกัน tree-shaking ลบ function นี้ทิ้ง
- **จำเป็น** สำหรับ background handlers

**`Firebase.initializeApp()`:**
- ต้อง init ใหม่เพราะ background handler รันใน **isolate แยก**
- Isolate = separate thread (ไม่ share state กับ main isolate)

**`RemoteMessage message`:**
- Object ที่มีข้อมูล notification:
  - `messageId`: ID ของ message
  - `data`: Custom data (call info)
  - `notification`: Notification payload (title, body)

**`StreamVideoPushNotificationManager.onBackgroundMessage()`:**
- Stream SDK method สำหรับจัดการ notification
- **ทำอะไร:**
  1. Parse message data
  2. Query call info จาก Stream API
  3. แสดง CallKit (iOS) / ConnectionService (Android) UI

---

## ขั้นตอนที่ 8: Request FCM Permission

```dart
    final messagingSettings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('✅ FCM permission status: ${messagingSettings.authorizationStatus}');
```

### อธิบาย:

**`FirebaseMessaging.instance.requestPermission()`:**
- ขอ permission จาก user
- แสดง popup ขอสิทธิ์

**Parameters:**
- **`alert: true`**: แสดง notification banner
- **`badge: true`**: แสดงตัวเลขบน app icon
- **`sound: true`**: เล่นเสียง notification

**Return:**
```dart
class NotificationSettings {
  AuthorizationStatus authorizationStatus;
  // granted, denied, provisional, notDetermined
}
```

**iOS Popup:**
```
"MyVideoApp" Would Like to Send You Notifications
Notifications may include alerts, sounds, and icon badges.
[Don't Allow]  [Allow]
```

**Android 13+ Popup:**
```
Allow MyVideoApp to send you notifications?
[Don't allow]  [Allow]
```

**Output ตัวอย่าง:**
```
✅ FCM permission status: AuthorizationStatus.granted
```

---

## ขั้นตอนที่ 9: Create Stream Client

```dart
    final client = createClient(
      user: User(id: currentUser.userId, name: currentUser.name),
      apiKey: currentUser.apiKey,
      userToken: currentUser.token,
    );
```

### อธิบาย:

**`createClient()` method:**
- สร้าง Stream Video client
- **Parameters:**
  - `user`: User object (id, name)
  - `apiKey`: Stream API Key
  - `userToken`: JWT token

**`User` object:**
```dart
User(
  id: '68da5610e8994916f01364b8',  // unique user ID
  name: 'ຮືວ່າງ ວ່າງ',              // display name
)
```

---

```dart
  static StreamVideo createClient({
    required User user,
    required String apiKey,
    required String userToken,
    bool attachPushManager = true,
  }) {
```

### อธิบาย:

**Named parameters:**
- `required` = ต้องระบุ
- `attachPushManager = true` = default value

---

```dart
    print('========================================');
    print('🔧 CREATING STREAM VIDEO CLIENT');
    print('User ID: ${user.id}');
    print('User Name: ${user.name}');
    print('API Key: $apiKey');
    print('Push Manager Enabled: $attachPushManager');
```

**Debug logging:**
```
========================================
🔧 CREATING STREAM VIDEO CLIENT
User ID: 68da5610e8994916f01364b8
User Name: ຮືວ່າງ ວ່າງ
API Key: r9mn4fsbzhub
Push Manager Enabled: true
========================================
```

---

## ขั้นตอนที่ 10: Setup Push Notification Manager

```dart
    final client = StreamVideo(
      apiKey,
      user: user,
      userToken: userToken,
      pushNotificationManagerProvider: attachPushManager
          ? StreamVideoPushNotificationManager.create(
              androidPushProvider: const StreamVideoPushProvider.firebase(
                name: 'niwner_notification',
              ),
              iosPushProvider: const StreamVideoPushProvider.apn(
                name: 'niwner_notification',
              ),
              onNotificationResponse: (remoteMessage, call) async {
                debugPrint('🔔 Notification tapped! Call ID: ${call.cid}');
                return NavigationResult.proceed;
              },
            )
          : null,
    );
```

### อธิบาย:

**`StreamVideo` Constructor:**
- สร้าง Stream Video client instance

**Parameters:**

1. **`apiKey`**:
   - `"r9mn4fsbzhub"`
   - ระบุว่าเป็น app ไหน

2. **`user`**:
   - User object
   - ระบุตัวตนของ user ปัจจุบัน

3. **`userToken`**:
   - JWT token
   - ใช้ authenticate กับ Stream API

4. **`pushNotificationManagerProvider`**:
   - **ถ้า `attachPushManager = true`**: สร้าง push manager
   - **ถ้า `false`**: `null` (ไม่มี push notifications)

---

### Push Notification Manager:

```dart
StreamVideoPushNotificationManager.create(
  androidPushProvider: const StreamVideoPushProvider.firebase(
    name: 'niwner_notification',
  ),
  iosPushProvider: const StreamVideoPushProvider.apn(
    name: 'niwner_notification',
  ),
  onNotificationResponse: (remoteMessage, call) async {
    debugPrint('🔔 Notification tapped!');
    return NavigationResult.proceed;
  },
)
```

### อธิบาย:

**`StreamVideoPushNotificationManager.create()`:**
- สร้าง push notification manager
- **ทำอะไร:**
  1. Get FCM Token (Android) / APNs Token (iOS)
  2. Register token กับ Stream Backend
  3. Listen for incoming notifications
  4. Handle notification taps

---

**`androidPushProvider`:**
```dart
StreamVideoPushProvider.firebase(
  name: 'niwner_notification',
)
```

- **Type**: Firebase Cloud Messaging (FCM)
- **`name`**: Push provider name
  - **ต้องตรงกับ** ที่ config ใน Stream Dashboard
  - Stream ใช้ name นี้หา FCM Server Key

**ทำไม name ต้องตรง:**
```
Flutter App:
  androidPushProvider: name = 'niwner_notification'
       ↓ register FCM token
Stream Backend:
  Save token with provider name = 'niwner_notification'
       ↓ when incoming call
Stream Backend:
  Query: "Get provider named 'niwner_notification'"
  Get FCM Server Key from that provider
       ↓ send push
Firebase:
  Use that Server Key to send notification
```

---

**`iosPushProvider`:**
```dart
StreamVideoPushProvider.apn(
  name: 'niwner_notification',
)
```

- **Type**: Apple Push Notification service (APNs)
- **`name`**: ต้องตรงกับ Stream Dashboard

---

**`onNotificationResponse`:**
```dart
(remoteMessage, call) async {
  debugPrint('🔔 Notification tapped! Call ID: ${call.cid}');
  return NavigationResult.proceed;
}
```

- **Callback** เมื่อ user กด notification
- **Parameters:**
  - `remoteMessage`: FCM message data
  - `call`: Call object ที่สร้างจาก message

- **Return:**
  - `NavigationResult.proceed`: ให้ SDK เปิด call screen
  - `NavigationResult.cancel`: ยกเลิก (ไม่เปิด)

---

## ขั้นตอนที่ 11: Connect to Stream Backend

```dart
    client.connect().then((_) {
      print('========================================');
      print('✅ STREAM VIDEO CLIENT CONNECTED');
      print('WebSocket: Connected');
      print('User Status: Online');
      print('========================================');
    }).catchError((error) {
      print('========================================');
      print('❌ STREAM VIDEO CONNECTION ERROR');
      print('Error: $error');
      print('========================================');
      print('🔧 Troubleshooting:');
      print('1. Check internet connection');
      print('2. Verify token is valid');
      print('3. Check API Key: $apiKey');
      print('========================================');
    });
```

### อธิบาย:

**`client.connect()`:**
- เชื่อมต่อกับ Stream Backend
- **Return**: `Future<void>`

**สิ่งที่เกิดขึ้น:**

### 1. Validate Token

**HTTP Request:**
```http
POST https://video.stream-io-api.com/api/v2/connect
Authorization: eyJhbGc...
Stream-Auth-Type: jwt
```

**Stream Backend:**
1. Decode JWT token
2. Verify signature ด้วย STREAM_API_SECRET
3. Check expiration (exp > now)
4. Extract user_id

**ถ้า valid → Continue**
**ถ้า invalid → Error: "Token signature is invalid"**

---

### 2. Open WebSocket Connection

```
Flutter App ↔ Stream Backend
WebSocket: wss://video.stream-io-api.com/ws
```

**ทำไมใช้ WebSocket:**
- Real-time communication
- Bi-directional
- Low latency
- Receive events ทันที (incoming calls, state changes)

---

ต้องการให้ฉันเขียนต่อจนครบทุกขั้นตอนไหมครับ? ตอนนี้อธิบายไปแล้ว 11 ขั้นตอนจากทั้งหมด 53 ขั้นตอน

ยังเหลืออีก:
- ขั้นตอนที่ 12-16: Register FCM Token, แสดง UI
- ขั้นตอนที่ 17-23: การโทรออก (User A)
- ขั้นตอนที่ 24-30: Stream Backend + Firebase
- ขั้นตอนที่ 31-39: การรับสาย (User B)
- ขั้นตอนที่ 40-46: WebRTC Setup
- ขั้นตอนที่ 47-53: Active Call และ End Call

ต้องการให้เขียนต่อเลยหรือแบ่งเป็นหลายไฟล์ครับ?
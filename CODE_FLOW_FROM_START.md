# 🚀 อธิบายโค้ดตั้งแต่เริ่มต้น App

## สารบัญ
1. [STEP 1: เปิด App - main() function](#step-1-เปิด-app---main-function)
2. [STEP 2: Initialize Firebase](#step-2-initialize-firebase)
3. [STEP 3: Register Background Handler](#step-3-register-background-handler)
4. [STEP 4: Request Notification Permission](#step-4-request-notification-permission)
5. [STEP 5: แสดง LoginPage](#step-5-แสดง-loginpage)
6. [STEP 6: User กรอก Login → เรียก Backend](#step-6-user-กรอก-login--เรียก-backend)
7. [STEP 7: Backend Generate Token](#step-7-backend-generate-token)
8. [STEP 8: Initialize StreamVideo Client](#step-8-initialize-streamvideo-client)
9. [STEP 9: Register FCM Token กับ Stream](#step-9-register-fcm-token-กับ-stream)
10. [STEP 10: Navigate ไป HomePage](#step-10-navigate-ไป-homepage)
11. [STEP 11: Listen for Incoming Calls](#step-11-listen-for-incoming-calls)
12. [STEP 12: User A โทรหา User B](#step-12-user-a-โทรหา-user-b)
13. [STEP 13: Stream ส่ง Push Notification](#step-13-stream-ส่ง-push-notification)
14. [STEP 14: User B รับ Notification](#step-14-user-b-รับ-notification)
15. [STEP 15: User B กด Accept](#step-15-user-b-กด-accept)
16. [STEP 16: WebRTC Connection Setup](#step-16-webrtc-connection-setup)
17. [STEP 17: Active Call - Video/Audio Streaming](#step-17-active-call---videoaudio-streaming)
18. [STEP 18: End Call](#step-18-end-call)

---

# STEP 1: เปิด App - main() function

## ไฟล์: `lib/main.dart`

```dart
void main() async {
```

### อธิบาย:
- **`void main()`**: Entry point ของ Flutter app
  - Dart compiler จะเริ่มรันที่นี่เป็นที่แรก
  - ทุก Flutter app ต้องมี `main()` function

- **`async`**: ทำให้ function นี้เป็น asynchronous
  - สามารถใช้ `await` ได้
  - จำเป็นเพราะต้อง initialize Firebase (ซึ่งเป็น async operation)

---

```dart
  WidgetsFlutterBinding.ensureInitialized();
```

### อธิบาย:
- **ทำอะไร:**
  - Initialize Flutter engine
  - Setup communication channel ระหว่าง Flutter framework กับ native platform (Android/iOS)

- **ทำไมต้องเรียก:**
  - ปกติ `runApp()` จะเรียกให้อัตโนมัติ
  - แต่ถ้าต้องใช้ native plugins **ก่อน** `runApp()` (เช่น Firebase) → ต้องเรียกเอง
  - ป้องกัน error: "ServicesBinding.defaultBinaryMessenger was accessed before the binding was initialized"

- **เมื่อไหร่ต้องเรียก:**
  - เรียก `await Firebase.initializeApp()` ก่อน `runApp()`
  - ใช้ `SharedPreferences`, `PathProvider`, หรือ native plugin อื่นๆ ก่อน `runApp()`

---

# STEP 2: Initialize Firebase

```dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
```

### อธิบาย:

**`Firebase.initializeApp()`:**
- **ทำอะไร:**
  1. อ่าน Firebase configuration (API keys, project IDs)
  2. เชื่อมต่อกับ Firebase services
  3. Setup Firebase SDK

- **`options: DefaultFirebaseOptions.currentPlatform`:**
  - เลือก Firebase config ตาม platform ที่รัน
  - ข้อมูลมาจาก `lib/firebase_options.dart`

**`DefaultFirebaseOptions.currentPlatform` ทำงานยังไง:**

```dart
static FirebaseOptions get currentPlatform {
  if (kIsWeb) {
    return web;  // ถ้ารันบน web browser
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return android;  // ถ้ารันบน Android
    case TargetPlatform.iOS:
      return ios;  // ถ้ารันบน iOS
    default:
      throw UnsupportedError('Unsupported platform');
  }
}
```

**ตัวอย่าง `FirebaseOptions.android`:**
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyC...',               // จาก google-services.json
  appId: '1:564591146605:android:...', // App ID
  messagingSenderId: '564591146605',   // FCM Sender ID
  projectId: 'notificationforlailaolab', // Firebase Project ID
  storageBucket: 'notificationforlailaolab.appspot.com',
);
```

**สิ่งที่เกิดขึ้นภายใน:**
1. Firebase SDK อ่าน config
2. เชื่อมต่อไปที่ Firebase Backend
3. Verify project credentials
4. Setup Firebase services:
   - Firebase Messaging (FCM)
   - Firebase Analytics (ถ้าเปิด)
   - Firebase Crashlytics (ถ้าเปิด)

**Output:**
- Firebase พร้อมใช้งาน
- `FirebaseMessaging.instance` สามารถเรียกได้

---

# STEP 3: Register Background Handler

```dart
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```

### อธิบาย:

**`FirebaseMessaging.onBackgroundMessage()`:**
- **ทำอะไร:**
  - Register function ที่จะทำงานเมื่อมี push notification มาตอนแอปอยู่ background/terminated

- **`firebaseMessagingBackgroundHandler`:**
  - Function ที่เราเขียนไว้ใน `lib/firebase_background_handler.dart`
  - ต้องเป็น **top-level function** (ไม่ใช่ method ใน class)
  - ต้องมี `@pragma('vm:entry-point')`

**ทำไมต้อง register:**
- เมื่อแอปไม่ได้เปิดอยู่ → notification ไม่สามารถส่งไปที่ main isolate ได้
- ต้องมี special handler ที่รันใน background isolate
- Handler นี้จะ:
  1. รับ notification data
  2. แสดง CallKit/ConnectionService UI
  3. Wake up แอป (ถ้าจำเป็น)

**Flow เมื่อมี notification:**

```
App State: Background/Terminated
          ↓
Firebase Cloud Messaging
          ↓
Native OS (Android/iOS)
          ↓
Flutter Background Isolate
          ↓
firebaseMessagingBackgroundHandler()
          ↓
StreamVideoPushNotificationManager.onBackgroundMessage()
          ↓
แสดง CallKit/ConnectionService UI
```

---

# STEP 4: Request Notification Permission

```dart
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
```

### อธิบาย:

**`requestPermission()`:**
- **ทำอะไร:**
  - แสดง popup ขอ permission จาก user
  - iOS: แสดงทุกครั้งที่เรียก (ครั้งแรก)
  - Android 13+: แสดงทุกครั้งที่เรียก (ครั้งแรก)
  - Android 12-: Auto granted (ไม่ต้องขอ)

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

**ตัวอย่าง:**
```dart
final settings = await FirebaseMessaging.instance.requestPermission(...);

if (settings.authorizationStatus == AuthorizationStatus.granted) {
  print('✅ User granted permission');
} else if (settings.authorizationStatus == AuthorizationStatus.denied) {
  print('❌ User denied permission');
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

---

```dart
  runApp(const MyApp());
}
```

### อธิบาย:

**`runApp()`:**
- **ทำอะไร:**
  1. สร้าง widget tree
  2. Attach ไปที่ screen
  3. เริ่ม render UI

- **`const MyApp()`**:
  - Root widget ของ app
  - เป็น `StatelessWidget` หรือ `StatefulWidget`

**สิ่งที่เกิดขึ้น:**
```
runApp(MyApp)
    ↓
MyApp.build()
    ↓
MaterialApp(home: LoginPage())
    ↓
LoginPage widget แสดงบนหน้าจอ
```

---

# STEP 5: แสดง LoginPage

## ไฟล์: `lib/main.dart`

```dart
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
      home: const LoginPage(),  // ← หน้าแรกที่แสดง
    );
  }
}
```

### อธิบาย:

**`MaterialApp`:**
- Root widget สำหรับ Material Design app
- กำหนด:
  - **`title`**: ชื่อ app (แสดงใน task switcher)
  - **`theme`**: ธีมของ app (สี, font, etc.)
  - **`home`**: หน้าแรกที่แสดง

**`home: const LoginPage()`:**
- แสดง `LoginPage` เป็นหน้าแรก
- `const`: compile-time constant (performance optimization)

**Output:**
- หน้าจอแสดง LoginPage
- User เห็น text fields สำหรับกรอก User ID และ Name

---

# STEP 6: User กรอก Login → เรียก Backend

## ไฟล์: `lib/pages/login_page.dart`

```dart
class _LoginPageState extends State<LoginPage> {
  final _userIdController = TextEditingController();
  final _userNameController = TextEditingController();
```

### อธิบาย:

**`TextEditingController`:**
- ควบคุม text field
- เก็บค่าที่ user พิมพ์
- สามารถอ่านค่าด้วย `controller.text`

**ทำไมต้องใช้:**
```dart
// ไม่ใช้ controller (ไม่แนะนำ)
TextField(
  onChanged: (value) {
    userId = value;  // ต้องเก็บ state เอง
  },
)

// ใช้ controller (แนะนำ)
TextField(
  controller: _userIdController,
)
// อ่านค่า: _userIdController.text
```

---

### User กด "Login" button:

```dart
Future<void> _login() async {
  final userId = _userIdController.text.trim();
  final userName = _userNameController.text.trim();
```

**`.trim()`:**
- ตัด whitespace หน้า-หลัง
- `"  user123  "` → `"user123"`

---

```dart
  if (userId.isEmpty || userName.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter user ID and name')),
    );
    return;
  }
```

### อธิบาย:

**Validation:**
- เช็คว่า user กรอกข้อมูลหรือไม่
- ถ้าไม่กรอก → แสดง Snackbar (popup ข้อความล่างหน้าจอ)

**`ScaffoldMessenger.of(context)`:**
- ใช้แสดง Snackbar, SnackBars queue
- `of(context)` = หา `ScaffoldMessenger` จาก widget tree

---

```dart
  setState(() => _isLoading = true);
```

### อธิบาย:

**`setState()`:**
- บอก Flutter ว่า state เปลี่ยน → rebuild UI
- `_isLoading = true` → แสดง loading indicator แทนปุ่ม

**UI เปลี่ยน:**
```dart
_isLoading
    ? CircularProgressIndicator()  // แสดง loading
    : ElevatedButton(...)           // แสดงปุ่ม
```

---

```dart
  try {
    final response = await http.post(
      Uri.parse('http://localhost:8181/v1/api/callStreams'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
```

### อธิบาย:

**`http.post()`:**
- ส่ง HTTP POST request

**Parameters:**

1. **`Uri.parse(url)`:**
   - แปลง string เป็น Uri object
   - `http://localhost:8181/v1/api/callStreams`

2. **`headers`:**
   ```dart
   {'Content-Type': 'application/json'}
   ```
   - บอก server ว่าเราส่ง JSON

3. **`body`:**
   ```dart
   jsonEncode({'userId': userId})
   ```
   - แปลง Map → JSON string
   - `{'userId': 'user-123'}` → `'{"userId":"user-123"}'`

**Request ที่ส่งไป:**
```http
POST http://localhost:8181/v1/api/callStreams
Content-Type: application/json

{"userId":"user-123"}
```

---

# STEP 7: Backend Generate Token

## ไฟล์: `backend/src/controllers/streamController.ts`

### Backend รับ request:

```typescript
export const generateStreamToken = (req: any, res: any) => {
  const userId = req.body?.userId;
```

**อ่านค่า:**
- `req.body` = request body ที่ Flutter app ส่งมา
- `req.body.userId` = `"user-123"`

---

```typescript
  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }
```

**Validation:**
- เช็คว่ามี userId หรือไม่
- ถ้าไม่มี → return error 400 (Bad Request)

---

```typescript
  const issuedAt = Math.floor(Date.now() / 1000);
  const expiresAt = issuedAt + TOKEN_TTL;
```

**สร้าง timestamp:**
```javascript
Date.now() = 1759900000000  // milliseconds
  ↓ / 1000
1759900000  // seconds (JWT ใช้ seconds)
  ↓ + TOKEN_TTL (86400 = 24 hours)
1759986400  // expiration timestamp
```

---

```typescript
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
```

**สร้าง JWT Token:**

**Input:**
- **Payload:** `{ user_id: "user-123", iat: 1759900000, exp: 1759986400 }`
- **Secret:** `STREAM_API_SECRET` (จาก .env)
- **Algorithm:** HS256

**Process:**
```
1. Encode Header:
   {"alg":"HS256","typ":"JWT"}
   → Base64 → "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"

2. Encode Payload:
   {"user_id":"user-123","iat":1759900000,"exp":1759986400}
   → Base64 → "eyJ1c2VyX2lkIjoidXNlci0xMjMiLCJpYXQiOjE3NTk5MDAwMDAsImV4cCI6MTc1OTk4NjQwMH0"

3. Create Signature:
   HMACSHA256(
     "eyJhbGc...JWT" + "." + "eyJ1c2V...",
     STREAM_API_SECRET
   )
   → "nUk_CXHHmp6HICwoPyHm0Ag2jQqmcdVMPuMBmXOK0-0"

4. Combine:
   Header.Payload.Signature
```

**Output:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidXNlci0xMjMiLCJpYXQiOjE3NTk5MDAwMDAsImV4cCI6MTc1OTk4NjQwMH0.nUk_CXHHmp6HICwoPyHm0Ag2jQqmcdVMPuMBmXOK0-0
```

---

```typescript
  return res.json({
    apiKey: STREAM_API_KEY,
    userId: userId,
    token: token,
    expiresAt: expiresAt,
  });
}
```

**ส่ง response กลับไป Flutter:**
```json
{
  "apiKey": "r9mn4fsbzhub",
  "userId": "user-123",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": 1759986400
}
```

---

# กลับไปที่ Flutter App

## ไฟล์: `lib/pages/login_page.dart`

```dart
    if (response.statusCode != 200) {
      throw Exception('Failed to get token');
    }
```

**เช็ค response:**
- Status 200 = success
- อื่นๆ = error

---

```dart
    final data = jsonDecode(response.body);
```

**แปลง JSON → Map:**
```dart
// response.body (String):
'{"apiKey":"r9mn4fsbzhub","userId":"user-123","token":"eyJ..."}'

// jsonDecode() ↓

// data (Map):
{
  'apiKey': 'r9mn4fsbzhub',
  'userId': 'user-123',
  'token': 'eyJ...',
  'expiresAt': 1759986400
}
```

---

```dart
    final apiKey = data['apiKey'];
    final token = data['token'];
```

**ดึงค่าจาก Map:**
- `data['apiKey']` → `"r9mn4fsbzhub"`
- `data['token']` → `"eyJ..."`

---

# STEP 8: Initialize StreamVideo Client

```dart
    await StreamService.initialize(
      apiKey: apiKey,
      userId: userId,
      userName: userName,
      userToken: token,
    );
```

## ไฟล์: `lib/services/stream_service.dart`

```dart
static Future<StreamVideo> initialize({
  required String apiKey,
  required String userId,
  required String userName,
  required String userToken,
}) async {
```

**ได้รับค่า:**
- `apiKey`: `"r9mn4fsbzhub"`
- `userId`: `"user-123"`
- `userName`: `"Alice"`
- `userToken`: `"eyJ..."`

---

```dart
  if (_client != null) {
    return _client!;
  }
```

**เช็ค singleton:**
- ถ้า init แล้ว → return client เดิม
- ป้องกันสร้างหลายตัว

---

```dart
  final user = User(id: userId, name: userName);
```

**สร้าง User object:**
```dart
User(
  id: 'user-123',
  name: 'Alice',
  // role, image, extraData (optional)
)
```

**User object ใช้ทำอะไร:**
- ระบุตัวตนของ user ปัจจุบัน
- แสดงชื่อใน UI
- ใช้ใน call logs

---

```dart
  _client = StreamVideo(
    apiKey,
    user: user,
    userToken: userToken,
    pushNotificationManagerProvider: StreamVideoPushNotificationManager.create(
      androidPushProvider: const StreamVideoPushProvider.firebase(
        name: 'niwner_notification',
      ),
      iosPushProvider: const StreamVideoPushProvider.apn(
        name: 'niwner_notification',
      ),
    ),
  );
```

**สร้าง StreamVideo client:**

**Parameters:**
1. **`apiKey`**: `"r9mn4fsbzhub"` - ระบุว่าเป็น app ไหน
2. **`user`**: User object - ระบุตัวตน
3. **`userToken`**: JWT token - ใช้ authenticate

4. **`pushNotificationManagerProvider`**:
   - จัดการ push notifications
   - Register FCM/APNs token
   - Handle incoming notifications

**`StreamVideoPushProvider.firebase(name: 'niwner_notification')`:**
- บอกว่าใช้ Firebase FCM
- `name` ต้องตรงกับ Push Provider ใน Stream Dashboard

---

# STEP 9: Register FCM Token กับ Stream

```dart
  await _client!.connect();
```

**`connect()` ทำอะไรบ้าง:**

### 9.1 Validate Token
```
Flutter App → Stream Backend
POST https://video.stream-io-api.com/api/v2/connect
Authorization: eyJhbGc... (JWT Token)

Stream Backend:
1. Decode JWT
2. Verify signature with STREAM_API_SECRET
3. Check expiration (exp > now)
4. Extract user_id

ถ้า valid → Continue
ถ้า invalid → Return error: "Token signature is invalid"
```

---

### 9.2 Open WebSocket Connection
```
Flutter App ↔ Stream Backend
WebSocket: wss://video.stream-io-api.com/ws

Purpose:
- Real-time events (incoming calls, call state changes)
- Bi-directional communication
- Low latency
```

---

### 9.3 Get FCM Token

```dart
// Inside StreamVideoPushNotificationManager:
final fcmToken = await FirebaseMessaging.instance.getToken();
print('FCM Token: $fcmToken');
```

**FCM Token:**
```
dFp8HxN-QkG7RzVQX-fPQW:APA91bFj3P9xKLm8Rq0S...
```
- ยาวประมาณ 163 characters
- Unique สำหรับแต่ละ device
- ใช้ระบุ device เวลาส่ง push notification

---

### 9.4 Register Token กับ Stream

```
Flutter App → Stream Backend
POST https://video.stream-io-api.com/api/v2/devices
Authorization: eyJhbGc...
Content-Type: application/json

{
  "id": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",
  "push_provider": "firebase",
  "push_provider_name": "niwner_notification",
  "user_id": "user-123"
}
```

**Stream Backend บันทึก:**
```
Database:
users {
  user_id: "user-123",
  devices: [
    {
      token: "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",
      provider: "niwner_notification",
      platform: "android",
      registered_at: "2025-02-07T10:30:00Z"
    }
  ]
}
```

**ทำไมต้อง register:**
- Stream ต้องรู้ว่าจะส่ง notification ไปที่ไหน
- เก็บ mapping: user_id → FCM token
- เมื่อมีคนโทรหา user-123 → Stream query token → ส่ง push

---

### 9.5 Sync User State

```
Stream Backend → Flutter App
Event: user.connected

{
  "type": "user.connected",
  "user": {
    "id": "user-123",
    "name": "Alice",
    "online": true
  },
  "connection_id": "abc-def-123"
}
```

---

**`connect()` สำเร็จ:**
```dart
print('✅ Stream Video connected');
```

**Output:**
- WebSocket connection established
- FCM token registered
- User status: online
- Ready to make/receive calls

---

# STEP 10: Navigate ไป HomePage

```dart
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
```

### อธิบาย:

**`mounted`:**
- เช็คว่า widget ยังอยู่ใน widget tree หรือไม่
- ถ้า user กด back ก่อน async operation เสร็จ → mounted = false
- ป้องกัน error: "setState() called after dispose()"

**`Navigator.pushReplacement()`:**
- Replace หน้าปัจจุบัน (LoginPage) ด้วยหน้าใหม่ (HomePage)
- User กด back จะไม่กลับไป LoginPage
- ต่างจาก `Navigator.push()` ที่ stack หน้า

**Flow:**
```
[LoginPage]
    ↓ pushReplacement
[HomePage]  ← กด back จะออก app
```

---

# STEP 11: Listen for Incoming Calls

## ไฟล์: `lib/pages/home_page.dart`

```dart
class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _observeIncomingCalls();
  }
```

### อธิบาย:

**`initState()`:**
- เรียกครั้งเดียวตอนสร้าง widget
- ใช้ setup listeners, controllers, etc.
- เหมาะสำหรับ subscribe streams

---

```dart
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
```

### อธิบาย:

**`state.incomingCall`:**
- **Type:** `ValueStream<Call?>`
- **คือ:** Stream ที่ emit ค่าเมื่อมี incoming call
- **ค่าที่ emit:**
  - มี incoming call → `Call` object
  - ไม่มี call → `null`

**`.listen((call) { ... })`:**
- Subscribe to stream
- Callback ทำงานเมื่อมีค่าใหม่

**Flow:**
```
1. มี notification เข้ามา
   ↓
2. Stream SDK parse message
   ↓
3. สร้าง Call object
   ↓
4. อัพเดต incomingCall stream
   ↓
5. Listener ทำงาน
   ↓
6. เปิด CallPage
```

**State:**
```dart
// Before incoming call:
incomingCall.value = null

// After incoming call:
incomingCall.value = Call(
  id: '11d3e2b5-...',
  type: 'default',
  createdBy: User(id: 'user-a', name: 'Alice'),
  members: ['user-a', 'user-b'],
  status: CallStatus.ringing,
)
```

---

**หน้าจอ HomePage:**

```dart
Widget build(BuildContext context) {
  final currentUser = StreamService.client.currentUser;

  return Scaffold(
    appBar: AppBar(
      title: Text('Hello, ${currentUser.name}'),
    ),
    body: Column(
      children: [
        Text('Your ID: ${currentUser.id}'),
        TextField(
          controller: _calleeIdController,
          decoration: InputDecoration(
            labelText: 'Callee User ID',
          ),
        ),
        ElevatedButton(
          onPressed: () => _startCall(isVideoCall: true),
          child: Text('Video Call'),
        ),
      ],
    ),
  );
}
```

**User เห็น:**
```
┌──────────────────────────────┐
│ Hello, Alice                 │
├──────────────────────────────┤
│ Your ID: user-123            │
│                              │
│ Callee User ID               │
│ [_________________]          │
│                              │
│ [🎥 Video Call]              │
└──────────────────────────────┘
```

---

# STEP 12: User A โทรหา User B

## User A กรอก User B ID และกดปุ่ม "Video Call"

```dart
Future<void> _startCall({required bool isVideoCall}) async {
  final calleeId = _calleeIdController.text.trim();
```

**อ่านค่า:**
- `calleeId` = `"user-b"` (ที่ user A กรอก)

---

```dart
  if (calleeId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter callee ID')),
    );
    return;
  }
```

**Validation:**
- เช็คว่ากรอก callee ID หรือไม่
- ถ้าไม่กรอก → แสดง error message

---

```dart
  final callId = const Uuid().v4();
```

**สร้าง Call ID:**
```
Uuid().v4() = "11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5"
```
- Format: UUID version 4 (random)
- Unique globally

---

```dart
  final call = StreamService.client.makeCall(
    callType: StreamCallType.defaultType(),
    id: callId,
  );
```

**สร้าง Call object:**

**`makeCall()` ทำอะไร:**
- สร้าง local `Call` instance
- **ยังไม่ได้สร้างใน server**
- เตรียม call configuration

**Parameters:**
- **`callType`**: `StreamCallType.defaultType()` → `"default"`
- **`id`**: `"11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5"`

**Return:**
```dart
Call(
  id: '11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5',
  type: 'default',
  client: StreamVideo(...),
  // state, methods
)
```

---

```dart
  await call.getOrCreate(
    memberIds: [calleeId],
    ringing: true,
  );
```

**สร้าง call ใน Stream Backend:**

### HTTP Request:

```http
POST https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5
Authorization: eyJhbGc... (User A Token)
Stream-Auth-Type: jwt
Content-Type: application/json

{
  "members": [
    {"user_id": "user-a"},
    {"user_id": "user-b"}
  ],
  "ring": true,
  "data": {
    "created_by_id": "user-a"
  }
}
```

**Query Parameters:**
- **Path:** `call/default/11d3e2b5-...`
  - `default` = call type
  - `11d3e2b5-...` = call ID

**Body:**
- **`members`**: รายชื่อ user IDs
  - Auto add creator (user-a)
  - เพิ่ม calleeId (user-b)
- **`ring: true`**: ✅ **สำคัญมาก!** → ส่ง push notification

---

### Stream Backend ทำอะไร:

**1. Validate:**
- เช็ค JWT token
- เช็ค user มีสิทธิ์สร้าง call หรือไม่
- เช็ค members ทุกคนมีอยู่จริง

**2. Create Call:**
```sql
-- Pseudo-code
INSERT INTO calls (
  id, type, created_by, created_at, status
) VALUES (
  '11d3e2b5-...', 'default', 'user-a', NOW(), 'ringing'
);

INSERT INTO call_members (call_id, user_id, role) VALUES
  ('11d3e2b5-...', 'user-a', 'admin'),
  ('11d3e2b5-...', 'user-b', 'user');
```

**3. Response:**
```json
{
  "call": {
    "id": "11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
    "type": "default",
    "cid": "default:11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
    "created_by": {
      "id": "user-a",
      "name": "Alice"
    },
    "created_at": "2025-02-07T10:35:00.000Z",
    "status": "ringing"
  },
  "members": [
    {"user_id": "user-a", "role": "admin"},
    {"user_id": "user-b", "role": "user"}
  ]
}
```

---

```dart
  await call.ring();
```

**ส่ง ring signal:**

### HTTP Request:

```http
POST https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5/ring
Authorization: eyJhbGc...
Stream-Auth-Type: jwt

{"ring": true}
```

**Stream Backend:**
1. อัพเดต call status → `ringing`
2. Trigger push notification workflow
3. Set ringing timeout (default: 45 seconds)

---

```dart
  print('✅ Call ring notification sent');

  if (mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(call: call, isOutgoing: true),
      ),
    );
  }
```

**เปิดหน้า CallPage:**
- User A เห็นหน้า "Calling user-b..."
- รอ User B รับสาย

---

# STEP 13: Stream ส่ง Push Notification

## Stream Backend Workflow:

### 13.1 Query User B Devices

```sql
-- Pseudo-code
SELECT * FROM devices
WHERE user_id = 'user-b'
AND push_provider_name = 'niwner_notification';
```

**Result:**
```json
{
  "devices": [
    {
      "id": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",
      "push_provider": "firebase",
      "push_provider_name": "niwner_notification",
      "platform": "android",
      "user_id": "user-b"
    }
  ]
}
```

**ถ้าไม่เจอ:**
- User B ยังไม่ได้ login
- FCM token ไม่ได้ register
- **ผลลัพธ์:** ไม่ส่ง notification (User B ไม่รับสาย)

---

### 13.2 Get Push Provider Configuration

```sql
-- Pseudo-code
SELECT * FROM push_providers
WHERE name = 'niwner_notification';
```

**Result:**
```json
{
  "name": "niwner_notification",
  "type": "firebase",
  "fcm_server_key": "AAAA...[Server Key from Dashboard]",
  "status": "active"
}
```

**ถ้าไม่เจอ หรือ status != active:**
- Push provider ไม่ได้ config
- **ผลลัพธ์:** ไม่ส่ง notification

---

### 13.3 สร้าง Notification Payload

```json
{
  "to": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",
  "priority": "high",
  "data": {
    "stream_call_cid": "default:11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
    "stream_call_id": "11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
    "stream_call_type": "default",
    "call_type": "call.ring",
    "created_by_id": "user-a",
    "created_by_name": "Alice",
    "receiver_id": "user-b",
    "sender": "stream_video"
  },
  "android": {
    "priority": "high",
    "ttl": "45s"
  },
  "apns": {
    "headers": {
      "apns-priority": "10",
      "apns-expiration": "45"
    },
    "payload": {
      "aps": {
        "alert": {
          "title": "Incoming Call",
          "body": "Alice is calling..."
        },
        "sound": "default",
        "category": "call"
      }
    }
  }
}
```

---

### 13.4 ส่งไปยัง Firebase FCM

```http
POST https://fcm.googleapis.com/fcm/send
Authorization: key=AAAA[FCM_SERVER_KEY]
Content-Type: application/json

{
  "to": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",
  "priority": "high",
  "data": { ... }
}
```

**Firebase Response:**
```json
{
  "multicast_id": 1234567890123456789,
  "success": 1,
  "failure": 0,
  "results": [
    {
      "message_id": "0:1234567890123456%abc123"
    }
  ]
}
```

**`success: 1`:**
- ส่งสำเร็จ
- Firebase จะส่งต่อไปยัง User B device

**`failure: 1`:**
- FCM Token invalid/expired
- Device offline นานเกินไป
- User uninstalled app

---

# STEP 14: User B รับ Notification

## กรณีที่ 1: User B แอปเปิดอยู่ (Foreground)

### ไฟล์: `lib/pages/home_page.dart`

```dart
@override
void initState() {
  super.initState();
  FirebaseMessaging.onMessage.listen(_handleRemoteMessage);
}

void _handleRemoteMessage(RemoteMessage message) {
  debugPrint('🔔 FCM MESSAGE RECEIVED (FOREGROUND)');
  debugPrint('Data: ${message.data}');
}
```

**`FirebaseMessaging.onMessage`:**
- Stream สำหรับ foreground messages
- Emit `RemoteMessage` เมื่อมี notification

**`RemoteMessage` object:**
```dart
RemoteMessage(
  messageId: '0:1234567890123456%abc123',
  data: {
    'stream_call_cid': 'default:11d3e2b5-...',
    'stream_call_id': '11d3e2b5-...',
    'call_type': 'call.ring',
    'created_by_name': 'Alice',
    ...
  },
  notification: null,  // Data message (no notification)
)
```

---

### Stream SDK Handle Message Automatically:

**Stream SDK ทำอะไร:**
1. Detect message เป็น Stream Video notification
2. Parse `stream_call_cid`, `call_type`
3. Query call details จาก Stream API
4. สร้าง `Call` object
5. **อัพเดต `incomingCall` stream**

```dart
// Stream SDK internal:
StreamVideo.instance.state.incomingCall.value = Call(...);
```

---

### Listener ทำงาน:

```dart
void _observeIncomingCalls() {
  StreamService.client.state.incomingCall.listen((call) {
    // ← Listener นี้ทำงาน!
    if (call != null && mounted) {
      print('📞 Incoming call from: ${call.state.value.createdBy?.name}');
      // → "📞 Incoming call from: Alice"

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallPage(call: call, isOutgoing: false),
        ),
      );
    }
  });
}
```

**Flow:**
```
FCM Message
    ↓
Stream SDK parse
    ↓
Query call details
    ↓
Update incomingCall stream
    ↓
Listener triggered
    ↓
Open CallPage
```

**User B เห็น:**
- หน้า CallPage ปรากฏทันที
- แสดง "Alice is calling..."
- มีปุ่ม Accept (เขียว) และ Reject (แดง)

---

## กรณีที่ 2: User B แอปอยู่เบื้องหลัง (Background/Terminated)

### ไฟล์: `lib/firebase_background_handler.dart`

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('🔔 BACKGROUND FCM MESSAGE RECEIVED');
  print('Data: ${message.data}');

  await StreamVideoPushNotificationManager.onBackgroundMessage(message);
}
```

**`@pragma('vm:entry-point')`:**
- บอก compiler ว่า function นี้ถูกเรียกจาก native
- ป้องกันถูกลบตอน tree-shaking

**`Firebase.initializeApp()`:**
- ต้อง init ใหม่เพราะ background handler รันใน isolate แยก
- Isolate ไม่ share state กับ main isolate

---

### `StreamVideoPushNotificationManager.onBackgroundMessage()`:

**ทำอะไร:**

1. **Parse message:**
   ```dart
   final callCid = message.data['stream_call_cid'];
   // "default:11d3e2b5-..."
   ```

2. **Query call details:**
   ```http
   GET https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-...
   Authorization: [User B Token]
   ```

3. **แสดง Native Call UI:**

   **Android (ConnectionService):**
   ```kotlin
   // Stream SDK เรียก Android Telecom API
   val handle = PhoneAccountHandle(...)
   val extras = Bundle().apply {
       putString("caller_name", "Alice")
       putString("call_id", "11d3e2b5-...")
   }
   telecomManager.addNewIncomingCall(handle, extras)
   ```

   **iOS (CallKit):**
   ```swift
   // Stream SDK เรียก iOS CallKit API
   let update = CXCallUpdate()
   update.localizedCallerName = "Alice"
   update.hasVideo = true

   provider.reportNewIncomingCall(with: uuid, update: update) { error in
       // Show native call UI
   }
   ```

**User B เห็น:**

**Android:**
- Full-screen incoming call UI (เหมือนโทรศัพท์ปกติ)
- แสดงชื่อ "Alice"
- ปุ่ม Accept (เขียว) และ Decline (แดง)

**iOS:**
- CallKit UI (เหมือนโทรศัพท์ iOS)
- แสดงชื่อ "Alice"
- Slide to answer

---

# STEP 15: User B กด Accept

## ไฟล์: `lib/pages/call_page.dart`

### User B เห็นหน้า CallPage:

```dart
class _CallPageState extends State<CallPage> {
  bool _isCallActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOutgoing) {
      _waitForAccept();
    } else {
      _showIncomingCallUI();  // ← User B (callee)
    }
  }
```

**`widget.isOutgoing`:**
- `true` = User A (caller)
- `false` = User B (callee)

---

### UI สำหรับ Incoming Call:

```dart
Widget build(BuildContext context) {
  if (!_isCallActive && !widget.isOutgoing) {
    // Incoming call UI
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          children: [
            Icon(Icons.person, size: 100, color: Colors.white),
            Text(
              widget.call.state.value.createdBy?.name ?? 'Unknown',
              // → "Alice"
              style: TextStyle(fontSize: 32, color: Colors.white),
            ),
            Text(
              'Incoming Call...',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            Row(
              children: [
                FloatingActionButton(
                  onPressed: _rejectCall,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.call_end),
                ),
                FloatingActionButton(
                  onPressed: _acceptCall,  // ← กด Accept
                  backgroundColor: Colors.green,
                  child: Icon(Icons.call),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ...
}
```

**User B เห็น:**
```
┌──────────────────────────────┐
│                              │
│       👤                     │
│                              │
│      Alice                   │
│                              │
│   Incoming Call...           │
│                              │
│                              │
│  [🔴 Reject]   [🟢 Accept]  │
│                              │
└──────────────────────────────┘
```

---

### User B กดปุ่ม Accept:

```dart
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
```

---

### `call.accept()` ทำอะไร:

**1. ส่ง HTTP Request:**
```http
POST https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5/accept
Authorization: [User B Token]
Stream-Auth-Type: jwt
Content-Type: application/json

{}
```

**2. Stream Backend อัพเดต:**
```
Call Status: ringing → active
Members: user-a (joined), user-b (joined)
```

**3. Notify User A:**
```
WebSocket Event → User A
{
  "type": "call.accepted",
  "call_cid": "default:11d3e2b5-...",
  "user": {
    "id": "user-b",
    "name": "Bob"
  }
}
```

**User A เห็น:**
- Status เปลี่ยนจาก "Ringing..." → "Connecting..."

---

# STEP 16: WebRTC Connection Setup

## 16.1 User A สร้าง Offer

**ทำอะไร:**
- สร้าง SDP (Session Description Protocol) Offer
- มีข้อมูล codecs, network info

**Code (ภายใน Stream SDK):**
```dart
// User A
final offer = await peerConnection.createOffer();
await peerConnection.setLocalDescription(offer);
```

**SDP Offer (ตัวอย่าง):**
```
v=0
o=- 1234567890 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0 1
m=audio 9 UDP/TLS/RTP/SAVPF 111 103 104
a=rtpmap:111 opus/48000/2
a=rtpmap:103 ISAC/16000
m=video 9 UDP/TLS/RTP/SAVPF 96 97
a=rtpmap:96 VP8/90000
a=rtpmap:97 H264/90000
```

---

### ส่ง Offer ไปยัง Stream Backend:

```http
POST https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5/sdp/offer
Authorization: [User A Token]

{
  "sdp": "v=0\no=- 1234567890...",
  "type": "offer"
}
```

---

### Stream Backend Forward to User B:

```
WebSocket → User B
{
  "type": "sdp.offer",
  "call_cid": "default:11d3e2b5-...",
  "sdp": "v=0\no=- 1234567890..."
}
```

---

## 16.2 User B สร้าง Answer

**Code (ภายใน Stream SDK):**
```dart
// User B
await peerConnection.setRemoteDescription(offer);
final answer = await peerConnection.createAnswer();
await peerConnection.setLocalDescription(answer);
```

**SDP Answer:**
```
v=0
o=- 9876543210 2 IN IP4 127.0.0.1
s=-
t=0 0
m=audio 9 UDP/TLS/RTP/SAVPF 111
a=rtpmap:111 opus/48000/2
m=video 9 UDP/TLS/RTP/SAVPF 96
a=rtpmap:96 VP8/90000
```

---

### ส่ง Answer กลับไปยัง User A:

```http
POST https://video.stream-io-api.com/api/v2/video/call/.../sdp/answer
Authorization: [User B Token]

{
  "sdp": "v=0\no=- 9876543210...",
  "type": "answer"
}
```

```
Stream Backend → User A (WebSocket)
{
  "type": "sdp.answer",
  "sdp": "v=0\no=- 9876543210..."
}
```

**User A:**
```dart
await peerConnection.setRemoteDescription(answer);
```

---

## 16.3 ICE Candidate Exchange

**ทำอะไร:**
- แลกเปลี่ยน network paths (IP addresses, ports)
- หา route ที่ดีที่สุดสำหรับ P2P connection

**ICE Candidate (ตัวอย่าง):**
```
candidate:1 1 UDP 2130706431 192.168.1.100 54321 typ host
candidate:2 1 UDP 1694498815 203.0.113.50 12345 typ srflx raddr 192.168.1.100 rport 54321
```

**Types:**
- **host**: Local IP
- **srflx**: Server Reflexive (public IP, via STUN)
- **relay**: Relayed (via TURN server)

---

**User A → Stream → User B:**
```http
POST https://video.stream-io-api.com/api/v2/video/call/.../ice
{
  "candidate": "candidate:1 1 UDP 2130706431...",
  "sdpMid": "0",
  "sdpMLineIndex": 0
}
```

**User B → Stream → User A:**
```http
POST https://video.stream-io-api.com/api/v2/video/call/.../ice
{
  "candidate": "candidate:2 1 UDP 1694498815...",
  ...
}
```

---

## 16.4 Connection Established

**เมื่อ ICE สำเร็จ:**
```dart
peerConnection.onIceConnectionState = (state) {
  if (state == RTCIceConnectionState.connected) {
    print('✅ WebRTC connected!');
  }
};
```

**Connection Path:**
```
User A Device
    ↓ (Direct P2P if possible)
User B Device

Or via TURN:
User A → TURN Server → User B
```

---

# STEP 17: Active Call - Video/Audio Streaming

## UI เปลี่ยนเป็น Active Call:

```dart
Widget build(BuildContext context) {
  // ...
  if (_isCallActive) {
    return Scaffold(
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
        child: Icon(Icons.call_end),
      ),
    );
  }
}
```

---

### `StreamCallContainer`:

**ทำอะไร:**
1. Setup video renderers
2. Handle media streams
3. Render participant videos
4. Provide call controls

**`StreamCallContent`:**
- Pre-built UI components:
  - Video tiles
  - Audio indicators
  - Network quality
  - Participant list
  - Mute/unmute buttons
  - Camera on/off
  - Speaker/earpiece toggle

---

### Media Streams:

**Audio:**
```dart
// User A microphone → encode → send to User B
// User B receive → decode → play on speaker
```

**Video:**
```dart
// User A camera → encode (VP8/H264) → send to User B
// User B receive → decode → render on screen
```

**Real-time:**
- Latency: ~100-300ms
- Bitrate: 500kbps-2Mbps (adaptive)
- Resolution: 320x240 → 1280x720 (adaptive)

---

### Call State:

```dart
call.state.listen((callState) {
  print('Status: ${callState.status}');
  print('Participants: ${callState.participants.length}');
  print('Duration: ${callState.duration}');
});
```

**CallState object:**
```dart
CallState(
  status: CallStatus.active,
  participants: [
    CallParticipant(
      userId: 'user-a',
      name: 'Alice',
      isLocalParticipant: true,
      isSpeaking: true,
      videoEnabled: true,
      audioEnabled: true,
    ),
    CallParticipant(
      userId: 'user-b',
      name: 'Bob',
      isLocalParticipant: false,
      isSpeaking: false,
      videoEnabled: true,
      audioEnabled: true,
    ),
  ],
  duration: Duration(seconds: 120),
)
```

---

# STEP 18: End Call

## User กดปุ่ม "End Call":

```dart
Future<void> _endCall() async {
  try {
    print('📴 Ending call...');
    await widget.call.leave();
    if (mounted) Navigator.pop(context);
  } catch (e) {
    print('❌ Failed to end call: $e');
  }
}
```

---

### `call.leave()` ทำอะไร:

**1. ส่ง HTTP Request:**
```http
POST https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5/leave
Authorization: [User Token]
```

**2. Disconnect WebRTC:**
```dart
// Stop media tracks
audioTrack.stop();
videoTrack.stop();

// Close peer connection
peerConnection.close();
```

**3. Update Call State:**
```
User A: left
User B: still in call (ถ้ายังไม่ leave)
```

**4. Notify Other Participants:**
```
WebSocket → User B
{
  "type": "call.member_left",
  "user": {"id": "user-a", "name": "Alice"}
}
```

---

### User B รับ event:

```dart
call.state.listen((state) {
  if (state.status == CallStatus.ended) {
    // User B เห็นว่า call ended
    Navigator.pop(context);
  }
});
```

**User B เห็น:**
- Video หาย
- หน้าจอกลับไป HomePage
- Toast/Snackbar: "Call ended"

---

### ถ้าต้องการ End Call สำหรับทุกคน:

```dart
await call.leave(endCall: true);
```

**ความต่าง:**
- **`leave()`**: ออกเฉพาะตัวเอง
- **`leave(endCall: true)`**: end call ทั้งหมด (ทุกคนออก)

---

# สรุป Flow ทั้งหมด

```
1. เปิด App
   main() → Initialize Firebase → Register Background Handler → Request Permission
   ↓
2. แสดง LoginPage
   User กรอก ID/Name → กดปุ่ม Login
   ↓
3. เรียก Backend
   POST /v1/api/callStreams → Backend generate JWT token
   ↓
4. Initialize StreamVideo
   StreamVideo() → connect() → Register FCM Token
   ↓
5. Navigate HomePage
   Listen for Incoming Calls
   ↓
6. User A โทร User B
   makeCall() → getOrCreate(ringing: true) → ring()
   ↓
7. Stream Backend
   Query User B devices → Get FCM token → Send to Firebase
   ↓
8. Firebase → User B Device
   Foreground: onMessage → IncomingCall stream → CallPage
   Background: onBackgroundMessage → CallKit/ConnectionService
   ↓
9. User B Accept
   call.accept() → Notify User A → Start WebRTC
   ↓
10. WebRTC Setup
    Offer/Answer SDP → ICE Candidates → Connection Established
    ↓
11. Active Call
    Audio/Video streaming → Real-time communication
    ↓
12. End Call
    call.leave() → Disconnect WebRTC → Navigate back → HomePage
```

---

# ความสัมพันธ์ระหว่าง Components

```
┌──────────────────────────────────────────────────────────────┐
│ Flutter App                                                   │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  main.dart                                                    │
│    └─ Firebase.initializeApp()                              │
│    └─ runApp(MyApp)                                          │
│         └─ LoginPage                                         │
│              └─ Call Backend API                             │
│              └─ StreamService.initialize()                   │
│                   └─ StreamVideo()                           │
│                        └─ connect()                          │
│                             └─ Register FCM Token            │
│                   └─ HomePage                                │
│                        └─ Listen incomingCall                │
│                        └─ makeCall() → getOrCreate() → ring()│
│                             └─ CallPage                      │
│                                  └─ accept()/reject()        │
│                                  └─ StreamCallContainer      │
│                                       └─ WebRTC Streaming    │
│                                                               │
└──────────────────────────────────────────────────────────────┘
         ↕                    ↕                    ↕
┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐
│ Backend         │  │ Stream Backend  │  │ Firebase FCM   │
│ (Token Server)  │  │ (Video/Audio)   │  │ (Push Notify)  │
└─────────────────┘  └─────────────────┘  └────────────────┘
```

---

**ไฟล์นี้อธิบายโค้ดตั้งแต่เปิด app (`main()`) ไปจนจบ call แบบ step-by-step 🎉**

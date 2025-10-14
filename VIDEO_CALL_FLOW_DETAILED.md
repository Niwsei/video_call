# 📞 Video Call Flow - คู่มือละเอียด

## 🎯 ภาพรวม

การโทรแบบ 1-on-1 ผ่าน Stream Video SDK มีขั้นตอนดังนี้:

```
User A (Caller)              Stream Backend              User B (Callee)
     |                              |                           |
     |------ 1. Create Call ------->|                           |
     |                              |------ 2. Push FCM ------->|
     |                              |                           |
     |<----- 3. Call Created -------|                           |
     |                              |                           |
     |                              |<----- 4. Accept Call -----|
     |<------------ 5. WebRTC Signaling (SDP/ICE) ------------->|
     |<=============== 6. Media Stream (Audio/Video) ===========>|
```

---

## 📋 Prerequisites - ข้อมูลที่ต้องมี

### User Information (ทั้ง 2 ฝั่ง)

```dart
// User A (Caller - ต้นทาง)
String userAId = '68da5610e8994916f01364b8';
String userAName = 'ຮືວ่າງ ວ່າງ';
String userAToken = 'eyJhbGciOiJIUzI1NiIs...'; // JWT from Stream

// User B (Callee - ปลายทาง)
String userBId = '68ad1babd03c44ef943bb6bb';
String userBName = 'tangiro kamado';
String userBToken = 'eyJhbGciOiJIUzI1NiIs...'; // JWT from Stream
```

### Stream Configuration

```dart
String apiKey = 'r9mn4fsbzhub';
String pushProviderName = 'niwner_notification';
```

### App State (แต่ละ User)

```dart
// ต้องมีข้อมูลเหล่านี้พร้อมก่อนโทร:
StreamVideo client;          // Stream Video Client (connected)
String fcmToken;             // Firebase Cloud Messaging Token
bool permissionsGranted;     // Camera & Microphone permissions
```

---

## 🏗️ Architecture Overview

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                            │
│                                                             │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  main.dart  │→ │ app_init.dart│→ │ home_page.dart│     │
│  └─────────────┘  └──────────────┘  └──────────────┘     │
│                                              │              │
│                                              ↓              │
│                                    ┌──────────────────┐    │
│                                    │ call_screen.dart │    │
│                                    └──────────────────┘    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Stream Video SDK
                         ↓
┌────────────────────────────────────────────────────────────┐
│                   Stream Backend                           │
│                                                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐           │
│  │ Call API │  │ User API │  │ Push Service │           │
│  └──────────┘  └──────────┘  └──────────────┘           │
└────────────────────────┬───────────────────────────────────┘
                         │
                         │ Firebase Cloud Messaging
                         ↓
┌────────────────────────────────────────────────────────────┐
│                Firebase Cloud Messaging                     │
│                                                            │
│           ┌─────────────┐         ┌─────────────┐        │
│           │  Push to    │         │  Push to    │        │
│           │  User A     │         │  User B     │        │
│           └─────────────┘         └─────────────┘        │
└────────────────────────────────────────────────────────────┘
```

---

## 🚀 Detailed Flow - ขั้นตอนละเอียด

---

## Phase 1: App Initialization (เริ่มต้น App)

### Step 1.1: Initialize Firebase

**Location:** `lib/main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler
  );

  runApp(const _BootstrapApp());
}
```

**สิ่งที่เกิดขึ้น:**
1. เริ่ม Flutter engine
2. เชื่อมต่อกับ Firebase project
3. ลงทะเบียน handler สำหรับรับ push notification ขณะ app ปิด

---

### Step 1.2: Create Stream Video Client

**Location:** `lib/app_initializer.dart` → `createClient()`

```dart
StreamVideo createClient({
  required User user,           // User A or User B
  required String apiKey,       // 'r9mn4fsbzhub'
  required String userToken,    // JWT token
}) {
  return StreamVideo(
    apiKey,
    user: user,
    userToken: userToken,
    options: const StreamVideoOptions(
      keepConnectionsAliveWhenInBackground: true,
    ),
    pushNotificationManagerProvider:
      StreamVideoPushNotificationManager.create(
        androidPushProvider: const StreamVideoPushProvider.firebase(
          name: 'niwner_notification',  // ต้องตรงกับ Stream Dashboard
        ),
        pushParams: const StreamVideoPushParams(
          appName: 'Stream Video Call',
        ),
      ),
  )..connect();
}
```

**สิ่งที่เกิดขึ้น:**
1. สร้าง StreamVideo client instance
2. เชื่อมต่อกับ Stream Backend (WebSocket)
3. Authenticate ด้วย JWT token
4. ลงทะเบียน Push Notification Provider

**Network Request:**
```http
POST https://video.stream-io-api.com/api/v2/auth/guest
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

Response:
{
  "user": { "id": "68da5610e8994916f01364b8", ... },
  "access_token": "...",
  "duration": "1h"
}
```

---

### Step 1.3: Register FCM Token with Stream

**สิ่งที่เกิดขึ้นอัตโนมัติ:**

```dart
// Stream SDK ทำเองโดยอัตโนมัติ
FirebaseMessaging.instance.getToken().then((fcmToken) {
  // SDK ส่ง FCM token ไปยัง Stream Backend
  streamClient.addDevice(
    id: fcmToken,
    pushProvider: 'firebase',
    pushProviderName: 'niwner_notification',
  );
});
```

**Network Request:**
```http
POST https://video.stream-io-api.com/api/v2/users/{userId}/devices
Authorization: Bearer ...

{
  "id": "cXXXXXXXXXXXXXXXXXXX...",  // FCM Token
  "push_provider": "firebase",
  "push_provider_name": "niwner_notification"
}

Response:
{
  "device": { "id": "cXXX...", "created_at": "..." }
}
```

**สำคัญ:** ถ้าขั้นตอนนี้ล้มเหลว → ปลายทางจะไม่ได้รับ push notification!

---

### Step 1.4: Setup Listeners

**Location:** `lib/home_page.dart` → `initState()`

```dart
@override
void initState() {
  super.initState();

  // Listen for foreground FCM messages
  _observeFcmMessages();

  // Listen for incoming calls
  _observeIncomingCalls();

  // Listen for CallKit/ConnectionService events
  _observeCallKitEvents();
}

void _observeIncomingCalls() {
  _incomingCallSub = StreamVideo.instance.state.incomingCall.listen((call) {
    if (call != null) {
      // เปิดหน้า Call Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(call: call, role: CallUiRole.callee),
        ),
      );
    }
  });
}
```

**สิ่งที่เกิดขึ้น:**
- ตั้งค่า listeners เพื่อรอ incoming call events
- พร้อมรับสายได้ทุกเมื่อ

---

## Phase 2: Initiating a Call (ฝั่งต้นทาง - User A)

### Step 2.1: User A กดปุ่มโทร

**Location:** `lib/home_page.dart` → `_startCall()`

```dart
// User A กดปุ่มโทรหา User B
await _startCall(
  memberIds: ['68ad1babd03c44ef943bb6bb'],  // User B ID
  video: true,
);
```

---

### Step 2.2: Create Call Object

**Location:** `lib/home_page.dart` → `_startCall()`

```dart
// สร้าง Call ID (deterministic สำหรับ 1-on-1)
final callId = '1v1-68ad1babd03c44ef943bb6bb-68da5610e8994916f01364b8';

// สร้าง Call object
final call = StreamVideo.instance.makeCall(
  callType: StreamCallType.defaultType(),
  id: callId,
);
```

**สิ่งที่เกิดขึ้น:**
- สร้าง Call object ใน local memory (ยังไม่ส่งไปยัง backend)
- Call ID แบบ deterministic ทำให้ทั้ง 2 ฝั่งอ้างถึง call เดียวกันได้

---

### Step 2.3: Navigate to Call Screen (Caller)

```dart
// เปิดหน้า Call Screen ก่อน (ให้ user เห็น UI ทันที)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CallScreen(call: call, role: CallUiRole.caller),
  ),
);
```

**UI State:** User A เห็นหน้า "กำลังโทร..." พร้อม loading indicator

---

### Step 2.4: Call getOrCreate() with ringing=true

**Location:** `lib/home_page.dart` → `_startCall()`

```dart
await call.getOrCreate(
  memberIds: ['68ad1babd03c44ef943bb6bb'],  // User B
  ringing: true,   // 🔔 สำคัญ! เปิด ringing mode
  video: true,
);
```

**Network Request:**
```http
POST https://video.stream-io-api.com/api/v2/video/call/{type}/{id}
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

{
  "data": {
    "members": [
      { "user_id": "68da5610e8994916f01364b8", "role": "admin" },  // User A
      { "user_id": "68ad1babd03c44ef943bb6bb", "role": "user" }    // User B
    ],
    "settings_override": {
      "video": { "enabled": true },
      "audio": { "enabled": true }
    }
  },
  "ring": true,  // 🔔 สำคัญ!
  "notify": true
}

Response:
{
  "call": {
    "id": "1v1-68ad1babd03c44ef943bb6bb-68da5610e8994916f01364b8",
    "type": "default",
    "cid": "default:1v1-...",
    "created_at": "2025-10-07T14:30:00Z",
    "created_by": {
      "id": "68da5610e8994916f01364b8",
      "name": "ຮືວ່າງ ວ່າງ"
    },
    "session": {
      "id": "...",
      "participants": [...]
    }
  },
  "members": [...],
  "duration": "123ms"
}
```

**สิ่งที่เกิดขึ้นใน Stream Backend:**

1. **สร้าง Call Session** ใน database
2. **ส่ง WebSocket event** ไปยัง User B (ถ้า online)
3. **🔔 Trigger Push Notification** ไปยัง User B ผ่าน Firebase

---

## Phase 3: Push Notification (Stream → Firebase → User B)

### Step 3.1: Stream Backend ส่ง Push Request ไปยัง Firebase

**Stream Backend → Firebase Cloud Messaging:**

```http
POST https://fcm.googleapis.com/fcm/send
Authorization: key=FIREBASE_SERVER_KEY
Content-Type: application/json

{
  "to": "cXXXXXXXXXXXX...",  // User B's FCM Token
  "data": {
    "stream_call_id": "1v1-68ad1babd03c44ef943bb6bb-68da5610e8994916f01364b8",
    "stream_call_type": "default",
    "stream_call_cid": "default:1v1-...",
    "call_display_name": "ຮືວ່າງ ວ່າງ",
    "created_by_id": "68da5610e8994916f01364b8",
    "created_by_display_name": "ຮືວ່າງ ວ່າງ",
    "type": "call.ring"
  },
  "priority": "high",
  "notification": {
    "title": "Incoming Call",
    "body": "ຮືວ່າງ ວ່າງ is calling you"
  }
}
```

**⚠️ สำคัญ:** ถ้า `push_provider_name` ใน Stream Dashboard ไม่ตรง → Push จะไม่ถูกส่ง!

---

### Step 3.2: Firebase ส่ง Push ไปยัง User B's Device

**Firebase → User B's Device:**

```
Firebase Cloud Messaging
    ↓
Android Push Notification Service / Apple Push Notification Service
    ↓
User B's Device (App may be in background/foreground)
```

---

## Phase 4: Receiving Call (ฝั่งปลายทาง - User B)

### Scenario A: App อยู่ Foreground

**Location:** `lib/home_page.dart` → `_handleRemoteMessage()`

```dart
void _observeFcmMessages() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // รับ FCM message
    debugPrint('🔔 FOREGROUND FCM MESSAGE RECEIVED');
    debugPrint('Message data: ${message.data}');

    // ส่งต่อให้ Stream SDK ประมวลผล
    StreamVideo.instance.handleRingingFlowNotifications(message.data);
  });
}
```

**สิ่งที่เกิดขึ้น:**
1. FCM message ถูกส่งมาที่ `FirebaseMessaging.onMessage`
2. Stream SDK parse message data
3. Stream SDK ดึงข้อมูล call จาก backend
4. Stream SDK emit event ไปยัง `incomingCall` stream

---

**Location:** `lib/home_page.dart` → `_observeIncomingCalls()`

```dart
void _observeIncomingCalls() {
  StreamVideo.instance.state.incomingCall.listen((call) {
    if (call != null) {
      debugPrint('📞 INCOMING CALL EVENT RECEIVED');
      debugPrint('Call ID: ${call.id}');

      // เปิดหน้า Call Screen (Callee)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            call: call,
            role: CallUiRole.callee,  // บอกว่าเป็นผู้รับสาย
          ),
        ),
      );
    }
  });
}
```

**UI State:** User B เห็นหน้า "สายเรียกเข้า" พร้อมปุ่ม รับสาย/ปฏิเสธ

---

### Scenario B: App อยู่ Background/Closed

**Location:** `lib/firebase_background_handler.dart`

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message
) async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // Fetch fresh user token
  final auth = await TokenService.fetchStreamAuth();

  // Create temporary Stream client
  final client = AppInitializer.createClient(
    user: User.regular(userId: auth.userId),
    apiKey: auth.apiKey,
    userToken: auth.token,
  );

  // Handle ringing flow
  await StreamVideo.instance.handleRingingFlowNotifications(message.data);

  // Clean up
  client.disposeAfterResolvingRinging();
}
```

**สิ่งที่เกิดขึ้น:**

1. **Android:** แสดง Full-Screen Notification (CallStyle)
2. **iOS:** แสดง CallKit UI
3. เมื่อ user กด "รับสาย":
   - App ถูกเปิด (หรือ resume)
   - Navigate ไปยัง Call Screen

---

### Step 4.1: User B กด "รับสาย"

**Location:** `lib/call_screen.dart` → `_handleAccept()`

```dart
Future<void> _handleAccept() async {
  final result = await widget.call.accept();

  result.when(
    success: (_) => print('✅ Call accepted'),
    failure: (error) => print('❌ Accept failed: ${error.message}'),
  );
}
```

**Network Request:**
```http
POST https://video.stream-io-api.com/api/v2/video/call/{type}/{id}/accept
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

Response:
{
  "call": { ... },
  "duration": "45ms"
}
```

**สิ่งที่เกิดขึ้น:**
1. ส่ง "accept" event ไปยัง Stream Backend
2. Stream Backend แจ้ง User A ว่า User B รับสายแล้ว
3. เริ่มกระบวนการ WebRTC Signaling

---

## Phase 5: WebRTC Connection Setup

### Step 5.1: SDP Offer/Answer Exchange

**User A (Caller) → Stream → User B (Callee):**

```
User A: สร้าง SDP Offer (รายละเอียดของ media streams)
    ↓
Stream Backend: ส่งต่อ SDP Offer ไปยัง User B
    ↓
User B: สร้าง SDP Answer
    ↓
Stream Backend: ส่งต่อ SDP Answer กลับไปยัง User A
```

**SDP (Session Description Protocol) ตัวอย่าง:**

```
v=0
o=- 1234567890 2 IN IP4 192.168.1.100
s=-
t=0 0
a=group:BUNDLE 0 1
m=audio 9 UDP/TLS/RTP/SAVPF 111 103
c=IN IP4 0.0.0.0
a=rtcp:9 IN IP4 0.0.0.0
a=ice-ufrag:xxxx
a=ice-pwd:xxxx
a=fingerprint:sha-256 XX:XX:XX...
a=sendrecv
m=video 9 UDP/TLS/RTP/SAVPF 96 97
...
```

---

### Step 5.2: ICE Candidate Exchange

**User A และ User B แลกเปลี่ยน ICE Candidates:**

```dart
// Stream SDK ทำให้อัตโนมัติ
call.session.iceCandidates.listen((candidate) {
  // Send to peer via Stream Backend
});
```

**ICE Candidate ตัวอย่าง:**

```json
{
  "candidate": "candidate:1 1 UDP 2130706431 192.168.1.100 54321 typ host",
  "sdpMLineIndex": 0,
  "sdpMid": "0"
}
```

**สิ่งที่เกิดขึ้น:**
- แต่ละฝั่งค้นหา network paths ที่เป็นไปได้
- ลอง connect แต่ละ path
- เลือก path ที่ดีที่สุด (โดยปกติเป็น P2P)

---

### Step 5.3: Establish Peer Connection

```
User A                    Stream SFU (optional)              User B
   |                              |                             |
   |<------------ ICE Connectivity Check ---------------------->|
   |                              |                             |
   |============== Direct P2P Connection (if possible) ========>|
   |                              |                             |
   |<=========== Media Stream (Audio/Video) ===================>|
```

**หรือถ้า P2P ไม่ได้:**

```
User A → Stream SFU (relay) → User B
```

---

## Phase 6: Active Call

### Step 6.1: Media Streaming

**User A:**
```dart
// Capture local camera/microphone
call.camera.enable();
call.microphone.enable();

// Stream SDK ส่ง media tracks ไปยัง peer
```

**User B:**
```dart
// รับ remote media tracks
call.state.valueStream.listen((callState) {
  final participants = callState.callParticipants;
  for (final participant in participants) {
    final videoTrack = participant.videoTrack;
    final audioTrack = participant.audioTrack;
    // Render video & play audio
  }
});
```

---

### Step 6.2: Call Controls

**User สามารถควบคุม call ได้:**

```dart
// Toggle camera
await call.camera.toggle();

// Toggle microphone
await call.microphone.toggle();

// Flip camera (front/back)
await call.camera.flip();

// Toggle speakerphone
await call.speakerphone.toggle();
```

---

## Phase 7: Ending the Call

### Scenario A: User A วางสาย

```dart
await call.end();  // ตัดสายสำหรับทุกคน
```

**Network Request:**
```http
POST https://video.stream-io-api.com/api/v2/video/call/{type}/{id}/end
Authorization: Bearer ...

Response:
{
  "call": { "ended_at": "2025-10-07T14:35:00Z", ... },
  "duration": "67ms"
}
```

**สิ่งที่เกิดขึ้น:**
1. Stream Backend บันทึกว่า call จบแล้ว
2. ส่ง "call.ended" event ไปยัง User B
3. User B's call screen ปิดอัตโนมัติ

---

### Scenario B: User B วางสาย

```dart
await call.leave();  // ออกจาก call (แต่ call ยังอยู่)
```

---

## 📊 Complete Sequence Diagram

```
User A App         Stream Backend       Firebase        User B App
    |                    |                  |               |
    |-- Initialize ------>|                  |               |
    |<-- Connected -------|                  |               |
    |                    |                  |               |-- Initialize --->
    |                    |<-- Connected --------------------------|
    |                    |                  |               |
    |                    |<-- Register FCM Token -------------|
    |                    |                  |               |
    |-- getOrCreate() -->|                  |               |
    |    (ring:true)     |                  |               |
    |                    |-- Push FCM ------>|               |
    |<-- Call Created ---|                  |               |
    |                    |                  |-- Push ------->|
    |                    |                  |               |
    |                    |                  |               |-- handleRinging -->
    |                    |                  |               |<-- Incoming Call Event
    |                    |                  |               |
    |                    |<-- Accept Call ------------------|
    |<-- Call Accepted Event ---------------|               |
    |                    |                  |               |
    |<------------ WebRTC Signaling (SDP/ICE) ------------->|
    |<================ Media Stream (P2P) ================>|
    |                    |                  |               |
    |-- End Call ------->|                  |               |
    |                    |-- Ended Event ------------------->|
    |<-- Call Ended -----|                  |               |
    |                    |                  |               |<-- Navigate Back
```

---

## 🔧 Important Code Locations

### 1. App Initialization
- `lib/main.dart` - Entry point
- `lib/app_initializer.dart` - Stream client setup
- `lib/firebase_options.dart` - Firebase config

### 2. Call Flow
- `lib/home_page.dart` - `_startCall()` - Create outgoing call
- `lib/home_page.dart` - `_observeIncomingCalls()` - Receive incoming call
- `lib/call_screen.dart` - Call UI and controls

### 3. Push Notifications
- `lib/firebase_background_handler.dart` - Background FCM handler
- `lib/home_page.dart` - `_handleRemoteMessage()` - Foreground FCM

### 4. Configuration
- `lib/app_keys.dart` - API keys and config
- `lib/dev_manual_auth.dart` - User tokens (manual mode)

---

## 🐛 Troubleshooting Guide

### ปัญหา: ปลายทางไม่ได้รับ notification

**สาเหตุที่เป็นไปได้:**

1. **FCM Token ไม่ได้ลงทะเบียนกับ Stream**
   - เช็ค logs: `📱 CURRENT FCM TOKEN`
   - แก้: ตรวจสอบว่า push manager enabled

2. **Push Provider ไม่ถูกต้อง**
   - เช็ค: Stream Dashboard → Push Notifications
   - แก้: ตั้งค่า FCM server key และ provider name

3. **Token signature invalid**
   - เช็ค logs: `❌ Token signature is invalid`
   - แก้: Generate token ใหม่จาก Stream Dashboard

### ปัญหา: Call timeout หลัง 28 วินาที

**สาเหตุ:**
- ปลายทางไม่ได้ accept call
- ปลายทางไม่ได้รับ notification

**แก้:**
- ตรวจสอบว่าปลายทางเห็น incoming call หรือไม่
- ตรวจสอบ push notification setup

### ปัญหา: WebRTC connection failed

**สาเหตุ:**
- Firewall block UDP ports
- Network behind strict NAT

**แก้:**
- ใช้ TURN server (Stream มีให้แล้ว)
- เช็ค network permissions

---

## 📚 Additional Resources

### Stream Documentation
- Call API: https://getstream.io/video/docs/api/call/
- Push Notifications: https://getstream.io/video/docs/flutter/push-notifications/

### Firebase Documentation
- Cloud Messaging: https://firebase.google.com/docs/cloud-messaging

### WebRTC
- WebRTC Basics: https://webrtc.org/getting-started/overview

---

## 🎯 Key Takeaways

1. **Token ต้องถูกต้อง:** Generate จาก Stream Dashboard ที่ app ถูกต้อง
2. **Push Provider ต้องตั้งค่า:** ใน Stream Dashboard ต้องมี FCM server key
3. **ringing: true สำคัญ:** ถ้าไม่ใส่ ปลายทางจะไม่ได้รับ push notification
4. **FCM Token ต้องลงทะเบียน:** Stream SDK ทำให้อัตโนมัติ แต่ต้อง enable push manager
5. **App ต้อง handle background:** ตั้งค่า background handler สำหรับรับ push ขณะ app ปิด

---

**หมายเหตุ:** คู่มือนี้อธิบาย flow แบบ 1-on-1 call โดยใช้ Manual Mode สำหรับ testing

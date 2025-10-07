# 🔔 Push Notification Flow - ละเอียดทุกขั้นตอน

## สารบัญ
1. [ภาพรวม](#ภาพรวม)
2. [Prerequisites - สิ่งที่ต้องมีก่อน](#prerequisites)
3. [7 ขั้นตอนการส่ง Notification](#7-ขั้นตอนการส่ง-notification)
4. [Code ที่เกี่ยวข้องทุกส่วน](#code-ที่เกี่ยวข้อง)
5. [Network Requests แบบละเอียด](#network-requests)
6. [Troubleshooting](#troubleshooting)

---

## ภาพรวม

```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐         ┌─────────────┐
│   User A    │         │    Stream    │         │   Firebase   │         │   User B    │
│  (Caller)   │         │   Backend    │         │     FCM      │         │  (Callee)   │
│   Chrome    │         │              │         │              │         │   Mobile    │
└──────┬──────┘         └──────┬───────┘         └──────┬───────┘         └──────┬──────┘
       │                       │                        │                        │
       │ 1. call.ring()        │                        │                        │
       │──────────────────────>│                        │                        │
       │                       │                        │                        │
       │                       │ 2. Query FCM Token     │                        │
       │                       │    for User B          │                        │
       │                       │───────┐                │                        │
       │                       │       │                │                        │
       │                       │<──────┘                │                        │
       │                       │                        │                        │
       │                       │ 3. Send Push Notification                       │
       │                       │    with call data      │                        │
       │                       │───────────────────────>│                        │
       │                       │                        │                        │
       │                       │                        │ 4. Route to device     │
       │                       │                        │    using FCM token     │
       │                       │                        │───────────────────────>│
       │                       │                        │                        │
       │                       │                        │                        │ 5. Receive
       │                       │                        │                        │    notification
       │                       │                        │                        │    data
       │                       │                        │                        │
       │                       │                        │                        │ 6. Process
       │                       │                        │                        │    in Flutter
       │                       │                        │                        │
       │                       │                        │                        │ 7. Show
       │                       │                        │                        │    CallKit UI
       │                       │                        │                        │
```

---

## Prerequisites

### 1. FCM Token ของ User B ต้องถูก Register ใน Stream Backend

**เมื่อไหร่:** ตอน User B เปิดแอปครั้งแรก

**Code Location:** `lib/app_initializer.dart:68-91`

```dart
static StreamVideo createClient({
  required User user,
  required String apiKey,
  required String userToken,
  bool attachPushManager = true,  // ✅ ต้องเป็น true!
}) {
  final client = StreamVideo(
    apiKey,
    user: user,
    userToken: userToken,
    pushNotificationManagerProvider: attachPushManager
        ? StreamVideoPushNotificationManager.create(
            androidPushProvider: const StreamVideoPushProvider.firebase(
              name: 'niwner_notification',  // ← ชื่อ Provider ใน Stream Dashboard
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

  return client;
}
```

**สิ่งที่เกิดขึ้นภายใน:**

เมื่อ `StreamVideoPushNotificationManager.create()` ถูกเรียก:

1. **ขอ FCM Token จาก Firebase:**
   ```dart
   // ภายใน Stream SDK
   final fcmToken = await FirebaseMessaging.instance.getToken();
   print('📱 FCM Token: $fcmToken');
   // เช่น: dFp8HxN-QkG... (ยาวประมาณ 163 ตัวอักษร)
   ```

2. **Register Token กับ Stream Backend:**

   **API Call:**
   ```http
   POST https://video.stream-io-api.com/api/v2/devices
   Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   Stream-Auth-Type: jwt
   Content-Type: application/json

   {
     "id": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",  // FCM Token
     "push_provider": "firebase",
     "push_provider_name": "niwner_notification",  // ต้องตรงกับใน Dashboard
     "user_id": "68ad1babd03c44ef943bb6bb"  // User B ID
   }
   ```

   **Response:**
   ```json
   {
     "device": {
       "id": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",
       "push_provider": "firebase",
       "user_id": "68ad1babd03c44ef943bb6bb",
       "created_at": "2025-02-07T10:30:00.000Z"
     }
   }
   ```

3. **Stream Backend บันทึกข้อมูล:**
   ```
   Stream Database:
   {
     user_id: "68ad1babd03c44ef943bb6bb",
     devices: [
       {
         fcm_token: "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",
         push_provider: "niwner_notification",
         platform: "android"
       }
     ]
   }
   ```

**หลักฐานว่าสำเร็จ:**

ดู logs ใน `lib/home_page.dart:_monitorFcmTokenChanges()`:
```
========================================
📱 CURRENT FCM TOKEN FOR tangiro kamado
Full Token: dFp8HxN-QkG7RzVQX-fPQW:APA91bF...
⚠️ IMPORTANT: This token should be automatically registered with Stream
========================================
```

---

### 2. Push Provider ต้องถูก Config ใน Stream Dashboard

**ที่ไหน:** https://dashboard.getstream.io/

**ขั้นตอน:**

1. **เลือก App ที่มี API Key: `r9mn4fsbzhub`**

2. **ไปที่ Video & Audio → Push Notifications**

3. **เพิ่ม Firebase Provider:**
   ```
   Provider Type: Firebase Cloud Messaging (FCM)
   Name: niwner_notification  ← ต้องตรงกับใน code!
   Server Key: [FCM Server Key จาก Firebase Console]
   ```

4. **หา FCM Server Key:**
   - ไปที่ Firebase Console: https://console.firebase.google.com
   - เลือกโปรเจค: `notificationforlailaolab`
   - Project Settings → Cloud Messaging
   - Copy **Server Key** (ไม่ใช่ Sender ID!)
   - หน้าตา: `AAAA...` (ยาวประมาณ 150 ตัวอักษร)

**ทำไมต้องมี:**

Stream Backend จะใช้ Server Key นี้เพื่อส่ง request ไปยัง Firebase FCM API:

```http
POST https://fcm.googleapis.com/fcm/send
Authorization: key=AAAA_YOUR_SERVER_KEY_HERE
Content-Type: application/json

{
  "to": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",  // FCM Token ของ User B
  "data": {
    "stream_call_id": "default:11d3e2b5-...",
    "stream_call_type": "default",
    // ... call data
  }
}
```

---

## 7 ขั้นตอนการส่ง Notification

### ขั้นที่ 1: User A เรียก `call.ring()`

**Code Location:** `lib/home_page.dart:240-277`

```dart
Future<void> _startCall(bool videoEnabled) async {
  final call = widget.client.makeCall(
    callType: StreamCallType.defaultType(),
    id: callId,  // เช่น: "11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5"
  );

  // สร้าง call
  await call.getOrCreate(
    memberIds: [calleeUserId],  // User B ID
    ringing: true,  // ✅ สำคัญมาก! จะไม่ส่ง notification ถ้าเป็น false
  );

  // ส่ง signal ให้ ring
  await call.ring();  // ← ตรงนี้ที่จะส่ง notification!

  debugPrint('✅ Call initiated with ringing notification');
}
```

**Parameters สำคัญ:**
- `ringing: true` - บอก Stream ว่าต้องส่ง push notification
- `memberIds: [calleeUserId]` - บอกว่าต้องส่งไปให้ใคร

---

### ขั้นที่ 2: User A → Stream Backend API

**API Call ที่ 1: `call.getOrCreate()`**

```http
POST https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  # User A Token
Stream-Auth-Type: jwt
Content-Type: application/json

{
  "members": [
    { "user_id": "68da5610e8994916f01364b8" },  // User A
    { "user_id": "68ad1babd03c44ef943bb6bb" }   // User B
  ],
  "ring": true,  // ✅ บอกว่าต้อง ring!
  "data": {
    "created_by_id": "68da5610e8994916f01364b8"
  }
}
```

**Response:**
```json
{
  "call": {
    "id": "11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
    "type": "default",
    "cid": "default:11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
    "created_by": {
      "id": "68da5610e8994916f01364b8",
      "name": "ຮືວ່າງ ວ່າງ"
    },
    "created_at": "2025-02-07T10:35:00.000Z"
  },
  "members": [
    {
      "user_id": "68da5610e8994916f01364b8",
      "role": "admin"
    },
    {
      "user_id": "68ad1babd03c44ef943bb6bb",
      "role": "user"
    }
  ]
}
```

**API Call ที่ 2: `call.ring()`**

```http
POST https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5/ring
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Stream-Auth-Type: jwt
Content-Type: application/json

{
  "ring": true
}
```

**Response:**
```json
{
  "duration": "45s"  // ระยะเวลาที่จะ ring ก่อน timeout
}
```

---

### ขั้นที่ 3: Stream Backend ประมวลผล

**สิ่งที่ Stream Backend ทำ (ภายใน Stream):**

1. **ตรวจสอบว่า User B มี devices ที่ register ไว้หรือไม่:**
   ```sql
   -- Pseudo-code ใน Stream Database
   SELECT * FROM devices
   WHERE user_id = '68ad1babd03c44ef943bb6bb'
   AND push_provider = 'niwner_notification'
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
         "user_id": "68ad1babd03c44ef943bb6bb"
       }
     ]
   }
   ```

2. **ดึง Push Provider Configuration:**
   ```json
   {
     "provider_name": "niwner_notification",
     "type": "firebase",
     "fcm_server_key": "AAAA...[Server Key จาก Dashboard]"
   }
   ```

3. **สร้าง Notification Payload:**
   ```json
   {
     "call_cid": "default:11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
     "call_id": "11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
     "type": "call.ring",
     "created_by_id": "68da5610e8994916f01364b8",
     "created_by_name": "ຮືວ່າງ ວ່າງ",
     "receiver_id": "68ad1babd03c44ef943bb6bb",
     "created_at": "2025-02-07T10:35:00.000Z"
   }
   ```

4. **เตรียมข้อมูลสำหรับ CallKit (iOS) หรือ ConnectionService (Android):**
   ```json
   {
     "title": "Incoming Call",
     "body": "ຮືວ່າງ ວ່າງ is calling...",
     "sound": "default",
     "badge": 1,
     "android_channel_id": "stream_call_notifications",
     "priority": "high",
     "click_action": "FLUTTER_NOTIFICATION_CLICK"
   }
   ```

---

### ขั้นที่ 4: Stream → Firebase FCM

**Stream Backend ส่ง HTTP Request ไปยัง Firebase:**

```http
POST https://fcm.googleapis.com/fcm/send
Authorization: key=AAAA[FCM_SERVER_KEY_FROM_DASHBOARD]
Content-Type: application/json

{
  "to": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",  // FCM Token ของ User B
  "priority": "high",
  "data": {
    "stream_call_cid": "default:11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
    "stream_call_id": "11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5",
    "stream_call_type": "default",
    "call_type": "call.ring",
    "created_by_id": "68da5610e8994916f01364b8",
    "created_by_name": "ຮືວ່າງ ວ່າງ",
    "receiver_id": "68ad1babd03c44ef943bb6bb",
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
          "body": "ຮືວ່າງ ວ່າງ is calling..."
        },
        "sound": "default",
        "category": "call"
      }
    }
  }
}
```

**Firebase Response:**
```json
{
  "multicast_id": 1234567890123456789,
  "success": 1,
  "failure": 0,
  "canonical_ids": 0,
  "results": [
    {
      "message_id": "0:1234567890123456%abc123"
    }
  ]
}
```

**หมายเหตุ:**
- `success: 1` = ส่งสำเร็จ
- `failure: 1` = ส่งไม่สำเร็จ (เช่น FCM Token invalid)

---

### ขั้นที่ 5: Firebase → User B Device

**Firebase FCM Service:**

1. **ค้นหา Device ที่มี FCM Token นี้:**
   - Firebase มี database ของทุก device ที่เคย register
   - ใช้ FCM Token เป็น key

2. **ส่ง Notification ผ่านช่องทาง:**
   - **Android:** Google Play Services
   - **iOS:** Apple Push Notification service (APNs)
   - **Web:** Service Worker (ถ้า support)

3. **Device รับ Notification:**
   - **Foreground (แอปเปิดอยู่):** ส่งตรงไปที่ Flutter code
   - **Background (แอปอยู่เบื้องหลัง):** ส่งไปที่ Background Handler
   - **Terminated (แอปปิด):** Wake up แอป → Background Handler

---

### ขั้นที่ 6: User B Device ประมวลผล

#### กรณี 1: แอปเปิดอยู่ (Foreground)

**Code Location:** `lib/home_page.dart:177-186`

```dart
void _handleRemoteMessage(RemoteMessage message) {
  debugPrint('========================================');
  debugPrint('🔔 FCM MESSAGE RECEIVED (FOREGROUND)');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Data: ${message.data}');
  debugPrint('========================================');

  // Stream SDK จะ handle โดยอัตโนมัติ
  // จะเรียก incomingCall listener ทันที
}
```

**Stream SDK ทำอะไร:**

1. **ตรวจสอบ message data:**
   ```dart
   final callCid = message.data['stream_call_cid'];  // "default:11d3e2b5-..."
   final callType = message.data['call_type'];        // "call.ring"
   ```

2. **Query call data จาก Stream Backend:**
   ```http
   GET https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5
   Authorization: [User B Token]
   Stream-Auth-Type: jwt
   ```

3. **สร้าง Call object:**
   ```dart
   final call = StreamVideo.instance.makeCall(
     callType: StreamCallType.defaultType(),
     id: '11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5',
   );
   ```

4. **อัพเดต state และ trigger listener:**
   ```dart
   StreamVideo.instance.state.incomingCall.value = call;
   ```

5. **Listener รับ event:**

**Code Location:** `lib/home_page.dart:161-175`

```dart
void _observeIncomingCalls() {
  _incomingCallSub = StreamVideo.instance.state.incomingCall.listen((call) {
    debugPrint('========================================');
    debugPrint('📞 INCOMING CALL EVENT RECEIVED');
    debugPrint('Call ID: ${call?.id}');
    debugPrint('Caller: ${call?.state.value.createdBy?.name}');
    debugPrint('========================================');

    if (!mounted || call == null) return;

    // เปิดหน้า CallScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(call: call, role: CallUiRole.callee),
      ),
    );
  });
}
```

6. **CallScreen แสดงขึ้น:**

**Code Location:** `lib/call_screen.dart`

```dart
class CallScreen extends StatefulWidget {
  final Call call;
  final CallUiRole role;  // CallUiRole.callee

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    super.initState();

    if (widget.role == CallUiRole.callee) {
      // แสดง UI รับสาย
      // มีปุ่ม Accept และ Reject
    }
  }
}
```

#### กรณี 2: แอปอยู่เบื้องหลัง (Background) หรือปิดอยู่ (Terminated)

**Code Location:** `lib/firebase_background_handler.dart`

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

  // Stream SDK Background Handler
  await StreamVideoPushNotificationManager.onBackgroundMessage(
    message,
    callDisplayHelper: CallDisplayHelper(),  // Custom UI
  );
}
```

**Stream Background Handler ทำอะไร:**

1. **แสดง Native Call UI (CallKit/ConnectionService):**

   **iOS (CallKit):**
   ```swift
   // Stream SDK เรียก iOS CallKit API
   CXCallUpdate *update = [[CXCallUpdate alloc] init];
   update.localizedCallerName = @"ຮືວ່າງ ວ່າງ";
   update.hasVideo = YES;

   [callController reportNewIncomingCall:uuid update:update completion:^(NSError *error) {
     // แสดงหน้าจอรับสายแบบ iOS native
   }];
   ```

   **Android (ConnectionService):**
   ```kotlin
   // Stream SDK เรียก Android Telecom API
   val phoneAccount = PhoneAccountHandle(...)
   val extras = Bundle().apply {
       putString("caller_name", "ຮືວ່າງ ວ່າງ")
       putString("call_id", "11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5")
   }

   telecomManager.addNewIncomingCall(phoneAccount, extras)
   // แสดงหน้าจอรับสายแบบ Android native
   ```

2. **User กด Accept:**
   - Native UI จะเรียก callback
   - Stream SDK wake up แอป Flutter
   - เปิดหน้า CallScreen
   - เริ่มต่อสาย

---

### ขั้นที่ 7: Logs ที่เห็นใน User B Device

**Foreground Logs:**
```
========================================
🔔 FCM MESSAGE RECEIVED (FOREGROUND)
Message ID: 0:1234567890123456%abc123
Data: {
  stream_call_cid: default:11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5,
  stream_call_id: 11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5,
  stream_call_type: default,
  call_type: call.ring,
  created_by_id: 68da5610e8994916f01364b8,
  created_by_name: ຮືວ່າງ ວ່າງ,
  receiver_id: 68ad1babd03c44ef943bb6bb
}
========================================

========================================
📞 INCOMING CALL EVENT RECEIVED
Call ID: 11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5
Caller: ຮືວ່າງ ວ່າງ
========================================

[Navigator] Pushing CallScreen...
```

**Background Logs:**
```
========================================
🔔 BACKGROUND FCM MESSAGE RECEIVED
Message ID: 0:1234567890123456%abc123
Message data: {stream_call_cid: default:11d3e2b5-..., ...}
========================================

[CallKit] Showing incoming call UI
[CallKit] Caller: ຮືວ່າງ ວ່າງ
```

---

## Code ที่เกี่ยวข้อง

### 1. FCM Token Registration

**File:** `lib/app_initializer.dart:68-91`

```dart
static StreamVideo createClient({
  required User user,
  required String apiKey,
  required String userToken,
  bool attachPushManager = true,
}) {
  final client = StreamVideo(
    apiKey,
    user: user,
    userToken: userToken,
    pushNotificationManagerProvider: attachPushManager
        ? StreamVideoPushNotificationManager.create(
            androidPushProvider: const StreamVideoPushProvider.firebase(
              name: 'niwner_notification',  // ← ต้องตรงกับ Dashboard
            ),
            iosPushProvider: const StreamVideoPushProvider.apn(
              name: 'niwner_notification',
            ),
            onNotificationResponse: (remoteMessage, call) async {
              debugPrint('🔔 Notification tapped!');
              return NavigationResult.proceed;
            },
          )
        : null,
  );

  return client;
}
```

### 2. Monitoring FCM Token

**File:** `lib/home_page.dart:146-159`

```dart
void _monitorFcmTokenChanges() {
  FirebaseMessaging.instance.getToken().then((token) {
    if (token != null) {
      debugPrint('========================================');
      debugPrint('📱 CURRENT FCM TOKEN FOR ${widget.client.currentUser.name}');
      debugPrint('Full Token: $token');
      debugPrint('========================================');
    }
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    debugPrint('🔄 FCM Token refreshed: $token');
    // Stream SDK จะ register token ใหม่โดยอัตโนมัติ
  });
}
```

### 3. Initiating Call with Ringing

**File:** `lib/home_page.dart:240-277`

```dart
Future<void> _startCall(bool videoEnabled) async {
  final call = widget.client.makeCall(
    callType: StreamCallType.defaultType(),
    id: callId,
  );

  debugPrint('========================================');
  debugPrint('📞 INITIATING CALL');
  debugPrint('Call ID: $callId');
  debugPrint('Callee User ID: $calleeUserId');
  debugPrint('Ringing: true');
  debugPrint('========================================');

  await call.getOrCreate(
    memberIds: [calleeUserId],
    ringing: true,  // ✅ ต้องมี!
  );

  await call.ring();  // ✅ ส่ง notification

  debugPrint('✅ Call ring notification sent');
}
```

### 4. Receiving Incoming Call (Foreground)

**File:** `lib/home_page.dart:161-175`

```dart
void _observeIncomingCalls() {
  _incomingCallSub = StreamVideo.instance.state.incomingCall.listen((call) {
    debugPrint('========================================');
    debugPrint('📞 INCOMING CALL EVENT RECEIVED');
    debugPrint('Call ID: ${call?.id}');
    debugPrint('Caller: ${call?.state.value.createdBy?.name}');
    debugPrint('========================================');

    if (!mounted || call == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(call: call, role: CallUiRole.callee),
      ),
    );
  });
}
```

### 5. Handling FCM Messages (Foreground)

**File:** `lib/home_page.dart:177-186`

```dart
void _handleRemoteMessage(RemoteMessage message) {
  debugPrint('========================================');
  debugPrint('🔔 FCM MESSAGE RECEIVED (FOREGROUND)');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Data: ${message.data}');
  debugPrint('From: ${message.from}');
  debugPrint('========================================');

  // Stream SDK จะ process message และเรียก incomingCall listener
}
```

### 6. Background Handler

**File:** `lib/firebase_background_handler.dart`

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

**File:** `lib/main.dart:37-38`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}
```

---

## Network Requests

### 1. Register FCM Token with Stream

```http
POST https://video.stream-io-api.com/api/v2/devices
Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Stream-Auth-Type: jwt
Content-Type: application/json

{
  "id": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",
  "push_provider": "firebase",
  "push_provider_name": "niwner_notification",
  "user_id": "68ad1babd03c44ef943bb6bb"
}
```

### 2. Create Call with Ringing

```http
POST https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5
Authorization: [User A Token]
Stream-Auth-Type: jwt

{
  "members": [
    {"user_id": "68da5610e8994916f01364b8"},
    {"user_id": "68ad1babd03c44ef943bb6bb"}
  ],
  "ring": true
}
```

### 3. Send Ring Signal

```http
POST https://video.stream-io-api.com/api/v2/video/call/default/11d3e2b5-19c4-4f1c-bd42-f0ea8d8ba9f5/ring
Authorization: [User A Token]
Stream-Auth-Type: jwt

{"ring": true}
```

### 4. Stream → Firebase FCM

```http
POST https://fcm.googleapis.com/fcm/send
Authorization: key=[FCM_SERVER_KEY]
Content-Type: application/json

{
  "to": "dFp8HxN-QkG7RzVQX-fPQW:APA91bF...",
  "priority": "high",
  "data": {
    "stream_call_cid": "default:11d3e2b5-...",
    "call_type": "call.ring",
    "created_by_name": "ຮືວ່າງ ວ່າງ"
  }
}
```

---

## Troubleshooting

### ❌ ปลายทางไม่ได้รับ Notification

#### 1. ตรวจสอบ `attachPushManager`

**File:** `lib/app_initializer.dart:68`

```dart
attachPushManager: true,  // ✅ ต้องเป็น true
```

**ถ้าเป็น `false`:**
- FCM Token จะไม่ถูก register กับ Stream
- Stream จะไม่รู้ว่าจะส่ง notification ไปที่ไหน

#### 2. ตรวจสอบ Push Provider ใน Stream Dashboard

```
Dashboard → Video & Audio → Push Notifications

✅ ต้องมี Provider:
   Name: niwner_notification
   Type: Firebase Cloud Messaging
   Server Key: AAAA... (ถูกต้อง)
```

**Test:**
ลองส่ง test notification จาก Stream Dashboard

#### 3. ตรวจสอบ FCM Token

**รัน:**
```bash
flutter run -d DEVICE_ID
```

**ดู logs:**
```
📱 CURRENT FCM TOKEN FOR tangiro kamado
Full Token: dFp8HxN-QkG7RzVQX-fPQW:APA91bF...
```

**ถ้าไม่เห็น token:**
- Firebase ไม่ทำงาน
- ตรวจสอบ `google-services.json` และ `GoogleService-Info.plist`

#### 4. ตรวจสอบ Firebase Configuration

**Android:** `android/app/google-services.json`
```json
{
  "project_info": {
    "project_id": "notificationforlailaolab"  // ✅ ต้องถูก
  }
}
```

**iOS:** `ios/Runner/GoogleService-Info.plist`
```xml
<key>PROJECT_ID</key>
<string>notificationforlailaolab</string>  <!-- ✅ ต้องถูก -->
```

**Test:**
```bash
dart check_firebase_config.dart
```

#### 5. ตรวจสอบ Token Signature

**รัน:**
```bash
dart test_backend_token.dart
```

**ต้องเห็น:**
```
✅ TOKEN IS VALID!
```

**ถ้าเห็น:**
```
❌ Token signature is invalid
```
→ แก้ไข backend `STREAM_API_SECRET` ตามคู่มือ `FIX_BACKEND_SECRET.md`

#### 6. ตรวจสอบ `ringing: true`

**File:** `lib/home_page.dart:266`

```dart
await call.getOrCreate(
  memberIds: [calleeUserId],
  ringing: true,  // ✅ ต้องเป็น true
);
```

**ถ้าเป็น `false`:**
- Stream จะไม่ส่ง notification
- ปลายทางต้อง poll เอง (ไม่แนะนำ)

#### 7. ตรวจสอบ Network Logs

**Chrome (User A):**
```
Dev Tools → Network → Filter: "ring"
```

**ต้องเห็น:**
```
POST /video/call/default/.../ring
Status: 200 OK
```

**Stream Dashboard:**
```
Dashboard → Logs
```

**ต้องเห็น:**
- `call.ring` event
- `push.sent` event

---

### ❌ Notification มาแต่ไม่แสดง UI

#### 1. Foreground - ไม่เปิด CallScreen

**ตรวจสอบ:** `lib/home_page.dart:161-175`

```dart
void _observeIncomingCalls() {
  _incomingCallSub = StreamVideo.instance.state.incomingCall.listen((call) {
    // ต้องมี logs นี้
    debugPrint('📞 INCOMING CALL EVENT RECEIVED');

    // ต้อง push navigator
    Navigator.push(...);
  });
}
```

**ถ้าไม่เห็น logs:**
- Listener ไม่ทำงาน
- ตรวจสอบว่า `_observeIncomingCalls()` ถูกเรียกใน `initState()`

#### 2. Background - ไม่แสดง CallKit/ConnectionService

**Android:**

**File:** `android/app/src/main/AndroidManifest.xml`

ต้องมี permissions:
```xml
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

**iOS:**

**File:** `ios/Runner/Info.plist`

ต้องมี:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>voip</string>
  <string>remote-notification</string>
</array>
```

---

### ❌ Notification มาช้า

**สาเหตุ:**
1. **Device Battery Optimization:**
   - Android: Settings → Battery → [App] → No restrictions
   - iOS: ปกติไม่มีปัญหา

2. **FCM Priority ต่ำ:**
   - Stream SDK ส่ง `priority: high` อยู่แล้ว
   - ถ้ามีปัญหา → ตรวจสอบ Firebase quota

3. **Network Latency:**
   - User A → Stream: ~100-200ms
   - Stream → Firebase: ~50-100ms
   - Firebase → User B: ~100-500ms
   - Total: ~300-800ms (ปกติ)

**Test:**
```bash
# Terminal 1 (User A)
flutter run -d chrome

# Terminal 2 (User B)
flutter run -d DEVICE_ID

# เริ่มโทร → เช็คเวลา
```

---

## สรุป Flow ทั้งหมด

```
1. User B เปิดแอป
   → Firebase gives FCM Token
   → Stream SDK registers token with Stream Backend
   → Stream Database: {user_id: B, fcm_token: "dFp..."}

2. User A กดโทร
   → call.getOrCreate(ringing: true)
   → call.ring()

3. Stream Backend รับ request
   → Query: User B มี devices ไหม?
   → Found: FCM Token "dFp..."
   → ดึง Push Provider config: "niwner_notification"

4. Stream → Firebase
   → POST https://fcm.googleapis.com/fcm/send
   → Authorization: key=[FCM_SERVER_KEY]
   → Body: {to: "dFp...", data: {call_cid: "...", ...}}

5. Firebase → User B Device
   → ค้นหา device ที่มี token "dFp..."
   → ส่งผ่าน Google Play Services (Android) / APNs (iOS)

6. User B Device รับ notification
   → Foreground: _handleRemoteMessage() → incomingCall listener → CallScreen
   → Background: firebaseMessagingBackgroundHandler() → CallKit/ConnectionService UI

7. User B เห็น incoming call
   → กด Accept/Reject
   → เริ่มสาย (ถ้า accept)
```

---

## Checklist สำหรับ Debugging

- [ ] `attachPushManager: true` ใน app_initializer.dart
- [ ] เห็น FCM Token ใน logs เมื่อเปิดแอป
- [ ] Push Provider "niwner_notification" ใน Stream Dashboard
- [ ] FCM Server Key ถูกต้องใน Dashboard
- [ ] Firebase Config ถูกต้อง (project: notificationforlailaolab)
- [ ] Token signature ผ่านการ validate
- [ ] `ringing: true` ใน call.getOrCreate()
- [ ] เรียก `call.ring()` หลังจาก getOrCreate()
- [ ] มี FCM message logs ในฝั่ง User B
- [ ] มี incoming call event logs ในฝั่ง User B
- [ ] Permissions ครบถ้วนใน AndroidManifest.xml / Info.plist

---

## 🆘 ถ้ายังแก้ไม่ได้

ส่งข้อมูลเหล่านี้:
1. **User A logs:** เวลากด call.ring()
2. **User B logs:** ทั้ง foreground และ background
3. **Stream Dashboard logs:** Dashboard → Logs → filter "ring"
4. **Firebase Console:** Cloud Messaging → Test notification to User B
5. **Screenshots:** Push Provider config ใน Stream Dashboard

---

**ไฟล์นี้อธิบายทุกขั้นตอนของการส่ง Push Notification แบบละเอียดแล้ว 🎉**

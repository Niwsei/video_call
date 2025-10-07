# 📖 คำอธิบายโค้ดแต่ละส่วนอย่างละเอียด

## สารบัญ
1. [Backend Code Explanation](#backend-code-explanation)
2. [Flutter App Code Explanation](#flutter-app-code-explanation)
3. [Stream Video SDK Methods](#stream-video-sdk-methods)
4. [Firebase Messaging Methods](#firebase-messaging-methods)
5. [Error Handling](#error-handling)
6. [Best Practices](#best-practices)

---

# Backend Code Explanation

## 1. Environment Variables (.env)

```env
PORT=8181
STREAM_API_KEY=r9mn4fsbzhub
STREAM_API_SECRET=your_api_secret_here
TOKEN_TTL_SECONDS=86400
```

### คำอธิบาย:
- **`PORT`**: พอร์ตที่ backend server จะรัน (8181)
  - ทำไมใช้ 8181: หลีกเลี่ยง conflict กับพอร์ตทั่วไป (3000, 8080)

- **`STREAM_API_KEY`**: API Key จาก Stream Dashboard
  - **Public key** - สามารถใส่ใน app ได้
  - ใช้ระบุว่าเป็น app ไหน

- **`STREAM_API_SECRET`**: API Secret จาก Stream Dashboard
  - **MUST BE SECRET!** - ห้ามใส่ใน app
  - ใช้ sign JWT token
  - ถ้ารั่วไหล = คนอื่นสามารถปลอมแปลง token ได้

- **`TOKEN_TTL_SECONDS`**: ระยะเวลาที่ token ใช้งานได้ (วินาที)
  - 86400 = 24 ชั่วโมง
  - สั้นเกินไป = user ต้อง login บ่อย
  - ยาวเกินไป = เสี่ยงด้านความปลอดภัย

---

## 2. Token Generation (streamController.ts)

```typescript
import jwt from 'jsonwebtoken';

const STREAM_API_SECRET = process.env.STREAM_API_SECRET!;
const STREAM_API_KEY = process.env.STREAM_API_KEY!;
const TOKEN_TTL = Number(process.env.TOKEN_TTL_SECONDS) || 3600;
```

### คำอธิบาย:
- **`jsonwebtoken`**: library สำหรับสร้างและ verify JWT tokens
- **`process.env.VARIABLE!`**: อ่านค่าจาก environment variables
  - `!` = TypeScript non-null assertion (บอกว่าค่านี้ต้องมี)

---

```typescript
export const generateStreamToken = (req: any, res: any) => {
```

### คำอธิบาย:
- **`export`**: ทำให้ function นี้สามารถ import ได้จากไฟล์อื่น
- **`req`**: Request object จาก Express (ข้อมูลที่ client ส่งมา)
- **`res`**: Response object จาก Express (ใช้ส่งข้อมูลกลับ)

---

```typescript
const userId = req.user?.userId || req.body?.userId;

if (!userId) {
  return res.status(400).json({ error: 'userId is required' });
}
```

### คำอธิบาย:
- **`req.user?.userId`**: ดึง userId จาก JWT token (ถ้ามี authentication middleware)
  - `?.` = optional chaining (ถ้า req.user เป็น null/undefined จะไม่ error)
- **`req.body?.userId`**: ดึง userId จาก request body (fallback)
- **`||`**: ใช้ค่าซ้ายถ้ามี ไม่งั้นใช้ค่าขวา

**Flow:**
1. ลอง get userId จาก JWT token ก่อน (secure)
2. ถ้าไม่มี → ลอง get จาก body
3. ถ้ายังไม่มี → return error 400 (Bad Request)

---

```typescript
const issuedAt = Math.floor(Date.now() / 1000);
const expiresAt = issuedAt + TOKEN_TTL;
```

### คำอธิบาย:
- **`Date.now()`**: เวลาปัจจุบันใน milliseconds (เช่น 1759900000000)
- **`/ 1000`**: แปลงเป็น seconds (JWT ใช้ seconds)
- **`Math.floor()`**: ปัดเศษลง (ตัดทศนิยมทิ้ง)
- **`issuedAt`**: เวลาที่ token ถูกสร้าง (iat = issued at)
- **`expiresAt`**: เวลาที่ token หมดอายุ (exp = expiration)

**ตัวอย่าง:**
```
issuedAt = 1759900000   // 7 Feb 2025, 10:00:00
TOKEN_TTL = 86400       // 24 hours
expiresAt = 1759986400  // 8 Feb 2025, 10:00:00
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

### คำอธิบาย:

**`jwt.sign()` parameters:**

1. **Payload (object แรก):**
   - **`user_id`**: ID ของ user (Stream ต้องการชื่อนี้เป๊ะ)
   - **`validity_in_seconds`**: ระยะเวลาที่ valid (optional, แต่ Stream แนะนำให้ใส่)
   - **`iat`**: issued at timestamp
   - **`exp`**: expiration timestamp (สำคัญ! ป้องกัน token ใช้ตลอดไป)

2. **Secret (string):**
   - ใช้ sign token
   - ต้องเป็นค่าเดียวกับที่ Stream มี
   - ถ้าผิด = "Token signature is invalid"

3. **Options (object สาม):**
   - **`algorithm: 'HS256'`**: วิธี sign token
     - HS256 = HMAC with SHA-256
     - Stream รองรับเฉพาะ HS256

**ผลลัพธ์:**
```
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIiwiaWF0IjoxNzU5OTAwMDAwLCJleHAiOjE3NTk5ODY0MDB9.abcd1234..."
```

**โครงสร้าง JWT Token:**
```
[Header].[Payload].[Signature]

Header (Base64):
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload (Base64):
{
  "user_id": "123",
  "iat": 1759900000,
  "exp": 1759986400
}

Signature:
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  STREAM_API_SECRET
)
```

---

```typescript
return res.json({
  apiKey: STREAM_API_KEY,
  userId: userId,
  token: token,
  expiresAt: expiresAt,
});
```

### คำอธิบาย:
- **`res.json()`**: ส่ง response เป็น JSON format
- **Response body:**
  ```json
  {
    "apiKey": "r9mn4fsbzhub",     // สำหรับ StreamVideo(apiKey, ...)
    "userId": "user-123",          // สำหรับ User(id: userId, ...)
    "token": "eyJhbGc...",         // สำหรับ userToken: token
    "expiresAt": 1759986400        // เช็คว่า token หมดอายุหรือยัง
  }
  ```

---

## 3. Router (streamRoutes.ts)

```typescript
import { Router } from 'express';
import { generateStreamToken } from '../controllers/streamController';

const router = Router();

router.post('/callStreams', generateStreamToken);

export default router;
```

### คำอธิบาย:
- **`Router()`**: สร้าง Express router object
- **`router.post(path, handler)`**: กำหนด route สำหรับ POST request
  - **path**: `/callStreams`
  - **handler**: `generateStreamToken` function

**URL สมบูรณ์:**
```
POST http://localhost:8181/v1/api/callStreams
```

**ทำไมใช้ POST แทน GET:**
- POST = ส่ง sensitive data ใน body (ปลอดภัยกว่า)
- GET = ส่งใน URL query (อาจถูก log ไว้)

---

## 4. Server (index.ts)

```typescript
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
```

### คำอธิบาย Libraries:
- **`express`**: Web framework สำหรับสร้าง API
- **`cors`**: Cross-Origin Resource Sharing
  - อนุญาตให้ app จาก domain อื่นเรียก API ได้
  - ถ้าไม่มี = Flutter app เรียกไม่ได้
- **`dotenv`**: โหลด environment variables จาก `.env` file

---

```typescript
dotenv.config();
```

### คำอธิบาย:
- อ่านไฟล์ `.env` และใส่ค่าเข้า `process.env`
- **ต้องเรียกก่อน** ใช้ `process.env.VARIABLE`

---

```typescript
const app = express();
const PORT = process.env.PORT || 8181;
```

### คำอธิบาย:
- **`express()`**: สร้าง Express application
- **`PORT`**: ใช้พอร์ตจาก .env ถ้าไม่มีใช้ 8181

---

```typescript
app.use(cors());
app.use(express.json());
```

### คำอธิบาย:
- **`app.use()`**: เพิ่ม middleware
- **`cors()`**: เปิดให้ทุก origin เรียก API ได้
  - Production ควรระบุ origin: `cors({ origin: 'https://myapp.com' })`
- **`express.json()`**: parse JSON request body
  - ทำให้เข้าถึง `req.body` ได้

---

```typescript
app.use('/v1/api', streamRoutes);
```

### คำอธิบาย:
- **Mount router** ที่ path `/v1/api`
- routes ใน `streamRoutes` จะเป็น `/v1/api/...`

**Example:**
```
router.post('/callStreams', ...)
→ POST /v1/api/callStreams
```

---

```typescript
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Server is running' });
});
```

### คำอธิบาย:
- **Health check endpoint**
- ใช้ตรวจสอบว่า server รันอยู่หรือไม่
- **ไม่ต้อง authentication** (public)

---

```typescript
app.listen(PORT, () => {
  console.log(`✅ Server is running on port ${PORT}`);
});
```

### คำอธิบาย:
- **`app.listen(port, callback)`**: เริ่ม server
- **callback**: ทำงานเมื่อ server พร้อมแล้ว

---

# Flutter App Code Explanation

## 1. Firebase Background Handler

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
```

### คำอธิบาย:
- **`@pragma('vm:entry-point')`**: บอก Dart compiler ว่า function นี้ถูกเรียกจาก native code
  - **ถ้าไม่มี**: tree-shaking อาจลบ function นี้ทิ้ง (optimize)
  - **จำเป็น** สำหรับ background handlers

- **`Future<void>`**: function นี้เป็น async และไม่ return ค่า
- **`RemoteMessage`**: object ที่มีข้อมูล notification จาก FCM

---

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### คำอธิบาย:
- **ต้อง initialize Firebase** ก่อนใช้งาน
- **`DefaultFirebaseOptions.currentPlatform`**: เลือก config ตาม platform
  - Android → `DefaultFirebaseOptions.android`
  - iOS → `DefaultFirebaseOptions.ios`
  - Web → `DefaultFirebaseOptions.web`

**ทำไมต้อง init ใหม่:**
- Background handler รันใน **isolate แยก**
- ไม่ share state กับ main app
- ต้อง init Firebase ใหม่

---

```dart
await StreamVideoPushNotificationManager.onBackgroundMessage(message);
```

### คำอธิบาย:
- **Stream SDK method** สำหรับจัดการ notification ใน background
- **ทำอะไร:**
  1. Parse message data (`stream_call_cid`, `call_type`, etc.)
  2. Query call info จาก Stream API
  3. แสดง **CallKit (iOS)** หรือ **ConnectionService (Android)**
  4. รอ user กด Accept/Reject

**Parameters:**
- **`message`**: `RemoteMessage` object จาก FCM

**Return:** `Future<void>`

**หมายเหตุ:**
- **ไม่ต้อง** parse message เอง
- Stream SDK handle ให้หมดแล้ว

---

## 2. Stream Service (stream_service.dart)

```dart
class StreamService {
  static StreamVideo? _client;
```

### คำอธิบาย:
- **Singleton pattern**: มี Stream client เดียวทั้ง app
- **`static`**: เข้าถึงได้โดยไม่ต้องสร้าง instance
  - `StreamService.initialize()` แทน `StreamService().initialize()`
- **`_client`**: private variable (ขึ้นต้นด้วย `_`)
- **`StreamVideo?`**: nullable type (อาจเป็น null)

---

```dart
static Future<StreamVideo> initialize({
  required String apiKey,
  required String userId,
  required String userName,
  required String userToken,
}) async {
```

### คำอธิบาย Parameters:
- **`required`**: parameter บังคับต้องใส่
- **`apiKey`**: จาก backend response (`data['apiKey']`)
- **`userId`**: unique ID ของ user
- **`userName`**: display name
- **`userToken`**: JWT token จาก backend

**Return:** `Future<StreamVideo>` - Stream client object

---

```dart
if (_client != null) {
  return _client!;
}
```

### คำอธิบาย:
- **Check ว่า init แล้วหรือยัง**
- ถ้า init แล้ว → return client เดิม (ไม่สร้างใหม่)
- **`!`**: force unwrap (บอกว่าค่าไม่ใช่ null แน่ๆ)

**ทำไมต้องเช็ค:**
- ป้องกันสร้าง client หลายตัว
- ประหยัด resource

---

```dart
final user = User(id: userId, name: userName);
```

### คำอธิบาย:
- **`User`**: Stream SDK class
- **Constructor:**
  ```dart
  User({
    required String id,        // unique user ID
    String? name,              // display name (optional)
    String? image,             // profile image URL (optional)
    Map<String, Object?>? extraData,  // custom data (optional)
  })
  ```

**ตัวอย่าง:**
```dart
final user = User(
  id: 'user-123',
  name: 'Alice',
  image: 'https://example.com/alice.jpg',
  extraData: {
    'phone': '+66812345678',
    'email': 'alice@example.com',
  },
);
```

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

### คำอธิบาย:

**`StreamVideo` Constructor:**
```dart
StreamVideo(
  String apiKey,                                    // Stream API Key
  {
    required User user,                             // User object
    required String userToken,                      // JWT token
    StreamVideoPushNotificationManager? pushNotificationManagerProvider,  // Push manager
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
  }
)
```

**Parameters:**

1. **`apiKey`**:
   - จาก Stream Dashboard
   - ใช้ระบุว่าเป็น app ไหน

2. **`user`**:
   - User object ที่สร้างไว้
   - มี id และ name

3. **`userToken`**:
   - JWT token จาก backend
   - ใช้ authenticate กับ Stream API

4. **`pushNotificationManagerProvider`**:
   - **Optional** แต่ **จำเป็น** ถ้าต้องการ push notifications
   - Config ว่าจะใช้ push provider ไหน

---

### Push Notification Manager

```dart
StreamVideoPushNotificationManager.create(
  androidPushProvider: const StreamVideoPushProvider.firebase(
    name: 'niwner_notification',
  ),
  iosPushProvider: const StreamVideoPushProvider.apn(
    name: 'niwner_notification',
  ),
)
```

### คำอธิบาย:

**`StreamVideoPushNotificationManager.create()`:**
- สร้าง manager สำหรับจัดการ push notifications
- **ทำอะไร:**
  1. Get FCM Token (Android) / APNs Token (iOS)
  2. Register token กับ Stream Backend
  3. Listen for incoming notifications
  4. Show CallKit/ConnectionService UI

**Parameters:**

1. **`androidPushProvider`**:
   ```dart
   StreamVideoPushProvider.firebase({
     required String name,  // Push provider name ใน Stream Dashboard
   })
   ```
   - **`name`**: ต้องตรงกับที่ config ใน Stream Dashboard

2. **`iosPushProvider`**:
   ```dart
   StreamVideoPushProvider.apn({
     required String name,  // Push provider name
   })
   ```

**ทำไม provider name ต้องตรง:**
```
Flutter App:
  name: 'niwner_notification'
     ↓ register FCM token
Stream Backend:
  Which provider to use?
  → Look for provider named 'niwner_notification'
  → Use FCM Server Key from that provider
     ↓ send push
Firebase:
  Receive push with that Server Key
     ↓ route to device
User Device:
  Show notification
```

---

```dart
await _client!.connect();
```

### คำอธิบาย:
- **`connect()`**: เชื่อมต่อกับ Stream Backend
- **ทำอะไร:**
  1. Validate JWT token
  2. Open WebSocket connection
  3. Sync user state
  4. Register push token

**Return:** `Future<void>`

**Errors:**
- `StreamWebSocketError`: network error
- `StreamAuthenticationError`: token invalid
- `StreamTimeoutError`: connect timeout

---

```dart
static StreamVideo get client {
  if (_client == null) {
    throw Exception('StreamVideo not initialized');
  }
  return _client!;
}
```

### คำอธิบาย:
- **Getter**: เข้าถึงเหมือน property
  - `StreamService.client` แทน `StreamService.getClient()`
- **Check null**: ถ้ายัง init จะ throw error
- **Safe access**: ป้องกันใช้งานก่อน init

---

## 3. Login Page

```dart
final response = await http.post(
  Uri.parse('http://localhost:8181/v1/api/callStreams'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'userId': userId}),
);
```

### คำอธิบาย:

**`http.post()` Parameters:**

1. **`Uri.parse(url)`**: แปลง string เป็น Uri object
   - **Production**: ต้องเปลี่ยนเป็น URL จริง
   ```dart
   Uri.parse('https://api.myapp.com/v1/api/callStreams')
   ```

2. **`headers`**: HTTP headers
   - **`Content-Type: application/json`**: บอกว่าส่ง JSON
   - สามารถเพิ่ม Authorization header:
   ```dart
   headers: {
     'Content-Type': 'application/json',
     'Authorization': 'Bearer $appJwtToken',
   }
   ```

3. **`body`**: request body
   - **ต้องเป็น string**
   - ใช้ `jsonEncode()` แปลง Map → JSON string
   ```dart
   {'userId': 'user-123'}  // Map
   ↓ jsonEncode()
   '{"userId":"user-123"}'  // String
   ```

**Response:**
```dart
class Response {
  int statusCode;      // 200, 400, 500, etc.
  String body;         // Response body (JSON string)
  Map<String, String> headers;
}
```

---

```dart
if (response.statusCode != 200) {
  throw Exception('Failed to get token');
}

final data = jsonDecode(response.body);
```

### คำอธิบาย:
- **Check status code**: 200 = success
- **`jsonDecode()`**: แปลง JSON string → Map
  ```dart
  '{"apiKey":"abc","userId":"123"}'  // String
  ↓ jsonDecode()
  {'apiKey': 'abc', 'userId': '123'}  // Map
  ```

---

```dart
await StreamService.initialize(
  apiKey: data['apiKey'],
  userId: userId,
  userName: userName,
  userToken: data['token'],
);
```

### คำอธิบาย:
- **Initialize Stream client** ด้วย data จาก backend
- **`data['apiKey']`**: access Map value
  - Type: `dynamic` (ต้อง cast เป็น String)

---

## 4. Home Page - Making Call

```dart
final callId = const Uuid().v4();
```

### คำอธิบาย:
- **`Uuid()`**: UUID generator (package: `uuid`)
- **`.v4()`**: สร้าง random UUID version 4
  - Format: `550e8400-e29b-41d4-a716-446655440000`
  - **Unique globally** (โอกาส collision = 0)

**ทำไมต้องใช้ UUID:**
- Call ID ต้อง **unique**
- ถ้าซ้ำ = conflict กับ call อื่น

---

```dart
final call = StreamService.client.makeCall(
  callType: StreamCallType.defaultType(),
  id: callId,
);
```

### คำอธิบาย:

**`makeCall()` Method:**
```dart
Call makeCall({
  required StreamCallType callType,  // ประเภท call
  required String id,                // Call ID (unique)
})
```

**Parameters:**

1. **`callType`**: ประเภทของ call
   ```dart
   // Built-in types:
   StreamCallType.defaultType()      // default
   StreamCallType.audioRoom()        // audio only room
   StreamCallType.livestream()       // livestream

   // Custom type:
   StreamCallType('my-custom-type')
   ```

2. **`id`**: Call ID
   - ต้อง unique
   - ใช้ระบุ call
   - Format: ใช้ UUID แนะนำ

**Return:** `Call` object

**Call object คืออะไร:**
- Represents call session
- มี methods: `getOrCreate()`, `ring()`, `accept()`, `leave()`
- มี state: members, duration, status

---

```dart
await call.getOrCreate(
  memberIds: [calleeId],
  ringing: true,
);
```

### คำอธิบาย:

**`getOrCreate()` Method:**
```dart
Future<GetOrCreateCallResponse> getOrCreate({
  List<String>? memberIds,        // User IDs ที่จะเป็น members
  bool ringing = false,           // ส่ง push notification หรือไม่
  bool notify = true,             // ส่ง event notification หรือไม่
  String? team,                   // Team ID (multi-tenant)
  Map<String, Object?>? custom,   // Custom data
  CallSettings? settings,         // Call settings (audio/video quality)
})
```

**Parameters:**

1. **`memberIds`**: รายชื่อ user IDs ที่จะเป็น members
   ```dart
   memberIds: ['user-a', 'user-b', 'user-c']
   ```
   - **ไม่ต้องใส่ตัวเอง** (auto add)
   - สำหรับ 1-on-1: ใส่ 1 คน
   - สำหรับ group: ใส่หลายคน

2. **`ringing`**: สำคัญมาก!
   - **`true`**: ส่ง push notification ไปหา members
   - **`false`**: ไม่ส่ง (members ต้อง join เอง)

   **Use cases:**
   ```dart
   // 1-on-1 call → ringing: true
   call.getOrCreate(memberIds: ['user-b'], ringing: true);

   // Group room → ringing: false (คนเข้าเมื่อพร้อม)
   call.getOrCreate(memberIds: ['user-b', 'user-c'], ringing: false);
   ```

3. **`notify`**: ส่ง WebSocket event หรือไม่
   - **`true`**: members ที่ online จะได้รับ event ทันที
   - **`false`**: ไม่ส่ง event

4. **`custom`**: custom data
   ```dart
   custom: {
     'callReason': 'Technical support',
     'priority': 'high',
   }
   ```

**Return:**
```dart
class GetOrCreateCallResponse {
  Call call;               // Call object
  bool created;            // true = สร้างใหม่, false = มีอยู่แล้ว
  List<Member> members;    // Members ทั้งหมด
}
```

**สิ่งที่เกิดขึ้น:**
1. ตรวจสอบว่า call ID นี้มีอยู่แล้วหรือไม่
2. ถ้าไม่มี → สร้างใหม่
3. เพิ่ม members
4. ถ้า `ringing: true` → trigger push notification

---

```dart
await call.ring();
```

### คำอธิบาย:

**`ring()` Method:**
```dart
Future<CallRingResponse> ring({
  Duration timeout = const Duration(seconds: 45),  // Ringing timeout
})
```

**ทำอะไร:**
- ส่ง signal ให้ members ว่า call กำลัง ring
- **ต่างจาก `getOrCreate(ringing: true)`:**
  - `getOrCreate(ringing: true)`: สร้าง call + ring
  - `ring()`: ring อีกครั้ง (สำหรับ call ที่มีอยู่แล้ว)

**Use case:**
```dart
// Scenario 1: สร้างใหม่และ ring
await call.getOrCreate(memberIds: ['user-b'], ringing: true);
// ไม่ต้อง call.ring() อีก

// Scenario 2: Ring อีกครั้ง (retry)
await call.getOrCreate(memberIds: ['user-b'], ringing: true);
await Future.delayed(Duration(seconds: 10));
if (call.state.value.status != CallStatus.active) {
  await call.ring();  // Ring again!
}
```

**Return:**
```dart
class CallRingResponse {
  Duration duration;  // Ringing duration (default: 45s)
}
```

---

## 5. Home Page - Receiving Call

```dart
void _observeIncomingCalls() {
  StreamService.client.state.incomingCall.listen((call) {
    if (call != null && mounted) {
      Navigator.push(...);
    }
  });
}
```

### คำอธิบาย:

**`state.incomingCall`:**
```dart
ValueStream<Call?> incomingCall
```
- **`ValueStream`**: RxDart stream (มี current value)
- **Type**: `Call?` (nullable)
- **เมื่อไหร่จะมีค่า:**
  - มี incoming call → `Call` object
  - ไม่มี call → `null`

**`.listen()`:**
```dart
StreamSubscription<Call?> listen(
  void Function(Call?) onData,  // Callback เมื่อมีค่าใหม่
)
```

**Flow:**
1. มี notification เข้ามา
2. Stream SDK parse message
3. สร้าง `Call` object
4. อัพเดต `incomingCall` stream
5. Listener ทำงาน → เปิด CallPage

---

## 6. Call Page - Accept/Reject

```dart
await call.accept();
```

### คำอธิบาย:

**`accept()` Method:**
```dart
Future<AcceptCallResponse> accept({
  CallSettings? settings,  // Audio/video settings
})
```

**ทำอะไร:**
1. ส่ง signal ไปยัง Stream Backend
2. เริ่ม WebRTC connection
3. Request camera/microphone permissions
4. Join call session

**Parameters:**
- **`settings`**: กำหนด audio/video settings
  ```dart
  call.accept(
    settings: CallSettings(
      audio: AudioSettings(
        micEnabled: true,
        speakerEnabled: true,
      ),
      video: VideoSettings(
        cameraEnabled: true,
        cameraPosition: CameraPosition.front,
      ),
    ),
  );
  ```

**Return:**
```dart
class AcceptCallResponse {
  Duration duration;  // Call duration limit (if set)
}
```

---

```dart
await call.reject();
```

### คำอธิบาย:

**`reject()` Method:**
```dart
Future<RejectCallResponse> reject({
  String? reason,  // Rejection reason
})
```

**ทำอะไร:**
1. ส่ง signal ว่า reject call
2. Notify caller
3. End call session

**Parameters:**
- **`reason`**: เหตุผลที่ reject (optional)
  ```dart
  call.reject(reason: 'Busy with another call');
  ```

**Caller จะเห็นอะไร:**
- Call status → `CallStatus.rejected`
- Event: `call.rejected`
- Custom reason (ถ้ามี)

---

```dart
await call.leave();
```

### คำอธิบาย:

**`leave()` Method:**
```dart
Future<void> leave({
  bool endCall = false,  // End call สำหรับทุกคนหรือไม่
})
```

**ทำอะไร:**
1. Disconnect WebRTC
2. Leave call session
3. ถ้า `endCall: true` → end call สำหรับทุกคน

**Parameters:**
- **`endCall`**:
  - **`false`**: ออกเฉพาะตัวเอง (default)
  - **`true`**: end call ทั้งหมด (ทุกคนถูก disconnect)

**Use cases:**
```dart
// User กด "Leave" button
await call.leave();  // ออกเฉพาะตัวเอง

// Host กด "End call for everyone"
await call.leave(endCall: true);  // ทุกคนออก
```

---

## 7. Call Page - Active Call UI

```dart
StreamCallContainer(
  call: widget.call,
  callContentBuilder: (context, call, callState) {
    return StreamCallContent(
      call: call,
      callState: callState,
    );
  },
)
```

### คำอธิบาย:

**`StreamCallContainer`:**
- **High-level widget** สำหรับแสดง call UI
- **ทำอะไร:**
  1. Setup WebRTC renderers
  2. Handle call state changes
  3. Provide call context

**Parameters:**

1. **`call`**: Call object
2. **`callContentBuilder`**: Builder function สำหรับสร้าง UI
   ```dart
   Widget Function(
     BuildContext context,
     Call call,
     CallState callState,
   )
   ```

---

**`StreamCallContent`:**
- **Pre-built UI** สำหรับ active call
- **มีอะไรบ้าง:**
  - Video renderers
  - Participant tiles
  - Control buttons (mute, camera, speaker)
  - Call stats
  - Network quality indicator

**Customization:**
```dart
StreamCallContent(
  call: call,
  callState: callState,
  callControlsBuilder: (context, call, callState) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.mic_off),
          onPressed: () => call.setMicrophoneEnabled(enabled: false),
        ),
        IconButton(
          icon: Icon(Icons.videocam_off),
          onPressed: () => call.setCameraEnabled(enabled: false),
        ),
      ],
    );
  },
)
```

---

# Stream Video SDK Methods

## Core Methods Summary

### Client Methods

| Method | Description | When to use |
|--------|-------------|-------------|
| `StreamVideo()` | สร้าง client | ตอน initialize app |
| `connect()` | เชื่อมต่อ backend | หลัง login |
| `disconnect()` | ตัดการเชื่อมต่อ | ตอน logout |
| `makeCall()` | สร้าง Call object | ก่อนโทร |

### Call Methods

| Method | Description | Parameters | When to use |
|--------|-------------|------------|-------------|
| `getOrCreate()` | สร้าง/ดึง call | `memberIds`, `ringing` | สร้าง call session |
| `ring()` | ส่ง ring signal | `timeout` | เริ่มโทร |
| `accept()` | รับสาย | `settings` | รับ incoming call |
| `reject()` | ปฏิเสธสาย | `reason` | ไม่รับสาย |
| `leave()` | ออกจาก call | `endCall` | วางสาย |
| `setMicrophoneEnabled()` | เปิด/ปิด mic | `enabled` | Mute/Unmute |
| `setCameraEnabled()` | เปิด/ปิดกล้อง | `enabled` | แสดง/ซ่อนวิดีโอ |
| `flipCamera()` | สลับกล้อง | - | เปลี่ยนหน้า/หลัง |

### State Observables

| Observable | Type | Description |
|------------|------|-------------|
| `incomingCall` | `ValueStream<Call?>` | Incoming call events |
| `call.state` | `ValueStream<CallState>` | Call state changes |
| `call.state.value.status` | `CallStatus` | Current status |
| `call.state.value.participants` | `List<CallParticipant>` | Participants |

### Call Status Values

```dart
enum CallStatus {
  idle,        // ยังไม่เริ่ม
  joining,     // กำลัง join
  active,      // กำลังคุย
  reconnecting, // กำลัง reconnect
  ended,       // จบแล้ว
  rejected,    // ถูก reject
}
```

---

# Firebase Messaging Methods

## Core Methods

### Initialization

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```
- **เมื่อไหร่**: ก่อนใช้ Firebase service ใดๆ
- **ที่ไหน**: `main()` function

---

### Request Permissions

```dart
NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,    // แสดง banner
  badge: true,    // แสดง badge number
  sound: true,    // เล่นเสียง
  provisional: false,  // iOS: ส่งโดยไม่ถามก่อน
);
```
- **Return**: `NotificationSettings` (status: granted/denied/provisional)
- **เมื่อไหร่**: ตอน app start หรือก่อน enable notifications

---

### Get FCM Token

```dart
String? token = await FirebaseMessaging.instance.getToken();
```
- **Return**: FCM Token (String, ~163 characters)
- **เมื่อไหร่**: หลัง request permissions
- **Use case**: ดู token สำหรับ debug

---

### Listen for Token Refresh

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  print('New token: $newToken');
  // Register new token with your backend
});
```
- **เมื่อไหร่**: Token เปลี่ยน (เช่น reinstall app)
- **ต้องทำอะไร**: Register token ใหม่กับ backend

---

### Handle Foreground Messages

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Foreground message: ${message.data}');
  // Show in-app notification or update UI
});
```
- **เมื่อไหร่**: แอปเปิดอยู่ (foreground)
- **Use case**: แสดง custom notification

---

### Handle Background Messages

```dart
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```
- **เมื่อไหร่**: แอปอยู่เบื้องหลัง (background/terminated)
- **หมายเหตุ**: Handler ต้องเป็น top-level function

---

### Handle Notification Tap

```dart
// Get initial message (opened app from terminated)
RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  _handleMessage(initialMessage);
}

// Listen for messages when app is in background
FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
```

---

# Error Handling

## Common Errors

### 1. Token Signature Invalid

```dart
try {
  await client.connect();
} catch (e) {
  if (e is StreamAuthenticationError) {
    print('Authentication failed: ${e.message}');
    // Token invalid → re-login
  }
}
```

**Cause:**
- Backend ใช้ API Secret ผิด
- Token หมดอายุ
- Token ถูก revoke

**Solution:**
- ตรวจสอบ `STREAM_API_SECRET` ใน backend
- Generate token ใหม่
- Check `exp` timestamp

---

### 2. Network Error

```dart
try {
  await call.getOrCreate(...);
} catch (e) {
  if (e is StreamWebSocketError) {
    print('Network error: ${e.message}');
    // Show retry button
  }
}
```

**Cause:**
- No internet
- Firewall blocking
- Server down

**Solution:**
- ตรวจสอบ internet connection
- Retry mechanism
- Show error message

---

### 3. Permission Denied

```dart
try {
  await call.accept();
} catch (e) {
  if (e is PlatformException && e.code == 'PermissionDenied') {
    print('Camera/Mic permission denied');
    // Show settings dialog
  }
}
```

**Cause:**
- User denied camera/microphone permission

**Solution:**
- Request permission again
- Show explanation
- Open app settings

---

### 4. Call Already Exists

```dart
try {
  await call.getOrCreate(...);
} catch (e) {
  if (e is StreamCallError && e.code == 'call-already-exists') {
    print('Call already exists');
    // Get existing call
  }
}
```

**Solution:**
- ใช้ `getOrCreate()` แทน `create()` (จะ get ถ้ามี)
- หรือใช้ call ID ใหม่

---

# Best Practices

## 1. Token Management

### ❌ Bad:
```dart
// Hardcode token in app
const token = 'eyJhbGc...';
StreamVideo(apiKey, userToken: token, ...);
```

### ✅ Good:
```dart
// Get from secure backend
final response = await http.post(backendUrl, ...);
final token = response['token'];
StreamVideo(apiKey, userToken: token, ...);
```

---

## 2. Error Handling

### ❌ Bad:
```dart
await call.accept();  // อาจ error ได้
```

### ✅ Good:
```dart
try {
  await call.accept();
} catch (e) {
  print('Error: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to accept call: $e')),
  );
}
```

---

## 3. Dispose Resources

### ❌ Bad:
```dart
// Never disconnect
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    StreamService.initialize(...);
    return MaterialApp(...);
  }
}
```

### ✅ Good:
```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    StreamService.dispose();  // Disconnect
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(...);
  }
}
```

---

## 4. Check Mounted

### ❌ Bad:
```dart
await call.accept();
Navigator.pop(context);  // อาจ error ถ้า widget ถูก dispose
```

### ✅ Good:
```dart
await call.accept();
if (mounted) {
  Navigator.pop(context);
}
```

---

## 5. Cancel Subscriptions

### ❌ Bad:
```dart
void initState() {
  super.initState();
  client.state.incomingCall.listen((call) { ... });
}
// Subscription ไม่ถูก cancel!
```

### ✅ Good:
```dart
StreamSubscription? _subscription;

void initState() {
  super.initState();
  _subscription = client.state.incomingCall.listen((call) { ... });
}

void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

---

## 6. Null Safety

### ❌ Bad:
```dart
final userName = call.state.value.createdBy.name;  // อาจเป็น null
```

### ✅ Good:
```dart
final userName = call.state.value.createdBy?.name ?? 'Unknown';
```

---

## 7. Logging

### ❌ Bad:
```dart
print('Call created');
```

### ✅ Good:
```dart
if (kDebugMode) {
  print('========================================');
  print('📞 CALL CREATED');
  print('Call ID: ${call.id}');
  print('Members: ${call.state.value.members.length}');
  print('========================================');
}
```

---

## 8. Call ID Generation

### ❌ Bad:
```dart
final callId = DateTime.now().toString();  // อาจซ้ำได้
```

### ✅ Good:
```dart
import 'package:uuid/uuid.dart';
final callId = const Uuid().v4();  // Globally unique
```

---

## 9. Backend URL

### ❌ Bad:
```dart
const backendUrl = 'http://localhost:8181/...';  // ไม่ทำงานบน device
```

### ✅ Good:
```dart
// Development
const backendUrl = kIsWeb
  ? 'http://localhost:8181/...'      // Web: localhost works
  : 'http://10.0.2.2:8181/...';     // Android emulator: 10.0.2.2

// Production
const backendUrl = 'https://api.myapp.com/...';
```

---

## 10. Push Provider Name

### ❌ Bad:
```dart
// In code:
StreamVideoPushProvider.firebase(name: 'firebase_provider')

// In Stream Dashboard:
Provider name: 'my_firebase_push'
```
→ ชื่อไม่ตรงกัน = ไม่ส่ง notification

### ✅ Good:
```dart
// In code:
StreamVideoPushProvider.firebase(name: 'niwner_notification')

// In Stream Dashboard:
Provider name: 'niwner_notification'
```
→ ชื่อตรงกัน = ส่งได้

---

# สรุป

## สิ่งที่ต้องเข้าใจ:

### Backend:
- JWT token generation
- API Secret security
- CORS configuration
- Error responses

### Flutter:
- StreamVideo initialization
- Push notification setup
- Call lifecycle (create → ring → accept → leave)
- State management
- Error handling

### Stream SDK:
- `makeCall()` + `getOrCreate()` + `ring()`
- `accept()` vs `reject()`
- `leave()` vs `leave(endCall: true)`
- Observing `incomingCall` stream
- CallKit/ConnectionService integration

### Firebase:
- FCM token registration
- Background message handling
- Foreground message handling
- Permission management

---

**ไฟล์นี้ครอบคลุมทุกส่วนของโค้ดแบบละเอียด พร้อมคำอธิบายความสามารถของแต่ละ method 📚**

# 🔧 วิธีใช้ Backend แทน Manual Mode

## เปลี่ยนจาก Manual Mode → Backend Mode

---

## ขั้นตอนที่ 1: ตั้งค่า Backend

### 1.1 ตรวจสอบ `.env` file ใน Backend

ไฟล์ `.env` ต้องมี:

```env
STREAM_API_KEY=r9mn4fsbzhub
STREAM_API_SECRET=your_secret_from_stream_dashboard
TOKEN_TTL_SECONDS=86400
```

**วิธีหา STREAM_API_SECRET:**

1. ไปที่ Stream Dashboard: https://dashboard.getstream.io/
2. เลือก app ที่มี API Key: `r9mn4fsbzhub`
3. ไปที่ **Settings** → **General**
4. หา **API Secret** → คลิก **Show** หรือ **Reveal**
5. **Copy secret** ทั้งหมด (ยาวประมาณ 50+ ตัวอักษร)
6. วางใน `.env`:
   ```env
   STREAM_API_SECRET=secret_ที่_copy_มา
   ```

### 1.2 Start Backend Server

```bash
# ใน directory ของ backend
npm install
npm run dev

# หรือ
yarn dev
```

ตรวจสอบว่า server รันที่ port ไหน (เช่น `http://localhost:8181`)

---

## ขั้นตอนที่ 2: อัพเดต Flutter App

### 2.1 แก้ไข app_keys.dart

เปิดไฟล์: `lib/app_keys.dart`

ตรวจสอบว่า `backendBaseUrl` ถูกต้อง:

```dart
// Backend base URL for token endpoint
// Note: On Android emulator, 'localhost' should be '10.0.2.2'.
static const String backendBaseUrl = String.fromEnvironment(
  'BACKEND_BASE_URL',
  defaultValue: 'http://localhost:8181',  // ← ตรงนี้
);
```

**สำหรับ Android Emulator:**
```dart
defaultValue: 'http://10.0.2.2:8181',
```

**สำหรับ Android มือถือจริง:**
```dart
defaultValue: 'http://192.168.x.x:8181',  // ← ใส่ IP ของเครื่อง PC
```

**วิธีหา IP ของเครื่อง PC:**

Windows:
```bash
ipconfig
# หา IPv4 Address (เช่น 192.168.1.100)
```

Mac/Linux:
```bash
ifconfig
# หา inet address
```

### 2.2 ปิด Manual Mode

**รัน app แบบไม่ใส่ `--dart-define=MANUAL_AUTH=true`:**

```bash
# User A (Chrome)
flutter run -d chrome

# User B (มือถือ)
flutter run -d AEEY6HBMPVEMGQQ4
```

หรือถ้าต้องการ test แบบเฉพาะ user หนึ่ง:

```bash
flutter run
```

แล้วเลือก user จากหน้า login (ถ้ามี)

---

## ขั้นตอนที่ 3: ตรวจสอบการทำงาน

### 3.1 เช็ค Backend Logs

ใน terminal ของ backend ควรเห็น:

```
POST /v1/api/callStreams
Status: 200
```

### 3.2 เช็ค Flutter Logs

ควรเห็น:

```
🔧 CREATING STREAM VIDEO CLIENT
User ID: xxxxx
Token (first 20 chars): eyJhbGciOiJIUzI1NiIs...
Push Manager Enabled: true
========================================

✅ Stream Video client connected successfully
```

**ไม่ควรเห็น:**
```
❌ Token signature is invalid
```

---

## ขั้นตอนที่ 4: ทดสอบโทร

1. เปิด app ทั้ง 2 เครื่อง (Chrome + มือถือ)
2. จาก Chrome → กดโทร
3. มือถือควรได้รับ notification
4. เช็ค Stream Dashboard → ควรเห็น call logs

---

## 🔧 Troubleshooting

### ปัญหา: Backend connection error

**สาเหตุ:** Flutter app เชื่อมต่อ backend ไม่ได้

**แก้ไข:**

1. เช็คว่า backend รันอยู่:
   ```bash
   curl http://localhost:8181
   ```

2. เช็ค `backendBaseUrl` ใน `app_keys.dart`

3. สำหรับ Android มือถือจริง → ใช้ IP แทน localhost:
   ```dart
   defaultValue: 'http://192.168.1.100:8181',
   ```

4. เช็ค firewall ไม่ block port 8181

### ปัญหา: Token signature is invalid

**สาเหตุ:** `STREAM_API_SECRET` ใน backend ผิด

**แก้ไข:**

1. ไปที่ Stream Dashboard → Settings → General
2. Copy **API Secret** ใหม่
3. อัพเดตใน `.env`:
   ```env
   STREAM_API_SECRET=secret_ใหม่
   ```
4. Restart backend server

### ปัญหา: Authorization failed

**สาเหตุ:** `checkAuthorizationMiddleware` ไม่ผ่าน

**แก้ไข:**

1. เช็คว่า frontend ส่ง `Authorization` header หรือยัง
2. เช็คว่า JWT token ของ app ถูกต้องหรือไม่
3. เช็ค middleware logic

---

## 📊 เปรียบเทียบ Manual Mode vs Backend Mode

| Feature | Manual Mode | Backend Mode |
|---------|-------------|--------------|
| **Token Generation** | Manual จาก Dashboard | Auto จาก Backend |
| **Token Expiry** | ต้อง generate ใหม่เอง | Auto refresh ได้ |
| **Security** | Token hard-code ในโค้ด ❌ | Token จาก secure backend ✅ |
| **Setup** | ง่าย | ซับซ้อนกว่า |
| **Use Case** | Development/Testing | Production |
| **User Management** | Manual | Dynamic |

---

## 💡 แนะนำ

**สำหรับ Development/Testing:**
→ ใช้ **Manual Mode** (ง่ายกว่า)

**สำหรับ Production:**
→ ใช้ **Backend Mode** (ปลอดภัยกว่า)

---

## 📝 หมายเหตุ

- ถ้าใช้ backend mode จะไม่ต้อง hard-code token ใน `dev_manual_auth.dart`
- Backend จะ generate token แบบ dynamic ตาม user ที่ login
- ต้องมี authentication system (JWT, OAuth, etc.) สำหรับระบุ user

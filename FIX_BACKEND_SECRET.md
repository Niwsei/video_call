# 🔧 แก้ไข Backend STREAM_API_SECRET

## ปัญหา
Backend generate token แล้วได้:
```
❌ Token signature is invalid
```

**สาเหตุ:** `STREAM_API_SECRET` ในไฟล์ `.env` ของ backend **ไม่ถูกต้อง**

---

## ✅ วิธีแก้ไข

### ขั้นตอนที่ 1: ไปหา API Secret ที่ถูกต้อง

1. **เปิด Stream Dashboard**: https://dashboard.getstream.io/
2. **Login** เข้าบัญชีของคุณ

3. **เลือก App ที่ถูกต้อง:**
   - ดูที่ **dropdown มุมบนซ้าย**
   - **หา app ที่มี API Key: `r9mn4fsbzhub`**
   - **คลิกเลือก app นั้น**

4. **ไปที่ Settings:**
   - คลิกเมนู **Settings** (หรือไอคอน ⚙️)
   - เลือก **General**

5. **หา API Secret:**
   - จะมีฟิลด์ชื่อ **API Secret** หรือ **Secret**
   - ข้างๆ จะมีปุ่ม **Show** หรือ **Reveal** หรือไอคอนตา 👁️
   - **คลิกเพื่อแสดง secret**

6. **Copy API Secret:**
   - Secret จะยาวประมาณ **50-80 ตัวอักษร**
   - มีหน้าตาประมาณ: `abcdef1234567890abcdef1234567890abcdef1234567890`
   - **Copy ทั้งหมด** (ระวังอย่าตัดบางส่วน)

---

### ขั้นตอนที่ 2: อัพเดต Backend `.env`

1. **เปิดโปรเจค Backend** ของคุณ

2. **หาไฟล์ `.env`** (อยู่ที่ root ของ backend project)

3. **แก้ไขบรรทัด `STREAM_API_SECRET`:**

   **ก่อนแก้:**
   ```env
   STREAM_API_KEY=r9mn4fsbzhub
   STREAM_API_SECRET=old_wrong_secret_here
   TOKEN_TTL_SECONDS=3600
   ```

   **หลังแก้:**
   ```env
   STREAM_API_KEY=r9mn4fsbzhub
   STREAM_API_SECRET=secret_ที่_copy_มาจาก_dashboard
   TOKEN_TTL_SECONDS=86400
   ```

4. **Save ไฟล์**

⚠️ **สำคัญ:**
- ต้อง copy **ทั้งหมด** ไม่ตัดบางส่วน
- **ไม่มีช่องว่าง** หน้าหรือหลัง secret
- **ไม่มี quotes** รอบๆ secret (เว้นแต่ไฟล์ .env ของคุณใช้ quotes)

---

### ขั้นตอนที่ 3: Restart Backend Server

1. **Stop server ที่รันอยู่:**
   - กด `Ctrl+C` ใน terminal

2. **Start server ใหม่:**
   ```bash
   npm run dev
   # หรือ
   yarn dev
   # หรือ
   node dist/index.js
   ```

3. **ตรวจสอบว่า server รันปกติ:**
   ```
   Server is running on port 8181
   ```

---

### ขั้นตอนที่ 4: ทดสอบ Generate Token ใหม่

**เรียก API เพื่อ generate token:**

**ถ้าใช้ curl:**
```bash
curl -X POST http://localhost:8181/v1/api/callStreams \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_APP_JWT_TOKEN"
```

**ถ้าใช้ Postman:**
- Method: POST
- URL: `http://localhost:8181/v1/api/callStreams`
- Headers:
  - `Content-Type: application/json`
  - `Authorization: Bearer YOUR_APP_JWT_TOKEN`

**Response ที่ต้องการ:**
```json
{
  "apiKey": "r9mn4fsbzhub",
  "userId": "68ad1babd03c44ef943bb6bb",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": 1759812917
}
```

**Copy token ใหม่ที่ได้**

---

### ขั้นตอนที่ 5: ทดสอบ Token

**วาง token ใหม่ใน test script:**

เปิดไฟล์: `test_backend_token.dart`

แก้บรรทัด:
```dart
const token = 'TOKEN_ใหม่_ที่_COPY_มาจาก_BACKEND';
```

**รันทดสอบ:**
```bash
dart test_backend_token.dart
```

**ผลลัพธ์ที่ต้องเห็น:**
```
✅ TOKEN IS VALID!
App Info:
  Name: Your App Name
  ID: xxxxx

✅ SUCCESS! Backend is generating correct tokens.
```

**ถ้ายังเห็น:**
```
❌ AUTHENTICATION FAILED!
```
→ **API Secret ยังไม่ถูกต้อง** ลองทำขั้นตอนที่ 1 ใหม่อีกครั้ง

---

### ขั้นตอนที่ 6: อัพเดต Flutter App

**ถ้าใช้ Manual Mode:**

เปิดไฟล์: `lib/dev_manual_auth.dart`

อัพเดต token:
```dart
static const ManualAuthUser userA = ManualAuthUser(
  apiKey: 'r9mn4fsbzhub',
  userId: '68da5610e8994916f01364b8',
  name: 'ຮືວ່າງ ວ່າງ',
  token: 'TOKEN_ใหม่_จาก_BACKEND',  // ← ตรงนี้
);

static const ManualAuthUser userB = ManualAuthUser(
  apiKey: 'r9mn4fsbzhub',
  userId: '68ad1babd03c44ef943bb6bb',
  name: 'tangiro kamado',
  token: 'TOKEN_ใหม่_จาก_BACKEND',  // ← ตรงนี้
);
```

**ถ้าใช้ Backend Mode:**

ไม่ต้องแก้ไขอะไร! แค่รัน app ปกติ:
```bash
flutter run -d chrome
flutter run -d AEEY6HBMPVEMGQQ4
```

---

## 🧪 ทดสอบว่าแก้ไขสำเร็จ

### Test 1: Backend Generate Token

```bash
curl -X POST http://localhost:8181/v1/api/callStreams \
  -H "Authorization: Bearer YOUR_JWT"
```

ควรได้ response พร้อม token ใหม่

### Test 2: Validate Token

```bash
dart test_backend_token.dart
```

ควรเห็น: `✅ TOKEN IS VALID!`

### Test 3: Flutter App Connect

รัน app:
```bash
flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=A
```

ควรเห็น:
```
✅ Stream Video client connected successfully
```

ไม่ควรเห็น:
```
❌ Token signature is invalid
```

### Test 4: โทรได้

1. รัน app ทั้ง 2 เครื่อง
2. โทรจาก A → B
3. B ควรได้รับ notification
4. เช็ค Stream Dashboard → ควรเห็น call logs

---

## ❓ FAQ

### Q: หา API Secret ไม่เจอ?
**A:**
- อยู่ในหน้า Settings → General
- มีชื่อว่า "API Secret" หรือ "Secret"
- ถ้ายังหาไม่เจอ → อาจต้องมีสิทธิ์ admin ของ app นั้น

### Q: Copy API Secret แล้วยัง invalid?
**A:**
1. ตรวจสอบว่า copy **ทั้งหมด** (ไม่ตัดบางส่วน)
2. ตรวจสอบว่า**ไม่มีช่องว่าง**หน้า-หลัง
3. ตรวจสอบว่าเลือก **app ที่ถูกต้อง** (มี API Key = `r9mn4fsbzhub`)

### Q: Restart backend แล้วยัง error?
**A:**
1. เช็คว่าไฟล์ `.env` ถูก save แล้ว
2. เช็คว่า backend อ่านค่าจากไฟล์ `.env` จริงๆ (บาง framework ต้อง config)
3. ลอง log ค่า `process.env.STREAM_API_SECRET` ดูว่าได้ค่าถูกต้องหรือไม่

### Q: มี app หลาย app ใน Dashboard?
**A:**
- ดูที่ API Key ให้ดี
- **ต้องเลือก app ที่มี API Key = `r9mn4fsbzhub`**
- ถ้าไม่แน่ใจ → ไปที่ Settings → General ของแต่ละ app เพื่อเช็ค API Key

---

## 📝 Checklist

- [ ] เปิด Stream Dashboard
- [ ] เลือก app ที่มี API Key: `r9mn4fsbzhub`
- [ ] ไปที่ Settings → General
- [ ] Copy API Secret (ทั้งหมด)
- [ ] อัพเดตในไฟล์ `.env` ของ backend
- [ ] Restart backend server
- [ ] Generate token ใหม่จาก backend
- [ ] ทดสอบ token ด้วย `dart test_backend_token.dart`
- [ ] เห็น `✅ TOKEN IS VALID!`
- [ ] อัพเดต token ใน Flutter app (ถ้าใช้ Manual Mode)
- [ ] ทดสอบโทร → สำเร็จ!

---

## 🆘 ถ้ายังแก้ไม่ได้

ส่งข้อมูลเหล่านี้:
1. Screenshot ของ Stream Dashboard → Settings → General (ปิด API Secret ก่อน capture!)
2. ส่วนของ `.env` ที่เกี่ยวข้อง (ปิด secret ก่อนส่ง!)
3. Output จาก `dart test_backend_token.dart`
4. Backend logs เมื่อ generate token

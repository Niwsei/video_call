# 🔧 แก้ไขปัญหา "Token signature is invalid"

## ปัญหาที่พบ
```
❌ Authentication failed!
"Token signature is invalid"
```

**สาเหตุ:** Token ที่ใช้อยู่ไม่ตรงกับ API Key `r9mn4fsbzhub` หรือถูก generate จาก App อื่น

**ผลกระทบ:**
- Call ไม่ปรากฏใน Stream Dashboard logs
- ปลายทางไม่ได้รับ notification
- Connection ล้มเหลว

---

## ✅ วิธีแก้ไข (ทำตามนี้ทีละขั้นตอน)

### ขั้นตอนที่ 1: เปิด Stream Dashboard

1. ไปที่: **https://dashboard.getstream.io/**
2. Login เข้าบัญชีของคุณ

---

### ขั้นตอนที่ 2: หา App ที่ถูกต้อง

1. ดูที่ **มุมบนซ้าย** → มี dropdown สำหรับเลือก App
2. **คลิก dropdown** นั้น
3. หา app ที่มี **API Key: `r9mn4fsbzhub`**
4. **คลิกเลือก app นั้น**

⚠️ **สำคัญ:** ต้องเลือก app ที่มี API Key ตรงกับ `r9mn4fsbzhub` ไม่งั้น token จะไม่ทำงาน!

---

### ขั้นตอนที่ 3: สร้าง User (ถ้ายังไม่มี)

#### สำหรับ User A (ev manager test):

1. ไปที่เมนู **Chat** → **Users** (หรือ **Video & Audio** → **Users**)
2. กด **Create New User** หรือ **+ Add User**
3. กรอกข้อมูล:
   ```
   User ID: 6721f3f8cd5644f9dc80f4f9
   Name: ev manager test
   ```
4. กด **Save** หรือ **Create**

#### สำหรับ User B (Dee admin1 Express):

1. กด **Create New User** อีกครั้ง
2. กรอกข้อมูล:
   ```
   User ID: 68a2eccfbffc43ed49cdf13f
   Name: Dee admin1 Express
   ```
3. กด **Save** หรือ **Create**

---

### ขั้นตอนที่ 4: Generate User Token

#### สำหรับ User A:

1. ในหน้า **Users** → ค้นหา User ID: `6721f3f8cd5644f9dc80f4f9`
2. **คลิกที่ user** นั้น
3. หาปุ่ม **Generate User Token** หรือ **Create Token**
4. เลือก **Token Expiration**:
   - แนะนำ: **1 day** หรือ **7 days**
   - อย่าเลือกสั้นเกินไป (เช่น 1 hour) เพราะต้อง generate ใหม่บ่อย
5. กด **Generate** หรือ **Create**
6. **Copy token ทั้งหมด** (จะยาวมาก ประมาณ 150-200 ตัวอักษร)

**Token ควรมีหน้าตาแบบนี้:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNjcyMWYzZjhjZDU2NDRmOWRjODBmNGY5IiwiaWF0IjoxNzA5ODEyMzQ1LCJleHAiOjE3MDk4OTg3NDV9.SomeLongRandomString_Here_123456789
```

#### สำหรับ User B:

ทำเหมือน User A แต่หา User ID: `68a2eccfbffc43ed49cdf13f`

---

### ขั้นตอนที่ 5: ทดสอบ Token ก่อนใส่ในแอป

**เปิด Terminal และรัน:**

```bash
dart test_new_token.dart
```

**Paste token ที่ copy มา** แล้วกด Enter

**ผลลัพธ์ที่ต้องเห็น:**
```
✅ TOKEN IS VALID AND WORKING!
📱 App Info:
   Name: Your App Name
   ID: xxxxx

✅ SUCCESS! This token is correct.
```

**ถ้าเห็น:**
```
❌ TOKEN AUTHENTICATION FAILED!
```
→ **Token ผิด! ต้อง generate ใหม่จาก app ที่ถูกต้อง**

---

### ขั้นตอนที่ 6: อัพเดต dev_manual_auth.dart

**เปิดไฟล์:** `lib/dev_manual_auth.dart`

**แทนที่ token:**

```dart
static const ManualAuthUser userA = ManualAuthUser(
  apiKey: 'r9mn4fsbzhub',
  userId: '6721f3f8cd5644f9dc80f4f9',
  name: 'ev manager test',
  token: 'PASTE_TOKEN_ของ_USER_A_ตรงนี้',  // ← แทนที่ทั้งหมด
);

static const ManualAuthUser userB = ManualAuthUser(
  apiKey: 'r9mn4fsbzhub',
  userId: '68a2eccfbffc43ed49cdf13f',
  name: 'Dee admin1 Express',
  token: 'PASTE_TOKEN_ของ_USER_B_ตรงนี้',  // ← แทนที่ทั้งหมด
);
```

**Save ไฟล์**

---

### ขั้นตอนที่ 7: ทดสอบใหม่

**รัน app:**

```bash
# Chrome (User A)
flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=A -d chrome

# มือถือ (User B)
flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=B -d AEEY6HBMPVEMGQQ4
```

**ดู logs ควรเห็น:**
```
✅ Stream Video client connected successfully
   User: 6721f3f8cd5644f9dc80f4f9
```

**ไม่ควรเห็น error:**
```
❌ Token signature is invalid
```

---

### ขั้นตอนที่ 8: ลองโทร

1. **จาก Chrome** → กดปุ่มโทร
2. **ดู logs มือถือ** → ควรเห็น:
   ```
   🔔 FOREGROUND FCM MESSAGE RECEIVED
   📞 INCOMING CALL EVENT RECEIVED
   ```
3. **ตรวจสอบ Stream Dashboard:**
   - ไปที่ **Video & Audio** → **Call Logs** หรือ **Activity**
   - **ควรเห็น call ปรากฏใน logs!**

---

## 🎯 Checklist

- [ ] เปิด Stream Dashboard แล้ว
- [ ] เลือก app ที่มี API Key: `r9mn4fsbzhub`
- [ ] สร้าง User A และ User B (หรือตรวจสอบว่ามีอยู่แล้ว)
- [ ] Generate token สำหรับ User A
- [ ] Generate token สำหรับ User B
- [ ] ทดสอบ token ด้วย `dart test_new_token.dart`
- [ ] อัพเดต token ใน `lib/dev_manual_auth.dart`
- [ ] รัน app ใหม่
- [ ] ลองโทรและดู logs
- [ ] เช็คว่า call ปรากฏใน Stream Dashboard

---

## ❓ FAQ

### Q: Token หมดอายุบ่อย ทำยังไง?
**A:** เลือก expiration ที่ยาวขึ้น (7 days หรือ 30 days) เมื่อ generate token

### Q: ไม่แน่ใจว่าเลือก app ถูกหรือไม่?
**A:** ดูที่ **Settings** → **General** → หา **API Key** ต้องตรงกับ `r9mn4fsbzhub`

### Q: Generate token แล้วแต่ยัง error?
**A:**
1. ตรวจสอบว่า copy token ทั้งหมด (ไม่ตัดบางส่วน)
2. ตรวจสอบว่าไม่มีช่องว่างหรือ newline ใน token
3. รัน `dart test_new_token.dart` เพื่อยืนยัน

### Q: Call ยังไม่ปรากฏใน Dashboard?
**A:**
1. Refresh หน้า Dashboard
2. ตรวจสอบว่าดูที่ app ที่ถูกต้อง
3. ดูที่ **Video & Audio** → **Call Logs** หรือ **Overview**

---

## 🆘 ถ้ายังแก้ไม่ได้

ส่งข้อมูลเหล่านี้:
1. Screenshot ของ Stream Dashboard หน้า **Settings** → **General** (แสดง API Key)
2. Output จาก `dart verify_stream_config.dart`
3. Output จาก `dart test_new_token.dart`
4. Logs ทั้งหมดตอนรัน app

# 📝 วิธี Generate Token สำหรับ Manual Mode

## สำหรับ Manual Mode (MANUAL_AUTH=true)

เมื่อใช้ manual mode, app **จะไม่เรียก backend** แต่จะใช้ token ที่ hard-code ใน `dev_manual_auth.dart`

---

## ✅ ขั้นตอนการ Generate Token

### ขั้นตอนที่ 1: เปิด Stream Dashboard

1. ไปที่: https://dashboard.getstream.io/
2. Login เข้าบัญชีของคุณ

### ขั้นตอนที่ 2: เลือก App ที่ถูกต้อง

1. ดูที่ **dropdown มุมบนซ้าย**
2. **หา app ที่มี API Key: `r9mn4fsbzhub`**
3. **คลิกเลือก app นั้น**

⚠️ **สำคัญ!** ถ้าเลือกผิด app → token จะไม่ทำงาน

### ขั้นตอนที่ 3: ตรวจสอบ API Key

1. ไปที่ **Settings** → **General**
2. เช็คว่า **API Key = `r9mn4fsbzhub`**
3. ถ้าไม่ตรง → กลับไปขั้นตอนที่ 2

### ขั้นตอนที่ 4: สร้าง Users (ถ้ายังไม่มี)

**สำหรับ User A:**
1. ไปที่ **Chat** → **Users** (หรือ **Explorer** → **Users**)
2. กด **Create New User**
3. กรอก:
   ```
   User ID: 68da5610e8994916f01364b8
   Name: ຮືວ່າງ ວ່າງ
   ```
4. กด **Save**

**สำหรับ User B:**
1. กด **Create New User** อีกครั้ง
2. กรอก:
   ```
   User ID: 68ad1babd03c44ef943bb6bb
   Name: tangiro kamado
   ```
3. กด **Save**

### ขั้นตอนที่ 5: Generate Token

**สำหรับ User A:**
1. ในหน้า **Users** → ค้นหา: `68da5610e8994916f01364b8`
2. คลิกที่ user
3. หาปุ่ม **Generate User Token** หรือ **Create Token**
4. เลือก expiration: **1 day** หรือ **7 days**
5. กด **Generate**
6. **Copy token ทั้งหมด**

**สำหรับ User B:**
1. ค้นหา: `68ad1babd03c44ef943bb6bb`
2. ทำเหมือน User A

### ขั้นตอนที่ 6: อัพเดต dev_manual_auth.dart

เปิดไฟล์: `lib/dev_manual_auth.dart`

แทนที่:

```dart
static const ManualAuthUser userA = ManualAuthUser(
  apiKey: 'r9mn4fsbzhub',
  userId: '68da5610e8994916f01364b8',
  name: 'ຮືວ่າງ ວ່າງ',
  token: 'PASTE_TOKEN_ของ_USER_A_ที่_COPY_มา',  // ← ตรงนี้
);

static const ManualAuthUser userB = ManualAuthUser(
  apiKey: 'r9mn4fsbzhub',
  userId: '68ad1babd03c44ef943bb6bb',
  name: 'tangiro kamado',
  token: 'PASTE_TOKEN_ของ_USER_B_ที่_COPY_มา',  // ← ตรงนี้
);
```

### ขั้นตอนที่ 7: ทดสอบ

รัน app:

```bash
# User A
flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=A -d chrome

# User B
flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=B -d AEEY6HBMPVEMGQQ4
```

ถ้า token ถูกต้อง จะเห็น:
```
✅ Stream Video client connected successfully
```

ถ้า token ผิด จะเห็น:
```
❌ Token signature is invalid
```

---

## 🔧 Troubleshooting

### ปัญหา: Token signature is invalid

**สาเหตุที่เป็นไปได้:**

1. **Generate จาก app ผิด**
   - แก้: ตรวจสอบว่าเลือก app ที่มี API Key: `r9mn4fsbzhub`

2. **API Key ผิด**
   - แก้: เช็ค Settings → General ว่า API Key ตรงกัน

3. **Copy token ไม่ครบ**
   - แก้: Copy token ใหม่ทั้งหมด (ประมาณ 150-200 ตัวอักษร)

4. **มีช่องว่างหรือ newline ใน token**
   - แก้: ลบช่องว่างทั้งหมด

### ทดสอบ Token ก่อนใช้

รัน:
```bash
dart test_new_token.dart
```

Paste token แล้วกด Enter

ถ้าเห็น:
```
✅ TOKEN IS VALID AND WORKING!
```
→ Token ใช้งานได้!

---

## 📌 หมายเหตุ

- Token จะหมดอายุตามที่ตั้งไว้ (1 hour, 1 day, 7 days, etc.)
- เมื่อหมดอายุต้อง generate ใหม่
- แนะนำตั้ง expiration เป็น **7 days** ขณะ development

# 🔔 Setup Push Notifications - ขั้นตอนที่ต้องทำใน Stream Dashboard

## ปัญหาปัจจุบัน
ต้นทางโทรออกได้ แต่ปลายทางไม่ได้รับ notification!

## สาเหตุ
**Push Provider ยังไม่ได้ตั้งค่าใน Stream Dashboard หรือตั้งค่าผิด**

---

## ✅ ขั้นตอนการตั้งค่า Push Notifications

### Part 1: ดึง FCM Server Key จาก Firebase Console

1. **ไปที่ Firebase Console**: https://console.firebase.google.com/
2. **เลือก Project**: `notificationforlailaolab`
3. **ไปที่ Project Settings** (⚙️ ขวาบน)
4. เลือกแท็บ **Cloud Messaging**
5. ในส่วน **Cloud Messaging API (Legacy)**:
   - ถ้า**ยังไม่เปิดใช้งาน** → กด **Enable**
   - ถ้า**เปิดแล้ว** → Copy **Server key**

⚠️ **สำคัญ**: ต้องเป็น **Cloud Messaging API (Legacy)** ไม่ใช่ API v1

**ตัวอย่าง Server Key:**
```
AAAA...xxxxx (ยาวประมาณ 150+ ตัวอักษร)
```

---

### Part 2: ตั้งค่า Push Provider ใน Stream Dashboard

1. **ไปที่ Stream Dashboard**: https://dashboard.getstream.io/

2. **เลือก App**: `r9mn4fsbzhub`

3. **ไปที่ Video & Audio** → **Push Notifications**

4. **เช็คว่ามี Provider ชื่อ `niwner_notification` หรือยัง**

   #### ถ้า**ยังไม่มี** → สร้างใหม่:

   **สำหรับ Android:**
   - กด **Add Push Provider**
   - เลือก **Firebase Cloud Messaging (FCM)**
   - **Name**: `niwner_notification` (ต้องตรงกับ `app_keys.dart`)
   - **Server Key**: วาง FCM Server Key ที่ copy มาจาก Firebase
   - **Notification Template** (Optional):
     ```json
     {
       "notification": {
         "title": "Incoming Call",
         "body": "{{caller.name}} is calling you"
       }
     }
     ```
   - กด **Save**

   **สำหรับ iOS:**
   - กด **Add Push Provider**
   - เลือก **Apple Push Notification service (APNs)**
   - **Name**: `niwner_notification` (ต้องตรงกับ `app_keys.dart`)
   - อัพโหลด **APNs Certificate** (.p8 หรือ .p12)
   - กด **Save**

   #### ถ้า**มีอยู่แล้ว** → ตรวจสอบ:

   - ชื่อต้องเป็น `niwner_notification` (ตรงกับใน `lib/app_keys.dart`)
   - **FCM Server Key** ต้องถูกต้อง
   - **Status** ต้องเป็น **Enabled**

---

### Part 3: ตรวจสอบใน app_keys.dart

เปิดไฟล์ `lib/app_keys.dart` และเช็คว่า:

```dart
// Replace with your APN provider name from Stream Dashboard
static const String iosPushProviderName = 'niwner_notification';

// Replace with your FCM provider name from Stream Dashboard
static const String androidPushProviderName = 'niwner_notification';
```

**ชื่อต้องตรงกับที่ตั้งไว้ใน Stream Dashboard ทุกตัวอักษร!**

---

### Part 4: ทดสอบว่าตั้งค่าถูกต้อง

1. **รัน app ทั้ง 2 เครื่อง**:

   ```bash
   # User A
   flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=A

   # User B
   flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=B
   ```

2. **ดู logs ว่ามี FCM Token**:

   ```
   📱 CURRENT FCM TOKEN
   Token (first 30 chars): cxxxxxx...
   ```

3. **ลองโทร** จาก User A → User B

4. **ดู logs ฝั่ง User B**:

   **ถ้าถูกต้อง จะเห็น:**
   ```
   🔔 FOREGROUND FCM MESSAGE RECEIVED
   Message data: {...}
   📞 INCOMING CALL EVENT RECEIVED
   ```

   **ถ้ายังไม่ได้รับ** → Push Provider ยังไม่ถูกต้อง

---

## 🧪 ทดสอบ Push Notification ด้วย Firebase Console

**ทดสอบว่า FCM ทำงานหรือไม่:**

1. ไปที่ Firebase Console → **Cloud Messaging**
2. กด **Send your first message**
3. **Notification text**: "Test notification"
4. กด **Send test message**
5. วาง **FCM Token** ของ User B (จาก logs)
6. กด **Test**

**ถ้าได้รับ notification** → Firebase ทำงาน แต่ Stream ยังไม่ได้ตั้งค่า
**ถ้าไม่ได้รับ** → มีปัญหาที่ Firebase หรือ App permissions

---

## ⚠️ ข้อควรระวัง

1. **FCM Server Key ต้องเป็น Legacy API** ไม่ใช่ v1
2. **Provider Name** ต้องตรงกันทุกที่:
   - `lib/app_keys.dart`
   - Stream Dashboard
3. **ทั้ง 2 เครื่องต้องเปิด app** ก่อนโทร
4. **Token ไม่หมดอายุ** (ดูจาก logs `🔑 TOKEN INFO`)

---

## 🎯 Checklist สำหรับแก้ปัญหา

- [ ] Firebase Console: เปิดใช้งาน Cloud Messaging API (Legacy)
- [ ] Firebase Console: Copy FCM Server Key
- [ ] Stream Dashboard: สร้าง/เช็ค Push Provider ชื่อ `niwner_notification`
- [ ] Stream Dashboard: ใส่ FCM Server Key
- [ ] `app_keys.dart`: เช็คว่าชื่อ provider ตรงกัน
- [ ] รัน app ทั้ง 2 เครื่อง
- [ ] เช็ค logs ว่ามี FCM Token
- [ ] ลองโทร และดู logs ฝั่งปลายทาง

---

## 🆘 ถ้ายังไม่ได้

ให้ส่ง:
1. Screenshot ของ **Stream Dashboard → Push Notifications**
2. **Logs ทั้งหมด** ของทั้ง User A และ User B
3. FCM Token ของ User B (จาก logs)

# ⚠️ สำคัญ! แก้ไฟล์นี้ก่อนรันแอป

## ปัญหาที่พบ
ไฟล์ `ios/Runner/GoogleService-Info.plist` ใช้ Firebase project ผิด!

- ❌ ปัจจุบันใช้: `niwnergetstream`
- ✅ ควรใช้: `notificationforlailaolab`

## วิธีแก้ไข

### ขั้นตอนที่ 1: ดาวน์โหลดไฟล์ใหม่

1. เปิด **Firebase Console**: https://console.firebase.google.com/
2. เลือก Project: **notificationforlailaolab**
3. คลิก **⚙️ Project Settings**
4. เลือกแท็บ **Your apps**
5. หา **iOS app** หรือ **Add app** (เลือก iOS)
   - **Apple bundle ID**: `com.example.streamVideoTest`
   - **App nickname**: Stream Video Test (หรืออะไรก็ได้)
6. คลิก **Download GoogleService-Info.plist**

### ขั้นตอนที่ 2: แทนที่ไฟล์

แทนที่ไฟล์ที่:
```
ios/Runner/GoogleService-Info.plist
```

ด้วยไฟล์ที่ดาวน์โหลดมา (ควรเป็น XML format ไม่ใช่ JSON!)

### ขั้นตอนที่ 3: ตรวจสอบ

รันคำสั่ง:
```bash
dart check_firebase_config.dart
```

ควรเห็น:
```
✅ Android configuration is CORRECT!
✅ iOS configuration is CORRECT!
```

### ขั้นตอนที่ 4: รัน app ใหม่

```bash
# User A
flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=A

# User B (บนอุปกรณ์อีกเครื่อง)
flutter run --dart-define=MANUAL_AUTH=true --dart-define=MANUAL_AUTH_USER=B
```

---

## ตรวจสอบหลังแก้ไข

หลังจากแทนที่ไฟล์และรัน app แล้ว ให้ดู logs:

```
🔧 CREATING STREAM VIDEO CLIENT
✅ Stream Video client connected successfully
🔗 Coordinator connection state: Connected
📱 CURRENT FCM TOKEN
```

เมื่อโทร:
- ต้นทาง: ควรเห็น `✅ Call created successfully`
- ปลายทาง: ควรเห็น `🔔 FOREGROUND FCM MESSAGE RECEIVED` และ `📞 INCOMING CALL EVENT RECEIVED`

---

## หากยังมีปัญหา

1. ตรวจสอบว่า **Push Provider** ใน Stream Dashboard ตรงกับ `app_keys.dart`:
   - Android: `niwner_notification`
   - iOS: `niwner_notification`

2. ตรวจสอบว่า **FCM Server Key** ใน Stream Dashboard ตรงกับ Firebase Console

3. ตรวจสอบว่า **Token** ไม่หมดอายุ (ดูจาก logs `🔑 TOKEN INFO`)

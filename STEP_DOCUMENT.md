# เอกสารอธิบายขั้นตอนการทำงานของ Video Call (ฉบับละเอียด)

เอกสารนี้อธิบายขั้นตอนการทำงานของฟังก์ชัน Video Call ในแอปพลิเคชัน ตั้งแต่การตั้งค่าเริ่มต้น, การจัดการ Notification, ไปจนถึงการโทรและการรับสาย

---

### Step 1: การตั้งค่าเริ่มต้นและเชื่อมต่อ (Project Setup & Initialization)

ขั้นตอนนี้คือการเตรียมความพร้อมทั้งหมดของแอปพลิเคชันเมื่อเปิดขึ้นมาครั้งแรก โดยมีหัวใจสำคัญคือการสร้างและเชื่อมต่อ `StreamVideo` client

*   **ไฟล์ที่เกี่ยวข้อง:**
    *   `main.dart`: จุดเริ่มต้นของแอปฯ
    *   `app_initializer.dart`: ศูนย์กลางการตั้งค่าทั้งหมด
    *   `app_keys.dart`: เก็บค่าคงที่สำคัญ เช่น API Key
    *   `firebase_options.dart`: การตั้งค่าโปรเจกต์ Firebase
    *   `tutorial_user.dart` / `dev_manual_auth.dart`: แหล่งข้อมูล User สำหรับการทดสอบ

*   **ลำดับการทำงาน:**
    1.  **`main.dart`**: แอปฯ เริ่มทำงานและเรียก `AppInitializer.init()` เพื่อเริ่มกระบวนการตั้งค่าทั้งหมด
    2.  **`app_initializer.dart` (ฟังก์ชัน `init`)**:
        *   **Firebase Init**: `await Firebase.initializeApp(...)` ถูกเรียกเพื่อเชื่อมต่อแอปฯ กับโปรเจกต์ Firebase ที่กำหนดไว้ใน `firebase_options.dart` ซึ่งจำเป็นสำหรับการรับ Push Notification
        *   **User Authentication**: ดึงข้อมูลผู้ใช้ (ID, Name, Token) จาก `tutorial_user.dart` หรือ `dev_manual_auth.dart` (สำหรับโหมดทดสอบ)
        *   **Stream Client Creation**: เรียก `createClient()` เพื่อสร้าง `StreamVideo` object ซึ่งเป็น object หลักในการสื่อสารกับ Stream
    3.  **`app_initializer.dart` (ฟังก์ชัน `createClient`)**:
        *   `StreamVideo(...)` ถูกเรียกพร้อมกับการตั้งค่าที่สำคัญ:
            *   `apiKey`: Key ของโปรเจกต์ Stream (จาก `app_keys.dart`)
            *   `user`: ข้อมูลผู้ใช้ปัจจุบัน
            *   `userToken`: Token ที่ยืนยันตัวตนของผู้ใช้คนนั้นๆ
            *   **`pushNotificationManagerProvider`**: **ส่วนนี้สำคัญที่สุดสำหรับการตั้งค่า Notification**
                *   `StreamVideoPushNotificationManager.create(...)` ถูกใช้เพื่อบอกให้ SDK รู้ว่าจะใช้ Push Provider เจ้าไหน
                *   `iosPushProvider`: ตั้งค่าเป็น APN (Apple Push Notification) พร้อมระบุ `name` ที่ตรงกับที่ตั้งค่าไว้ใน Dashboard ของ Stream
                *   `androidPushProvider`: ตั้งค่าเป็น Firebase (FCM) พร้อมระบุ `name` ที่ตรงกับที่ตั้งค่าไว้ใน Dashboard ของ Stream
        *   **`..connect()`**: หลังจากสร้าง client แล้ว คำสั่งนี้จะทำการเชื่อมต่อกับ Stream Server ทันที เพื่อให้แอปฯ พร้อมใช้งาน (โทรออก/รับสาย)

---

### Step 2: การจัดการ Push Notification

แอปฯ ต้องสามารถจัดการ Notification ได้ทั้งตอนที่แอปฯ เปิดอยู่ (Foreground), ทำงานเบื้องหลัง (Background), หรือถูกปิดไปแล้ว (Terminated)

*   **ไฟล์ที่เกี่ยวข้อง:**
    *   `firebase_background_handler.dart`: จัดการ Notification เมื่อแอปฯ ไม่ได้เปิดอยู่
    *   `home_page.dart`: จัดการ Notification เมื่อแอปฯ เปิดอยู่

*   **การทำงาน:**

    *   **เมื่อแอปฯ อยู่ในสถานะ Background/Terminated:**
        1.  เมื่อมีสายเข้า Stream จะส่ง Push Notification ผ่าน FCM/APN มายังอุปกรณ์
        2.  **`firebase_background_handler.dart`**: โค้ดในไฟล์นี้จะถูกปลุกให้ทำงานโดยอัตโนมัติผ่าน `FirebaseMessaging.onBackgroundMessage` ที่ลงทะเบียนไว้ใน `main.dart`
        3.  ภายใน `firebaseMessagingBackgroundHandler()`:
            *   จะมีการสร้าง `StreamVideo` client ขึ้นมาใหม่ชั่วคราว
            *   จากนั้นเรียก `StreamVideo.instance.handleRingingFlowNotifications(message.data)`
            *   คำสั่งนี้จะให้ Stream SDK จัดการข้อมูลจาก Notification และ **แสดงผล UI รับสายของระบบปฏิบัติการ (OS-level call UI)** เช่น CallKit บน iOS หรือ ConnectionService บน Android

    *   **เมื่อแอปฯ อยู่ในสถานะ Foreground:**
        1.  **`home_page.dart` (ฟังก์ชัน `_observeFcmMessages`)**: มีการดักฟัง `FirebaseMessaging.onMessage`
        2.  เมื่อมี Notification เข้ามาขณะที่แอปฯ เปิดอยู่ `_handleRemoteMessage()` จะถูกเรียก
        3.  ซึ่งภายในก็จะเรียก `StreamVideo.instance.handleRingingFlowNotifications(message.data)` เช่นกัน เพื่อให้ SDK อัปเดตสถานะการโทรภายในแอปฯ

---

### Step 3: การรับสาย (Handling Incoming Calls)

หลังจากที่ SDK ประมวลผล Notification แล้ว แอปฯ จะต้องแสดงหน้าจอรับสายให้ผู้ใช้เห็น

*   **ไฟล์ที่เกี่ยวข้อง:**
    *   `home_page.dart`

*   **การทำงาน:**

    *   **กรณีที่ 1: รับสายขณะแอปฯ เปิดอยู่ (Foreground)**
        1.  **`_observeIncomingCalls()`**: ฟังก์ชันนี้จะคอยดักฟัง `StreamVideo.instance.state.incomingCall`
        2.  เมื่อมีสายเข้า (หลังจากที่ `handleRingingFlowNotifications` ทำงานใน Step 2) Stream state นี้จะส่ง `Call` object ออกมา
        3.  แอปฯ จะ `Navigator.push` ไปยัง `CallScreen` ทันที พร้อมส่ง `Call` object และ `role: CallUiRole.callee` ไปด้วย

    *   **กรณีที่ 2: ผู้ใช้กดรับสายจาก OS-level UI (Background/Terminated)**
        1.  **`_observeCallKitEvents()`**: ฟังก์ชันนี้จะดักฟัง Event จาก CallKit/ConnectionService
        2.  เมื่อผู้ใช้กดปุ่ม "รับสาย" บน UI ของ OS, `onCallAccepted` จะทำงาน
        3.  แอปฯ จะถูกปลุกขึ้นมา (ถ้ายังไม่เปิด) และ `Navigator.push` ไปยัง `CallScreen` เพื่อเริ่มการสนทนา

---

### Step 4: การโทรออก (Making an Outgoing Call)

กระบวนการเมื่อผู้ใช้เป็นฝ่ายเริ่มต้นการโทร

*   **ไฟล์ที่เกี่ยวข้อง:**
    *   `home_page.dart` (ฟังก์ชัน `_startCall`)

*   **การทำงาน:**
    1.  **ตรวจสอบสิทธิ์ (Permissions)**: เช็คให้แน่ใจว่าแอปฯ ได้รับอนุญาตให้ใช้กล้องและไมโครโฟน
    2.  **สร้าง Call Object**: `StreamVideo.instance.makeCall(...)` เพื่อสร้าง "ห้อง" สำหรับการโทร
    3.  **ไปยังหน้าจอการโทร**: `Navigator.push` ไปยัง `CallScreen` ทันที โดยส่ง `role: CallUiRole.caller` ไปเพื่อบอกให้ UI แสดงสถานะ "กำลังโทรออก"
    4.  **เริ่มการโทรและส่ง Notification**:
        ```dart
        call.getOrCreate(
          memberIds: members,
          ringing: true, // <-- คำสั่งสำคัญ
          video: wantsVideo,
        );
        ```
        การตั้งค่า `ringing: true` คือการบอกให้ Stream Server **ส่ง Push Notification** ไปยังผู้ใช้ทุกคนที่อยู่ใน `memberIds` เพื่อแจ้งว่ามีสายเรียกเข้า

---

### Step 5: หน้าจอการโทรและควบคุม (Call Screen UI & Logic)

UI และ Logic ที่ใช้ระหว่างการสนทนา

*   **ไฟล์ที่เกี่ยวข้อง:**
    *   `call_screen.dart`

*   **การทำงาน:**
    1.  **`StreamCallContainer`**: เป็น Widget หลักจาก SDK ที่จัดการเรื่องยากๆ ทั้งหมด เช่น การแสดงผลวิดีโอ, การรับ-ส่งข้อมูลเสียง, และการซิงค์สถานะต่างๆ
    2.  **`_CallOverlay`**: เป็น UI ที่เราสร้างขึ้นมาครอบทับเพื่อปรับแต่งหน้าตาให้สวยงามและเหมาะสมกับแอปฯ ของเรา
    3.  **การจัดการสถานะ (State Management)**:
        *   `_CallOverlayState` จะดักฟัง `call.state.valueStream` เพื่อรับการเปลี่ยนแปลงสถานะทั้งหมดของการโทร
        *   **`_applyState()`**: เมื่อมีสถานะใหม่เข้ามา ฟังก์ชันนี้จะทำงานและอัปเดตตัวแปร `_stage`
        *   **`_resolveStage()`**: แปลงสถานะจาก SDK (เช่น `CallStatusConnected`, `CallStatusDisconnected`) ให้เป็นสถานะที่ UI เข้าใจได้ (เช่น `_CallUiStage.active`, `_CallUiStage.ended`)
    4.  **การแสดงผลตามสถานะ**:
        *   `_buildStageContent()`: จะแสดงผล UI ส่วนกลางของหน้าจอตาม `_stage` ปัจจุบัน เช่น แสดง Avatar และข้อความ "กำลังโทร..." หรือแสดงเวลาที่คุยไปแล้ว
        *   `_buildBottomControls()`: จะสร้างชุดปุ่มควบคุมที่เหมาะสมกับ `_stage` นั้นๆ เช่น
            *   `_CallUiStage.incoming`: แสดงปุ่ม "รับสาย" (`onAccept`) และ "ปฏิเสธ" (`onReject`)
            *   `_CallUiStage.active`: แสดงปุ่มควบคุมต่างๆ (`ToggleMicrophoneOption`, `ToggleCameraOption`, ปุ่มวางสาย)
    5.  **การโต้ตอบของผู้ใช้**: เมื่อผู้ใช้กดปุ่มต่างๆ จะมีการเรียกฟังก์ชันของ `Call` object เช่น `call.accept()`, `call.reject()`, `call.leave()` เพื่อส่งคำสั่งไปยัง Stream Server
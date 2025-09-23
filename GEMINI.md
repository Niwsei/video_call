# GEMINI.md - Stream Video Flutter Call App

## 📱 ภาพรวมของโปรเจค

แอปพลิเคชัน Video Call ที่สร้างด้วย Flutter และ Stream Video SDK ที่มีความสามารถในการโทรแบบ 1-on-1 และ group call พร้อมฟีเจอร์ครบครัน

## 🏗️ สถาปัตยกรรม

```
lib/
├── main.dart                # Entry point และ client initialization
├── home_page.dart          # หน้าแรก - join/create call
├── call_screen.dart        # หน้าจอ video call
├── models/                 # Data models (ถ้ามี)
├── services/              # Business logic services
└── widgets/               # Custom widgets
```

## 🔧 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  stream_video_flutter: ^0.5.0
  permission_handler: ^11.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## ⚙️ การตั้งค่าเริ่มต้น

### Android Permissions (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### iOS Permissions (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for video calls</string>
```

## 🚀 การเริ่มต้นใช้งาน

### 1. Stream Video Client Setup
```dart
final client = StreamVideo(
  'YOUR_API_KEY',
  user: User.regular(userId: 'USER_ID', name: 'USER_NAME'),
  userToken: 'YOUR_USER_TOKEN',
);
```

### 2. Call Creation
```dart
final call = client.makeCall(
  callType: StreamCallType.defaultType(),
  id: 'UNIQUE_CALL_ID',
);
```

### 3. Join Call
```dart
await call.getOrCreate();
await call.join();
```

## 📱 คอมโพเนนต์หลัก

### HomePage
- Permission handling
- Call information display
- Join existing call
- Create new call
- User-friendly UI with status indicators

### CallScreen
- Real-time video rendering
- Participant management
- Call controls (mic, camera, flip, leave)
- Connection status monitoring
- Grid layout for multiple participants

## 🎮 ฟีเจอร์หลัก

### Call Controls
- **Microphone Toggle**: เปิด/ปิดไมค์
- **Camera Toggle**: เปิด/ปิดกล้อง
- **Camera Flip**: สลับกล้องหน้า/หลัง
- **Leave Call**: ออกจาก call
- **Custom Actions**: ปุ่มกิจกรรมพิเศษ (เช่น Hello button)

### Participant Features
- **Video Renderer**: แสดงวิดีโอของแต่ละคน
- **Audio Indicator**: แสดงสถานะไมค์
- **Name Display**: แสดงชื่อผู้เข้าร่วม
- **Local Indicator**: แสดงว่าใครเป็น "You"
- **Avatar Fallback**: แสดง avatar เมื่อไม่มีวิดีโอ

## 🔄 State Management

### CallState Properties
- `callParticipants`: รายชื่อผู้เข้าร่วมทั้งหมด
- `localParticipant`: ข้อมูลผู้ใช้ปัจจุบัน
- `status`: สถานะการเชื่อมต่อ

### CallParticipantState Properties
- `hasVideo`: มีวิดีโอหรือไม่
- `hasAudio`: มีเสียงหรือไม่
- `isLocal`: เป็นผู้ใช้ปัจจุบันหรือไม่
- `name`: ชื่อผู้เข้าร่วม
- `userId`: User ID

## 🛡️ Permission Management

### Permission Check Flow
1. ตรวจสอบ permissions ปัจจุบัน
2. แสดงสถานะใน UI
3. Request permissions หากจำเป็น
4. แสดง dialog สำหรับการเปิด settings
5. Update UI ตามสถานะ permissions

### Permission Handler
```dart
Future<void> _checkPermissions() async {
  final cameraStatus = await Permission.camera.status;
  final microphoneStatus = await Permission.microphone.status;
  
  setState(() {
    _permissionsGranted = cameraStatus.isGranted && microphoneStatus.isGranted;
  });
}
```

## 🎨 UI/UX Design

### Design System
- **Colors**: Blue primary, gradient backgrounds
- **Typography**: Material 3 text styles
- **Spacing**: Consistent 8px grid system
- **Cards**: Rounded corners with shadows
- **Buttons**: Circular FABs with proper states

### Responsive Layout
- **Single Participant**: Full screen video
- **Multiple Participants**: Grid layout (2 columns)
- **Portrait/Landscape**: Adaptive aspect ratios

## 🔊 Audio/Video Handling

### Stream Video Renderer
```dart
StreamVideoRenderer(
  call: widget.call,
  participant: participant,
  videoTrackType: SfuTrackType.video,
)
```

### Audio/Video Controls
```dart
// Toggle microphone
await call.setMicrophoneEnabled(enabled: !isAudioEnabled);

// Toggle camera
await call.setCameraEnabled(enabled: !isVideoEnabled);

// Flip camera
await call.flipCamera();
```

## 📊 Connection Monitoring

### Real-time Status
- Connection indicator (Connected/Connecting)
- Participant count display
- Network status monitoring
- Error handling with user feedback

### Stream Listening
```dart
widget.call.state.valueStream.listen((callState) {
  setState(() {
    _isConnected = callState.status == CallStatus.connected;
  });
});
```

## 🐛 Error Handling

### Common Error Scenarios
- **Network Issues**: Connection timeout, poor connectivity
- **Permission Denied**: Camera/microphone access
- **Call Creation Failed**: Invalid parameters, server issues
- **Join Failed**: Call doesn't exist, capacity reached

### Error Recovery
```dart
try {
  await call.join();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

## 🔧 การปรับแต่งขั้นสูง

### Custom Call Controls
สามารถเพิ่มปุ่มควบคุมใหม่ได้:
```dart
_buildControlButton(
  icon: Icons.screen_share,
  color: Colors.white,
  backgroundColor: Colors.blue,
  onPressed: () => call.toggleScreenShare(),
)
```

### Participant Grid Customization
ปรับแต่งการแสดงผลผู้เข้าร่วม:
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: participants.length == 1 ? 1 : 2,
    childAspectRatio: 16 / 9,
  ),
  // ...
)
```

## 📚 API Reference

### StreamVideo Methods
- `makeCall()`: สร้าง call object
- `dispose()`: ทำความสะอาด resources

### Call Methods
- `getOrCreate()`: สร้างหรือเข้าร่วม call
- `join()`: เข้าร่วม call
- `leave()`: ออกจาก call
- `setMicrophoneEnabled()`: ควบคุมไมค์
- `setCameraEnabled()`: ควบคุมกล้อง
- `flipCamera()`: สลับกล้อง

### State Streams
- `call.state.valueStream`: สถานะ call
- `call.state.listen()`: ฟัง state changes

## 🚀 การ Deploy

### Development
```bash
flutter pub get
flutter run --debug
```

### Production
```bash
flutter build apk --release    # Android
flutter build ios --release    # iOS
```

### Testing
```bash
flutter test                   # Unit tests
flutter integration_test       # Integration tests
```

## 🔐 Security Considerations

### Token Management
- ใช้ JWT tokens ที่มี expiration time
- Refresh tokens ก่อนหมดอายุ
- เก็บ tokens อย่างปลอดภัย

### Permissions
- Request permissions เมื่อจำเป็นเท่านั้น
- แสดงเหตุผลที่ชัดเจนให้ผู้ใช้
- Handle permission denial gracefully

## 📈 Performance Optimization

### Memory Management
- Dispose controllers เมื่อไม่ใช้
- ใช้ `StreamBuilder` แทน `setState` ที่ไม่จำเป็น
- Clean up listeners ใน `dispose()`

### Network Optimization
- ใช้ adaptive bitrate
- Monitor connection quality
- Handle network changes

## 🧪 Testing Strategy

### Unit Tests
- Test business logic
- Mock Stream Video SDK
- Test state management

### Integration Tests
- Test complete user flows
- Test permission handling
- Test call scenarios

### Device Testing
- Test on real devices (not emulators for video)
- Test different network conditions
- Test various screen sizes

## 📱 Platform-Specific Considerations

### Android
- Proguard rules สำหรับ WebRTC
- Background processing permissions
- Audio focus management

### iOS
- CallKit integration (optional)
- Background modes configuration
- App Transport Security settings

## 🔄 Continuous Integration

### GitHub Actions Example
```yaml
name: Flutter CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk
```

## 📖 References

- [Stream Video Flutter Documentation](https://getstream.io/video/docs/flutter/)
- [Flutter WebRTC Guide](https://flutter.dev/docs/development/platform-integration/web)
- [Permission Handler Package](https://pub.dev/packages/permission_handler)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Add tests
5. Update documentation
6. Submit pull request

## 📄 License

```
Copyright (c) 2024
Licensed under the MIT License
```

## 📞 Support

- Email: support@example.com
- Discord: [Project Discord](https://discord.gg/example)
- Issues: [GitHub Issues](https://github.com/example/repo/issues)

---

**Last Updated**: January 2024  
**Version**: 1.0.0  
**Flutter Version**: 3.16.0  
**Stream Video SDK**: 0.5.0
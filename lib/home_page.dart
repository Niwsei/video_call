import 'dart:async';

/// SwiftX Express – Home dashboard
///
/// Flow (high‑level)
/// 1) App boots (main.dart) → AppInitializer.init(..) + store user + register
///    global background FCM handler.
/// 2) HomePage.initState registers: foreground FCM listener, in‑app
///    incoming‑call stream, OS call acceptance events, and Android
///    consume-and-accept flow after process death.
/// 3) Customer tab: create orders, view driver + timeline, press call to dial.
/// 4) Driver tab: switch active driver, advance order status, call customer.
/// 5) Calls:
///    - Outgoing: _startCall (steps 1‑4 inside function).
///    - Incoming (foreground): _observeIncomingCalls → open CallScreen.
///    - Incoming (OS UI accept): _observeCallKitEvents → open CallScreen.
///    - Incoming (Android app killed): _consumeAcceptedCallFromTerminated.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';
import 'package:uuid/uuid.dart';

import 'call_screen.dart';
import 'delivery_models.dart';
import 'tutorial_user.dart';
import 'dev_manual_auth.dart';

class HomePage extends StatefulWidget {
  final StreamVideo client;
  const HomePage({super.key, required this.client});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _uuid = const Uuid();
  bool _permissionsGranted = false;
  bool _isVideoCall = true;

  StreamSubscription<RemoteMessage>? _fcmFgSub;
  StreamSubscription<Call?>? _incomingCallSub;
  StreamSubscription<dynamic>? _callKitSub;

  late final Map<String, TutorialUser> _userDirectory;
  late final List<TutorialUser> _drivers;
  late final List<DeliveryOrder> _orders;
  late String _activeDriverId;

  @override
  void initState() {
    super.initState();
    // Step 2.1 – Build an in‑memory directory of users
    if (ManualAuth.enabled) {
      // Use manual A/B users so IDs/names match dev_manual_auth.dart
      final a = ManualAuth.userA;
      final b = ManualAuth.userB;
      final manualList = [
        TutorialUser(
          user: User.regular(userId: a.userId, name: a.name),
          token: null,
        ),
        TutorialUser(
          user: User.regular(userId: b.userId, name: b.name),
          token: null,
        ),
      ];
      _userDirectory = {for (final u in manualList) u.user.id: u};
    } else {
      _userDirectory = {
        for (final user in TutorialUser.users) user.user.id: user,
      };
    }

    final currentUserId = widget.client.currentUser.id;
    _drivers =
        _userDirectory.values
            .where((user) => user.user.id != currentUserId)
            .toList();
    _activeDriverId =
        _drivers.isNotEmpty ? _drivers.first.user.id : currentUserId;

    // Step 2.2 – Seed a few demo orders
    _orders = _seedInitialOrders();

    // Step 2.3 – Permissions and listeners
    _checkPermissions();
    if (!kIsWeb) {
      _requestNotificationPermissions();
      _observeFcmMessages(); // Foreground FCM → in‑app notifications
    }
    _observeIncomingCalls(); // Stream incoming call while app open
    _observeCallKitEvents(); // OS accepts (CallKit/CS)
    _consumeAcceptedCallFromTerminated(); // Android resume after process death
  }

  @override
  void dispose() {
    _fcmFgSub?.cancel();
    _incomingCallSub?.cancel();
    _callKitSub?.cancel();
    super.dispose();
  }

  List<DeliveryOrder> _seedInitialOrders() {
    final now = DateTime.now();
    final meId = widget.client.currentUser.id;
    final primaryDriver = _drivers.isNotEmpty ? _drivers.first.user.id : meId;
    final secondaryDriver =
        _drivers.length > 1 ? _drivers[1].user.id : primaryDriver;

    return <DeliveryOrder>[
      DeliveryOrder(
        code: 'SVX-${now.millisecondsSinceEpoch % 10000}'.padLeft(4, '0'),
        packageSummary: 'เอกสารสัญญาด่วน',
        pickupAddress: 'สยามสแควร์วัน',
        dropOffAddress: 'ออฟฟิศ Stream (FYI Center)',
        customerId: meId,
        driverId: primaryDriver,
        scheduledAt: now.subtract(const Duration(minutes: 12)),
        eta: const Duration(minutes: 35),
        stage: DeliveryStage.driverEnRoute,
      ),
      DeliveryOrder(
        code: 'SVX-${(now.millisecondsSinceEpoch + 427) % 10000}'.padLeft(
          4,
          '0',
        ),
        packageSummary: 'อาหารแช่แข็ง (เก็บเย็น)',
        pickupAddress: 'Warehouse Bangna',
        dropOffAddress: 'The PARQ ชั้น 16',
        customerId: meId,
        driverId: secondaryDriver,
        scheduledAt: now.subtract(const Duration(minutes: 3)),
        eta: const Duration(minutes: 55),
        stage: DeliveryStage.requested,
      ),
    ];
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) {
      // Browser will prompt on first media use; treat as granted for UI flow.
      setState(() => _permissionsGranted = true);
      return;
    }
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    setState(() => _permissionsGranted = cam.isGranted && mic.isGranted);
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    final statuses = await [Permission.camera, Permission.microphone].request();
    final ok = statuses.values.every((s) => s.isGranted);
    setState(() => _permissionsGranted = ok);
    if (!ok && mounted) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('ต้องการสิทธิ์กล้อง/ไมค์'),
          content: const Text('อนุญาตการเข้าถึงเพื่อวิดีโอคอลกับไรเดอร์ได้อย่างสมบูรณ์'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('ไปที่การตั้งค่า'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _requestNotificationPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (CurrentPlatform.isAndroid) {
      StreamVideoPushNotificationManager.ensureFullScreenIntentPermission();
    }
  }

  /// Subscribe to foreground FCM messages so Stream can process ringing/missed
  void _observeFcmMessages() {
    _fcmFgSub = FirebaseMessaging.onMessage.listen(_handleRemoteMessage);
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    await StreamVideo.instance.handleRingingFlowNotifications(message.data);
  }

  /// Step 2.3.3 – In‑app incoming call while app is open (foreground)
  void _observeIncomingCalls() {
    _incomingCallSub = StreamVideo.instance.state.incomingCall.listen((call) {
      if (!mounted || call == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(call: call, role: CallUiRole.callee),
        ),
      );
    });
  }

  /// Step 2.3.4 – Accept call from OS UI (CallKit/ConnectionService)
  void _observeCallKitEvents() {
    _callKitSub = StreamVideo.instance.observeCoreCallKitEvents(
      onCallAccepted: (callToJoin) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => CallScreen(call: callToJoin, role: CallUiRole.callee),
          ),
        );
      },
    );
  }

  /// Step 2.3.5 – Android: app was killed, user accepted from OS → resume
  void _consumeAcceptedCallFromTerminated() {
    if (CurrentPlatform.isIos) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StreamVideo.instance.consumeAndAcceptActiveCall(
        onCallAccepted: (callToJoin) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => CallScreen(call: callToJoin, role: CallUiRole.callee),
            ),
          );
        },
      );
    });
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  TutorialUser? _userFor(String id) => _userDirectory[id];

  String _displayName(String id) =>
      _userFor(id)?.user.name?.trim().isNotEmpty == true
          ? _userFor(id)!.user.name!
          : id;

  String? _avatarUrl(String id) => _userFor(id)?.user.image;

  String _formatEta(DeliveryOrder order) {
    final remaining = order.remainingEta;
    if (remaining == Duration.zero) {
      return 'ถึงที่หมายแล้ว';
    }
    final minutes = remaining.inMinutes;
    if (minutes <= 1) return 'เหลือไม่ถึง 1 นาที';
    if (minutes < 60) return 'อีก $minutes นาที';
    final hours = remaining.inHours;
    final remMinutes = remaining.inMinutes.remainder(60);
    return 'อีก $hours ชม. ${remMinutes.toString().padLeft(2, '0')} นาที';
  }

  //ตรวจสิทธิ์ กล้อง/ไมค์
  /// Outgoing call flow (1‑1 voice/video)
  /// Steps inside this function:
  /// 1) Guard rails – validate member list, permissions, avoid active/outgoing
  ///    call duplication.
  /// 2) Create call object via StreamVideo.makeCall.
  /// 3) getOrCreate(ringing: true) → triggers push & ringing flow.
  /// 4) Navigate to CallScreen(role: caller).
  Future<void> _startCall({
    required Iterable<String> memberIds,
    bool? video,
  }) async {
    final uniqueMembers =
        memberIds.toSet()..remove(widget.client.currentUser.id);
    if (uniqueMembers.isEmpty) {
      _notify('ไม่พบปลายทางที่จะโทรหา');
      return;
    }

    if (!_permissionsGranted) {
      await _requestPermissions();
      if (!_permissionsGranted) return;
    }

    final activeCall = StreamVideo.instance.activeCall;
    if (activeCall != null) {
      _notify('มีสายกำลังทำงานอยู่');
      return;
    }

    final outgoingCall = StreamVideo.instance.state.outgoingCall.valueOrNull;
    if (outgoingCall != null) {
      _notify('กำลังโทรออกอยู่แล้ว');
      return;
    }

    // Use a deterministic 1v1 call-id in manual mode to aid debugging.
    String callId;
    if (ManualAuth.enabled && uniqueMembers.length == 1) {
      final sorted = [widget.client.currentUser.id, uniqueMembers.first]..sort();
      callId = '1v1-${sorted.join('-')}';
    } else {
      callId = 'svx-${_uuid.v4()}';
    }

    final call = StreamVideo.instance.makeCall(
      callType: StreamCallType.defaultType(),
      id: callId,
    );

    // Navigate first for faster perceived response; create the call in background.
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(call: call, role: CallUiRole.caller),
      ),
    );

    final members = uniqueMembers.toList();
    final wantsVideo = video ?? _isVideoCall;
    final startedAt = DateTime.now();
    debugPrint('getOrCreate start id=$callId members=$members video=$wantsVideo');
    unawaited(
      call
          .getOrCreate(
            memberIds: members,
            // Use ringing=true to emit in-app incoming call events for the callee
            ringing: true,
            video: wantsVideo,
          )
          .then((_) {
        final ms = DateTime.now().difference(startedAt).inMilliseconds;
        debugPrint('getOrCreate done (${ms}ms) id=$callId');
      }).catchError((error, stack) {
        debugPrint('Failed to create call: $error\n$stack');
        _notify('โทรออกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
      }),
    );
  }

  /// Driver action – advance order to next allowed stage (guarding backward
  /// or duplicate transitions). Updates UI on success.
  void _advanceOrder(DeliveryOrder order, {DeliveryStage? toStage}) {
    final changed = order.advance(toStage);
    if (!changed) {
      _notify('สถานะล่าสุดถูกอัปเดตแล้ว');
      return;
    }
    setState(() {});
  }

  /// Cancel order if not already delivered/cancelled; updates UI on success.
  void _cancelOrder(DeliveryOrder order) {
    final cancelled = order.cancel();
    if (!cancelled) {
      _notify('ไม่สามารถยกเลิกได้ในขณะนี้');
      return;
    }
    setState(() {});
  }

  /// Create a new demo order and assign it round‑robin to available drivers.
  void _createNewOrder() {
    final meId = widget.client.currentUser.id;
    final driverId =
        _drivers.isNotEmpty
            ? _drivers[_orders.length % _drivers.length].user.id
            : meId;
    final now = DateTime.now();
    final newOrder = DeliveryOrder(
      code: 'SVX-${_uuid.v4().substring(0, 6).toUpperCase()}',
      packageSummary: 'พัสดุด่วน ${_orders.length + 1}',
      pickupAddress: 'จุดรับ ${_orders.length + 5}',
      dropOffAddress: 'จุดส่ง ${_orders.length + 12}',
      customerId: meId,
      driverId: driverId,
      scheduledAt: now,
      eta: const Duration(minutes: 45),
    );
    setState(() => _orders.insert(0, newOrder));
    _notify('สร้างออเดอร์ใหม่เรียบร้อย');
  }

  /// Customer tab – list my orders, contact driver, create new order.
  Widget _buildCustomerView() {
    final meId = widget.client.currentUser.id;
    final orders = _orders.where((order) => order.customerId == meId).toList();
    if (orders.isEmpty) {
      return _buildEmptyState(
        context,
        message: 'ยังไม่มีรายการจัดส่ง สร้างงานแรกของคุณได้เลย',
        action: FilledButton.icon(
          onPressed: _createNewOrder,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 6,
            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: .4),
          ),
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'สร้างออเดอร์ด่วน',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildCustomerOrderCard(context, order);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemCount: orders.length,
    );
  }

  /// Driver tab – switch active driver, see assigned orders, advance status.
  Widget _buildDriverView() {
    final theme = Theme.of(context);
    final driverOrders =
        _orders.where((order) => order.driverId == _activeDriverId).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Card(
            elevation: 6,
            clipBehavior: Clip.antiAlias,
            shadowColor: theme.colorScheme.secondary.withValues(alpha: .25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondaryContainer.withValues(alpha: .3),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary.withValues(alpha: .25),
                            theme.colorScheme.secondary.withValues(alpha: .15),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.secondary.withValues(alpha: .2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.delivery_dining_rounded,
                          color: theme.colorScheme.secondary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _activeDriverId,
                        decoration: InputDecoration(
                          labelText: 'สลับบทบาทไรเดอร์',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor:
                              theme.colorScheme.surface.withValues(alpha: .9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: theme.colorScheme.surface,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _activeDriverId = value);
                        },
                        items:
                            _drivers
                                .map(
                                  (driver) => DropdownMenuItem(
                                    value: driver.user.id,
                                    child: Text(
                                      driver.user.name ?? driver.user.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child:
              driverOrders.isEmpty
                  ? _buildEmptyState(
                      context,
                      message: 'ยังไม่มีงานที่ได้รับมอบหมายให้ไรเดอร์คนนี้',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final order = driverOrders[index];
                        return _buildDriverOrderCard(context, order);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemCount: driverOrders.length,
                    ),
        ),
      ],
    );
  }

  Widget _buildCustomerOrderCard(BuildContext context, DeliveryOrder order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final driverName = _displayName(order.driverId);
    final driverAvatar = _avatarUrl(order.driverId);
    final stageColor = order.stage.accentColor;
    final trimmedDriverName = driverName.trim();
    final driverInitial =
        trimmedDriverName.isNotEmpty ? trimmedDriverName[0].toUpperCase() : '?';

    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shadowColor: colorScheme.primary.withValues(alpha: .3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withValues(alpha: .5),
              colorScheme.secondaryContainer.withValues(alpha: .2),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: .3),
                          colorScheme.secondary.withValues(alpha: .2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: .2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      backgroundImage:
                          driverAvatar != null ? NetworkImage(driverAvatar) : null,
                      child: driverAvatar == null
                          ? Text(
                              driverInitial,
                              style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ) ??
                                  TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ออเดอร์ ${order.code}',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ) ??
                              TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ไรเดอร์: $driverName',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ) ??
                              TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          stageColor.withValues(alpha: .25),
                          stageColor.withValues(alpha: .15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: stageColor.withValues(alpha: .3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: stageColor.withValues(alpha: .15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      order.stage.label,
                      style: TextStyle(
                        color: stageColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildAddressRow(
                context,
                icon: Icons.my_location_rounded,
                title: 'สถานที่รับ',
                detail: order.pickupAddress,
              ),
              const SizedBox(height: 10),
              _buildAddressRow(
                context,
                icon: Icons.location_on_rounded,
                title: 'ปลายทาง',
                detail: order.dropOffAddress,
              ),
              const Divider(height: 32),
              _buildTimeline(context, order),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startCall(
                        memberIds: [order.driverId],
                        video: _isVideoCall,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: colorScheme.primary.withValues(alpha: .4),
                      ),
                      icon: Icon(
                        _isVideoCall
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        size: 22,
                      ),
                      label: Text(
                        _isVideoCall ? 'วิดีโอคอล' : 'โทรหา',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _notify('ส่งข้อความหาไรเดอร์เรียบร้อย'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: .5),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    label: const Text(
                      'แชท',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatEta(order),
                    style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ) ??
                        TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverOrderCard(BuildContext context, DeliveryOrder order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customerName = _displayName(order.customerId);
    final customerAvatar = _avatarUrl(order.customerId);
    final nextStage = order.nextStage;
    final trimmedCustomerName = customerName.trim();
    final customerInitial = trimmedCustomerName.isNotEmpty
        ? trimmedCustomerName[0].toUpperCase()
        : '?';

    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shadowColor: colorScheme.secondary.withValues(alpha: .3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.secondaryContainer.withValues(alpha: .5),
              colorScheme.tertiaryContainer.withValues(alpha: .2),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondary.withValues(alpha: .3),
                          colorScheme.tertiary.withValues(alpha: .2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.secondary.withValues(alpha: .2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.transparent,
                      backgroundImage:
                          customerAvatar != null ? NetworkImage(customerAvatar) : null,
                      child: customerAvatar == null
                          ? Text(
                              customerInitial,
                              style: theme.textTheme.titleLarge?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ) ??
                                  TextStyle(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ออเดอร์ ${order.code}',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ) ??
                              TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ลูกค้า: $customerName',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ) ??
                              TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'cancel') {
                        _cancelOrder(order);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'cancel',
                        child: Text('ยกเลิกงาน'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                order.packageSummary,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ) ??
                    TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                order.pickupAddress,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ) ??
                    TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                '→ ${order.dropOffAddress}',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ) ??
                    TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const Divider(height: 32),
              _buildStageBadges(order),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          nextStage == null ? null : () => _advanceOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: colorScheme.secondary.withValues(alpha: .4),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text(
                        nextStage?.driverButtonLabel ?? 'เสร็จสิ้น',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _startCall(
                      memberIds: [order.customerId],
                      video: false,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      side: BorderSide(
                        color: colorScheme.secondary.withValues(alpha: .5),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 20),
                    label: const Text(
                      'โทร',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'อัปเดตล่าสุด ${_formatShortTime(context, order.lastUpdated)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ) ??
                        TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, DeliveryOrder order) {
    final stages = List<DeliveryStage>.from(kDeliveryProgression);
    if (order.stage == DeliveryStage.cancelled &&
        !stages.contains(DeliveryStage.cancelled)) {
      stages.add(DeliveryStage.cancelled);
    }

    return Column(
      children: [
        for (int i = 0; i < stages.length; i++)
          _buildTimelineRow(
            context,
            order,
            stages[i],
            isLast: i == stages.length - 1,
          ),
      ],
    );
  }

  /// Timeline row – visual checkpoint + timestamp for each delivery stage.
  Widget _buildTimelineRow(
    BuildContext context,
    DeliveryOrder order,
    DeliveryStage stage, {
    required bool isLast,
  }) {
    final reached = _isStageReached(order, stage);
    final timestamp = order.timestampFor(stage);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  reached ? stage.accentColor : Colors.grey.shade300,
              child: Icon(
                stage.icon,
                size: 18,
                color: reached ? Colors.white : Colors.black45,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color:
                    reached
                        ? stage.accentColor.withValues(alpha: .6)
                        : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      stage.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: reached ? Colors.black87 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (timestamp != null)
                      Text(
                        _formatShortTime(context, timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                  ],
                ),
                Text(
                  stage.description,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Compact, readable badges that reflect reached stages for a quick glance.
  Widget _buildStageBadges(DeliveryOrder order) {
    final stages = List<DeliveryStage>.from(kDeliveryProgression);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          stages.map((stage) {
            final reached = _isStageReached(order, stage);
            return Chip(
              avatar: Icon(
                stage.icon,
                size: 18,
                color: reached ? Colors.white : stage.accentColor,
              ),
              backgroundColor:
                  reached
                      ? stage.accentColor
                      : stage.accentColor.withValues(alpha: .15),
              label: Text(
                stage.label,
                style: TextStyle(
                  color: reached ? Colors.white : stage.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
    );
  }

  /// Generic address row for pickup/dropoff sections on cards.
  Widget _buildAddressRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String detail,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final titleStyle = theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        );

    final detailStyle = theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ) ??
        TextStyle(color: colorScheme.onSurfaceVariant);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              const SizedBox(height: 2),
              Text(detail, style: detailStyle),
            ],
          ),
        ),
      ],
    );
  }

  /// Reusable empty state with optional action widget.
  Widget _buildEmptyState(
    BuildContext context, {
    required String message,
    Widget? action,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Card(
        elevation: 4,
        color: theme.colorScheme.surface.withValues(alpha: .98),
        shadowColor: theme.colorScheme.primary.withValues(alpha: .15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: .15),
                Colors.white.withValues(alpha: .8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: .2),
                        theme.colorScheme.primary.withValues(alpha: .1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: .15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.transparent,
                    child: Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ) ??
                      TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 28),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format timestamp into short time using current Material localization.
  String _formatShortTime(BuildContext context, DateTime time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time));
  }

  /// Helper to decide if a stage is considered “reached” for visual cues.
  bool _isStageReached(DeliveryOrder order, DeliveryStage stage) {
    if (stage == DeliveryStage.cancelled) {
      return order.stage == DeliveryStage.cancelled;
    }
    final currentIndex = kDeliveryProgression.indexOf(order.stage);
    final stageIndex = kDeliveryProgression.indexOf(stage);
    if (currentIndex == -1 || stageIndex == -1) {
      return false;
    }
    return stageIndex <= currentIndex;
  }

  Future<void> _preflightCheck() async {
    try {
      if (!_permissionsGranted) {
        await _requestPermissions();
        if (!_permissionsGranted) {
          _notify('ต้องอนุญาตกล้อง/ไมค์ก่อน');
          return;
        }
      }

      final me = widget.client.currentUser.id;
      final callId = 'preflight-$me-${DateTime.now().millisecondsSinceEpoch}';
      final call = StreamVideo.instance.makeCall(
        callType: StreamCallType.defaultType(),
        id: callId,
      );
      final startedAt = DateTime.now();
      await call.getOrCreate(
        memberIds: const <String>[],
        ringing: false,
        video: false,
      );
      final ms = DateTime.now().difference(startedAt).inMilliseconds;
      _notify('Preflight OK ($ms ms) id=$callId');
    } catch (e, st) {
      debugPrint('Preflight failed: $e\n$st');
      _notify('Preflight ล้มเหลว: $e');
    }
  }

  void _showConfiguredUsers() {
    final theme = Theme.of(context);
    final isManual = ManualAuth.enabled;
    final me = widget.client.currentUser.id;
    final List<Map<String, String>> rows = [];

    if (isManual) {
      final a = ManualAuth.userA;
      final b = ManualAuth.userB;
      rows.addAll([
        {
          'label': 'Manual A',
          'userId': a.userId,
          'name': a.name,
          'me': (me == a.userId) ? '•' : '',
        },
        {
          'label': 'Manual B',
          'userId': b.userId,
          'name': b.name,
          'me': (me == b.userId) ? '•' : '',
        },
      ]);
    } else {
      final users = TutorialUser.users;
      for (final t in users) {
        rows.add({
          'label': 'Tutorial',
          'userId': t.user.id,
          'name': t.user.name ?? t.user.id,
          'me': (me == t.user.id) ? '•' : '',
        });
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ผู้ใช้ที่พร้อมสำหรับทดสอบ',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final r in rows) ...[
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(r['me']!.isNotEmpty ? 'ฉัน' : r['label']!),
                  title: Text(r['name'] ?? ''),
                  subtitle: Text('userId: ${r['userId']}'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'หมายเหตุ: โหมด Manual/Tutorial แสดงผู้ใช้ที่กำหนดในแอปเท่านั้น ไม่ใช่สถานะออนไลน์จริง',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 24,
          toolbarHeight: 110,
          elevation: 8,
          shadowColor: colorScheme.primary.withValues(alpha: .4),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: .85),
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: .3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SwiftX Express Console'),
              const SizedBox(height: 4),
              Text(
                'แดชบอร์ดจัดการงานจัดส่งและการคอลแบบเรียลไทม์',
                style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: .82),
                    ) ??
                    TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: .82),
                    ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colorScheme.onPrimary.withValues(alpha: .25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'สร้างออเดอร์ใหม่',
                  onPressed: _createNewOrder,
                  icon: const Icon(Icons.add_rounded, size: 26),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colorScheme.onPrimary.withValues(alpha: .25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'ตรวจระบบโทร (Preflight)',
                  onPressed: _preflightCheck,
                  icon: const Icon(Icons.health_and_safety_rounded, size: 22),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colorScheme.onPrimary.withValues(alpha: .25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'ดูรายชื่อสำหรับทดสอบ',
                  onPressed: _showConfiguredUsers,
                  icon: const Icon(Icons.people_alt_rounded, size: 22),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.onPrimary.withValues(alpha: .25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _isVideoCall
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      color: colorScheme.onPrimary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isVideoCall ? 'โหมดวิดีโอ' : 'โหมดเสียง',
                      style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ) ??
                          TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 14),
                    Transform.scale(
                      scale: .95,
                      child: Switch(
                        value: _isVideoCall,
                        onChanged: (value) => setState(() => _isVideoCall = value),
                        activeColor: colorScheme.onPrimary,
                        activeTrackColor:
                            colorScheme.onPrimary.withValues(alpha: .35),
                        inactiveThumbColor: colorScheme.onPrimary.withValues(alpha: .7),
                        inactiveTrackColor:
                            colorScheme.onPrimary.withValues(alpha: .2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(96),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colorScheme.onPrimary.withValues(alpha: .25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  padding: const EdgeInsets.all(6),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.onPrimary.withValues(alpha: .35),
                        colorScheme.onPrimary.withValues(alpha: .25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.onPrimary.withValues(alpha: .2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.shopping_bag_rounded, size: 24),
                      text: 'ฝั่งลูกค้า',
                    ),
                    Tab(
                      icon: Icon(Icons.delivery_dining_rounded, size: 24),
                      text: 'ฝั่งไรเดอร์',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withValues(alpha: .12),
                theme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCustomerView(),
              _buildDriverView(),
            ],
          ),
        ),
      ),
    );
  }
}

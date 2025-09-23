// lib/home_page.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_push_notification/stream_video_push_notification.dart';
import 'package:stream_video_test/app_initializer.dart';
import 'package:uuid/uuid.dart';

import 'call_lifecycle.dart';
import 'call_display_utils.dart';
import 'call_screen.dart';
import 'app_keys.dart';
import 'firebase_options.dart';
import 'tutorial_user.dart';

class HomePage extends StatefulWidget {
  final StreamVideo client;

  const HomePage({super.key, required this.client});

  @override
  State<HomePage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  bool _isJoining = false;
  bool _permissionsGranted = false;
  bool _isVideoCall = true;
  final List<String> _selectedUserIds = [];
  final Subscriptions _subscriptions = Subscriptions();
  StreamSubscription<StreamCallEvent>? _callEventsSubscription;
  StreamSubscription<CallState>? _callStateSubscription;
  CallLifecycleStage _callLifecycleStage = CallLifecycleStage.idle;
  String? _callLifecycleDetails = 'Ready for new calls';

  static const int _fcmSubscription = 1;
  static const int _callKitSubscription = 2;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _requestNotificationPermissions();
    _tryConsumingIncomingCallFromTerminatedState();
    _observeFcmMessages();
    _observeCallKitEvents();
  }

  @override
  void dispose() {
    _stopObservingCall();
    _subscriptions.cancelAll();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    setState(() {
      _permissionsGranted =
          cameraStatus.isGranted && microphoneStatus.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    final allGranted = statuses.values.every((status) => status.isGranted);

    setState(() {
      _permissionsGranted = allGranted;
    });

    if (!allGranted) {
      _showPermissionDialog();
    }
  }

  Future<void> _requestNotificationPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void _showPermissionDialog() {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Camera and microphone permissions are required for video calls. '
              'Please grant these permissions in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  // Handle Firebase messaging for incoming calls
  void _observeFcmMessages() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _subscriptions.add(
      _fcmSubscription,
      FirebaseMessaging.onMessage.listen(_handleRemoteMessage),
    );
  }

  Future<bool> _handleRemoteMessage(RemoteMessage message) async {
    return StreamVideo.instance.handleRingingFlowNotifications(message.data);
  }

  // Handle CallKit events for accepting/declining calls
  void _observeCallKitEvents() {
    final streamVideo = StreamVideo.instance;
    _subscriptions.add(
      _callKitSubscription,
      streamVideo.observeCoreCallKitEvents(
        onCallAccepted: (callToJoin) {
          _setActiveCallAndNavigate(callToJoin, markAsAccepted: true);
        },
      ),
    );
  }

  // Handle incoming calls when app is reopened from terminated state
  void _tryConsumingIncomingCallFromTerminatedState() {
    // This is only relevant for Android
    if (CurrentPlatform.isIos) return;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      StreamVideo.instance.consumeAndAcceptActiveCall(
        onCallAccepted: (callToJoin) {
          _setActiveCallAndNavigate(callToJoin, markAsAccepted: true);
        },
      );
    });
  }

  // Create a ringing call
  Future<void> _createRingingCall() async {
    if (!_permissionsGranted) {
      await _requestPermissions();
      if (!_permissionsGranted) return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one user to call'),
        ),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final call = StreamVideo.instance.makeCall(
        callType: StreamCallType.defaultType(),
        id: "niwner12345",
      );

      final targetNames = _formatSelectedParticipantNames();
      _updateCallLifecycleStage(
        CallLifecycleStage.ringing,
        detail: targetNames.isNotEmpty ? 'Calling ' + targetNames : null,
      );

      _setActiveCallAndNavigate(call);

      final result = await call.getOrCreate(
        memberIds: _selectedUserIds,
        video: _isVideoCall,
        ringing: true,
      );

      await result.fold<Future<void>>(
        success: (_) async {
          final joinResult = await call.join();
          await joinResult.fold<Future<void>>(
            success: (_) async {},
            failure: (failure) async {
              _stopObservingCall();
              _updateCallLifecycleStage(CallLifecycleStage.idle);
              if (mounted) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to join call: ${failure.error.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
        },
        failure: (failure) async {
          _stopObservingCall();
          _updateCallLifecycleStage(CallLifecycleStage.idle);
          if (mounted) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start call: ${failure.error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );

    } catch (e) {
      _stopObservingCall();
      _updateCallLifecycleStage(CallLifecycleStage.idle);
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  void _setActiveCallAndNavigate(Call call, {bool markAsAccepted = false}) {
    _startObservingCall(call);
    if (markAsAccepted && _callLifecycleStage != CallLifecycleStage.accepted) {
      _updateCallLifecycleStage(
        CallLifecycleStage.accepted,
        detail: 'Joined call',
      );
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => CallScreen(call: call)));
  }

  void _startObservingCall(Call call) {
    _callEventsSubscription?.cancel();
    _callEventsSubscription = call.callEvents.listen(_handleCallEvent);

    _callStateSubscription?.cancel();
    _callStateSubscription = call.state.valueStream.listen(_handleCallState);

    _handleCallState(call.state.value);
  }

  void _stopObservingCall() {
    _callEventsSubscription?.cancel();
    _callEventsSubscription = null;
    _callStateSubscription?.cancel();
    _callStateSubscription = null;
  }

  void _handleCallEvent(StreamCallEvent event) {
    if (!mounted) return;

    if (event is StreamCallRingingEvent) {
      if (_callLifecycleStage != CallLifecycleStage.ringing) {
        _updateCallLifecycleStage(
          CallLifecycleStage.ringing,
          detail: _callLifecycleDetails,
        );
      }
    } else if (event is StreamCallAcceptedEvent) {
      final acceptedBy = displayNameFromCallUser(event.acceptedBy);
      _updateCallLifecycleStage(
        CallLifecycleStage.accepted,
        detail: 'Accepted by $acceptedBy',
        announce: true,
      );
    } else if (event is StreamCallRejectedEvent) {
      final rejectedBy = displayNameFromCallUser(event.rejectedBy);
      _updateCallLifecycleStage(
        CallLifecycleStage.rejected,
        detail: 'Rejected by $rejectedBy',
        announce: true,
      );
    } else if (event is StreamCallMissedEvent) {
      final missedBy = formatNameList(
        event.members
            .map((member) => displayNameFromUserId(member.userId))
            .toList(),
      );
      _updateCallLifecycleStage(
        CallLifecycleStage.missed,
        detail: missedBy.isNotEmpty ? 'Missed by $missedBy' : null,
        announce: true,
      );
    } else if (event is StreamCallEndedEvent) {
      final endedBy =
          event.endedBy != null
              ? displayNameFromCallUser(event.endedBy!)
              : 'System';
      final reasonText = (event.reason ?? event.type).toLowerCase();

      if (reasonText.contains('cancel')) {
        _updateCallLifecycleStage(
          CallLifecycleStage.cancelled,
          detail: 'Cancelled by $endedBy',
          announce: true,
        );
      } else if (!_callLifecycleStage.isTerminal) {
        _updateCallLifecycleStage(
          CallLifecycleStage.ended,
          detail: 'Ended by $endedBy',
          announce: true,
        );
      }
    }
  }

  void _handleCallState(CallState state) {
    final status = state.status;

    if (!_callLifecycleStage.isTerminal) {
      if ((status.isOutgoing || state.isRingingFlow) &&
          _callLifecycleStage != CallLifecycleStage.ringing) {
        _updateCallLifecycleStage(
          CallLifecycleStage.ringing,
          detail: _callLifecycleDetails,
        );
      }

      if ((status.isJoined || status.isConnected) &&
          _callLifecycleStage != CallLifecycleStage.accepted) {
        final connectedNames =
            state.callParticipants
                .where((participant) => !participant.isLocal)
                .map((participant) {
                  final trimmed = participant.name.trim();
                  if (trimmed.isNotEmpty) {
                    return trimmed;
                  }
                  return displayNameFromUserId(participant.userId);
                })
                .where((name) => name.isNotEmpty)
                .toList();

        final detail =
            connectedNames.isEmpty
                ? null
                : 'Connected with ${formatNameList(connectedNames)}';

        _updateCallLifecycleStage(CallLifecycleStage.accepted, detail: detail);
      }
    }

    if (status is CallStatusDisconnected && !_callLifecycleStage.isTerminal) {
      final reason = status.reason;
      if (reason is DisconnectReasonCancelled) {
        final by = displayNameFromUserId(reason.byUserId);
        _updateCallLifecycleStage(
          CallLifecycleStage.cancelled,
          detail: 'Cancelled by $by',
          announce: true,
        );
      } else if (reason is DisconnectReasonRejected) {
        final by = displayNameFromUserId(reason.byUserId);
        _updateCallLifecycleStage(
          CallLifecycleStage.rejected,
          detail: 'Rejected by $by',
          announce: true,
        );
      } else if (reason is DisconnectReasonTimeout) {
        _updateCallLifecycleStage(
          CallLifecycleStage.missed,
          detail: null,
          announce: true,
        );
      } else {
        _updateCallLifecycleStage(
          CallLifecycleStage.ended,
          detail: null,
          announce: true,
        );
      }
    }
  }

  void _updateCallLifecycleStage(
    CallLifecycleStage stage, {
    String? detail,
    bool announce = false,
  }) {
    final trimmedDetail =
        detail != null && detail.trim().isNotEmpty ? detail.trim() : null;
    final fallbackDetail = stage.defaultDetail;
    final nextDetail = trimmedDetail ?? fallbackDetail;

    if (_callLifecycleStage == stage && _callLifecycleDetails == nextDetail) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _callLifecycleStage = stage;
      _callLifecycleDetails = nextDetail;
    });

    if (stage.isTerminal) {
      _stopObservingCall();
    }

    if (announce) {
      final message =
          nextDetail != null ? '${stage.label}: $nextDetail' : stage.label;
      _showStatusSnackBar(message);
    }
  }

  void _showStatusSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatSelectedParticipantNames() {
    return formatNameList(_selectedUserIds.map(displayNameFromUserId).toList());
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.client.currentUser;
    final availableUsers =
        TutorialUser.users
            .where((user) => user.user.id != currentUser.id)
            .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Ringing Tutorial'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderSection(currentUser),
                    const SizedBox(height: 32),
                    _buildCallInfoSection(currentUser),
                    const SizedBox(height: 24),
                    _buildUserSelection(availableUsers),
                    const SizedBox(height: 24),
                    _buildCallTypeSelection(),
                    const SizedBox(height: 24),
                    _buildPermissionStatus(),
                    const SizedBox(height: 24),
                    _buildCallButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(UserInfo currentUser) {
    final name = currentUser.name.trim();
    final greetingName = name.isNotEmpty ? name : currentUser.id;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello $greetingName!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select users to ring and start a call',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCallInfoSection(UserInfo currentUser) {
    final name = currentUser.name.trim();
    final displayName = name.isNotEmpty ? name : 'No name';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Call Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('User ID:', currentUser.id),
          const SizedBox(height: 8),
          _buildInfoRow('User Name:', displayName),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Selected:',
            _selectedUserIds.isEmpty
                ? 'None selected'
                : '${_selectedUserIds.length} user(s)',
          ),
          const SizedBox(height: 16),
          _buildStatusRow(),
        ],
      ),
    );
  }

  Widget _buildUserSelection(List<TutorialUser> availableUsers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select who would you like to ring?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableUsers.map((user) {
                  final isSelected = _selectedUserIds.contains(user.user.id);
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedUserIds.remove(user.user.id);
                        } else {
                          _selectedUserIds.add(user.user.id);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected
                              ? Colors.blue.shade600
                              : Colors.grey.shade200,
                      foregroundColor:
                          isSelected ? Colors.white : Colors.grey.shade800,
                      elevation: isSelected ? 2 : 0,
                    ),
                    child: Text(user.user.name ?? user.user.id),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCallTypeSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Call Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isVideoCall = true;
                    });
                  },
                  icon: const Icon(Icons.videocam),
                  label: const Text('Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isVideoCall
                            ? Colors.blue.shade600
                            : Colors.grey.shade200,
                    foregroundColor:
                        _isVideoCall ? Colors.white : Colors.grey.shade800,
                    elevation: _isVideoCall ? 2 : 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isVideoCall = false;
                    });
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !_isVideoCall
                            ? Colors.blue.shade600
                            : Colors.grey.shade200,
                    foregroundColor:
                        !_isVideoCall ? Colors.white : Colors.grey.shade800,
                    elevation: !_isVideoCall ? 2 : 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _permissionsGranted ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _permissionsGranted
                  ? Colors.green.shade300
                  : Colors.orange.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _permissionsGranted ? Icons.check_circle : Icons.warning,
                color: _permissionsGranted ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _permissionsGranted
                      ? 'All permissions granted'
                      : 'Permissions required',
                  style: TextStyle(
                    color:
                        _permissionsGranted
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _permissionsGranted
                ? 'Camera and microphone access granted. Ready to start calls!'
                : 'Camera and microphone permissions are required for video calls.',
            style: TextStyle(
              color:
                  _permissionsGranted
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton() {
    if (_isJoining) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'Starting call...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed:
          _selectedUserIds.isEmpty
              ? null
              : (_permissionsGranted
                  ? _createRingingCall
                  : _requestPermissions),
      icon: Icon(_permissionsGranted ? Icons.call : Icons.security, size: 24),
      label: Text(
        _permissionsGranted ? 'RING' : 'Grant Permissions',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _permissionsGranted && _selectedUserIds.isNotEmpty
                ? Colors.blue.shade600
                : Colors.orange.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  Widget _buildStatusRow() {
    final detail = _callLifecycleDetails;
    final accent = _callLifecycleStage.accentColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            'Status:',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_callLifecycleStage.icon, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _callLifecycleStage.label,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (detail != null && detail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    detail,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    final tutorialUser = await AppInitializer.getStoredUser();
    if (tutorialUser == null) return;

    final streamVideo = StreamVideo(
      AppKeys.streamApiKey,
      user: tutorialUser.user,
      userToken: tutorialUser.token ?? '',
      options: const StreamVideoOptions(
        keepConnectionsAliveWhenInBackground: true,
      ),
      pushNotificationManagerProvider:
          StreamVideoPushNotificationManager.create(
            iosPushProvider: const StreamVideoPushProvider.apn(
              name: AppKeys.iosPushProviderName,
            ),
            androidPushProvider: const StreamVideoPushProvider.firebase(
              name: AppKeys.androidPushProviderName,
            ),
            pushParams: const StreamVideoPushParams(
              appName: 'Stream Video Call',
              ios: IOSParams(iconName: 'IconMask'),
            ),
            registerApnDeviceToken: true,
          ),
    )..connect();

    final declineSubscription = streamVideo.observeCallDeclinedCallKitEvent();
    streamVideo.disposeAfterResolvingRinging(
      disposingCallback: () => declineSubscription?.cancel(),
    );

    await StreamVideo.instance.handleRingingFlowNotifications(message.data);
  } catch (e, stk) {
    debugPrint('Error handling remote message: $e');
    debugPrint(stk.toString());
  }
}




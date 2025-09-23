import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'call_lifecycle.dart';
import 'call_display_utils.dart';

class CallScreen extends StatefulWidget {
  final Call call;
  const CallScreen({super.key, required this.call});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  CameraPosition _cameraPosition = CameraPosition.front;
  bool _isSwitchingCamera = false;
  bool _isRecordingActionInProgress = false;
  late CallState _callState;
  StreamSubscription<StreamCallEvent>? _callEventsSubscription;
  StreamSubscription<CallState>? _callStateSubscription;
  CallLifecycleStage _lifecycleStage = CallLifecycleStage.idle;
  String? _lifecycleDetail;

  @override
  void initState() {
    super.initState();
    _callState = widget.call.state.value;
    if (_callState.status.isJoined || _callState.status.isConnected) {
      _lifecycleStage = CallLifecycleStage.accepted;
      _lifecycleDetail = CallLifecycleStage.accepted.defaultDetail;
    } else if (_callState.status is CallStatusDisconnected) {
      _lifecycleStage = CallLifecycleStage.ended;
      _lifecycleDetail = CallLifecycleStage.ended.defaultDetail;
    } else {
      _lifecycleStage = CallLifecycleStage.ringing;
      _lifecycleDetail = CallLifecycleStage.ringing.defaultDetail;
    }
    _callEventsSubscription = widget.call.callEvents.listen(_handleCallEvent);
    _callStateSubscription = widget.call.state.valueStream.listen(
      _handleCallState,
    );
  }

  @override
  void dispose() {
    _callEventsSubscription?.cancel();
    _callStateSubscription?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _handleCallEvent(StreamCallEvent event) {
    if (!mounted) return;

    if (event is StreamCallRingingEvent) {
      if (_lifecycleStage != CallLifecycleStage.ringing) {
        _updateLifecycleStage(
          CallLifecycleStage.ringing,
          detail: _lifecycleDetail ?? CallLifecycleStage.ringing.defaultDetail,
        );
      }
    } else if (event is StreamCallAcceptedEvent) {
      final acceptedBy = displayNameFromCallUser(event.acceptedBy);
      _updateLifecycleStage(
        CallLifecycleStage.accepted,
        detail: 'Accepted by $acceptedBy',
        announce: true,
      );
    } else if (event is StreamCallRejectedEvent) {
      final rejectedBy = displayNameFromCallUser(event.rejectedBy);
      _updateLifecycleStage(
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
      _updateLifecycleStage(
        CallLifecycleStage.missed,
        detail:
            missedBy.isNotEmpty
                ? 'Missed by $missedBy'
                : CallLifecycleStage.missed.defaultDetail,
        announce: true,
      );
    } else if (event is StreamCallEndedEvent) {
      final endedBy =
          event.endedBy != null
              ? displayNameFromCallUser(event.endedBy!)
              : 'System';
      final reasonText = (event.reason ?? event.type).toLowerCase();
      if (reasonText.contains('cancel')) {
        _updateLifecycleStage(
          CallLifecycleStage.cancelled,
          detail: 'Cancelled by $endedBy',
          announce: true,
        );
      } else if (!_lifecycleStage.isTerminal) {
        _updateLifecycleStage(
          CallLifecycleStage.ended,
          detail: 'Ended by $endedBy',
          announce: true,
        );
      }
    }
  }

  void _handleCallState(CallState callState) {
    if (!mounted) return;

    final previousState = _callState;
    setState(() {
      _callState = callState;
    });

    final status = callState.status;

    if (!_lifecycleStage.isTerminal) {
      if ((status.isOutgoing || callState.isRingingFlow) &&
          _lifecycleStage != CallLifecycleStage.ringing) {
        _updateLifecycleStage(
          CallLifecycleStage.ringing,
          detail: _lifecycleDetail ?? CallLifecycleStage.ringing.defaultDetail,
        );
      }

      if ((status.isJoined || status.isConnected) &&
          _lifecycleStage != CallLifecycleStage.accepted) {
        final connectedNames =
            callState.callParticipants
                .where((participant) => !participant.isLocal)
                .map(_resolveParticipantName)
                .where((name) => name.isNotEmpty)
                .toList();

        final detail =
            connectedNames.isEmpty
                ? CallLifecycleStage.accepted.defaultDetail
                : 'Connected with ${formatNameList(connectedNames)}';

        _updateLifecycleStage(CallLifecycleStage.accepted, detail: detail);
      }
    }

    if (status is CallStatusDisconnected && !_lifecycleStage.isTerminal) {
      final reason = status.reason;
      if (reason is DisconnectReasonCancelled) {
        final by = displayNameFromUserId(reason.byUserId);
        _updateLifecycleStage(
          CallLifecycleStage.cancelled,
          detail: 'Cancelled by $by',
          announce: true,
        );
      } else if (reason is DisconnectReasonRejected) {
        final by = displayNameFromUserId(reason.byUserId);
        _updateLifecycleStage(
          CallLifecycleStage.rejected,
          detail: 'Rejected by $by',
          announce: true,
        );
      } else if (reason is DisconnectReasonTimeout) {
        _updateLifecycleStage(
          CallLifecycleStage.missed,
          detail: CallLifecycleStage.missed.defaultDetail,
          announce: true,
        );
      } else {
        _updateLifecycleStage(
          CallLifecycleStage.ended,
          detail: CallLifecycleStage.ended.defaultDetail,
          announce: true,
        );
      }
    }

    if (callState.isRecording != previousState.isRecording) {
      _announceStatusChange(
        callState.isRecording ? 'Recording started' : 'Recording stopped',
      );
    }

    if (callState.isBroadcasting != previousState.isBroadcasting) {
      _announceStatusChange(
        callState.isBroadcasting
            ? 'Broadcasting started'
            : 'Broadcasting stopped',
      );
    }

    if (callState.isBackstage != previousState.isBackstage) {
      _announceStatusChange(
        callState.isBackstage
            ? 'Backstage mode enabled'
            : 'Backstage mode disabled',
      );
    }

    if (callState.isTranscribing != previousState.isTranscribing) {
      _announceStatusChange(
        callState.isTranscribing
            ? 'Transcription started'
            : 'Transcription stopped',
      );
    }
  }

  void _updateLifecycleStage(
    CallLifecycleStage stage, {
    String? detail,
    bool announce = false,
  }) {
    final trimmed = detail?.trim();
    final nextDetail =
        (trimmed != null && trimmed.isNotEmpty) ? trimmed : stage.defaultDetail;

    if (!mounted) return;
    if (_lifecycleStage == stage && _lifecycleDetail == nextDetail) {
      return;
    }

    setState(() {
      _lifecycleStage = stage;
      _lifecycleDetail = nextDetail;
    });

    if (announce) {
      final message =
          nextDetail != null ? '${stage.label}: $nextDetail' : stage.label;
      _showSnackBar(message);
    }
  }

  void _announceStatusChange(String message) {
    if (!mounted) return;
    _showSnackBar(message);
    final textDirection = Directionality.of(context);
    SemanticsService.announce(message, textDirection);
  }

  List<Widget> _buildStatusBadges() {
    final badges = <Widget>[];

    if (_callState.isRecording) {
      badges.add(
        _buildStatusChip(
          icon: Icons.fiber_manual_record,
          label: 'Recording',
          color: Colors.redAccent,
        ),
      );
    }

    if (_callState.isBroadcasting) {
      badges.add(
        _buildStatusChip(
          icon: Icons.podcasts,
          label: 'Broadcasting',
          color: Colors.orangeAccent,
        ),
      );
    }

    if (_callState.isBackstage) {
      badges.add(
        _buildStatusChip(
          icon: Icons.group_work,
          label: 'Backstage',
          color: Colors.blueAccent,
        ),
      );
    }

    if (_callState.isTranscribing) {
      badges.add(
        _buildStatusChip(
          icon: Icons.subtitles,
          label: 'Transcribing',
          color: Colors.greenAccent,
        ),
      );
    }

    return badges;
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _resolveParticipantName(CallParticipantState participant) {
    final trimmed = participant.name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return displayNameFromUserId(participant.userId);
  }

  Future<void> _handleSwitchCamera() async {
    if (_isSwitchingCamera) return;
    if (mounted) setState(() => _isSwitchingCamera = true);

    try {
      final newPosition =
          _cameraPosition == CameraPosition.front
              ? CameraPosition.back
              : CameraPosition.front;
      await widget.call.setCameraPosition(newPosition);
      if (mounted) setState(() => _cameraPosition = newPosition);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to switch camera: $e')));
      }
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() => _isSwitchingCamera = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localParticipant = _callState.localParticipant;
    final isAudioEnabled = localParticipant?.isAudioEnabled ?? false;
    final isVideoEnabled = localParticipant?.isVideoEnabled ?? false;
    final isRecording = _callState.isRecording;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildParticipantsView(_callState.callParticipants),
            ),
            if (_isSwitchingCamera)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.1)),
                ),
              ),
            Positioned(top: 20, left: 20, right: 20, child: _buildTopBar()),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _buildCallControls(
                context,
                isAudioEnabled: isAudioEnabled,
                isVideoEnabled: isVideoEnabled,
                isRecording: isRecording,
                isRecordingBusy: _isRecordingActionInProgress,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final callState = _callState;
    final participantCount = callState.callParticipants.length;
    final participantLabel =
        '$participantCount participant${participantCount != 1 ? 's' : ''}';
    final accent = _lifecycleStage.accentColor;
    final detail = _lifecycleDetail ?? _lifecycleStage.defaultDetail;
    final statusBadges = _buildStatusBadges();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Meeting ID: ${widget.call.id.substring(0, 8)}...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  participantLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_lifecycleStage.icon, color: accent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _lifecycleStage.label,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (detail != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    detail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              if (statusBadges.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    children: statusBadges,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsView(List<CallParticipantState> participants) {
    if (participants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Waiting for participants to join...',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 100, bottom: 180, left: 8, right: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            participants.length == 1
                ? 1
                : participants.length <= 4
                ? 2
                : 3,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: participants.length,
      itemBuilder:
          (context, index) => _buildParticipantTile(participants[index]),
    );
  }

  Widget _buildParticipantTile(CallParticipantState participant) {
    final hasVideo = participant.isVideoEnabled;
    final resolvedName = _resolveParticipantName(participant);
    final initial =
        resolvedName.isNotEmpty
            ? resolvedName.substring(0, 1).toUpperCase()
            : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: participant.isLocal ? Colors.blue : Colors.transparent,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  hasVideo
                      ? StreamVideoRenderer(
                        call: widget.call,
                        participant: participant,
                        videoTrackType: SfuTrackType.video,
                      )
                      : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.blueGrey.shade800,
                              Colors.blueGrey.shade900,
                            ],
                          ),
                        ),
                        child: Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blueGrey.shade700,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        resolvedName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!participant.isAudioEnabled)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_off,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (participant.isLocal)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls(
    BuildContext context, {
    required bool isAudioEnabled,
    required bool isVideoEnabled,
    required bool isRecording,
    required bool isRecordingBusy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle Audio
          _buildControlButton(
            icon: isAudioEnabled ? Icons.mic : Icons.mic_off,
            color: isAudioEnabled ? Colors.white : Colors.red,
            backgroundColor:
                isAudioEnabled
                    ? Colors.black.withOpacity(0.6)
                    : Colors.red.withOpacity(0.8),
            onPressed: () {
              if (isAudioEnabled) {
                widget.call.setMicrophoneEnabled(enabled: false);
              } else {
                widget.call.setMicrophoneEnabled(enabled: true);
              }
            },
          ),

          // Toggle Video
          _buildControlButton(
            icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            color: isVideoEnabled ? Colors.white : Colors.red,
            backgroundColor:
                isVideoEnabled
                    ? Colors.black.withOpacity(0.6)
                    : Colors.red.withOpacity(0.8),
            onPressed: () {
              if (isVideoEnabled) {
                widget.call.setCameraEnabled(enabled: false);
              } else {
                widget.call.setCameraEnabled(enabled: true);
              }
            },
          ),

          // Switch Camera
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            color: Colors.white,
            backgroundColor: Colors.black.withOpacity(0.6),
            onPressed: _isSwitchingCamera ? null : _handleSwitchCamera,
          ),

          // Toggle Recording
          _buildControlButton(
            icon: Icons.fiber_manual_record,
            color: Colors.white,
            backgroundColor:
                isRecording
                    ? Colors.red.withOpacity(0.8)
                    : Colors.black.withOpacity(0.6),
            onPressed:
                isRecordingBusy
                    ? null
                    : () async {
                      setState(() {
                        _isRecordingActionInProgress = true;
                      });

                      try {
                        final result =
                            isRecording
                                ? await widget.call.stopRecording()
                                : await widget.call.startRecording();

                        result.fold(
                          success: (_) {},
                          failure: (failure) {
                            final errorMessage =
                                failure.error.message ?? 'Unknown error';
                            _showSnackBar(
                              'Failed to ${isRecording ? 'stop' : 'start'} recording: $errorMessage',
                            );
                          },
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isRecordingActionInProgress = false;
                          });
                        }
                      }
                    },
          ),

          // End Call
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.white,
            backgroundColor: Colors.red,
            onPressed: () async {
              await widget.call.leave();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

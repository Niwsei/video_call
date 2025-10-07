import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

enum CallUiRole { caller, callee }

class CallScreen extends StatelessWidget {
  const CallScreen({super.key, required this.call, required this.role});

  final Call call;
  final CallUiRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          StreamCallContainer(
            call: call,
            onCallDisconnected: (_) => Navigator.of(context).maybePop(),
            incomingCallWidgetBuilder: (context, _) => const SizedBox.shrink(),
            outgoingCallWidgetBuilder: (context, _) => const SizedBox.shrink(),
            callContentWidgetBuilder:
                (context, activeCall) => StreamCallContent(
                  call: activeCall,
                  extendBody: true,
                  callAppBarWidgetBuilder: (_, __) => null,
                  callControlsWidgetBuilder: (_, __) => const SizedBox.shrink(),
                ),
          ),
          _CallOverlay(call: call, role: role),
        ],
      ),
    );
  }
}

enum _CallUiStage { outgoing, incoming, connecting, active, ended }

class _CallOverlay extends StatefulWidget {
  const _CallOverlay({required this.call, required this.role});

  final Call call;
  final CallUiRole role;

  @override
  State<_CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<_CallOverlay> {
  Timer? _ticker;
  StreamSubscription<CallState>? _stateSub;
  DateTime? _connectedAt;
  Duration? _durationSnapshot;

  CallState? _latestState;
  _CallUiStage _stage = _CallUiStage.outgoing;
  List<_ParticipantDisplay> _participants = const <_ParticipantDisplay>[];
  _CallEndVisual? _endedVisual;
  DateTime? _lastStatusChangeAt;

  bool _isEndInFlight = false;
  bool _isAcceptInFlight = false;
  bool _isRejectInFlight = false;

  @override
  void initState() {
    super.initState();
    _attachStateListener(widget.call);
  }

  @override
  void didUpdateWidget(covariant _CallOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call != widget.call) {
      _detachStateListener();
      _connectedAt = null;
      _durationSnapshot = null;
      _attachStateListener(widget.call);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  void _attachStateListener(Call call) {
    _stateSub = call.state.valueStream.listen(_applyState);
    _applyState(call.state.value);
  }

  void _detachStateListener() {
    _stateSub?.cancel();
    _stateSub = null;
    _stopTicker();
    _latestState = null;
  }

  void _applyState(CallState state) {
    final status = state.status;
    final isActive =
        status is CallStatusConnected || status is CallStatusJoined;

    if (_lastStatusChangeAt != null) {
      debugPrint(
        '[CallScreen] status ${status.runtimeType} after '
        '${DateTime.now().difference(_lastStatusChangeAt!).inMilliseconds} ms',
      );
    }
    _lastStatusChangeAt = DateTime.now();

    if (isActive) {
      _connectedAt ??= state.startedAt ?? DateTime.now();
      _durationSnapshot = null;
      _startTicker();
    } else if (status is CallStatusDisconnected) {
      final start = _connectedAt ?? state.startedAt;
      final end = state.endedAt ?? DateTime.now();
      if (start != null && !end.isBefore(start)) {
        _durationSnapshot = end.difference(start);
      }
      _stopTicker();
    } else {
      if (status is CallStatusIdle) {
        _connectedAt = null;
        _durationSnapshot = null;
      }
      _stopTicker();
    }

    final stage = _resolveStage(state);
    final participants = _resolveParticipants(state);
    final endedDetails =
        stage == _CallUiStage.ended ? _resolveEndedDetails(state) : null;

    if (!mounted) {
      _latestState = state;
      _stage = stage;
      _participants = participants;
      _endedVisual = endedDetails;
      return;
    }

    setState(() {
      _latestState = state;
      _stage = stage;
      _participants = participants;
      _endedVisual = endedDetails;
    });
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Duration? _currentDuration(CallState state) {
    if (_durationSnapshot != null) {
      return _durationSnapshot;
    }
    final start = _connectedAt ?? state.startedAt;
    if (start == null) return null;
    return DateTime.now().difference(start);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null || duration.isNegative) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      final hrs = hours.toString().padLeft(2, '0');
      return '$hrs:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = _latestState;
    if (state == null) {
      return const SizedBox.shrink();
    }

    final duration = _currentDuration(state);

    final children = <Widget>[
      Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: _buildBackground(stage: _stage, endedDetails: _endedVisual),
        ),
      ),
    ];

    final status = _buildStageContent(context, state, duration);
    if (status != null) {
      children.add(status);
    }

    final controls = _buildBottomControls(context, state);
    if (controls != null) {
      children.add(controls);
    }

    return Stack(fit: StackFit.expand, children: children);
  }

  _CallUiStage _resolveStage(CallState state) {
    final status = state.status;
    if (status is CallStatusDisconnected) return _CallUiStage.ended;
    if (status is CallStatusConnected || status is CallStatusJoined) {
      return _CallUiStage.active;
    }
    if (status is CallStatusOutgoing) {
      return status.acceptedByCallee
          ? _CallUiStage.connecting
          : _CallUiStage.outgoing;
    }
    if (status is CallStatusIncoming) {
      return status.acceptedByMe
          ? _CallUiStage.connecting
          : _CallUiStage.incoming;
    }
    if (status is CallStatusConnecting ||
        status is CallStatusJoining ||
        status is CallStatusMigrating ||
        status is CallStatusReconnecting) {
      return _CallUiStage.connecting;
    }
    if (status is CallStatusReconnectionFailed) {
      return _CallUiStage.ended;
    }
    if (state.isRingingFlow) {
      return widget.role == CallUiRole.caller
          ? _CallUiStage.outgoing
          : _CallUiStage.incoming;
    }
    return widget.role == CallUiRole.caller
        ? _CallUiStage.outgoing
        : _CallUiStage.incoming;
  }

  Widget _buildBackground({
    required _CallUiStage stage,
    _CallEndVisual? endedDetails,
  }) {
    final colors = switch (stage) {
      _CallUiStage.outgoing => [
        const Color(0xFF075E54).withValues(alpha: 0.92),
        const Color(0xFF128C7E).withValues(alpha: 0.88),
      ],
      _CallUiStage.incoming => [
        const Color(0xFF0B141A).withValues(alpha: 0.94),
        const Color(0xFF075E54).withValues(alpha: 0.86),
      ],
      _CallUiStage.connecting => [
        const Color(0xFF0A2640).withValues(alpha: 0.94),
        const Color(0xFF144E73).withValues(alpha: 0.88),
      ],
      _CallUiStage.active => [
        Colors.black.withValues(alpha: 0.55),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.55),
      ],
      _CallUiStage.ended =>
        _endedVisual?.backgroundGradient ??
            <Color>[
              (_endedVisual?.accentColor ?? Colors.redAccent).withValues(
                alpha: 0.22,
              ),
              Colors.black.withValues(alpha: 0.9),
            ],
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    );
  }

  Widget? _buildStageContent(
    BuildContext context,
    CallState state,
    Duration? duration,
  ) {
    return switch (_stage) {
      _CallUiStage.outgoing => _CenteredStatus(
        participants: _participants,
        headline: 'กำลังโทร…',
        subtitle:
            (state.status is CallStatusOutgoing &&
                    (state.status as CallStatusOutgoing).acceptedByCallee)
                ? 'ปลายทางกำลังกดรับ'
                : 'รอสายตอบรับ',
        showProgress: true,
      ),
      _CallUiStage.incoming => _CenteredStatus(
        participants: _participants,
        headline: 'สายเรียกเข้า',
        subtitle:
            widget.role == CallUiRole.callee
                ? 'แตะปุ่มสีเขียวเพื่อรับสาย'
                : 'รอให้ปลายทางตอบรับ',
        accent: Colors.greenAccent,
        showProgress: false,
      ),
      _CallUiStage.connecting => _CenteredStatus(
        participants: _participants,
        headline: 'กำลังเชื่อมต่อ…',
        subtitle: 'โปรดรอสักครู่',
        showProgress: true,
      ),
      _CallUiStage.active => _ActiveHeader(
        displayName: _formatDisplayName(_participants),
        durationLabel: _formatDuration(duration),
      ),
      _CallUiStage.ended => _EndedStatus(
        participants: _participants,
        visual:
            _endedVisual ??
            _CallEndVisual(
              title: 'สายถูกตัด',
              accentColor: Colors.redAccent,
              icon: Icons.call_end_rounded,
            ),
        durationLabel:
            duration != null && duration.inSeconds > 0
                ? _formatDuration(duration)
                : null,
      ),
    };
  }

  Widget? _buildBottomControls(BuildContext context, CallState state) {
    switch (_stage) {
      case _CallUiStage.outgoing:
        return _HangUpButton(
          label: 'ยกเลิก',
          isBusy: _isEndInFlight,
          onPressed: () => _handleHangUp(cancelForEveryone: true),
        );
      case _CallUiStage.connecting:
        return _HangUpButton(
          label: 'ยุติ',
          isBusy: _isEndInFlight,
          onPressed: () => _handleHangUp(cancelForEveryone: true),
        );
      case _CallUiStage.incoming:
        if (widget.role != CallUiRole.callee) {
          return _HangUpButton(
            label: 'ยกเลิก',
            isBusy: _isEndInFlight,
            onPressed: () => _handleHangUp(cancelForEveryone: true),
          );
        }
        return _IncomingControls(
          isAccepting: _isAcceptInFlight,
          isRejecting: _isRejectInFlight,
          onAccept: _handleAccept,
          onReject: _handleReject,
        );
      case _CallUiStage.active:
        return _ActiveControlsBar(
          call: widget.call,
          onHangUp: () => _handleHangUp(cancelForEveryone: false),
          isHangUpBusy: _isEndInFlight,
        );
      case _CallUiStage.ended:
        final showRecord = _endedVisual?.canRecordMessage ?? false;
        return _EndedControls(
          showRecordMessage: showRecord,
          onClose: () => Navigator.of(context).maybePop(),
          onRecordMessage: showRecord ? _handleRecordMessage : null,
        );
    }
  }

  Future<void> _handleHangUp({required bool cancelForEveryone}) async {
    if (_isEndInFlight) return;
    setState(() => _isEndInFlight = true);
    try {
      final result =
          cancelForEveryone
              ? await widget.call.end()
              : await widget.call.leave();
      result.whenOrNull(
        failure: (error) {
          _showSnackBar('ไม่สามารถตัดสายได้: ${error.message}');
          return null;
        },
      );
    } catch (error) {
      _showSnackBar('เกิดข้อผิดพลาดในการตัดสาย');
    } finally {
      if (mounted) {
        setState(() => _isEndInFlight = false);
      }
    }
  }

  Future<void> _handleAccept() async {
    if (_isAcceptInFlight) return;
    setState(() {
      _isAcceptInFlight = true;
      _isRejectInFlight = false;
    });
    try {
      final result = await widget.call.accept();
      result.whenOrNull(
        failure: (error) {
          _showSnackBar('รับสายไม่สำเร็จ: ${error.message}');
          return null;
        },
      );
    } catch (error) {
      _showSnackBar('เกิดข้อผิดพลาดในการรับสาย');
    } finally {
      if (mounted) {
        setState(() => _isAcceptInFlight = false);
      }
    }
  }

  Future<void> _handleReject() async {
    if (_isRejectInFlight) return;
    setState(() {
      _isRejectInFlight = true;
      _isAcceptInFlight = false;
    });
    try {
      final result = await widget.call.reject();
      result.whenOrNull(
        failure: (error) {
          _showSnackBar('ปฏิเสธสายไม่สำเร็จ: ${error.message}');
          return null;
        },
      );
    } catch (error) {
      _showSnackBar('เกิดข้อผิดพลาดในการปฏิเสธสาย');
    } finally {
      if (mounted) {
        setState(() => _isRejectInFlight = false);
      }
    }
  }

  void _handleRecordMessage() {
    _showSnackBar('ฟีเจอร์บันทึกข้อความยังไม่พร้อมใช้งาน');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_ParticipantDisplay> _resolveParticipants(CallState state) {
    final others =
        state.callMembers
            .where((member) => member.userId != state.currentUserId)
            .map((member) {
              final name = member.name.trim();
              final displayName = name.isNotEmpty ? name : member.userId;

              final image = member.image?.trim();
              final imageUrl = (image?.isNotEmpty ?? false) ? image : null;

              return _ParticipantDisplay(
                userId: member.userId,
                displayName: displayName,
                imageUrl: imageUrl,
              );
            })
            .toList();
    if (others.isNotEmpty) {
      return others;
    }
    final created = state.createdByUser;
    return [
      _ParticipantDisplay(
        userId: created.id,
        displayName: created.name.isNotEmpty ? created.name : created.id,
        imageUrl: created.image.isNotEmpty ? created.image : null,
      ),
    ];
  }

  String _formatDisplayName(List<_ParticipantDisplay> participants) {
    if (participants.isEmpty) return 'ผู้ติดต่อ';
    if (participants.length == 1) {
      return participants.first.displayName;
    }
    final names = participants.map((p) => p.displayName).toList();
    if (names.length == 2) {
      return '${names[0]}, ${names[1]}';
    }
    final others = names.length - 2;
    return '${names.take(2).join(', ')} +$others';
  }

  _CallEndVisual _resolveEndedDetails(CallState state) {
    final status = state.status;
    if (status is CallStatusReconnectionFailed) {
      return const _CallEndVisual(
        title: 'การเชื่อมต่อขาดหาย',
        subtitle: 'ไม่สามารถเชื่อมต่อซ้ำได้',
        accentColor: Colors.redAccent,
        icon: Icons.signal_wifi_off_rounded,
      );
    }
    if (status is! CallStatusDisconnected) {
      return _CallEndVisual(
        title: 'สายถูกตัด',
        accentColor: Colors.redAccent,
        icon: Icons.call_end_rounded,
      );
    }

    final reason = status.reason;
    final me = state.currentUserId;

    if (reason is DisconnectReasonTimeout) {
      final isCaller = widget.role == CallUiRole.caller;
      if (isCaller) {
        return const _CallEndVisual(
          title: 'ไม่รับสาย',
          accentColor: Colors.white,
          icon: Icons.call_missed_outgoing_rounded,
          backgroundGradient: [Color(0xFFE5478C), Color(0xFFC43A78)],
          canRecordMessage: true,
          showIcon: false,
        );
      }
      return const _CallEndVisual(
        title: 'สายพลาด',
        subtitle: 'คุณไม่ได้รับสายทันเวลา',
        accentColor: Colors.orangeAccent,
        icon: Icons.call_missed_rounded,
      );
    }

    if (reason is DisconnectReasonRejected) {
      final rejectedByMe = reason.byUserId == me;
      return _CallEndVisual(
        title: rejectedByMe ? 'คุณปฏิเสธสาย' : 'สายถูกปฏิเสธ',
        subtitle: rejectedByMe ? 'สายถูกปฏิเสธโดยคุณ' : 'ผู้ใช้ปฏิเสธสาย',
        accentColor: Colors.redAccent,
        icon: Icons.call_end_rounded,
      );
    }

    if (reason is DisconnectReasonCancelled) {
      final cancelledByMe = reason.byUserId == me;
      return _CallEndVisual(
        title: cancelledByMe ? 'คุณยกเลิกสาย' : 'สายถูกยกเลิก',
        subtitle:
            cancelledByMe
                ? 'คุณยุติสายก่อนมีการรับสาย'
                : 'ปลายทางยุติสายก่อนรับ',
        accentColor: Colors.deepOrangeAccent,
        icon: Icons.call_end_rounded,
      );
    }

    if (reason is DisconnectReasonBlocked) {
      return const _CallEndVisual(
        title: 'ไม่สามารถติดต่อได้',
        subtitle: 'ปลายทางบล็อกการติดต่อ',
        accentColor: Colors.redAccent,
        icon: Icons.block_rounded,
      );
    }

    if (reason is DisconnectReasonFailure ||
        reason is DisconnectReasonSfuError) {
      return const _CallEndVisual(
        title: 'การเชื่อมต่อล้มเหลว',
        subtitle: 'ลองใหม่อีกครั้งภายหลัง',
        accentColor: Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
    }

    if (reason is DisconnectReasonReconnectionFailed) {
      return const _CallEndVisual(
        title: 'การเชื่อมต่อขาดหาย',
        subtitle: 'ไม่สามารถเชื่อมต่อซ้ำได้',
        accentColor: Colors.redAccent,
        icon: Icons.signal_wifi_off_rounded,
      );
    }

    if (reason is DisconnectReasonReplaced) {
      return const _CallEndVisual(
        title: 'เชื่อมต่อจากอุปกรณ์อื่น',
        subtitle: 'สายนี้ถูกย้ายไปยังอุปกรณ์อื่น',
        accentColor: Colors.blueAccent,
        icon: Icons.phone_forwarded_rounded,
      );
    }

    return const _CallEndVisual(
      title: 'สายสิ้นสุด',
      subtitle: 'การสนทนาสิ้นสุดเรียบร้อย',
      accentColor: Colors.greenAccent,
      icon: Icons.call_rounded,
    );
  }
}

class _ParticipantDisplay {
  const _ParticipantDisplay({
    required this.userId,
    required this.displayName,
    this.imageUrl,
  });

  final String userId;
  final String displayName;
  final String? imageUrl;

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return userId.isNotEmpty ? userId[0].toUpperCase() : '?';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part.isEmpty) continue;
      buffer.write(part[0].toUpperCase());
      if (buffer.length >= 2) break;
    }
    final result = buffer.toString();
    return result.isEmpty ? trimmed[0].toUpperCase() : result;
  }
}

class _CenteredStatus extends StatelessWidget {
  const _CenteredStatus({
    required this.participants,
    required this.headline,
    this.subtitle,
    this.accent,
    this.showProgress = false,
  });

  final List<_ParticipantDisplay> participants;
  final String headline;
  final String? subtitle;
  final Color? accent;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    late final String name;
    if (participants.isEmpty) {
      name = 'ผู้ติดต่อ';
    } else if (participants.length == 1) {
      name = participants.first.displayName;
    } else {
      name =
          '${participants.first.displayName} และอีก ${participants.length - 1}';
    }

    return Positioned.fill(
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            _AvatarCluster(participants: participants),
            const SizedBox(height: 24),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              headline,
              style: TextStyle(
                color: accent ?? Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
            if (showProgress) ...[
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ] else
              const SizedBox(height: 32),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ActiveHeader extends StatelessWidget {
  const _ActiveHeader({required this.displayName, required this.durationLabel});

  final String displayName;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  durationLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EndedStatus extends StatelessWidget {
  const _EndedStatus({
    required this.participants,
    required this.visual,
    this.durationLabel,
  });

  final List<_ParticipantDisplay> participants;
  final _CallEndVisual visual;
  final String? durationLabel;

  @override
  Widget build(BuildContext context) {
    final name =
        participants.isEmpty ? 'ผู้ติดต่อ' : participants.first.displayName;

    return Positioned.fill(
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            _AvatarCluster(participants: participants, radius: 52),
            const SizedBox(height: 24),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (visual.showIcon) ...[
                  Icon(visual.icon, color: visual.accentColor, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(
                  visual.title,
                  style: TextStyle(
                    color: visual.accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (visual.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                visual.subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
            if (durationLabel != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ระยะเวลา ${durationLabel!}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _HangUpButton extends StatelessWidget {
  const _HangUpButton({
    required this.onPressed,
    required this.label,
    required this.isBusy,
  });

  final VoidCallback onPressed;
  final String label;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isBusy ? null : onPressed,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child:
                        isBusy
                            ? const Padding(
                              padding: EdgeInsets.all(18),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingControls extends StatelessWidget {
  const _IncomingControls({
    required this.isAccepting,
    required this.isRejecting,
    required this.onAccept,
    required this.onReject,
  });

  final bool isAccepting;
  final bool isRejecting;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 48, right: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IncomingAction(
                color: Colors.redAccent,
                icon: Icons.call_end_rounded,
                label: 'ปฏิเสธ',
                isBusy: isRejecting,
                onTap: isRejecting ? null : onReject,
              ),
              _IncomingAction(
                color: Colors.greenAccent,
                icon: Icons.call_rounded,
                label: 'รับสาย',
                isBusy: isAccepting,
                onTap: isAccepting ? null : onAccept,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingAction extends StatelessWidget {
  const _IncomingAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.isBusy,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final bool isBusy;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap:
              onTap == null
                  ? null
                  : () {
                    onTap!.call();
                  },
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child:
                isBusy
                    ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _ActiveControlsBar extends StatelessWidget {
  const _ActiveControlsBar({
    required this.call,
    required this.onHangUp,
    required this.isHangUpBusy,
  });

  final Call call;
  final VoidCallback onHangUp;
  final bool isHangUpBusy;

  @override
  Widget build(BuildContext context) {
    final theme = StreamCallControlsTheme.of(context);
    final controlsTheme = theme.copyWith(
      optionBackgroundColor: Colors.white.withValues(alpha: 0.08),
      inactiveOptionBackgroundColor: Colors.white.withValues(alpha: 0.12),
      optionIconColor: Colors.white,
      inactiveOptionIconColor: Colors.white70,
      optionPadding: const EdgeInsets.all(18),
    );

    final controls = <Widget>[
      ToggleMicrophoneOption(call: call),
      ToggleCameraOption(call: call),
      if (CurrentPlatform.isAndroid || CurrentPlatform.isIos)
        ToggleSpeakerphoneOption(call: call),
      FlipCameraOption(call: call),
      CallControlOption(
        icon: const Icon(Icons.call_end_rounded),
        backgroundColor: Colors.redAccent,
        iconColor: Colors.white,
        onPressed: isHangUpBusy ? null : onHangUp,
      ),
    ];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: StreamCallControlsTheme(
            data: controlsTheme,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: controls,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EndedControls extends StatelessWidget {
  const _EndedControls({
    required this.onClose,
    required this.showRecordMessage,
    this.onRecordMessage,
  });

  final VoidCallback onClose;
  final bool showRecordMessage;
  final VoidCallback? onRecordMessage;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _EndedActionButton(
        icon: Icons.close_rounded,
        label: 'ปิด',
        onTap: onClose,
      ),
    ];

    if (showRecordMessage) {
      items.add(
        _EndedActionButton(
          icon: Icons.videocam_rounded,
          label: 'บันทึกข้อความ',
          onTap: onRecordMessage,
        ),
      );
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i != items.length - 1) const SizedBox(width: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EndedActionButton extends StatelessWidget {
  const _EndedActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _AvatarCluster extends StatelessWidget {
  const _AvatarCluster({required this.participants, this.radius = 48});

  final List<_ParticipantDisplay> participants;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return _AvatarCircle(initials: '?', radius: radius);
    }
    if (participants.length == 1) {
      return _AvatarCircle(
        radius: radius,
        initials: participants.first.initials,
        imageUrl: participants.first.imageUrl,
      );
    }

    final first = participants[0];
    final second = participants[1];

    return SizedBox(
      width: radius * 2 + 16,
      height: radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: radius * 0.15,
            child: _AvatarCircle(
              radius: radius,
              initials: first.initials,
              imageUrl: first.imageUrl,
            ),
          ),
          Positioned(
            right: radius * 0.15,
            child: _AvatarCircle(
              radius: radius,
              initials: second.initials,
              imageUrl: second.imageUrl,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.radius,
    required this.initials,
    this.imageUrl,
  });

  final double radius;
  final String initials;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child:
          hasImage
              ? null
              : Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
    );
  }
}

class _CallEndVisual {
  const _CallEndVisual({
    required this.title,
    this.subtitle,
    required this.accentColor,
    required this.icon,
    this.backgroundGradient,
    this.canRecordMessage = false,
    this.showIcon = true,
  });

  final String title;
  final String? subtitle;
  final Color accentColor;
  final IconData icon;
  final List<Color>? backgroundGradient;
  final bool canRecordMessage;
  final bool showIcon;
}

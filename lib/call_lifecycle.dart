import 'package:flutter/material.dart';

enum CallLifecycleStage {
  idle,
  ringing,
  accepted,
  missed,
  rejected,
  cancelled,
  ended,
}

extension CallLifecycleStageX on CallLifecycleStage {
  String get label {
    switch (this) {
      case CallLifecycleStage.idle:
        return 'Idle';
      case CallLifecycleStage.ringing:
        return 'Ringing';
      case CallLifecycleStage.accepted:
        return 'Accepted';
      case CallLifecycleStage.missed:
        return 'Missed';
      case CallLifecycleStage.rejected:
        return 'Rejected';
      case CallLifecycleStage.cancelled:
        return 'Cancelled';
      case CallLifecycleStage.ended:
        return 'Ended';
    }
  }

  Color get accentColor {
    switch (this) {
      case CallLifecycleStage.idle:
        return Colors.grey.shade500;
      case CallLifecycleStage.ringing:
        return Colors.orange.shade600;
      case CallLifecycleStage.accepted:
        return Colors.green.shade600;
      case CallLifecycleStage.missed:
        return Colors.red.shade500;
      case CallLifecycleStage.rejected:
        return Colors.red.shade700;
      case CallLifecycleStage.cancelled:
        return Colors.blueGrey.shade600;
      case CallLifecycleStage.ended:
        return Colors.blue.shade600;
    }
  }

  String? get defaultDetail {
    switch (this) {
      case CallLifecycleStage.idle:
        return 'Ready for new calls';
      case CallLifecycleStage.ringing:
        return 'Waiting for participants to answer';
      case CallLifecycleStage.accepted:
        return 'Call connected';
      case CallLifecycleStage.missed:
        return 'No one answered';
      case CallLifecycleStage.rejected:
        return 'Call was rejected';
      case CallLifecycleStage.cancelled:
        return 'Call was cancelled';
      case CallLifecycleStage.ended:
        return 'Call ended';
    }
  }

  IconData get icon {
    switch (this) {
      case CallLifecycleStage.idle:
        return Icons.pause_circle_filled;
      case CallLifecycleStage.ringing:
        return Icons.notifications_active;
      case CallLifecycleStage.accepted:
        return Icons.call_made;
      case CallLifecycleStage.missed:
        return Icons.call_missed;
      case CallLifecycleStage.rejected:
        return Icons.call_end;
      case CallLifecycleStage.cancelled:
        return Icons.cancel_schedule_send;
      case CallLifecycleStage.ended:
        return Icons.call_received;
    }
  }

  bool get isTerminal {
    switch (this) {
      case CallLifecycleStage.missed:
      case CallLifecycleStage.rejected:
      case CallLifecycleStage.cancelled:
      case CallLifecycleStage.ended:
        return true;
      case CallLifecycleStage.idle:
      case CallLifecycleStage.ringing:
      case CallLifecycleStage.accepted:
        return false;
    }
  }
}

import 'package:flutter/material.dart';

enum DeliveryStage {
  requested,
  driverEnRoute,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
}

const List<DeliveryStage> kDeliveryProgression = <DeliveryStage>[
  DeliveryStage.requested,
  DeliveryStage.driverEnRoute,
  DeliveryStage.pickedUp,
  DeliveryStage.inTransit,
  DeliveryStage.delivered,
];

extension DeliveryStageText on DeliveryStage {
  String get label {
    switch (this) {
      case DeliveryStage.requested:
        return 'รอรับงาน';
      case DeliveryStage.driverEnRoute:
        return 'ไรเดอร์กำลังไป';
      case DeliveryStage.pickedUp:
        return 'รับพัสดุแล้ว';
      case DeliveryStage.inTransit:
        return 'กำลังจัดส่ง';
      case DeliveryStage.delivered:
        return 'ส่งสำเร็จ';
      case DeliveryStage.cancelled:
        return 'ถูกยกเลิก';
    }
  }

  String get description {
    switch (this) {
      case DeliveryStage.requested:
        return 'ออเดอร์ถูกสร้างและรอไรเดอร์รับงาน';
      case DeliveryStage.driverEnRoute:
        return 'ไรเดอร์กำลังมุ่งหน้าไปจุดรับของ';
      case DeliveryStage.pickedUp:
        return 'ไรเดอร์รับพัสดุเรียบร้อยแล้ว';
      case DeliveryStage.inTransit:
        return 'พัสดุกำลังเดินทางไปยังผู้รับ';
      case DeliveryStage.delivered:
        return 'พัสดุถูกส่งถึงมือผู้รับ';
      case DeliveryStage.cancelled:
        return 'งานนี้ถูกยกเลิก';
    }
  }

  Color get accentColor {
    switch (this) {
      case DeliveryStage.requested:
        return const Color(0xFF9AA5B1);
      case DeliveryStage.driverEnRoute:
        return const Color(0xFF448AFF);
      case DeliveryStage.pickedUp:
        return const Color(0xFF26A69A);
      case DeliveryStage.inTransit:
        return const Color(0xFF00BFA5);
      case DeliveryStage.delivered:
        return const Color(0xFF4CAF50);
      case DeliveryStage.cancelled:
        return const Color(0xFFE53935);
    }
  }

  IconData get icon {
    switch (this) {
      case DeliveryStage.requested:
        return Icons.receipt_long_rounded;
      case DeliveryStage.driverEnRoute:
        return Icons.directions_bike_rounded;
      case DeliveryStage.pickedUp:
        return Icons.inventory_2_rounded;
      case DeliveryStage.inTransit:
        return Icons.local_shipping_rounded;
      case DeliveryStage.delivered:
        return Icons.verified_rounded;
      case DeliveryStage.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String get driverButtonLabel {
    switch (this) {
      case DeliveryStage.requested:
        return 'รับงาน';
      case DeliveryStage.driverEnRoute:
        return 'ถึงจุดรับแล้ว';
      case DeliveryStage.pickedUp:
        return 'เริ่มจัดส่ง';
      case DeliveryStage.inTransit:
        return 'ส่งสำเร็จ';
      case DeliveryStage.delivered:
        return 'งานเสร็จสิ้น';
      case DeliveryStage.cancelled:
        return 'งานถูกยกเลิก';
    }
  }
}

class DeliveryTimelineEntry {
  DeliveryTimelineEntry({
    required this.stage,
    required this.timestamp,
    this.manual = true,
  });

  final DeliveryStage stage;
  final DateTime timestamp;
  final bool manual;
}

class DeliveryOrder {
  DeliveryOrder({
    required this.code,
    required this.packageSummary,
    required this.pickupAddress,
    required this.dropOffAddress,
    required this.customerId,
    required this.driverId,
    required this.scheduledAt,
    required this.eta,
    DeliveryStage stage = DeliveryStage.requested,
  }) : _stage = stage,
       lastUpdated = DateTime.now() {
    timeline.add(
      DeliveryTimelineEntry(
        stage: _stage,
        timestamp: lastUpdated,
        manual: false,
      ),
    );
  }

  final String code;
  final String packageSummary;
  final String pickupAddress;
  final String dropOffAddress;
  final String customerId;
  final String driverId;
  final DateTime scheduledAt;
  final Duration eta;
  final List<DeliveryTimelineEntry> timeline = <DeliveryTimelineEntry>[];
  DateTime lastUpdated;

  DeliveryStage _stage;

  DeliveryStage get stage => _stage;

  DeliveryStage? get nextStage {
    if (_stage == DeliveryStage.cancelled) return null;
    final index = kDeliveryProgression.indexOf(_stage);
    if (index == -1) return null;
    final nextIndex = index + 1;
    if (nextIndex >= kDeliveryProgression.length) return null;
    return kDeliveryProgression[nextIndex];
  }

  bool advance([DeliveryStage? target]) {
    final DeliveryStage? destination = target ?? nextStage;
    if (destination == null) return false;
    if (destination == _stage) return false;
    if (_stage == DeliveryStage.cancelled) return false;

    final currentIndex = kDeliveryProgression.indexOf(_stage);
    final targetIndex = kDeliveryProgression.indexOf(destination);
    if (targetIndex != -1 &&
        currentIndex != -1 &&
        targetIndex <= currentIndex) {
      return false;
    }

    _stage = destination;
    lastUpdated = DateTime.now();
    timeline.add(
      DeliveryTimelineEntry(
        stage: _stage,
        timestamp: lastUpdated,
        manual: target != null,
      ),
    );
    return true;
  }

  bool cancel() {
    if (_stage == DeliveryStage.cancelled ||
        _stage == DeliveryStage.delivered) {
      return false;
    }
    _stage = DeliveryStage.cancelled;
    lastUpdated = DateTime.now();
    timeline.add(DeliveryTimelineEntry(stage: _stage, timestamp: lastUpdated));
    return true;
  }

  DateTime? timestampFor(DeliveryStage stage) {
    for (final entry in timeline.reversed) {
      if (entry.stage == stage) {
        return entry.timestamp;
      }
    }
    return null;
  }

  bool get isCompleted =>
      _stage == DeliveryStage.delivered || _stage == DeliveryStage.cancelled;

  Duration get remainingEta {
    if (_stage == DeliveryStage.delivered) {
      return Duration.zero;
    }
    final elapsed = DateTime.now().difference(scheduledAt);
    final remaining = eta - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.status,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.items = const [],
    this.controlledDrug = false,
    this.coldChain = false,
    this.distance,
    this.estimatedTime,
    this.deliveryTimeMinutes,
    this.notes,
    this.createdAt,
    this.assignedAt,
    this.deliveredAt,
  });

  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final String dropoffAddress;
  final String status;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final List<String> items;
  final bool controlledDrug;
  final bool coldChain;
  final String? distance;
  final String? estimatedTime;
  final int? deliveryTimeMinutes;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? deliveredAt;

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrderModel(
      id: doc.id,
      pharmacyId: data['pharmacyId'] as String? ?? '',
      pharmacyName: data['pharmacyName'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      pickupAddress: data['pickupAddress'] as String? ?? '',
      dropoffAddress: data['dropoffAddress'] as String? ?? '',
      status: data['status'] as String? ?? '',
      riderId: data['riderId'] as String?,
      riderName: data['riderName'] as String?,
      riderPhone: data['riderPhone'] as String?,
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      controlledDrug: data['controlledDrug'] as bool? ?? false,
      coldChain: data['coldChain'] as bool? ?? false,
      distance: data['distance'] as String?,
      estimatedTime: data['estimatedTime'] as String?,
      deliveryTimeMinutes: data['deliveryTimeMinutes'] as int?,
      notes: data['notes'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      assignedAt: _parseTimestamp(data['assignedAt']),
      deliveredAt: _parseTimestamp(data['deliveredAt']),
    );
  }

  OrderModel.noOp()
      : this(
          id: '',
          pharmacyId: '',
          pharmacyName: '',
          customerName: '',
          customerPhone: '',
          pickupAddress: '',
          dropoffAddress: '',
          status: '',
        );

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  double? get distanceKm {
    if (distance == null) return null;
    final match = RegExp(r'[\d.]+').firstMatch(distance!);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  bool get isActive =>
      status == 'Assigned' ||
      status == 'Picked Up' ||
      status == 'On the Way';

  bool get isCompleted =>
      status == 'Delivered' || status == 'Completed';

  bool get isReady => status == 'Ready' || status == 'Assigned';
}

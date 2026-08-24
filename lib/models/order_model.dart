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

  Map<String, dynamic> toJson() => {
        'id': id,
        'pharmacyId': pharmacyId,
        'pharmacyName': pharmacyName,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'status': status,
        'riderId': riderId,
        'riderName': riderName,
        'items': items,
        'controlledDrug': controlledDrug,
        'coldChain': coldChain,
        'distance': distance,
        'estimatedTime': estimatedTime,
        'deliveryTimeMinutes': deliveryTimeMinutes,
        'notes': notes,
        'createdAt': createdAt?.toIso8601String(),
        'assignedAt': assignedAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: (json['id'] ?? '') as String,
        pharmacyId: (json['pharmacyId'] ?? '') as String,
        pharmacyName: (json['pharmacyName'] ?? '') as String,
        customerName: (json['customerName'] ?? '') as String,
        customerPhone: (json['customerPhone'] ?? '') as String,
        pickupAddress: (json['pickupAddress'] ?? '') as String,
        dropoffAddress: (json['dropoffAddress'] ?? '') as String,
        status: (json['status'] ?? 'Pending') as String,
        riderId: json['riderId'] as String?,
        riderName: json['riderName'] as String?,
        items: (json['items'] as List?)
                ?.map((item) => item.toString())
                .toList() ??
            const [],
        controlledDrug: json['controlledDrug'] == true,
        coldChain: json['coldChain'] == true,
        distance: json['distance']?.toString(),
        estimatedTime: json['estimatedTime']?.toString(),
        deliveryTimeMinutes:
            (json['deliveryTimeMinutes'] as num?)?.toInt(),
        notes: json['notes']?.toString(),
        createdAt: _parseDate(json['createdAt']),
        assignedAt: _parseDate(json['assignedAt']),
        deliveredAt: _parseDate(json['deliveredAt']),
      );

  OrderModel copyWith({
    String? id,
    String? pharmacyId,
    String? pharmacyName,
    String? customerName,
    String? customerPhone,
    String? pickupAddress,
    String? dropoffAddress,
    String? status,
    Object? riderId = _unset,
    Object? riderName = _unset,
    List<String>? items,
    bool? controlledDrug,
    bool? coldChain,
    Object? distance = _unset,
    Object? estimatedTime = _unset,
    Object? deliveryTimeMinutes = _unset,
    Object? notes = _unset,
    Object? createdAt = _unset,
    Object? assignedAt = _unset,
    Object? deliveredAt = _unset,
  }) {
    return OrderModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      status: status ?? this.status,
      riderId: identical(riderId, _unset) ? this.riderId : riderId as String?,
      riderName:
          identical(riderName, _unset) ? this.riderName : riderName as String?,
      items: items ?? this.items,
      controlledDrug: controlledDrug ?? this.controlledDrug,
      coldChain: coldChain ?? this.coldChain,
      distance:
          identical(distance, _unset) ? this.distance : distance as String?,
      estimatedTime: identical(estimatedTime, _unset)
          ? this.estimatedTime
          : estimatedTime as String?,
      deliveryTimeMinutes: identical(deliveryTimeMinutes, _unset)
          ? this.deliveryTimeMinutes
          : deliveryTimeMinutes as int?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
      assignedAt: identical(assignedAt, _unset)
          ? this.assignedAt
          : assignedAt as DateTime?,
      deliveredAt: identical(deliveredAt, _unset)
          ? this.deliveredAt
          : deliveredAt as DateTime?,
    );
  }

  static const Object _unset = Object();

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

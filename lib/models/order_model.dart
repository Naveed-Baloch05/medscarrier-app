import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    this.dropoffLat,
    this.dropoffLng,
    this.pickupLat,
    this.pickupLng,
    this.failureReason,
    this.failureNote,
    this.failedAt,
    this.returnStatus,
    this.pickupQrValue,
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
  final double? dropoffLat;
  final double? dropoffLng;
  final double? pickupLat;
  final double? pickupLng;
  final String? failureReason;
  final String? failureNote;
  final DateTime? failedAt;
  final String? returnStatus;
  final String? pickupQrValue;

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final dropoffLocation = _extractLocation(data['dropoffLocation']);
    final pickupLocation = _extractLocation(data['pickupLocation']);

    final resolvedDropoffLat = _asDouble(
      data['dropoffLat'] ??
          dropoffLocation['lat'] ??
          data['customerLat'] ??
          data['latitude'],
    );
    final resolvedDropoffLng = _asDouble(
      data['dropoffLng'] ??
          dropoffLocation['lng'] ??
          data['customerLng'] ??
          data['longitude'],
    );

    final resolvedPickupLat = _asDouble(
      data['pickupLat'] ?? pickupLocation['lat'],
    );
    final resolvedPickupLng = _asDouble(
      data['pickupLng'] ?? pickupLocation['lng'],
    );

    return OrderModel(
      id: doc.id,
      pharmacyId: data['pharmacyId'] as String? ?? '',
      pharmacyName: data['pharmacyName'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      pickupAddress: data['pickupAddress'] as String? ?? '',
      dropoffAddress: (data['dropoffAddress'] ?? data['deliveryAddress'])
              as String? ??
          '',
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
      dropoffLat: resolvedDropoffLat,
      dropoffLng: resolvedDropoffLng,
      pickupLat: resolvedPickupLat,
      pickupLng: resolvedPickupLng,
      failureReason: data['failureReason'] as String?,
      failureNote: data['failureNote'] as String?,
      failedAt: _parseTimestamp(data['failedAt']),
      returnStatus: data['returnStatus'] as String?,
      pickupQrValue: data['pickupQrValue'] as String?,
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
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Map<String, dynamic> _extractLocation(dynamic location) {
    if (location is GeoPoint) {
      return {'lat': location.latitude, 'lng': location.longitude};
    }
    if (location is Map) {
      final lat = location['lat'] ?? location['latitude'];
      final lng = location['lng'] ?? location['longitude'];
      return {
        'lat': (lat as num?)?.toDouble(),
        'lng': (lng as num?)?.toDouble(),
      };
    }
    return {'lat': null, 'lng': null};
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  LatLng? get dropoffLatLng =>
      dropoffLat != null && dropoffLng != null
          ? LatLng(dropoffLat!, dropoffLng!)
          : null;

  LatLng? get pickupLatLng =>
      pickupLat != null && pickupLng != null
          ? LatLng(pickupLat!, pickupLng!)
          : null;

  bool get hasDropoffCoordinates =>
      dropoffLat != null && dropoffLng != null;

  double? get distanceKm {
    if (distance == null) return null;
    final match = RegExp(r'[\d.]+').firstMatch(distance!);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  String get orderId => id.startsWith('#') ? id : '#ORD-$id';

  String get displayStatus => status.isNotEmpty ? status : 'Pending';

  bool get isActive =>
      status == 'Assigned' ||
      status == 'Picked Up' ||
      status == 'On the Way' ||
      status == 'Out for Delivery';

  bool get isCompleted =>
      status == 'Delivered' || status == 'Completed';

  bool get isFailed =>
      status == 'Failed' ||
      status == 'Delivery Failed' ||
      status == 'Cancelled';

  bool get isReady => status == 'Ready' || status == 'Assigned';

  OrderModel copyWith({
    String? id,
    String? pharmacyId,
    String? pharmacyName,
    String? customerName,
    String? customerPhone,
    String? pickupAddress,
    String? dropoffAddress,
    String? status,
    String? riderId,
    String? riderName,
    String? riderPhone,
    List<String>? items,
    bool? controlledDrug,
    bool? coldChain,
    String? distance,
    String? estimatedTime,
    int? deliveryTimeMinutes,
    String? notes,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? deliveredAt,
    double? dropoffLat,
    double? dropoffLng,
    double? pickupLat,
    double? pickupLng,
    String? failureReason,
    String? failureNote,
    DateTime? failedAt,
    String? returnStatus,
    String? pickupQrValue,
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
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      items: items ?? this.items,
      controlledDrug: controlledDrug ?? this.controlledDrug,
      coldChain: coldChain ?? this.coldChain,
      distance: distance ?? this.distance,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      deliveryTimeMinutes: deliveryTimeMinutes ?? this.deliveryTimeMinutes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      failureReason: failureReason ?? this.failureReason,
      failureNote: failureNote ?? this.failureNote,
      failedAt: failedAt ?? this.failedAt,
      returnStatus: returnStatus ?? this.returnStatus,
      pickupQrValue: pickupQrValue ?? this.pickupQrValue,
    );
  }
}

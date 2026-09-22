import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_model.dart';

class RouteStopModel {
  const RouteStopModel({
    required this.id,
    required this.orderId,
    required this.routeId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    this.city = '',
    this.postcode = '',
    this.latitude,
    this.longitude,
    this.status = 'pending',
    this.sequence = 1,
    this.originalSequence = 1,
    this.notes,
    this.failureReason,
    this.failureNote,
    this.scannedAt,
    this.deliveredAt,
    this.failedAt,
    this.items = const [],
    this.coldChain = false,
    this.controlledDrug = false,
    this.pharmacyId = '',
    this.pharmacyName = '',
    this.riderId = '',
    this.recipientName,
  });

  final String id;
  final String orderId;
  final String routeId;
  final String customerName;
  final String customerPhone;
  final String address;
  final String city;
  final String postcode;
  final double? latitude;
  final double? longitude;
  final String status; // 'pending', 'delivered', 'failed'
  final int sequence;
  final int originalSequence;
  final String? notes;
  final String? failureReason;
  final String? failureNote;
  final DateTime? scannedAt;
  final DateTime? deliveredAt;
  final DateTime? failedAt;
  final List<String> items;
  final bool coldChain;
  final bool controlledDrug;
  final String pharmacyId;
  final String pharmacyName;
  final String riderId;
  final String? recipientName;

  LatLng? get latLng =>
      latitude != null && longitude != null ? LatLng(latitude!, longitude!) : null;

  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isPending => !isDelivered && !isFailed;

  String get formattedAddress {
    final parts = [address, city, postcode].where((s) => s.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'routeId': routeId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'city': city,
      'postcode': postcode,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'sequence': sequence,
      'originalSequence': originalSequence,
      'notes': notes,
      'failureReason': failureReason,
      'failureNote': failureNote,
      'scannedAt': scannedAt != null ? Timestamp.fromDate(scannedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'failedAt': failedAt != null ? Timestamp.fromDate(failedAt!) : null,
      'items': items,
      'coldChain': coldChain,
      'controlledDrug': controlledDrug,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'riderId': riderId,
      'recipientName': recipientName,
    };
  }

  factory RouteStopModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return RouteStopModel(
      id: map['id'] as String? ?? map['orderId'] as String? ?? '',
      orderId: map['orderId'] as String? ?? map['id'] as String? ?? '',
      routeId: map['routeId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      address: map['address'] as String? ?? map['dropoffAddress'] as String? ?? '',
      city: map['city'] as String? ?? '',
      postcode: map['postcode'] as String? ?? '',
      latitude: parseDouble(map['latitude'] ?? map['dropoffLat']),
      longitude: parseDouble(map['longitude'] ?? map['dropoffLng']),
      status: map['status'] as String? ?? 'pending',
      sequence: (map['sequence'] as num?)?.toInt() ?? 1,
      originalSequence: (map['originalSequence'] as num?)?.toInt() ?? 1,
      notes: map['notes'] as String?,
      failureReason: map['failureReason'] as String?,
      failureNote: map['failureNote'] as String?,
      scannedAt: parseDate(map['scannedAt']),
      deliveredAt: parseDate(map['deliveredAt']),
      failedAt: parseDate(map['failedAt']),
      items: (map['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      coldChain: map['coldChain'] as bool? ?? false,
      controlledDrug: map['controlledDrug'] as bool? ?? false,
      pharmacyId: map['pharmacyId'] as String? ?? '',
      pharmacyName: map['pharmacyName'] as String? ?? '',
      riderId: map['riderId'] as String? ?? '',
      recipientName: map['recipientName'] as String?,
    );
  }

  factory RouteStopModel.fromOrderModel(OrderModel order, {required String routeId, int sequence = 1}) {
    return RouteStopModel(
      id: order.id,
      orderId: order.id,
      routeId: routeId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      address: order.dropoffAddress,
      latitude: order.dropoffLat,
      longitude: order.dropoffLng,
      status: order.isCompleted ? 'delivered' : (order.isFailed ? 'failed' : 'pending'),
      sequence: sequence,
      originalSequence: sequence,
      notes: order.notes,
      failureReason: order.failureReason,
      failureNote: order.failureNote,
      scannedAt: DateTime.now(),
      deliveredAt: order.deliveredAt,
      failedAt: order.failedAt,
      items: order.items,
      coldChain: order.coldChain,
      controlledDrug: order.controlledDrug,
      pharmacyId: order.pharmacyId,
      pharmacyName: order.pharmacyName,
      riderId: order.riderId ?? '',
    );
  }

  OrderModel toOrderModel() {
    return OrderModel(
      id: orderId,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      customerName: customerName,
      customerPhone: customerPhone,
      pickupAddress: '',
      dropoffAddress: address,
      status: isDelivered ? 'Delivered' : (isFailed ? 'Failed' : 'On the Way'),
      riderId: riderId.isNotEmpty ? riderId : null,
      items: items,
      controlledDrug: controlledDrug,
      coldChain: coldChain,
      notes: notes,
      dropoffLat: latitude,
      dropoffLng: longitude,
      deliveredAt: deliveredAt,
      failedAt: failedAt,
      failureReason: failureReason,
      failureNote: failureNote,
    );
  }

  RouteStopModel copyWith({
    String? id,
    String? orderId,
    String? routeId,
    String? customerName,
    String? customerPhone,
    String? address,
    String? city,
    String? postcode,
    double? latitude,
    double? longitude,
    String? status,
    int? sequence,
    int? originalSequence,
    String? notes,
    String? failureReason,
    String? failureNote,
    DateTime? scannedAt,
    DateTime? deliveredAt,
    DateTime? failedAt,
    List<String>? items,
    bool? coldChain,
    bool? controlledDrug,
    String? pharmacyId,
    String? pharmacyName,
    String? riderId,
    String? recipientName,
  }) {
    return RouteStopModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      routeId: routeId ?? this.routeId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      sequence: sequence ?? this.sequence,
      originalSequence: originalSequence ?? this.originalSequence,
      notes: notes ?? this.notes,
      failureReason: failureReason ?? this.failureReason,
      failureNote: failureNote ?? this.failureNote,
      scannedAt: scannedAt ?? this.scannedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      failedAt: failedAt ?? this.failedAt,
      items: items ?? this.items,
      coldChain: coldChain ?? this.coldChain,
      controlledDrug: controlledDrug ?? this.controlledDrug,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      riderId: riderId ?? this.riderId,
      recipientName: recipientName ?? this.recipientName,
    );
  }
}

class DeliveryRouteModel {
  const DeliveryRouteModel({
    required this.id,
    required this.riderId,
    required this.date,
    this.name = '',
    this.riderName = '',
    this.pharmacyId = '',
    this.pharmacyName = '',
    this.status = 'draft', // 'draft', 'building', 'optimized', 'active', 'completed'
    this.stops = const [],
    this.originalOrderIds = const [],
    this.optimizedOrderIds = const [],
    this.startLocation,
    this.totalDistanceMeters = 0.0,
    this.totalDurationSeconds = 0,
    this.carriedStops = false,
    this.createdAt,
    this.optimizedAt,
    this.completedAt,
  });

  final String id;
  final String riderId;
  final String name;
  final String riderName;
  final String pharmacyId;
  final String pharmacyName;
  final DateTime date;
  final String status;
  final List<RouteStopModel> stops;
  final List<String> originalOrderIds;
  final List<String> optimizedOrderIds;
  final Map<String, dynamic>? startLocation;
  final double totalDistanceMeters;
  final int totalDurationSeconds;
  final bool carriedStops;
  final DateTime? createdAt;
  final DateTime? optimizedAt;
  final DateTime? completedAt;

  int get totalStops => stops.length;
  int get deliveredCount => stops.where((s) => s.isDelivered).length;
  int get failedCount => stops.where((s) => s.isFailed).length;
  int get pendingCount => stops.where((s) => s.isPending).length;
  int get processedCount => deliveredCount + failedCount;
  bool get isCompleted => status == 'completed' || (totalStops > 0 && pendingCount == 0);
  bool get isActive => status == 'active';

  LatLng? get startLatLng {
    if (startLocation == null) return null;
    final lat = (startLocation!['lat'] ?? startLocation!['latitude'] as num?)?.toDouble();
    final lng = (startLocation!['lng'] ?? startLocation!['longitude'] as num?)?.toDouble();
    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'riderId': riderId,
      'name': name,
      'riderName': riderName.isNotEmpty ? riderName : name,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'date': Timestamp.fromDate(date),
      'status': status,
      'stops': stops.map((s) => s.toMap()).toList(),
      'originalOrderIds': originalOrderIds,
      'optimizedOrderIds': optimizedOrderIds,
      'startLocation': startLocation,
      'totalDistanceMeters': totalDistanceMeters,
      'totalDurationSeconds': totalDurationSeconds,
      'carriedStops': carriedStops,
      'deliveredCount': deliveredCount,
      'failedCount': failedCount,
      'totalStops': totalStops,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'optimizedAt': optimizedAt != null ? Timestamp.fromDate(optimizedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory DeliveryRouteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final rawStops = data['stops'] as List<dynamic>? ?? const [];
    final stopsList = rawStops
        .map((s) => RouteStopModel.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList();

    return DeliveryRouteModel(
      id: doc.id,
      riderId: data['riderId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      riderName: data['riderName'] as String? ?? data['name'] as String? ?? '',
      pharmacyId: data['pharmacyId'] as String? ?? '',
      pharmacyName: data['pharmacyName'] as String? ?? '',
      date: parseDate(data['date']) ?? DateTime.now(),
      status: data['status'] as String? ?? 'draft',
      stops: stopsList,
      originalOrderIds: (data['originalOrderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      optimizedOrderIds: (data['optimizedOrderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      startLocation: data['startLocation'] is Map
          ? Map<String, dynamic>.from(data['startLocation'] as Map)
          : null,
      totalDistanceMeters: (data['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      totalDurationSeconds: (data['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      carriedStops: data['carriedStops'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
      optimizedAt: parseDate(data['optimizedAt']),
      completedAt: parseDate(data['completedAt']),
    );
  }

  DeliveryRouteModel copyWith({
    String? id,
    String? riderId,
    String? name,
    String? riderName,
    String? pharmacyId,
    String? pharmacyName,
    DateTime? date,
    String? status,
    List<RouteStopModel>? stops,
    List<String>? originalOrderIds,
    List<String>? optimizedOrderIds,
    Map<String, dynamic>? startLocation,
    double? totalDistanceMeters,
    int? totalDurationSeconds,
    bool? carriedStops,
    DateTime? createdAt,
    DateTime? optimizedAt,
    DateTime? completedAt,
  }) {
    return DeliveryRouteModel(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      name: name ?? this.name,
      riderName: riderName ?? this.riderName,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      date: date ?? this.date,
      status: status ?? this.status,
      stops: stops ?? this.stops,
      originalOrderIds: originalOrderIds ?? this.originalOrderIds,
      optimizedOrderIds: optimizedOrderIds ?? this.optimizedOrderIds,
      startLocation: startLocation ?? this.startLocation,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      carriedStops: carriedStops ?? this.carriedStops,
      createdAt: createdAt ?? this.createdAt,
      optimizedAt: optimizedAt ?? this.optimizedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

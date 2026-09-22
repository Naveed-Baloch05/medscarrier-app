import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Live tracking snapshot stored in `rider_locations/{riderId}` while a
/// rider is actively delivering an optimized batch route. Written by the
/// rider, read in real time by the pharmacy via Firestore snapshots.
class RiderLiveLocation {
  const RiderLiveLocation({
    required this.riderId,
    this.pharmacyId = '',
    this.routeId = '',
    this.latitude,
    this.longitude,
    this.currentStopIndex = 0,
    this.currentOrderId = '',
    this.currentCustomerName = '',
    this.currentAddress = '',
    this.totalStops = 0,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.status = '',
    this.updatedAt,
  });

  final String riderId;
  final String pharmacyId;
  final String routeId;
  final double? latitude;
  final double? longitude;
  final int currentStopIndex;
  final String currentOrderId;
  final String currentCustomerName;
  final String currentAddress;
  final int totalStops;
  final int deliveredCount;
  final int failedCount;
  final String status; // 'delivering', 'completed', 'offline'
  final DateTime? updatedAt;

  LatLng? get latLng =>
      latitude != null && longitude != null
          ? LatLng(latitude!, longitude!)
          : null;

  int get totalProcessed => deliveredCount + failedCount;

  bool get isActivelyDelivering => status == 'delivering';

  int get stopNumber =>
      currentStopIndex >= 0 ? currentStopIndex + 1 : 0;

  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      if (pharmacyId.isNotEmpty) 'pharmacyId': pharmacyId,
      if (routeId.isNotEmpty) 'routeId': routeId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'currentStopIndex': currentStopIndex,
      'currentOrderId': currentOrderId,
      'currentCustomerName': currentCustomerName,
      'currentAddress': currentAddress,
      'totalStops': totalStops,
      'deliveredCount': deliveredCount,
      'failedCount': failedCount,
      'status': status,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory RiderLiveLocation.fromMap(
    String docId,
    Map<String, dynamic>? data,
  ) {
    final safe = data ?? const <String, dynamic>{};

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return RiderLiveLocation(
      riderId: safe['riderId']?.toString() ?? docId,
      pharmacyId: (safe['pharmacyId'] ?? '').toString(),
      routeId: (safe['routeId'] ?? '').toString(),
      latitude: parseDouble(safe['latitude'] ?? safe['lat']),
      longitude: parseDouble(safe['longitude'] ?? safe['lng']),
      currentStopIndex:
          (safe['currentStopIndex'] as num?)?.toInt() ?? 0,
      currentOrderId: (safe['currentOrderId'] ?? '').toString(),
      currentCustomerName:
          (safe['currentCustomerName'] ?? '').toString(),
      currentAddress: (safe['currentAddress'] ?? '').toString(),
      totalStops: (safe['totalStops'] as num?)?.toInt() ?? 0,
      deliveredCount: (safe['deliveredCount'] as num?)?.toInt() ?? 0,
      failedCount: (safe['failedCount'] as num?)?.toInt() ?? 0,
      status: (safe['status'] ?? '').toString(),
      updatedAt: parseDate(safe['updatedAt']),
    );
  }
}
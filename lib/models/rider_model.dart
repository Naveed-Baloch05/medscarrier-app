import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RiderModel {
  const RiderModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleReg,
    this.pharmacyId = '',
    this.pharmacyName = '',
    this.online = false,
    this.active = true,
    this.location,
    this.deliveries = 0,
    this.currentOrder,
    this.lastSeen,
    this.deliveryStatus,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleReg;
  final String pharmacyId;
  final String pharmacyName;
  final bool online;
  final bool active;
  final Map<String, dynamic>? location;
  final int deliveries;
  final String? currentOrder;
  final DateTime? lastSeen;
  final String? deliveryStatus;
  final DateTime? createdAt;

  double? get latitude {
    if (location == null) return null;
    final lat = location!['lat'] ?? location!['latitude'];
    if (lat is num) return lat.toDouble();
    return null;
  }

  double? get longitude {
    if (location == null) return null;
    final lng = location!['lng'] ?? location!['longitude'];
    if (lng is num) return lng.toDouble();
    return null;
  }

  LatLng? get latLng {
    final lat = latitude;
    final lng = longitude;
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'vehicleType': vehicleType,
        'vehicleReg': vehicleReg,
        'pharmacyId': pharmacyId,
        'pharmacyName': pharmacyName,
        'online': online,
        'active': active,
        'location': location,
        'deliveries': deliveries,
        'currentOrder': currentOrder,
        'lastSeen': lastSeen?.toIso8601String(),
        'deliveryStatus': deliveryStatus,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory RiderModel.fromJson(String id, Map<String, dynamic> json) {
    Map<String, dynamic>? locationMap;
    final rawLoc = json['location'];
    if (rawLoc is GeoPoint) {
      locationMap = {'lat': rawLoc.latitude, 'lng': rawLoc.longitude};
    } else if (rawLoc is Map<String, dynamic>) {
      locationMap = rawLoc;
    } else if (rawLoc is Map) {
      locationMap = Map<String, dynamic>.from(rawLoc);
    } else if (json['latitude'] != null && json['longitude'] != null) {
      locationMap = {
        'lat': (json['latitude'] as num).toDouble(),
        'lng': (json['longitude'] as num).toDouble(),
      };
    }

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return RiderModel(
      id: id.isNotEmpty ? id : (json['id'] as String? ?? ''),
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      vehicleReg: json['vehicleReg'] as String? ??
          json['vehicleRegistrationNumber'] as String? ??
          '',
      pharmacyId: json['pharmacyId'] as String? ?? '',
      pharmacyName: json['pharmacyName'] as String? ?? '',
      online: json['online'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      location: locationMap,
      deliveries: (json['deliveries'] as num?)?.toInt() ?? 0,
      currentOrder: json['currentOrder'] as String?,
      lastSeen: parseDate(json['lastSeen']),
      deliveryStatus: json['deliveryStatus'] as String?,
      createdAt: parseDate(json['createdAt']),
    );
  }
}

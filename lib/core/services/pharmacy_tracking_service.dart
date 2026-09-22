import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/delivery_route_model.dart';
import '../../models/order_model.dart';
import '../../models/rider_live_location.dart';
import '../../models/rider_model.dart';

class PharmacyTrackingService {
  PharmacyTrackingService._();
  static final PharmacyTrackingService instance = PharmacyTrackingService._();
  factory PharmacyTrackingService() => instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==============================================================
  // REAL-TIME ROUTE STREAM BY ROUTE ID
  // ==============================================================

  Stream<DeliveryRouteModel?> routeStream(String routeId) {
    if (routeId.trim().isEmpty) {
      return Stream.value(null);
    }
    return _firestore.collection('routes').doc(routeId.trim()).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return DeliveryRouteModel.fromFirestore(doc);
    });
  }

  // ==============================================================
  // REAL-TIME ACTIVE ROUTE STREAM FOR PHARMACY
  // ==============================================================

  Stream<DeliveryRouteModel?> activeRouteForPharmacyStream({
    required String pharmacyId,
    String? riderId,
  }) {
    final cleanPharmId = pharmacyId.trim();
    if (cleanPharmId.isEmpty) {
      return Stream.value(null);
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('routes')
        .where('pharmacyId', isEqualTo: cleanPharmId);

    if (riderId != null && riderId.trim().isNotEmpty) {
      query = query.where('riderId', isEqualTo: riderId.trim());
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final routes = snapshot.docs.map((d) => DeliveryRouteModel.fromFirestore(d)).toList();
      // Prioritize active, then optimized, then completed
      final activeRoutes = routes.where((r) => r.isActive).toList();
      if (activeRoutes.isNotEmpty) {
        activeRoutes.sort((a, b) {
          final aDate = a.optimizedAt ?? a.createdAt ?? DateTime(2000);
          final bDate = b.optimizedAt ?? b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        return activeRoutes.first;
      }

      final optRoutes = routes.where((r) => r.status == 'optimized').toList();
      if (optRoutes.isNotEmpty) {
        return optRoutes.first;
      }

      final completedRoutes = routes.where((r) => r.status == 'completed').toList();
      if (completedRoutes.isNotEmpty) {
        completedRoutes.sort((a, b) {
          final aDate = a.completedAt ?? a.createdAt ?? DateTime(2000);
          final bDate = b.completedAt ?? b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        return completedRoutes.first;
      }

      return routes.first;
    });
  }

  // ==============================================================
  // REAL-TIME PHARMACY ROUTES STREAM
  // ==============================================================

  Stream<List<DeliveryRouteModel>> pharmacyRoutesStream(String pharmacyId) {
    final cleanPharmId = pharmacyId.trim();
    if (cleanPharmId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('routes')
        .where('pharmacyId', isEqualTo: cleanPharmId)
        .snapshots()
        .map((snapshot) {
      final routes = snapshot.docs.map((d) => DeliveryRouteModel.fromFirestore(d)).toList();
      routes.sort((a, b) {
        final aDate = a.optimizedAt ?? a.createdAt ?? DateTime(2000);
        final bDate = b.optimizedAt ?? b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return routes;
    });
  }

  // ==============================================================
  // REAL-TIME RIDER LIVE LOCATION STREAM
  // ==============================================================

  Stream<RiderModel?> riderLiveLocationStream(String riderId) {
    if (riderId.trim().isEmpty) {
      return Stream.value(null);
    }

    return _firestore.collection('riders').doc(riderId.trim()).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return RiderModel.fromJson(doc.id, doc.data()!);
    });
  }

  // ==============================================================
  // LIVE BATCH ROUTE TRACKING (rider_locations/{riderId})
  // ==============================================================

  /// Real-time stream of the rider's active batch-route tracking snapshot,
  /// written by the rider to `rider_locations/{riderId}` while delivering.
  Stream<RiderLiveLocation?> riderBatchLocationStream(String riderId) {
    if (riderId.trim().isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection('rider_locations')
        .doc(riderId.trim())
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return RiderLiveLocation.fromMap(doc.id, doc.data());
    });
  }

  // ==============================================================
  // REAL-TIME ASSIGNED ORDERS STREAM FOR SPECIFIC RIDER & PHARMACY
  // ==============================================================

  Stream<List<OrderModel>> pharmacyRiderOrdersStream({
    required String pharmacyId,
    required String riderId,
  }) {
    if (pharmacyId.trim().isEmpty || riderId.trim().isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('pharmacyId', isEqualTo: pharmacyId.trim())
        .where('riderId', isEqualTo: riderId.trim())
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      // Sort with active first, then pending, then completed/failed
      orders.sort((a, b) {
        final aPriority = _statusPriority(a.status);
        final bPriority = _statusPriority(b.status);
        return aPriority.compareTo(bPriority);
      });

      return orders;
    });
  }

  int _statusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'on the way':
      case 'picked up':
      case 'arrived':
        return 0; // Currently active
      case 'assigned':
      case 'ready':
        return 1; // Pending next
      case 'delivered':
      case 'completed':
        return 2; // Completed
      case 'failed':
        return 3; // Failed
      default:
        return 4;
    }
  }

  // ==============================================================
  // FETCH PHARMACY LOCATION
  // ==============================================================

  Future<LatLng?> fetchPharmacyLocation(String pharmacyId) async {
    if (pharmacyId.trim().isEmpty) return null;

    try {
      final doc = await _firestore.collection('pharmacies').doc(pharmacyId.trim()).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final loc = data['location'];
        if (loc is GeoPoint) {
          return LatLng(loc.latitude, loc.longitude);
        }
        if (loc is Map) {
          final lat = (loc['lat'] ?? loc['latitude'] as num?)?.toDouble();
          final lng = (loc['lng'] ?? loc['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            return LatLng(lat, lng);
          }
        }
        final lat = (data['latitude'] ?? data['lat'] as num?)?.toDouble();
        final lng = (data['longitude'] ?? data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (_) {}

    return null;
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../models/order_model.dart';
import '../../models/route_model.dart';
import '../utils/route_utils.dart';
import 'rider_delivery_details_service.dart';

class RiderMapSession {
  const RiderMapSession({
    required this.order,
    this.pharmacyName,
    this.pharmacyAddress,
    this.pickupLat,
    this.pickupLng,
    this.customerName,
    this.customerAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.riderId,
    this.riderName,
    this.riderLat,
    this.riderLng,
    this.arrivedAt,
    this.pickupQrValue,
  });

  final OrderModel order;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? customerName;
  final String? customerAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? riderId;
  final String? riderName;
  final double? riderLat;
  final double? riderLng;
  final DateTime? arrivedAt;
  final String? pickupQrValue;

  String get pharmacy =>
      pharmacyName?.trim().isNotEmpty == true
          ? pharmacyName!
          : (order.pharmacyName.trim().isNotEmpty
              ? order.pharmacyName
              : 'Pharmacy');

  String get pharmacyAddressText =>
      pharmacyAddress?.trim().isNotEmpty == true
          ? pharmacyAddress!
          : (order.pickupAddress.trim().isNotEmpty
              ? order.pickupAddress
              : '');

  String get customer =>
      customerName?.trim().isNotEmpty == true
          ? customerName!
          : (order.customerName.trim().isNotEmpty
              ? order.customerName
              : 'Customer');

  String get customerAddressText =>
      customerAddress?.trim().isNotEmpty == true
          ? customerAddress!
          : (order.dropoffAddress.trim().isNotEmpty
              ? order.dropoffAddress
              : '');

  String get distance => order.distance?.trim().isNotEmpty == true
      ? order.distance!
      : '—';

  String get eta {
    if (order.estimatedTime?.trim().isNotEmpty == true) {
      return order.estimatedTime!;
    }

    final minutes = order.deliveryTimeMinutes;
    if (minutes != null && minutes > 0) {
      return '$minutes min';
    }

    return '—';
  }

  bool get hasOrder =>
      order.id.trim().isNotEmpty && !order.isCompleted;

  bool get isArrived => arrivedAt != null;

  /// Returns true if the order is picked up and currently heading to customer
  bool get isPickedUp =>
      order.status == 'Picked Up' ||
      order.status == 'On the Way' ||
      order.status == 'On the way' ||
      pickupQrValue != null;

  /// Resolves the current target coordinates based on delivery stage.
  /// BEFORE PICKUP: Pharmacy
  /// AFTER PICKUP: Customer Drop-off
  LatLng? get currentDestination {
    if (!isPickedUp) {
      if (pickupLat != null && pickupLng != null) {
        return LatLng(pickupLat!, pickupLng!);
      }
    }
    if (dropoffLat != null && dropoffLng != null) {
      return LatLng(dropoffLat!, dropoffLng!);
    }
    if (pickupLat != null && pickupLng != null) {
      return LatLng(pickupLat!, pickupLng!);
    }
    return null;
  }
}

class RiderMapService {
  RiderMapService._();

  static final RiderMapService instance = RiderMapService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RiderDeliveryDetailsService _details =
      RiderDeliveryDetailsService.instance;

  static const String _mapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: String.fromEnvironment(
      'MAPS_API_KEY',
      defaultValue: '',
    ),
  );

  /// Resolves the rider's currently assigned active order.
  Future<OrderModel?> getActiveOrder(String riderId) async {
    if (riderId.trim().isEmpty) {
      return null;
    }

    final riderDoc = await _resolveRiderDoc(riderId);
    if (riderDoc == null) {
      return null;
    }

    final data = riderDoc.data() ?? const <String, dynamic>{};
    final currentOrderId = (data['currentOrder'] as String?)?.trim();

    final snapshot = await _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .get();

    final orders = snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();

    if (orders.isEmpty) {
      return null;
    }

    if (currentOrderId != null && currentOrderId.isNotEmpty) {
      final match = orders.where((o) => o.id == currentOrderId).toList();
      if (match.isNotEmpty && match.first.isActive) {
        return match.first;
      }
    }

    orders.sort((a, b) {
      final aTime = a.assignedAt ?? a.createdAt ?? DateTime(0);
      final bTime = b.assignedAt ?? b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    return orders.firstWhere(
      (o) => o.isActive,
      orElse: () => orders.first,
    );
  }

  /// Real-time stream of the rider's map session.
  Stream<RiderMapSession> mapSessionStream(String riderId) {
    return _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .asyncMap((snapshot) async {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList()
        ..sort((a, b) {
          final aTime = a.assignedAt ?? a.createdAt ?? DateTime(0);
          final bTime = b.assignedAt ?? b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });

      OrderModel order = orders.firstWhere(
        (o) => o.isActive,
        orElse: () => OrderModel.noOp(),
      );

      if (order.id.isEmpty && orders.isNotEmpty) {
        order = orders.first;
      }

      return _buildSession(order, riderId);
    });
  }

  /// Real-time stream for a specific order ID.
  Stream<RiderMapSession> orderSessionStream(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) {
        return RiderMapSession(
          order: OrderModel.noOp(),
        );
      }

      final order = OrderModel.fromFirestore(doc);
      final riderId = order.riderId ?? '';
      return _buildSession(order, riderId);
    });
  }

  /// One-shot fetch used as a fallback.
  Future<RiderMapSession> orderSessionOnce(String orderId) async {
    if (orderId.trim().isEmpty) {
      return RiderMapSession(
        order: OrderModel.noOp(),
      );
    }

    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists || doc.data() == null) {
      return RiderMapSession(
        order: OrderModel.noOp(),
      );
    }

    final order = OrderModel.fromFirestore(doc);
    final riderId = order.riderId ?? '';
    return _buildSession(order, riderId);
  }

  Future<RiderMapSession> _buildSession(
    OrderModel order,
    String riderId,
  ) async {
    if (order.id.isEmpty) {
      return RiderMapSession(
        order: order,
      );
    }

    final orderDoc =
        await _firestore.collection('orders').doc(order.id).get();
    final orderData = orderDoc.data() ?? const <String, dynamic>{};

    final pharmacy = await _resolvePharmacy(order.pharmacyId);
    final coords = _extractOrderCoords(orderData);

    final riderDoc = await _resolveRiderDoc(riderId);
    final riderData = riderDoc?.data() ?? const <String, dynamic>{};
    final riderLocation = _extractLocation(riderData['location']);
    final riderName =
        ((riderData['fullName'] ?? riderData['name'] ?? '').toString()).trim();

    return RiderMapSession(
      order: order,
      pharmacyName: pharmacy?['name'],
      pharmacyAddress: pharmacy?['address'],
      pickupLat: coords['pickupLat'] ??
          (pharmacy?['latitude'] as num?)?.toDouble(),
      pickupLng: coords['pickupLng'] ??
          (pharmacy?['longitude'] as num?)?.toDouble(),
      customerName: order.customerName.isEmpty
          ? (orderData['customerName'] as String?)
          : order.customerName,
      customerAddress: order.dropoffAddress.isEmpty
          ? (orderData['dropoffAddress'] as String?)
          : order.dropoffAddress,
      dropoffLat: coords['dropoffLat'],
      dropoffLng: coords['dropoffLng'],
      riderId: riderId.trim().isEmpty ? null : riderId.trim(),
      riderName: riderName,
      riderLat: riderLocation['lat'],
      riderLng: riderLocation['lng'],
      arrivedAt: _parseDate(orderData['arrivedAt']),
      pickupQrValue: orderData['pickupQrValue'] as String?,
    );
  }

  // ============================================================
  // GOOGLE ROUTES API
  // ============================================================

  /// Requests real road routing from Google Routes API v2.
  /// Computes recommended and alternate routes with traffic-aware ETA.
  Future<List<RouteModel>> computeRoutes({
    required LatLng origin,
    required LatLng destination,
    String? customApiKey,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : _mapsApiKey;

    if (apiKey.isEmpty) {
      // Return a basic fallback route if no API key is provided
      return [
        _buildFallbackRoute(origin, destination),
      ];
    }

    final url = Uri.parse(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
    );

    final requestBody = {
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          }
        }
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          }
        }
      },
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_AWARE',
      'computeAlternativeRoutes': true,
      'routeModifiers': {
        'avoidTolls': false,
        'avoidHighways': false,
        'avoidFerries': false,
      },
      'languageCode': 'en-US',
      'units': 'METRIC',
    };

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask':
          'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs,routes.description,routes.warnings',
    };

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(requestBody))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routesJson = data['routes'] as List<dynamic>?;

        if (routesJson != null && routesJson.isNotEmpty) {
          final List<RouteModel> routes = [];

          for (int i = 0; i < routesJson.length; i++) {
            final r = routesJson[i] as Map<String, dynamic>;
            final polylineStr =
                (r['polyline']?['encodedPolyline'] as String?) ?? '';
            final points = RouteUtils.decodePolyline(polylineStr);

            final distanceMeters = (r['distanceMeters'] as int?) ?? 0;
            final durationStr = (r['duration'] as String?) ?? '0s';
            final durationSeconds =
                RouteStepModel.parseDurationSeconds(durationStr);

            final description = (r['description'] as String?) ??
                (i == 0 ? 'Fastest Route' : 'Alternative ${i + 1}');

            final legs = r['legs'] as List<dynamic>?;
            final List<RouteStepModel> steps = [];

            if (legs != null && legs.isNotEmpty) {
              final firstLeg = legs.first as Map<String, dynamic>;
              final stepsJson = firstLeg['steps'] as List<dynamic>?;
              if (stepsJson != null) {
                for (final s in stepsJson) {
                  steps.add(RouteStepModel.fromJson(s as Map<String, dynamic>));
                }
              }
            }

            routes.add(RouteModel(
              id: 'route_$i',
              points: points.isNotEmpty ? points : [origin, destination],
              distanceMeters: distanceMeters,
              distanceText: RouteStepModel.formatDistance(distanceMeters),
              durationSeconds: durationSeconds,
              durationText: RouteStepModel.formatDuration(durationSeconds),
              summary: description,
              steps: steps,
              isRecommended: i == 0,
            ));
          }

          return routes;
        }
      }

      // If response is not OK, return fallback
      return [_buildFallbackRoute(origin, destination)];
    } catch (_) {
      // Graceful fallback to straight line on connection error
      return [_buildFallbackRoute(origin, destination)];
    }
  }

  RouteModel _buildFallbackRoute(LatLng origin, LatLng destination) {
    final dist = RouteUtils.distanceMeters(origin, destination).round();
    final durationSec = (dist / 8.33).round(); // ~30 km/h average speed in seconds

    return RouteModel(
      id: 'fallback_route',
      points: [origin, destination],
      distanceMeters: dist,
      distanceText: RouteStepModel.formatDistance(dist),
      durationSeconds: durationSec,
      durationText: RouteStepModel.formatDuration(durationSec),
      summary: 'Direct Path',
      steps: [
        RouteStepModel(
          instruction: 'Proceed to destination',
          distanceMeters: dist,
          distanceText: RouteStepModel.formatDistance(dist),
          durationText: RouteStepModel.formatDuration(durationSec),
          maneuver: 'STRAIGHT',
          startLocation: origin,
          endLocation: destination,
        )
      ],
      isRecommended: true,
    );
  }

  // ============================================================
  // LIVE LOCATION PERSISTENCE (THROTTLED)
  // ============================================================

  /// Updates the rider's current location in Firestore (`riders/{riderId}`).
  Future<void> updateRiderLiveLocation({
    required String riderId,
    required double latitude,
    required double longitude,
  }) async {
    if (riderId.trim().isEmpty) return;

    try {
      final doc = await _resolveRiderDoc(riderId);
      final docId = doc?.id ?? riderId;

      await _firestore.collection('riders').doc(docId).update({
        'location': {
          'lat': latitude,
          'lng': longitude,
        },
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Non-critical background update failure ignored to prevent UI disruption
    }
  }

  Future<Map<String, dynamic>?> _resolvePharmacy(String pharmacyId) async {
    if (pharmacyId.trim().isEmpty) {
      return null;
    }

    final doc =
        await _firestore.collection('pharmacies').doc(pharmacyId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final data = doc.data()!;
    final location = _extractLocation(data['location']);

    return {
      'name': (data['pharmacyName'] ?? data['name'] ?? '').toString(),
      'address': (data['businessAddress'] ?? data['address'] ?? '').toString(),
      'latitude': location['lat'],
      'longitude': location['lng'],
    };
  }

  Map<String, dynamic> _extractOrderCoords(Map<String, dynamic> data) {
    final orderLocation = _extractLocation(data['dropoffLocation']);
    final pickupLocation = _extractLocation(data['pickupLocation']);

    return {
      'pickupLat': _asDouble(
        data['pickupLat'] ?? pickupLocation['lat'],
      ),
      'pickupLng': _asDouble(
        data['pickupLng'] ?? pickupLocation['lng'],
      ),
      'dropoffLat': _asDouble(
        data['dropoffLat'] ?? orderLocation['lat'] ?? data['customerLat'],
      ),
      'dropoffLng': _asDouble(
        data['dropoffLng'] ?? orderLocation['lng'] ?? data['customerLng'],
      ),
    };
  }

  Map<String, dynamic> _extractLocation(dynamic location) {
    if (location is GeoPoint) {
      return {
        'lat': location.latitude,
        'lng': location.longitude,
      };
    }

    if (location is Map) {
      final lat = location['lat'] ?? location['latitude'];
      final lng = location['lng'] ?? location['longitude'];

      return {
        'lat': (lat as num?)?.toDouble(),
        'lng': (lng as num?)?.toDouble(),
      };
    }

    return {
      'lat': null,
      'lng': null,
    };
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveRiderDoc(
      String riderId) async {
    final directDoc =
        await _firestore.collection('riders').doc(riderId).get();
    if (directDoc.exists) {
      return directDoc;
    }

    final uidQuery = await _firestore
        .collection('riders')
        .where('uid', isEqualTo: riderId)
        .limit(1)
        .get();

    if (uidQuery.docs.isNotEmpty) {
      return uidQuery.docs.first;
    }

    final idQuery = await _firestore
        .collection('riders')
        .where('id', isEqualTo: riderId)
        .limit(1)
        .get();

    if (idQuery.docs.isNotEmpty) {
      return idQuery.docs.first;
    }

    return null;
  }

  Future<void> markArrived(String orderId) async {
    if (orderId.trim().isEmpty) {
      throw Exception('Order id is missing.');
    }

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'arrivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark arrival: $e');
    }
  }

  Future<void> completeDelivery({
    required String orderId,
    String? recipientName,
    List<Map<String, double>>? signaturePoints,
    bool medicineHandoverConfirmed = false,
  }) {
    return _details.completeDelivery(
      orderId: orderId,
      recipientName: recipientName,
      signaturePoints: signaturePoints,
      medicineHandoverConfirmed: medicineHandoverConfirmed,
    );
  }
}
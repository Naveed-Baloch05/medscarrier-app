import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/delivery_route_model.dart';
import '../../models/order_model.dart';

class RiderBatchScanResult {
  const RiderBatchScanResult({
    required this.order,
    this.isNew = true,
  });

  final OrderModel order;
  final bool isNew;
}

class RiderBatchService {
  RiderBatchService._();
  static final RiderBatchService instance = RiderBatchService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // ROUTE CREATION & PERSISTENCE (PHASE 2, 6, 17, 26, 27)
  // ============================================================

  /// Creates a persistent Route document in Firestore under `routes` collection.
  Future<DeliveryRouteModel> createRoute({
    required String riderId,
    required DateTime date,
    String? name,
    String? pharmacyId,
    String? pharmacyName,
    LatLng? startLocation,
    bool carryPreviousStops = false,
  }) async {
    debugPrint('=== [CREATE ROUTE STARTED] ===');
    debugPrint('Rider ID: $riderId, Date: $date, Name: $name');

    final cleanRiderId = riderId.trim();
    if (cleanRiderId.isEmpty) {
      debugPrint('[CREATE ROUTE ERROR]: Rider ID is empty.');
      throw ArgumentError('Rider ID is required to create a delivery route.');
    }

    final routeRef = _firestore.collection('routes').doc();
    final routeId = routeRef.id;

    final formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final resolvedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : 'Route - $formattedDate';

    Map<String, dynamic>? startLocMap;
    if (startLocation != null) {
      startLocMap = {
        'lat': startLocation.latitude,
        'lng': startLocation.longitude,
      };
    }

    List<RouteStopModel> initialStops = [];
    if (carryPreviousStops) {
      try {
        initialStops = await fetchCarriedStops(cleanRiderId);
      } catch (e) {
        debugPrint('[FETCH CARRIED STOPS FALLBACK]: $e');
      }
    }

    var resolvedPharmacyId = pharmacyId?.trim() ?? '';
    var resolvedPharmacyName = pharmacyName?.trim() ?? '';

    if (resolvedPharmacyId.isEmpty) {
      try {
        final riderDoc = await _firestore.collection('riders').doc(cleanRiderId).get();
        if (riderDoc.exists && riderDoc.data() != null) {
          final data = riderDoc.data()!;
          resolvedPharmacyId = (data['pharmacyId'] as String? ?? '').trim();
          resolvedPharmacyName = (data['pharmacyName'] as String? ?? '').trim();
        }
      } catch (e) {
        debugPrint('[CREATE ROUTE]: Could not fetch rider pharmacy info: $e');
      }
    }

    final newRoute = DeliveryRouteModel(
      id: routeId,
      riderId: cleanRiderId,
      name: resolvedName,
      pharmacyId: resolvedPharmacyId,
      pharmacyName: resolvedPharmacyName,
      date: date,
      status: 'draft',
      stops: initialStops,
      originalOrderIds: initialStops.map((s) => s.orderId).toList(),
      optimizedOrderIds: initialStops.map((s) => s.orderId).toList(),
      startLocation: startLocMap,
      carriedStops: carryPreviousStops,
      createdAt: DateTime.now(),
    );

    debugPrint('=== [CREATING FIRESTORE ROUTE] ===');
    debugPrint('Collection: routes, Doc ID: $routeId, Pharmacy ID: $resolvedPharmacyId');
    await routeRef.set(newRoute.toFirestore());
    debugPrint('=== [FIREBASE ROUTE CREATED: $routeId] ===');

    return newRoute;
  }

  /// Fetches an in-progress or draft route for a rider if one exists today.
  Future<DeliveryRouteModel?> getActiveRouteForRider(String riderId) async {
    if (riderId.trim().isEmpty) return null;

    try {
      final query = await _firestore
          .collection('routes')
          .where('riderId', isEqualTo: riderId)
          .where('status', whereIn: ['draft', 'building', 'optimized', 'active'])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return DeliveryRouteModel.fromFirestore(query.docs.first);
      }
    } catch (_) {
      // Fallback
    }
    return null;
  }

  /// Realtime stream of the current active or in-progress route for a rider.
  Stream<DeliveryRouteModel?> streamActiveRouteForRider(String riderId) {
    final clean = riderId.trim();
    if (clean.isEmpty) return Stream.value(null);

    return _firestore
        .collection('routes')
        .where('riderId', isEqualTo: clean)
        .where('status', whereIn: ['draft', 'building', 'optimized', 'active'])
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final docs = snap.docs.toList()
        ..sort((a, b) {
          final aT = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bT = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return bT.compareTo(aT);
        });
      return DeliveryRouteModel.fromFirestore(docs.first);
    });
  }

  /// Fetches a route by its unique Firestore document ID.
  Future<DeliveryRouteModel?> getRouteById(String routeId) async {
    final clean = routeId.trim();
    if (clean.isEmpty) return null;
    try {
      final doc = await _firestore.collection('routes').doc(clean).get();
      if (doc.exists && doc.data() != null) {
        return DeliveryRouteModel.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  /// Fetches undelivered stops from previous routes that were not completed.
  Future<List<RouteStopModel>> fetchCarriedStops(String riderId) async {
    final carried = <RouteStopModel>[];
    final cleanRiderId = riderId.trim();
    if (cleanRiderId.isEmpty) return carried;

    try {
      final pastRoutes = await _firestore
          .collection('routes')
          .where('riderId', isEqualTo: cleanRiderId)
          .limit(10)
          .get();

      final docs = pastRoutes.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });

      for (final doc in docs.take(3)) {
        final route = DeliveryRouteModel.fromFirestore(doc);
        for (final stop in route.stops) {
          if (stop.isPending && !carried.any((c) => c.orderId == stop.orderId)) {
            carried.add(stop.copyWith(
              sequence: carried.length + 1,
              originalSequence: carried.length + 1,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('[FETCH CARRIED STOPS ERROR]: $e');
    }
    return carried;
  }

  /// Adds a verified stop to the persistent Route document.
  Future<void> addStopToRoute({
    required String routeId,
    required RouteStopModel stop,
  }) async {
    if (routeId.trim().isEmpty) return;

    final routeRef = _firestore.collection('routes').doc(routeId);
    final routeDoc = await routeRef.get();
    if (!routeDoc.exists || routeDoc.data() == null) return;

    final existingRoute = DeliveryRouteModel.fromFirestore(routeDoc);
    final updatedStops = List<RouteStopModel>.from(existingRoute.stops);

    final resolvedStop = (stop.pharmacyId.isEmpty && existingRoute.pharmacyId.isNotEmpty)
        ? stop.copyWith(
            pharmacyId: existingRoute.pharmacyId,
            pharmacyName: existingRoute.pharmacyName,
          )
        : stop;

    // Prevent duplicate addition in Firestore
    final exists = updatedStops.any((s) => s.orderId == resolvedStop.orderId);
    if (!exists) {
      updatedStops.add(resolvedStop.copyWith(
        sequence: updatedStops.length + 1,
        originalSequence: updatedStops.length + 1,
      ));
    }

    await routeRef.update({
      'stops': updatedStops.map((s) => s.toMap()).toList(),
      'originalOrderIds': updatedStops.map((s) => s.orderId).toList(),
      'totalStops': updatedStops.length,
      'status': 'building',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Also link the order in orders collection
    if (stop.orderId.isNotEmpty) {
      try {
        await _firestore.collection('orders').doc(stop.orderId).set({
          'routeId': routeId,
          if (stop.riderId.isNotEmpty) 'riderId': stop.riderId,
          'status': 'Assigned',
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Updates an individual route stop (e.g. corrected address, notes, recipient).
  Future<void> updateRouteStop({
    required String routeId,
    required RouteStopModel stop,
  }) async {
    if (routeId.trim().isEmpty) return;

    final routeRef = _firestore.collection('routes').doc(routeId);
    final routeDoc = await routeRef.get();
    if (!routeDoc.exists || routeDoc.data() == null) return;

    final existingRoute = DeliveryRouteModel.fromFirestore(routeDoc);
    final updatedStops = existingRoute.stops.map((s) {
      return s.id == stop.id || s.orderId == stop.orderId ? stop : s;
    }).toList();

    await routeRef.update({
      'stops': updatedStops.map((s) => s.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Also update order document if notes/address changed
    if (stop.orderId.isNotEmpty) {
      try {
        await _firestore.collection('orders').doc(stop.orderId).set({
          'dropoffAddress': stop.address,
          if (stop.latitude != null) 'dropoffLat': stop.latitude,
          if (stop.longitude != null) 'dropoffLng': stop.longitude,
          if (stop.notes != null) 'notes': stop.notes,
          'customerName': stop.customerName,
          'customerPhone': stop.customerPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Removes an individual stop from the route.
  Future<void> removeStopFromRoute({
    required String routeId,
    required String orderId,
  }) async {
    if (routeId.trim().isEmpty) return;

    final routeRef = _firestore.collection('routes').doc(routeId);
    final routeDoc = await routeRef.get();
    if (!routeDoc.exists || routeDoc.data() == null) return;

    final existingRoute = DeliveryRouteModel.fromFirestore(routeDoc);
    final updatedStops = existingRoute.stops.where((s) => s.orderId != orderId).toList();

    // Re-sequence
    for (int i = 0; i < updatedStops.length; i++) {
      updatedStops[i] = updatedStops[i].copyWith(sequence: i + 1);
    }

    await routeRef.update({
      'stops': updatedStops.map((s) => s.toMap()).toList(),
      'originalOrderIds': updatedStops.map((s) => s.orderId).toList(),
      'totalStops': updatedStops.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Saves the confirmed optimized sequence and updates route status to 'active'.
  Future<void> saveOptimizedRoute({
    required String routeId,
    required List<RouteStopModel> orderedStops,
    required double totalDistanceMeters,
    required int totalDurationSeconds,
    required String riderId,
  }) async {
    if (routeId.trim().isEmpty) return;

    final routeRef = _firestore.collection('routes').doc(routeId);

    // Save reordered stops with updated sequence numbers
    final sequenced = <RouteStopModel>[];
    for (int i = 0; i < orderedStops.length; i++) {
      sequenced.add(orderedStops[i].copyWith(sequence: i + 1));
    }

    await routeRef.update({
      'stops': sequenced.map((s) => s.toMap()).toList(),
      'optimizedOrderIds': sequenced.map((s) => s.orderId).toList(),
      'totalDistanceMeters': totalDistanceMeters,
      'totalDurationSeconds': totalDurationSeconds,
      'status': 'active',
      'optimizedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Mark all orders as On the Way
    final batch = _firestore.batch();
    for (final stop in sequenced) {
      if (stop.orderId.isNotEmpty) {
        final ref = _firestore.collection('orders').doc(stop.orderId);
        batch.set(
          ref,
          {
            'status': 'On the Way',
            'routeId': routeId,
            'routeStartedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            if (riderId.isNotEmpty) 'riderId': riderId,
          },
          SetOptions(merge: true),
        );
      }
    }
    await batch.commit();
  }

  /// Marks a specific stop and order as Delivered.
  Future<void> markStopDelivered({
    required String? routeId,
    required String orderId,
    required String riderId,
    String? recipientName,
  }) async {
    if (orderId.trim().isEmpty) {
      throw Exception('Order ID is missing.');
    }

    final now = DateTime.now();

    // 1. Update Order in orders collection
    try {
      final updateData = <String, dynamic>{
        'status': 'Delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (recipientName != null && recipientName.trim().isNotEmpty) {
        updateData['recipientName'] = recipientName.trim();
      }
      if (riderId.trim().isNotEmpty) {
        updateData['riderId'] = riderId.trim();
      }

      await _firestore.collection('orders').doc(orderId).set(
            updateData,
            SetOptions(merge: true),
          );

      // Increment rider delivery counter
      if (riderId.trim().isNotEmpty) {
        final riderDoc = await _resolveRiderDoc(riderId);
        if (riderDoc != null) {
          final docId = riderDoc.id;
          final currentCount = riderDoc.data()?['deliveries'] as int? ?? 0;
          await _firestore.collection('riders').doc(docId).update({
            'deliveries': currentCount + 1,
            'currentOrder': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update order status in Firebase: $e');
    }

    // 2. Update Route document if routeId is provided
    if (routeId != null && routeId.trim().isNotEmpty) {
      try {
        final routeRef = _firestore.collection('routes').doc(routeId);
        final routeDoc = await routeRef.get();
        if (routeDoc.exists && routeDoc.data() != null) {
          final route = DeliveryRouteModel.fromFirestore(routeDoc);
          final updatedStops = route.stops.map((s) {
            if (s.orderId == orderId) {
              return s.copyWith(
                status: 'delivered',
                deliveredAt: now,
                recipientName: recipientName,
              );
            }
            return s;
          }).toList();

          final deliveredCount = updatedStops.where((s) => s.isDelivered).length;
          final isCompleted = updatedStops.every((s) => !s.isPending);

          await routeRef.update({
            'stops': updatedStops.map((s) => s.toMap()).toList(),
            'deliveredCount': deliveredCount,
            if (isCompleted) 'status': 'completed',
            if (isCompleted) 'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
    }
  }

  /// Marks a specific stop and order as Failed.
  Future<void> markStopFailed({
    required String? routeId,
    required String orderId,
    required String riderId,
    required String reason,
    String? note,
  }) async {
    if (orderId.trim().isEmpty) {
      throw Exception('Order ID is missing.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Failure reason is required.');
    }

    final now = DateTime.now();

    // 1. Update Order in orders collection
    try {
      final updateData = <String, dynamic>{
        'status': 'Failed',
        'failureReason': reason.trim(),
        'failedAt': FieldValue.serverTimestamp(),
        'returnStatus': 'Pending Return to Pharmacy',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (note != null && note.trim().isNotEmpty) {
        updateData['failureNote'] = note.trim();
      }
      if (riderId.trim().isNotEmpty) {
        updateData['riderId'] = riderId.trim();
      }

      await _firestore.collection('orders').doc(orderId).set(
            updateData,
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to record delivery failure in Firebase: $e');
    }

    // 2. Update Route document if routeId is provided
    if (routeId != null && routeId.trim().isNotEmpty) {
      try {
        final routeRef = _firestore.collection('routes').doc(routeId);
        final routeDoc = await routeRef.get();
        if (routeDoc.exists && routeDoc.data() != null) {
          final route = DeliveryRouteModel.fromFirestore(routeDoc);
          final updatedStops = route.stops.map((s) {
            if (s.orderId == orderId) {
              return s.copyWith(
                status: 'failed',
                failureReason: reason.trim(),
                failureNote: note?.trim(),
                failedAt: now,
              );
            }
            return s;
          }).toList();

          final failedCount = updatedStops.where((s) => s.isFailed).length;
          final isCompleted = updatedStops.every((s) => !s.isPending);

          await routeRef.update({
            'stops': updatedStops.map((s) => s.toMap()).toList(),
            'failedCount': failedCount,
            if (isCompleted) 'status': 'completed',
            if (isCompleted) 'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
    }
  }

  /// Undoes a recently processed stop status, restoring it to 'pending'.
  Future<void> undoStopStatus({
    required String? routeId,
    required String orderId,
    required String riderId,
  }) async {
    if (orderId.trim().isEmpty) return;

    try {
      await _firestore.collection('orders').doc(orderId).set({
        'status': 'On the Way',
        'failureReason': null,
        'failureNote': null,
        'deliveredAt': null,
        'failedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    if (routeId != null && routeId.trim().isNotEmpty) {
      try {
        final routeRef = _firestore.collection('routes').doc(routeId);
        final routeDoc = await routeRef.get();
        if (routeDoc.exists && routeDoc.data() != null) {
          final route = DeliveryRouteModel.fromFirestore(routeDoc);
          final updatedStops = route.stops.map((s) {
            if (s.orderId == orderId) {
              return s.copyWith(
                status: 'pending',
                failureReason: null,
                failureNote: null,
                deliveredAt: null,
                failedAt: null,
              );
            }
            return s;
          }).toList();

          final deliveredCount = updatedStops.where((s) => s.isDelivered).length;
          final failedCount = updatedStops.where((s) => s.isFailed).length;

          await routeRef.update({
            'stops': updatedStops.map((s) => s.toMap()).toList(),
            'deliveredCount': deliveredCount,
            'failedCount': failedCount,
            'status': 'active',
            'completedAt': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
    }
  }

  /// Marks a route completely finished in Firestore and calculates final stats.
  Future<void> completeRoute({
    required String routeId,
  }) async {
    if (routeId.trim().isEmpty) return;

    try {
      final routeRef = _firestore.collection('routes').doc(routeId);
      final routeDoc = await routeRef.get();
      if (!routeDoc.exists || routeDoc.data() == null) return;

      final route = DeliveryRouteModel.fromFirestore(routeDoc);
      final deliveredCount = route.stops.where((s) => s.isDelivered).length;
      final failedCount = route.stops.where((s) => s.isFailed).length;

      await routeRef.update({
        'status': 'completed',
        'deliveredCount': deliveredCount,
        'failedCount': failedCount,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Retrieves completed routes for history view.
  Future<List<DeliveryRouteModel>> getRiderCompletedRoutes(String riderId) async {
    if (riderId.trim().isEmpty) return [];

    try {
      final query = await _firestore
          .collection('routes')
          .where('riderId', isEqualTo: riderId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(20)
          .get();

      return query.docs.map((d) => DeliveryRouteModel.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // SCANNING & ADDRESS RESOLUTION (PHASE 4, 5, 9)
  // ============================================================

  /// Looks up an order by QR / Barcode, parsing JSON or querying candidate order keys.
  Future<OrderModel> lookupOrderByQr({
    required String qrValue,
    String? currentRiderId,
    String? currentPharmacyId,
  }) async {
    final clean = qrValue.trim();
    if (clean.isEmpty) {
      throw Exception('Scanned code is empty.');
    }

    // 1. If scanned code is structured JSON, parse it
    if (clean.startsWith('{') && clean.endsWith('}')) {
      try {
        final decoded = json.decode(clean) as Map<String, dynamic>;
        final orderId = decoded['orderId'] ?? decoded['id'] ?? '';
        if (orderId.toString().isNotEmpty) {
          final lookedUp = await _findOrderInFirestore(orderId.toString());
          if (lookedUp != null) {
            return lookedUp;
          }
          // If not found in Firestore, create order model from JSON metadata
          return _buildOrderFromJsonPayload(decoded);
        }
      } catch (_) {}
    }

    // 2. Look up via candidate keys in Firestore
    final candidates = _extractCandidateIds(clean);

    DocumentSnapshot<Map<String, dynamic>>? matchedDoc;

    for (final id in candidates) {
      final doc = await _firestore.collection('orders').doc(id).get();
      if (doc.exists && doc.data() != null) {
        matchedDoc = doc;
        break;
      }
    }

    if (matchedDoc == null) {
      for (final id in candidates) {
        final query = await _firestore
            .collection('orders')
            .where('orderId', isEqualTo: id)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          matchedDoc = query.docs.first;
          break;
        }
      }
    }

    if (matchedDoc == null) {
      for (final id in candidates) {
        final query = await _firestore
            .collection('orders')
            .where('id', isEqualTo: id)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          matchedDoc = query.docs.first;
          break;
        }
      }
    }

    if (matchedDoc == null) {
      final qrQuery = await _firestore
          .collection('orders')
          .where('pickupQrValue', isEqualTo: clean)
          .limit(1)
          .get();
      if (qrQuery.docs.isNotEmpty) {
        matchedDoc = qrQuery.docs.first;
      }
    }

    if (matchedDoc == null) {
      final qrQuery2 = await _firestore
          .collection('orders')
          .where('qrCode', isEqualTo: clean)
          .limit(1)
          .get();
      if (qrQuery2.docs.isNotEmpty) {
        matchedDoc = qrQuery2.docs.first;
      }
    }

    if (matchedDoc == null || !matchedDoc.exists || matchedDoc.data() == null) {
      throw Exception('Delivery not found. Code "$clean" is not recognized.');
    }

    var order = OrderModel.fromFirestore(matchedDoc);

    // Validate: Already delivered
    if (order.isCompleted) {
      throw Exception('Order #${order.id} has already been delivered.');
    }

    // Resolve coordinates if missing on order
    if (!order.hasDropoffCoordinates && order.dropoffAddress.isNotEmpty) {
      final geocoded = await geocodeAddress(order.dropoffAddress);
      if (geocoded != null) {
        order = order.copyWith(
          dropoffLat: geocoded.latitude,
          dropoffLng: geocoded.longitude,
        );
      }
    }

    return order;
  }

  Future<OrderModel?> _findOrderInFirestore(String id) async {
    final doc = await _firestore.collection('orders').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return OrderModel.fromFirestore(doc);
    }
    return null;
  }

  OrderModel _buildOrderFromJsonPayload(Map<String, dynamic> json) {
    final id = json['orderId'] ?? json['id'] ?? 'PKG-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final customer = json['customerName'] ?? json['customer'] ?? 'Customer';
    final phone = json['customerPhone'] ?? json['phone'] ?? '';
    final address = json['dropoffAddress'] ?? json['address'] ?? '';
    final lat = (json['latitude'] ?? json['lat'] as num?)?.toDouble();
    final lng = (json['longitude'] ?? json['lng'] as num?)?.toDouble();

    return OrderModel(
      id: id.toString(),
      pharmacyId: json['pharmacyId'] ?? '',
      pharmacyName: json['pharmacyName'] ?? 'Pharmacy',
      customerName: customer.toString(),
      customerPhone: phone.toString(),
      pickupAddress: '',
      dropoffAddress: address.toString(),
      status: 'Ready',
      dropoffLat: lat,
      dropoffLng: lng,
      notes: json['notes']?.toString(),
      coldChain: json['coldChain'] as bool? ?? false,
      controlledDrug: json['controlledDrug'] as bool? ?? false,
    );
  }

  List<String> _extractCandidateIds(String raw) {
    final candidates = <String>{raw};

    if (raw.startsWith('#ORD-')) {
      candidates.add(raw.substring(5));
      candidates.add(raw.substring(1));
    } else if (raw.startsWith('ORD-')) {
      candidates.add(raw.substring(4));
      candidates.add('#$raw');
    } else if (raw.startsWith('#')) {
      candidates.add(raw.substring(1));
      candidates.add('ORD-${raw.substring(1)}');
      candidates.add('#ORD-${raw.substring(1)}');
    } else {
      candidates.add('#$raw');
      candidates.add('ORD-$raw');
      candidates.add('#ORD-$raw');
    }

    return candidates.toList();
  }

  /// Geocodes address string to LatLng using geocoding package.
  Future<LatLng?> geocodeAddress(String address) async {
    final clean = address.trim();
    if (clean.isEmpty) return null;

    try {
      final locations = await geo.locationFromAddress(clean);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (_) {
      // Gracefully handle geocoding lookup failures
    }
    return null;
  }

  /// Resolves pharmacy information from Firestore.
  Future<Map<String, dynamic>?> fetchPharmacy(String pharmacyId) async {
    if (pharmacyId.trim().isEmpty) return null;

    try {
      final doc = await _firestore.collection('pharmacies').doc(pharmacyId).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      final location = data['location'];
      double? lat;
      double? lng;

      if (location is GeoPoint) {
        lat = location.latitude;
        lng = location.longitude;
      } else if (location is Map) {
        lat = (location['lat'] ?? location['latitude'] as num?)?.toDouble();
        lng = (location['lng'] ?? location['longitude'] as num?)?.toDouble();
      }

      return {
        'id': doc.id,
        'name': data['pharmacyName'] ?? data['name'] ?? 'Pharmacy',
        'address': data['businessAddress'] ?? data['address'] ?? '',
        'phone': data['phone'] ?? '',
        'latitude': lat,
        'longitude': lng,
      };
    } catch (_) {
      return null;
    }
  }

  /// Sets all batch orders as 'On the Way' when the route is started.
  Future<void> startRouteForOrders({
    required List<String> orderIds,
    required String riderId,
  }) async {
    final batch = _firestore.batch();
    for (final id in orderIds) {
      final ref = _firestore.collection('orders').doc(id);
      batch.set(
        ref,
        {
          'status': 'On the Way',
          'routeStartedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          if (riderId.isNotEmpty) 'riderId': riderId,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveRiderDoc(String riderId) async {
    final directDoc = await _firestore.collection('riders').doc(riderId).get();
    if (directDoc.exists) return directDoc;

    final uidQuery = await _firestore
        .collection('riders')
        .where('uid', isEqualTo: riderId)
        .limit(1)
        .get();
    if (uidQuery.docs.isNotEmpty) return uidQuery.docs.first;

    final idQuery = await _firestore
        .collection('riders')
        .where('id', isEqualTo: riderId)
        .limit(1)
        .get();
    if (idQuery.docs.isNotEmpty) return idQuery.docs.first;

    return null;
  }
}

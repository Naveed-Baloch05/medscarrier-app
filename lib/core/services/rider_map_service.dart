import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/order_model.dart';
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
    if (minutes != null && minutes > 0) return '$minutes min';
    return '—';
  }

  bool get hasOrder =>
      order.id.trim().isNotEmpty && !order.isCompleted;

  bool get isArrived => arrivedAt != null;
}

class RiderMapService {
  RiderMapService._();
  static final RiderMapService instance = RiderMapService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RiderDeliveryDetailsService _details = RiderDeliveryDetailsService.instance;

  /// Resolves the rider's currently assigned (active) order. If the rider has
  /// a [currentOrder] that belongs to them and is active, that wins; otherwise
  /// the most recently assigned active order is used.
  Future<OrderModel?> getActiveOrder(String riderId) async {
    if (riderId.trim().isEmpty) return null;

    final riderDoc = await _resolveRiderDoc(riderId);
    if (riderDoc == null) return null;

    final data = riderDoc.data() ?? const <String, dynamic>{};
    final currentOrderId = (data['currentOrder'] as String?)?.trim();

    final snapshot = await _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .get();

    final orders = snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();

    if (orders.isEmpty) return null;

    if (currentOrderId != null && currentOrderId.isNotEmpty) {
      final match = orders.where((o) => o.id == currentOrderId).toList();
      if (match.isNotEmpty && match.first.isActive) return match.first;
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

  /// Real-time stream of the rider's map session. Emits whenever the active
  /// order, its status, or the rider's location changes. When no active order
  /// exists, emits [RiderMapSession] with an empty order.
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

      OrderModel order =
          orders.firstWhere((o) => o.isActive, orElse: () => OrderModel.noOp());
      if (order.id.isEmpty && orders.isNotEmpty) {
        order = orders.first;
      }

      return _buildSession(order, riderId);
    });
  }

  /// Real-time stream for a specific order id. Emits whenever that order or
  /// the assigned rider's location changes.
  Stream<RiderMapSession> orderSessionStream(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) {
        return RiderMapSession(order: OrderModel.noOp());
      }
      final order = OrderModel.fromFirestore(doc);
      final riderId = order.riderId ?? '';
      return _buildSession(order, riderId);
    });
  }

  Future<RiderMapSession> _buildSession(OrderModel order, String riderId) async {
    if (order.id.isEmpty) {
      return RiderMapSession(order: order);
    }

    final orderDoc =
        await _firestore.collection('orders').doc(order.id).get();
    final orderData = orderDoc.data() ?? const <String, dynamic>{};

    final pharmacy = await _resolvePharmacy(order.pharmacyId);
    final coords = _extractOrderCoords(orderData);

    final riderDoc = await _resolveRiderDoc(riderId);
    final riderData = riderDoc?.data() ?? const <String, dynamic>{};
    final riderLocation = _extractLocation(riderData['location']);
    final riderName = ((riderData['fullName'] ?? riderData['name'] ?? '')
            .toString())
        .trim();

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
      riderId: riderName.isEmpty ? null : riderId,
      riderName: riderName,
      riderLat: riderLocation['lat'],
      riderLng: riderLocation['lng'],
      arrivedAt: _parseDate(orderData['arrivedAt']),
      pickupQrValue: orderData['pickupQrValue'] as String?,
    );
  }

  Future<Map<String, dynamic>?> _resolvePharmacy(String pharmacyId) async {
    if (pharmacyId.trim().isEmpty) return null;
    final doc = await _firestore.collection('pharmacies').doc(pharmacyId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    final location = _extractLocation(data['location']);
    return {
      'name': (data['pharmacyName'] ?? data['name'] ?? '').toString(),
      'address':
          (data['businessAddress'] ?? data['address'] ?? '').toString(),
      'latitude': location['lat'],
      'longitude': location['lng'],
    };
  }

  Map<String, dynamic> _extractOrderCoords(Map<String, dynamic> data) {
    final orderLocation = _extractLocation(data['dropoffLocation']);
    return {
      'pickupLat': _asDouble(data['pickupLat'] ??
          _extractLocation(data['pickupLocation'])['lat']),
      'pickupLng': _asDouble(data['pickupLng'] ??
          _extractLocation(data['pickupLocation'])['lng']),
      'dropoffLat': _asDouble(
          data['dropoffLat'] ?? orderLocation['lat'] ?? data['customerLat']),
      'dropoffLng': _asDouble(
          data['dropoffLng'] ?? orderLocation['lng'] ?? data['customerLng']),
    };
  }

  Map<String, dynamic> _extractLocation(dynamic location) {
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

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveRiderDoc(
      String riderId) async {
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

  /// Records the rider's arrival at the customer. Uses an [arrivedAt]
  /// timestamp on the order document, keeping the existing status system intact.
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

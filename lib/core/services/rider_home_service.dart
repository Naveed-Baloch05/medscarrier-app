import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/order_model.dart';
import '../../models/rider_model.dart';

class RiderHomeService {
  RiderHomeService._();
  static final RiderHomeService instance = RiderHomeService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RiderModel?> getRiderProfile(String riderId) async {
    if (riderId.trim().isEmpty) return null;
    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;

      final directDoc =
          await _firestore.collection('riders').doc(riderId).get();
      if (directDoc.exists && directDoc.data() != null) {
        doc = directDoc;
      }

      if (doc == null) {
        final uidQuery = await _firestore
            .collection('riders')
            .where('uid', isEqualTo: riderId)
            .limit(1)
            .get();
        if (uidQuery.docs.isNotEmpty) {
          doc = uidQuery.docs.first;
        }
      }

      if (doc == null) {
        final idQuery = await _firestore
            .collection('riders')
            .where('id', isEqualTo: riderId)
            .limit(1)
            .get();
        if (idQuery.docs.isNotEmpty) {
          doc = idQuery.docs.first;
        }
      }

      if (doc == null || !doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      final resolvedId = (data['id'] as String?)?.isNotEmpty == true
          ? (data['id'] as String)
          : ((data['uid'] as String?)?.isNotEmpty == true
              ? (data['uid'] as String)
              : (doc.id.isNotEmpty ? doc.id : riderId));

      return RiderModel(
        id: resolvedId,
        fullName: data['fullName'] as String? ?? data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        vehicleType: data['vehicleType'] as String? ?? '',
        vehicleReg: data['vehicleReg'] as String? ??
            data['vehicleRegistrationNumber'] as String? ??
            '',
        online: data['online'] as bool? ?? false,
        active: data['active'] as bool? ?? true,
        location: data['location'] is Map
            ? Map<String, dynamic>.from(data['location'] as Map)
            : null,
        deliveries: data['deliveries'] as int? ?? 0,
        currentOrder: data['currentOrder'] as String?,
        lastSeen: _parseTimestamp(data['lastSeen']),
        deliveryStatus: data['deliveryStatus'] as String?,
        createdAt: _parseTimestamp(data['createdAt']),
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<OrderModel>> getRiderOrders(String riderId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<RiderModel?> riderProfileStream(String riderId) {
    return _firestore.collection('riders').doc(riderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      return RiderModel(
        id: doc.id,
        fullName:
            data['fullName'] as String? ?? data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        vehicleType: data['vehicleType'] as String? ?? '',
        vehicleReg:
            data['vehicleReg'] as String? ??
            data['vehicleRegistrationNumber'] as String? ??
            '',
        online: data['online'] as bool? ?? false,
        active: data['active'] as bool? ?? true,
        location: data['location'] is Map
            ? Map<String, dynamic>.from(data['location'] as Map)
            : null,
        deliveries: data['deliveries'] as int? ?? 0,
        currentOrder: data['currentOrder'] as String?,
        lastSeen: _parseTimestamp(data['lastSeen']),
        deliveryStatus: data['deliveryStatus'] as String?,
        createdAt: _parseTimestamp(data['createdAt']),
      );
    });
  }

  Stream<List<OrderModel>> riderOrdersStream(String riderId) {
    return _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> toggleOnlineStatus(String riderId, bool isOnline) async {
    try {
      await _firestore.collection('riders').doc(riderId).update({
        'online': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update online status: $e');
    }
  }

  Future<void> updateDeliveryConfirmation({
    required String orderId,
    required bool cdConfirmed,
    required bool coldChainConfirmed,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'cdConfirmedByRider': cdConfirmed,
        'coldChainConfirmedByRider': coldChainConfirmed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update delivery confirmation: $e');
    }
  }

  Future<void> markOrderPickedUp(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Picked Up',
        'pickedUpAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark order as picked up: $e');
    }
  }

  Future<void> markOrderOnTheWay(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'On the Way',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> markOrderDelivered(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final riderId = orderDoc.data()?['riderId'] as String?;
        if (riderId != null && riderId.isNotEmpty) {
          final riderDoc =
              await _firestore.collection('riders').doc(riderId).get();
          if (riderDoc.exists) {
            final currentCount = riderDoc.data()?['deliveries'] as int? ?? 0;
            await _firestore.collection('riders').doc(riderId).update({
              'deliveries': currentCount + 1,
              'currentOrder': null,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to mark order as delivered: $e');
    }
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/order_model.dart';

class RiderDeliveriesService {
  RiderDeliveriesService._();
  static final RiderDeliveriesService instance = RiderDeliveriesService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<OrderModel>> getRiderOrders(String riderId) async {
    if (riderId.trim().isEmpty) return [];

    final riderDoc = await _resolveRiderDoc(riderId);
    if (riderDoc == null) return [];

    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .get();

    final orders = ordersSnapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();

    orders.sort((a, b) {
      final aTime = a.assignedAt ?? a.createdAt ?? DateTime(0);
      final bTime = b.assignedAt ?? b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    return orders;
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

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveRiderDoc(
      String riderId) async {
    final directDoc =
        await _firestore.collection('riders').doc(riderId).get();
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

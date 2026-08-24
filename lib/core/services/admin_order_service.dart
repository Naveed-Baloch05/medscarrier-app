import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrderService {
  AdminOrderService._();
  static final AdminOrderService instance = AdminOrderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> _activeStatuses = [
    'Assigned',
    'Collecting',
    'Picked Up',
    'On the Way',
  ];

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _riders =>
      _firestore.collection('riders');

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final snapshot =
          await _orders.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    try {
      final snapshot = await _orders
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  Future<void> assignOrder(String orderId, String riderId) async {
    try {
      await _orders.doc(orderId).update({
        'riderId': riderId,
        'status': 'Assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign order: $e');
    }
  }

  Future<void> autoAssignOrder(String orderId) async {
    try {
      final ridersSnapshot = await _riders
          .where('online', isEqualTo: true)
          .where('active', isEqualTo: true)
          .get();

      final candidates = ridersSnapshot.docs.toList();
      if (candidates.isEmpty) {
        throw Exception('No online active riders available');
      }

      String? bestRiderId;
      int bestLoad = 0;

      for (final riderDoc in candidates) {
        final riderOrders =
            await _orders.where('riderId', isEqualTo: riderDoc.id).get();
        final load = riderOrders.docs
            .where((doc) => _activeStatuses.contains(doc.data()['status']))
            .length;

        if (bestRiderId == null || load < bestLoad) {
          bestRiderId = riderDoc.id;
          bestLoad = load;
        }
      }

      if (bestRiderId == null) {
        throw Exception('No suitable rider found for assignment');
      }

      await assignOrder(orderId, bestRiderId);
    } catch (e) {
      throw Exception('Failed to auto-assign order: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _orders.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _orders.doc(orderId).update({
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> ordersStream() {
    return _orders.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList(),
        );
  }
}

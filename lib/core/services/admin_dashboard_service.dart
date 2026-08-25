import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';

class AdminDashboardService {
  AdminDashboardService._();
  static final AdminDashboardService instance = AdminDashboardService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pharmacies =>
      _firestore.collection('pharmacies');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _riders =>
      _firestore.collection('riders');

  Future<Map<String, int>> fetchDashboardData() async {
    try {
      final results = await Future.wait([
        _firestore.collection('orders').count().get(),
        _getActiveOrderCount(),
        _getCompletedOrderCount(),
        _getAverageDeliveryTimeMinutes(),
        _firestore.collection('riders').count().get(),
        _getOnlineRiderCount(),
        _getActiveRiderCount(),
        _firestore.collection('pharmacies').count().get(),
        _getPendingPharmacyCount(),
        _getActivePharmacyCount(),
      ]);

      return {
        'totalOrders': (results[0] as AggregateQuerySnapshot).count ?? 0,
        'activeOrders': results[1] as int,
        'completedOrders': results[2] as int,
        'avgDeliveryTime': results[3] as int,
        'totalRiders': (results[4] as AggregateQuerySnapshot).count ?? 0,
        'onlineRiders': results[5] as int,
        'activeRiders': results[6] as int,
        'totalPharmacies': (results[7] as AggregateQuerySnapshot).count ?? 0,
        'pendingPharmacies': results[8] as int,
        'activePharmacies': results[9] as int,
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }

  Future<List<PharmacyModel>> fetchPendingPharmacies() async {
    try {
      final snapshot = await _pharmacies
          .where('status', isEqualTo: 'Pending')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return PharmacyModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending pharmacies: $e');
    }
  }

  Future<List<OrderModel>> fetchReadyOrders() async {
    try {
      final snapshot = await _orders
          .where('status', isEqualTo: 'Ready')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      return snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch ready orders: $e');
    }
  }

  Future<List<OrderModel>> fetchActiveOrders() async {
    try {
      final snapshot = await _orders
          .where('status', whereIn: ['Assigned', 'Collecting', 'Picked Up', 'On the Way'])
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      return snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch active orders: $e');
    }
  }

  Future<void> approvePharmacy(String pharmacyId) async {
    await _pharmacies.doc(pharmacyId).update({
      'status': 'Approved',
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectPharmacy(String pharmacyId) async {
    await _pharmacies.doc(pharmacyId).update({
      'status': 'Rejected',
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignOrder(String orderId, String riderId) async {
    await _orders.doc(orderId).update({
      'riderId': riderId,
      'status': 'Assigned',
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> autoAssignOrder(String orderId) async {
    final ridersSnapshot = await _riders
        .where('online', isEqualTo: true)
        .where('active', isEqualTo: true)
        .get();

    final candidates = ridersSnapshot.docs.toList();
    if (candidates.isEmpty) {
      throw Exception('No online active riders available');
    }

    final activeStatuses = ['Assigned', 'Collecting', 'Picked Up', 'On the Way'];
    String? bestRiderId;
    int bestLoad = 999;

    for (final riderDoc in candidates) {
      final riderOrders = await _orders
          .where('riderId', isEqualTo: riderDoc.id)
          .get();
      final load = riderOrders.docs
          .where((doc) => activeStatuses.contains(doc.data()['status']))
          .length;

      if (load < bestLoad) {
        bestRiderId = riderDoc.id;
        bestLoad = load;
      }
    }

    if (bestRiderId == null) {
      throw Exception('No suitable rider found for assignment');
    }

    await assignOrder(orderId, bestRiderId);
  }

  Future<int> _getActiveOrderCount() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', whereIn: [
          'Assigned',
          'Collecting',
          'Picked Up',
          'On the Way',
        ])
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getCompletedOrderCount() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Delivered')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getAverageDeliveryTimeMinutes() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Delivered')
        .where('deliveryTimeMinutes', isGreaterThan: 0)
        .orderBy('deliveryTimeMinutes')
        .limit(100)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    int total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['deliveryTimeMinutes'] as int?) ?? 0;
    }
    return total ~/ snapshot.docs.length;
  }

  Future<int> _getOnlineRiderCount() async {
    final snapshot = await _firestore
        .collection('riders')
        .where('online', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getActiveRiderCount() async {
    final snapshot = await _firestore
        .collection('riders')
        .where('active', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getPendingPharmacyCount() async {
    final snapshot = await _firestore
        .collection('pharmacies')
        .where('status', isEqualTo: 'Pending')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getActivePharmacyCount() async {
    final snapshot = await _firestore
        .collection('pharmacies')
        .where('active', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRiderService {
  AdminRiderService._();
  static final AdminRiderService instance = AdminRiderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _riders =>
      _firestore.collection('riders');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Future<List<Map<String, dynamic>>> getAllRiders() async {
    try {
      final snapshot = await _riders.get();
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch riders: $e');
    }
  }

  Future<void> addRider(Map<String, dynamic> riderData) async {
    try {
      final docRef = _riders.doc();
      await docRef.set({
        ...riderData,
        'id': docRef.id,
        'active': riderData['active'] ?? true,
        'online': riderData['online'] ?? false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add rider: $e');
    }
  }

  Future<void> updateRider(String riderId, Map<String, dynamic> data) async {
    try {
      await _riders.doc(riderId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update rider: $e');
    }
  }

  Future<void> activateRider(String riderId) => _setActive(riderId, true);

  Future<void> deactivateRider(String riderId) => _setActive(riderId, false);

  Future<void> assignOrderToRider(String riderId, String orderId) async {
    try {
      await _orders.doc(orderId).update({
        'riderId': riderId,
        'status': 'Assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign order to rider: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> ridersStream() {
    return _riders.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> onlineRidersStream() {
    return _riders.where('online', isEqualTo: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList(),
        );
  }

  Future<void> _setActive(String riderId, bool active) async {
    try {
      await _riders.doc(riderId).update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update rider state: $e');
    }
  }
}

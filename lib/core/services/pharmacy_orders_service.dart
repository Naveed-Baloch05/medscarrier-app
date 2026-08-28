import 'package:cloud_firestore/cloud_firestore.dart';

import '../../bloc/pharmacy_orders/pharmacy_orders_state.dart';

class PharmacyOrdersService {
  PharmacyOrdersService._();
  static final PharmacyOrdersService instance = PharmacyOrdersService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(dt.year, dt.month, dt.day);

    final h12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final time =
        '${h12.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')} '
        '${dt.hour >= 12 ? 'PM' : 'AM'}';

    if (orderDate == today) return time;
    if (orderDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.day}/${dt.month}/$time';
  }

  PharmacyOrder _mapOrder(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final createdAt = data['createdAt'];

    DateTime? createdDt;
    if (createdAt is Timestamp) {
      createdDt = createdAt.toDate();
    } else if (createdAt is DateTime) {
      createdDt = createdAt;
    }

    final docId = doc.id;
    final orderId = docId.startsWith('#') ? docId : '#ORD-$docId';

    return PharmacyOrder(
      id: orderId,
      customerName: data['customerName'] as String? ?? '',
      medicineCount: items.isNotEmpty ? items.length : (data['medicineCount'] as int? ?? 0),
      time: _formatTime(createdDt),
      status: data['status'] as String? ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      items: items,
      riderName: data['riderName'] as String? ?? '',
      riderPhone: data['riderPhone'] as String? ?? '',
    );
  }

  String _docIdFromOrder(String orderId) {
    return orderId.startsWith('#ORD-') ? orderId.substring(5) : orderId;
  }

  Future<List<PharmacyOrder>> getOrders(String pharmacyId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    final orders = snapshot.docs.map(_mapOrder).toList();

    orders.sort((a, b) {
      final aStatus = a.status.toLowerCase();
      final bStatus = b.status.toLowerCase();
      const statusOrder = {
        'new': 0,
        'preparing': 1,
        'ready': 2,
        'assigned': 3,
        'picked up': 4,
        'on the way': 5,
        'delivered': 6,
        'completed': 7,
      };
      final aIdx = statusOrder[aStatus] ?? 99;
      final bIdx = statusOrder[bStatus] ?? 99;
      return aIdx.compareTo(bIdx);
    });

    return orders;
  }

  Future<PharmacyOrder> addOrder({
    required String pharmacyId,
    required String customerName,
    required int medicineCount,
    required String status,
    required double totalAmount,
  }) async {
    final docRef = await _firestore.collection('orders').add({
      'pharmacyId': pharmacyId,
      'customerName': customerName,
      'medicineCount': medicineCount,
      'status': status,
      'totalAmount': totalAmount,
      'items': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return _mapOrder(doc);
  }

  Future<void> updateOrder({
    required String id,
    required String customerName,
    required int medicineCount,
    required String status,
    required double totalAmount,
  }) async {
    final docId = _docIdFromOrder(id);
    await _firestore.collection('orders').doc(docId).update({
      'customerName': customerName,
      'medicineCount': medicineCount,
      'status': status,
      'totalAmount': totalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOrder(String id) async {
    final docId = _docIdFromOrder(id);
    await _firestore.collection('orders').doc(docId).delete();
  }

  Future<void> updateOrderStatus({
    required String id,
    required String newStatus,
    String riderName = '',
    String riderPhone = '',
  }) async {
    final docId = _docIdFromOrder(id);

    final updateData = <String, dynamic>{
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (riderName.isNotEmpty) updateData['riderName'] = riderName;
    if (riderPhone.isNotEmpty) updateData['riderPhone'] = riderPhone;

    if (newStatus.toLowerCase() == 'delivered') {
      updateData['deliveredAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('orders').doc(docId).update(updateData);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../bloc/pharmacy_orders/pharmacy_orders_state.dart';

class PharmacyOrdersService {
  PharmacyOrdersService._();

  static final PharmacyOrdersService instance = PharmacyOrdersService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // ==============================================================
  // CURRENT PHARMACY ID
  // ==============================================================

  String _getPharmacyId(String pharmacyId) {
    if (pharmacyId.trim().isNotEmpty) {
      return pharmacyId.trim();
    }

    final user = _auth.currentUser;

    if (user == null) {
      return '';
    }

    return user.uid;
  }

  // ==============================================================
  // FORMAT TIME
  // ==============================================================

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final orderDate = DateTime(
      dt.year,
      dt.month,
      dt.day,
    );

    final h12 = dt.hour == 0
        ? 12
        : (dt.hour > 12 ? dt.hour - 12 : dt.hour);

    final time =
        '${h12.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')} '
        '${dt.hour >= 12 ? 'PM' : 'AM'}';

    if (orderDate == today) {
      return time;
    }

    if (orderDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return '${dt.day}/${dt.month}/$time';
  }

  // ==============================================================
  // TIMESTAMP PARSER
  // ==============================================================

  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ==============================================================
  // MAP FIRESTORE ORDER -> PHARMACY ORDER
  // ==============================================================

  PharmacyOrder _mapOrder(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rawItems = data['items'];

    final items = rawItems is List
        ? rawItems.map((item) => item.toString()).toList()
        : <String>[];

    final createdAt = _parseDateTime(data['createdAt']);
    final assignedAt = _parseDateTime(data['assignedAt']);
    final deliveredAt = _parseDateTime(data['deliveredAt']);
    final failedAt = _parseDateTime(data['failedAt']);

    final rawMedicineCount = data['medicineCount'];

    int medicineCount;

    if (rawMedicineCount is num) {
      medicineCount = rawMedicineCount.toInt();
    } else if (items.isNotEmpty) {
      medicineCount = items.length;
    } else {
      medicineCount = 0;
    }

    final docId = doc.id;

    final orderId = docId.startsWith('#')
        ? docId
        : '#ORD-$docId';

    final dropoffLocation = data['dropoffLocation'];
    double? dropoffLat = (data['dropoffLat'] ?? data['latitude'] as num?)?.toDouble();
    double? dropoffLng = (data['dropoffLng'] ?? data['longitude'] as num?)?.toDouble();
    if (dropoffLat == null && dropoffLocation is Map) {
      dropoffLat = (dropoffLocation['lat'] ?? dropoffLocation['latitude'] as num?)?.toDouble();
      dropoffLng = (dropoffLocation['lng'] ?? dropoffLocation['longitude'] as num?)?.toDouble();
    }

    return PharmacyOrder(
      id: orderId,
      rawId: docId,
      customerName: data['customerName']?.toString() ?? '',
      customerPhone: data['customerPhone']?.toString() ?? '',
      deliveryAddress: (data['dropoffAddress'] ?? data['deliveryAddress'])?.toString() ?? '',
      medicineCount: medicineCount,
      time: _formatTime(createdAt),
      status: data['status']?.toString() ?? 'New',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      items: items,
      riderId: data['riderId']?.toString() ?? '',
      riderName: data['riderName']?.toString() ?? '',
      riderPhone: data['riderPhone']?.toString() ?? '',
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      failureReason: data['failureReason']?.toString(),
      failureNote: data['failureNote']?.toString(),
      assignedAt: assignedAt,
      deliveredAt: deliveredAt,
      failedAt: failedAt,
      controlledDrug: data['controlledDrug'] as bool? ?? false,
      coldChain: data['coldChain'] as bool? ?? false,
    );
  }

  // ==============================================================
  // CONVERT DISPLAY ORDER ID -> FIRESTORE DOCUMENT ID
  // ==============================================================

  String _docIdFromOrder(String orderId) {
    final cleaned = orderId.trim();

    if (cleaned.startsWith('#ORD-')) {
      return cleaned.substring(5);
    }

    if (cleaned.startsWith('#')) {
      return cleaned.substring(1);
    }

    return cleaned;
  }

  // ==============================================================
  // GET PHARMACY ORDERS (ONE-SHOT)
  // ==============================================================

  Future<List<PharmacyOrder>> getOrders(String pharmacyId) async {
    final currentPharmacyId = _getPharmacyId(pharmacyId);
    if (currentPharmacyId.isEmpty) return [];

    final snapshot = await _firestore
        .collection('orders')
        .where(
      'pharmacyId',
      isEqualTo: currentPharmacyId,
    )
        .get();

    final orders = snapshot.docs
        .map(_mapOrder)
        .toList();

    _sortOrders(orders);
    return orders;
  }

  // ==============================================================
  // REAL-TIME PHARMACY ORDERS STREAM
  // ==============================================================

  Stream<List<PharmacyOrder>> pharmacyOrdersStream(String pharmacyId) {
    final currentPharmacyId = _getPharmacyId(pharmacyId);
    if (currentPharmacyId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('pharmacyId', isEqualTo: currentPharmacyId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(_mapOrder).toList();
      _sortOrders(orders);
      return orders;
    });
  }

  void _sortOrders(List<PharmacyOrder> orders) {
    const statusOrder = {
      'new': 0,
      'preparing': 1,
      'ready': 2,
      'assigned': 3,
      'picked up': 4,
      'on the way': 5,
      'arrived': 6,
      'out for delivery': 7,
      'delivered': 8,
      'completed': 9,
      'failed': 10,
    };

    orders.sort((a, b) {
      final aIndex =
          statusOrder[a.status.toLowerCase()] ?? 99;

      final bIndex =
          statusOrder[b.status.toLowerCase()] ?? 99;

      return aIndex.compareTo(bIndex);
    });
  }

  // ==============================================================
  // ADD ORDER
  // ==============================================================

  Future<PharmacyOrder> addOrder({
    required String pharmacyId,
    required String customerName,
    required int medicineCount,
    required String status,
    required double totalAmount,
    String deliveryAddress = '',
    double? deliveryLat,
    double? deliveryLng,
    String customerPhone = '',
    bool controlledDrug = false,
    bool coldChain = false,
  }) async {
    final currentPharmacyId = _getPharmacyId(pharmacyId);

    final locationData = <String, dynamic>{
      'deliveryAddress': deliveryAddress,
    };

    if (deliveryLat != null && deliveryLng != null) {
      locationData['dropoffLat'] = deliveryLat;
      locationData['dropoffLng'] = deliveryLng;
      locationData['dropoffLocation'] = {'lat': deliveryLat, 'lng': deliveryLng};
    }

    final docRef = await _firestore.collection('orders').add({
      'pharmacyId': currentPharmacyId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'medicineCount': medicineCount,
      'status': status,
      'totalAmount': totalAmount,
      'items': <String>[],
      'dropoffAddress': deliveryAddress,
      'controlledDrug': controlledDrug,
      'coldChain': coldChain,
      ...locationData,
      'riderId': null,
      'riderName': '',
      'riderPhone': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return _mapOrder(doc);
  }

  // ==============================================================
  // UPDATE ORDER
  // ==============================================================

  Future<void> updateOrder({
    required String id,
    required String customerName,
    required int medicineCount,
    required String status,
    required double totalAmount,
  }) async {
    final docId = _docIdFromOrder(id);

    if (docId.isEmpty) {
      throw Exception('Invalid order ID.');
    }

    await _firestore
        .collection('orders')
        .doc(docId)
        .update({
      'customerName': customerName,
      'medicineCount': medicineCount,
      'status': status,
      'totalAmount': totalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==============================================================
  // DELETE ORDER
  // ==============================================================

  Future<void> deleteOrder(String id) async {
    final docId = _docIdFromOrder(id);

    if (docId.isEmpty) {
      throw Exception('Invalid order ID.');
    }

    await _firestore
        .collection('orders')
        .doc(docId)
        .delete();
  }

  // ==============================================================
  // UPDATE ORDER STATUS
  // ==============================================================

  Future<void> updateOrderStatus({
    required String id,
    required String newStatus,
    String riderName = '',
    String riderPhone = '',
    String riderId = '',
  }) async {
    final docId = _docIdFromOrder(id);

    if (docId.isEmpty) {
      throw Exception('Invalid order ID.');
    }

    final updateData = <String, dynamic>{
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (riderName.trim().isNotEmpty) {
      updateData['riderName'] = riderName.trim();
    }

    if (riderPhone.trim().isNotEmpty) {
      updateData['riderPhone'] = riderPhone.trim();
    }

    if (riderId.trim().isNotEmpty) {
      updateData['riderId'] = riderId.trim();
    }

    if (newStatus.toLowerCase() == 'assigned') {
      updateData['assignedAt'] = FieldValue.serverTimestamp();
    }

    if (newStatus.toLowerCase() == 'delivered' ||
        newStatus.toLowerCase() == 'completed') {
      updateData['deliveredAt'] = FieldValue.serverTimestamp();
    }

    if (newStatus.toLowerCase() == 'failed') {
      updateData['failedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore
        .collection('orders')
        .doc(docId)
        .update(updateData);
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/order_model.dart';

class RiderOrderUpdate {
  const RiderOrderUpdate({
    required this.order,
    this.pickupQrValue,
  });

  final OrderModel order;
  final String? pickupQrValue;
}

class RiderDeliveryDetailsService {
  RiderDeliveryDetailsService._();
  static final RiderDeliveryDetailsService instance =
      RiderDeliveryDetailsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<OrderModel?> getOrder(String orderId) async {
    if (orderId.trim().isEmpty) return null;

    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return OrderModel.fromFirestore(doc);
  }

  Stream<RiderOrderUpdate?> orderStream(String orderId) {
    if (orderId.trim().isEmpty) {
      return Stream.value(null);
    }
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return RiderOrderUpdate(
        order: OrderModel.fromFirestore(doc),
        pickupQrValue: data['pickupQrValue'] as String?,
      );
    });
  }

  Future<void> verifyPickupQR({
    required String orderId,
    required String qrValue,
  }) async {
    final clean = qrValue.trim();
    if (orderId.isEmpty) {
      throw Exception('Order id is missing.');
    }
    if (clean.isEmpty) {
      throw Exception('Invalid QR code.');
    }

    try {
      await _firestore.collection('orders').doc(orderId).set(
        {
          'pickupQrValue': clean,
          'pickupVerified': true,
          'status': 'Picked Up',
          'pickedUpAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to verify pickup QR: $e');
    }
  }

  Future<void> startDelivery(String orderId) async {
    if (orderId.isEmpty) {
      throw Exception('Order id is missing.');
    }
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'On the Way',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to start delivery: $e');
    }
  }

  Future<void> completeDelivery({
    required String orderId,
    String? recipientName,
    List<Map<String, double>>? signaturePoints,
    bool medicineHandoverConfirmed = false,
  }) async {
    if (orderId.isEmpty) {
      throw Exception('Order id is missing.');
    }
    try {
      final handoverData = <String, dynamic>{
        'medicineHandoverConfirmed': medicineHandoverConfirmed,
        'completedAt': FieldValue.serverTimestamp(),
      };
      if (recipientName != null && recipientName.trim().isNotEmpty) {
        handoverData['recipientName'] = recipientName.trim();
      }
      if (signaturePoints != null && signaturePoints.isNotEmpty) {
        handoverData['signaturePoints'] = signaturePoints;
      }

      await _firestore.collection('orders').doc(orderId).set(
        {
          'status': 'Delivered',
          'deliveredAt': FieldValue.serverTimestamp(),
          ...handoverData,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _incrementRiderDeliveries(orderId);
    } catch (e) {
      throw Exception('Failed to complete delivery: $e');
    }
  }

  Future<void> _incrementRiderDeliveries(String orderId) async {
    final orderDoc =
        await _firestore.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) return;

    final riderId = orderDoc.data()?['riderId'] as String?;
    if (riderId == null || riderId.isEmpty) return;

    final riderDoc =
        await _firestore.collection('riders').doc(riderId).get();
    if (!riderDoc.exists) return;

    final currentCount = riderDoc.data()?['deliveries'] as int? ?? 0;
    await _firestore.collection('riders').doc(riderId).update({
      'deliveries': currentCount + 1,
      'currentOrder': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

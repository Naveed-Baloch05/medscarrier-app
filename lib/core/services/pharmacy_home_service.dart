import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/pharmacy_model.dart';

class PharmacyHomeService {
  PharmacyHomeService._();
  static final PharmacyHomeService instance = PharmacyHomeService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<PharmacyModel?> getPharmacy(String pharmacyId) async {
    if (pharmacyId.trim().isEmpty) return null;

    DocumentSnapshot<Map<String, dynamic>>? doc;

    final directDoc =
        await _firestore.collection('pharmacies').doc(pharmacyId).get();
    if (directDoc.exists && directDoc.data() != null) {
      doc = directDoc;
    }

    if (doc == null) {
      final uidQuery = await _firestore
          .collection('pharmacies')
          .where('uid', isEqualTo: pharmacyId)
          .limit(1)
          .get();
      if (uidQuery.docs.isNotEmpty) {
        doc = uidQuery.docs.first;
      }
    }

    if (doc == null) {
      final idQuery = await _firestore
          .collection('pharmacies')
          .where('id', isEqualTo: pharmacyId)
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
            : (doc.id.isNotEmpty ? doc.id : pharmacyId));

    return PharmacyModel.fromJson({...data, 'id': resolvedId});
  }

  Future<Map<String, int>> getOrderCounts(String pharmacyId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    int newCount = 0;
    int preparingCount = 0;
    int readyCount = 0;
    int deliveredCount = 0;

    for (final doc in snapshot.docs) {
      final status = (doc.data()['status'] as String? ?? '').toLowerCase();
      switch (status) {
        case 'new':
          newCount++;
          break;
        case 'preparing':
          preparingCount++;
          break;
        case 'ready':
        case 'assigned':
          readyCount++;
          break;
        case 'delivered':
        case 'completed':
          deliveredCount++;
          break;
      }
    }

    return {
      'totalOrders': snapshot.docs.length,
      'completedOrders': deliveredCount,
      'activeOrders': newCount + preparingCount + readyCount,
      'newOrders': newCount,
      'preparingOrders': preparingCount,
      'readyOrders': readyCount,
      'deliveredOrders': deliveredCount,
    };
  }
}

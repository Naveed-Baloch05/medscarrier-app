import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/pharmacy_notification_model.dart';

class PharmacyNotificationService {
  PharmacyNotificationService._();
  static final PharmacyNotificationService instance =
      PharmacyNotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notificationsCol(String uid) =>
      _firestore.collection('pharmacies').doc(uid).collection('notifications');

  Stream<List<PharmacyNotificationModel>> streamNotifications(String uid) {
    return _notificationsCol(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PharmacyNotificationModel.fromFirestore(doc))
            .toList());
  }

  Future<int> getUnreadCount(String uid) async {
    final snapshot = await _notificationsCol(uid)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> markAsRead(String uid, String notificationId) async {
    await _notificationsCol(uid).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final unread = await _notificationsCol(uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> createNotification({
    required String uid,
    required String title,
    required String body,
    required String type,
    String? orderId,
  }) async {
    await _notificationsCol(uid).add({
      'title': title,
      'body': body,
      'type': type,
      'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}

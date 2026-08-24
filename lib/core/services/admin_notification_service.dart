import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_notification_model.dart';

class AdminNotificationService {
  AdminNotificationService._();
  static final AdminNotificationService instance =
      AdminNotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notifications =>
      _firestore.collection('admin_notifications');

  Stream<List<AdminNotificationModel>> streamNotifications() {
    return _notifications
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminNotificationModel.fromFirestore(doc))
            .toList());
  }

  Future<int> getUnreadCount() async {
    final snapshot = await _notifications
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final unread = await _notifications
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    String? referenceId,
  }) async {
    await _notifications.add({
      'title': title,
      'body': body,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'referenceId': referenceId,
    });
  }
}

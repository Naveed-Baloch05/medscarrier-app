import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/support_ticket_model.dart';

class AdminSupportService {
  AdminSupportService._();
  static final AdminSupportService instance = AdminSupportService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _tickets => _firestore.collection('support_tickets');
  CollectionReference get _messages => _firestore.collection('support_messages');

  Stream<List<SupportTicketModel>> streamTickets() {
    return _tickets
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicketModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<SupportMessageModel>> streamMessages(String ticketId) {
    return _messages
        .where('ticketId', isEqualTo: ticketId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportMessageModel.fromFirestore(doc))
            .toList());
  }

  Future<void> sendAdminMessage({
    required String ticketId,
    required String message,
  }) async {
    await _messages.add({
      'ticketId': ticketId,
      'senderType': 'admin',
      'senderName': 'Admin',
      'senderId': 'admin',
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await _tickets.doc(ticketId).update({
      'lastMessage': message,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMessagesAsRead(String ticketId) async {
    final unread = await _messages
        .where('ticketId', isEqualTo: ticketId)
        .where('senderType', isNotEqualTo: 'admin')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    await _tickets.doc(ticketId).update({'unreadAdmin': 0});
  }

  Future<void> closeTicket(String ticketId) async {
    await _tickets.doc(ticketId).update({'status': 'closed'});
  }

  Future<void> reopenTicket(String ticketId) async {
    await _tickets.doc(ticketId).update({'status': 'open'});
  }
}

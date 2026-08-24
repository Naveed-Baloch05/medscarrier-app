import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.subject,
    required this.senderType,
    required this.senderName,
    required this.senderId,
    required this.status,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadAdmin,
  });

  final String id;
  final String subject;
  final String senderType;
  final String senderName;
  final String senderId;
  final String status;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadAdmin;

  factory SupportTicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicketModel(
      id: doc.id,
      subject: data['subject'] as String? ?? '',
      senderType: data['senderType'] as String? ?? 'customer',
      senderName: data['senderName'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : DateTime.now(),
      unreadAdmin: data['unreadAdmin'] as int? ?? 0,
    );
  }
}

class SupportMessageModel {
  const SupportMessageModel({
    required this.id,
    required this.ticketId,
    required this.senderType,
    required this.senderName,
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String ticketId;
  final String senderType;
  final String senderName;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  factory SupportMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportMessageModel(
      id: doc.id,
      ticketId: data['ticketId'] as String? ?? '',
      senderType: data['senderType'] as String? ?? 'admin',
      senderName: data['senderName'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'senderType': senderType,
      'senderName': senderName,
      'senderId': senderId,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}

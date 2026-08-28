import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyNotificationModel {
  const PharmacyNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String? orderId;

  factory PharmacyNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PharmacyNotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      orderId: data['orderId'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': isRead,
        'orderId': orderId,
      };
}

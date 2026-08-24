import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyModel {
  const PharmacyModel({
    required this.id,
    required this.pharmacyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.businessAddress,
    required this.gphcNumber,
    this.status = 'Pending',
    this.active = false,
    this.createdAt,
  });

  final String id;
  final String pharmacyName;
  final String contactName;
  final String email;
  final String phone;
  final String businessAddress;
  final String gphcNumber;
  final String status;
  final bool active;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'pharmacyName': pharmacyName,
        'contactName': contactName,
        'email': email,
        'phone': phone,
        'businessAddress': businessAddress,
        'gphcNumber': gphcNumber,
        'status': status,
        'active': active,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory PharmacyModel.fromJson(Map<String, dynamic> json) => PharmacyModel(
        id: json['id'] as String,
        pharmacyName: json['pharmacyName'] as String,
        contactName: json['contactName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        businessAddress: json['businessAddress'] as String,
        gphcNumber: json['gphcNumber'] as String,
        status: json['status'] as String? ?? 'Pending',
        active: json['active'] as bool? ?? false,
        createdAt: _parseDate(json['createdAt']),
      );
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

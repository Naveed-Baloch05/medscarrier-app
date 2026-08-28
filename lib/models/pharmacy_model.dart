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
    this.licenseDocumentUrl,
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
  final String? licenseDocumentUrl;
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
        'licenseDocumentUrl': licenseDocumentUrl,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['uid'] ?? json['pharmacyId'];
    final id = (rawId != null && rawId.toString().trim().isNotEmpty)
        ? rawId.toString().trim()
        : '';
    return PharmacyModel(
      id: id,
      pharmacyName: json['pharmacyName'] as String? ?? json['name'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      businessAddress: json['businessAddress'] as String? ?? json['address'] as String? ?? '',
      gphcNumber: json['gphcNumber'] as String? ?? json['licenseNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      active: json['active'] as bool? ?? false,
      licenseDocumentUrl: json['licenseDocumentUrl'] as String? ??
          json['licenseUrl'] as String? ??
          json['licenseDocument'] as String?,
      createdAt: _parseDate(json['createdAt']),
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
}

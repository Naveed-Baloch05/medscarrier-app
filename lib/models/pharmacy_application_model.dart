import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyApplicationModel {
  const PharmacyApplicationModel({
    required this.applicationId,
    required this.pharmacyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.businessAddress,
    required this.gphcNumber,
    this.licenseDocumentUrl,
    this.uid,
    this.status = 'pending',
    this.accountCreated = false,
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.reviewedBy,
  });

  final String applicationId;
  final String pharmacyName;
  final String contactName;
  final String email;
  final String phone;
  final String businessAddress;
  final String gphcNumber;
  final String? licenseDocumentUrl;
  final String? uid;
  final String status;
  final bool accountCreated;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? reviewedBy;

  factory PharmacyApplicationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PharmacyApplicationModel(
      applicationId: doc.id,
      pharmacyName: data['pharmacyName'] as String? ?? '',
      contactName: data['contactName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      businessAddress: data['businessAddress'] as String? ?? '',
      gphcNumber: data['gphcNumber'] as String? ?? '',
      licenseDocumentUrl: data['licenseDocumentUrl'] as String?,
      uid: data['uid'] as String?,
      status: data['status'] as String? ?? 'pending',
      accountCreated: data['accountCreated'] as bool? ?? false,
      submittedAt: _parseTimestamp(data['submittedAt']),
      approvedAt: _parseTimestamp(data['approvedAt']),
      rejectedAt: _parseTimestamp(data['rejectedAt']),
      rejectionReason: data['rejectionReason'] as String?,
      reviewedBy: data['reviewedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'pharmacyName': pharmacyName,
        'contactName': contactName,
        'email': email,
        'phone': phone,
        'businessAddress': businessAddress,
        'gphcNumber': gphcNumber,
        'licenseDocumentUrl': licenseDocumentUrl,
        'uid': uid,
        'status': status,
        'accountCreated': accountCreated,
        'submittedAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}

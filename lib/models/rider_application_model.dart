import 'package:cloud_firestore/cloud_firestore.dart';

class RiderApplicationModel {
  const RiderApplicationModel({
    required this.applicationId,
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleRegistrationNumber,
    this.profilePhotoUrl,
    this.drivingLicenceFrontUrl,
    this.drivingLicenceBackUrl,
    this.termsAccepted = false,
    this.rightToWorkConsent = false,
    this.backgroundCheckConsent = false,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  final String applicationId;
  String get id => applicationId;
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleRegistrationNumber;
  final String? profilePhotoUrl;
  final String? drivingLicenceFrontUrl;
  final String? drivingLicenceBackUrl;
  final bool termsAccepted;
  final bool rightToWorkConsent;
  final bool backgroundCheckConsent;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  factory RiderApplicationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return RiderApplicationModel(
      applicationId: doc.id,
      uid: data['uid'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      vehicleType: data['vehicleType'] as String? ?? '',
      vehicleRegistrationNumber:
          data['vehicleRegistrationNumber'] as String? ?? '',
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      drivingLicenceFrontUrl: data['drivingLicenceFrontUrl'] as String?,
      drivingLicenceBackUrl: data['drivingLicenceBackUrl'] as String?,
      termsAccepted: data['termsAccepted'] as bool? ?? false,
      rightToWorkConsent: data['rightToWorkConsent'] as bool? ?? false,
      backgroundCheckConsent:
          data['backgroundCheckConsent'] as bool? ?? false,
      status: data['status'] as String? ?? 'pending',
      submittedAt: _parseTimestamp(data['submittedAt']),
      reviewedAt: _parseTimestamp(data['reviewedAt']),
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'vehicleType': vehicleType,
        'vehicleRegistrationNumber': vehicleRegistrationNumber,
        'profilePhotoUrl': profilePhotoUrl,
        'drivingLicenceFrontUrl': drivingLicenceFrontUrl,
        'drivingLicenceBackUrl': drivingLicenceBackUrl,
        'termsAccepted': termsAccepted,
        'rightToWorkConsent': rightToWorkConsent,
        'backgroundCheckConsent': backgroundCheckConsent,
        'status': status,
        'submittedAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}

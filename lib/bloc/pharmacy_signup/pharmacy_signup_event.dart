import 'dart:io';

abstract class PharmacySignupEvent {
  const PharmacySignupEvent();
}

class PharmacySignupSubmitted extends PharmacySignupEvent {
  const PharmacySignupSubmitted({
    required this.pharmacyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.businessAddress,
    this.latitude,
    this.longitude,
    required this.gphcNumber,
    required this.password,
    this.licenseDocument,
  });

  final String pharmacyName;
  final String contactName;
  final String email;
  final String phone;
  final String businessAddress;
  final double? latitude;
  final double? longitude;
  final String gphcNumber;
  final String password;
  final File? licenseDocument;
}

class PharmacySignupReset extends PharmacySignupEvent {
  const PharmacySignupReset();
}

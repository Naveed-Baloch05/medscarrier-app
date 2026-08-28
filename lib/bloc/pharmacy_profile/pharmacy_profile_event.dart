import 'dart:io';

abstract class PharmacyProfileEvent {
  const PharmacyProfileEvent();
}

class LoadPharmacyProfile extends PharmacyProfileEvent {
  const LoadPharmacyProfile(this.uid);

  final String uid;
}

class PharmacyProfileUpdated extends PharmacyProfileEvent {
  const PharmacyProfileUpdated({
    required this.pharmacyName,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.businessAddress,
    required this.gphcNumber,
    this.openingTime,
    this.closingTime,
    this.notificationsEnabled,
  });

  final String pharmacyName;
  final String contactName;
  final String phone;
  final String email;
  final String businessAddress;
  final String gphcNumber;
  final String? openingTime;
  final String? closingTime;
  final bool? notificationsEnabled;
}

class PharmacyOpenToggled extends PharmacyProfileEvent {
  const PharmacyOpenToggled(this.isOpen);

  final bool isOpen;
}

class PharmacyProfilePhotoChanged extends PharmacyProfileEvent {
  const PharmacyProfilePhotoChanged(this.imageFile);

  final File imageFile;
}

class PharmacyProfilePhotoRemoved extends PharmacyProfileEvent {
  const PharmacyProfilePhotoRemoved();
}

class PharmacyPasswordChanged extends PharmacyProfileEvent {
  const PharmacyPasswordChanged({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}
